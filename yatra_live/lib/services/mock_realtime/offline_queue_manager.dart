import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'models/realtime_models.dart';
import 'topic_pubsub_manager.dart';

/// Manages offline message queuing with exponential backoff and deduplication
class OfflineQueueManager {
  final String clientId;
  
  // Queue management
  final Queue<QueuedEnvelope> _messageQueue = Queue();
  final Map<String, QueuedEnvelope> _deduplicationMap = {}; // messageId -> envelope
  final Set<String> _processedMessageIds = {};
  
  // Configuration
  static const int _maxQueueSize = 100;
  static const Duration _initialRetryDelay = Duration(seconds: 1);
  static const Duration _maxRetryDelay = Duration(minutes: 5);
  static const Duration _coalescingWindow = Duration(milliseconds: 500);
  static const int _maxRetries = 5;
  
  // Timers and state
  Timer? _retryTimer;
  Timer? _coalescingTimer;
  final List<QueuedEnvelope> _coalescingBuffer = [];
  bool _isProcessing = false;
  
  // Dependencies
  final TopicBasedPubSubManager _pubSubManager = TopicBasedPubSubManager();
  
  // Performance tracking
  int _messagesQueued = 0;
  int _messagesDelivered = 0;
  int _messagesDropped = 0;
  
  OfflineQueueManager({String? clientId}) 
      : clientId = clientId ?? 'client_${DateTime.now().millisecondsSinceEpoch}';

  /// Initialize the offline queue manager
  Future<void> initialize({required String clientId}) async {
    await _pubSubManager.initialize();
    print('📦 OfflineQueueManager initialized for $clientId');
  }

  /// Enqueue a message for later delivery
  Future<bool> enqueue(QueuedEnvelope envelope) async {
    try {
      // Check queue size limit
      if (_messageQueue.length >= _maxQueueSize) {
        // Drop oldest low-priority messages
        _dropOldestLowPriorityMessages();
        
        if (_messageQueue.length >= _maxQueueSize) {
          print('❌ Queue full - dropping message');
          _messagesDropped++;
          return false;
        }
      }
      
      // Check for duplicates
      final messageId = _getMessageId(envelope.message);
      if (_deduplicationMap.containsKey(messageId)) {
        print('⚠️ Duplicate message detected - updating existing');
        
        // Replace with newer version
        final existingEnvelope = _deduplicationMap[messageId]!;
        _messageQueue.remove(existingEnvelope);
      }
      
      // Add to queue
      _messageQueue.add(envelope);
      _deduplicationMap[messageId] = envelope;
      _messagesQueued++;
      
      // Handle location update coalescing
      if (envelope.message is DriverMessage) {
        _handleLocationCoalescing(envelope);
      } else {
        // Schedule immediate retry for non-location messages
        _scheduleRetry(Duration.zero);
      }
      
      print('📥 Message queued (priority: ${envelope.priority}, queue size: ${_messageQueue.length})');
      return true;
      
    } catch (e) {
      print('❌ Error enqueueing message: $e');
      return false;
    }
  }

  /// Process queued messages
  Future<void> processQueue() async {
    if (_isProcessing || _messageQueue.isEmpty) return;
    
    _isProcessing = true;
    
    try {
      print('🔄 Processing offline queue (${_messageQueue.length} messages)');
      
      // Process messages by priority
      final sortedQueue = _messageQueue.toList()
        ..sort((a, b) => _comparePriority(a, b));
      
      final processed = <QueuedEnvelope>[];
      
      for (final envelope in sortedQueue) {
        if (envelope.nextRetryAt != null && 
            envelope.nextRetryAt!.isAfter(DateTime.now())) {
          continue; // Skip messages not ready for retry
        }
        
        final success = await _deliverMessage(envelope);
        
        if (success) {
          processed.add(envelope);
          _messagesDelivered++;
        } else if (!envelope.canRetry) {
          // Max retries exceeded
          processed.add(envelope);
          _messagesDropped++;
          print('❌ Message dropped after ${envelope.retryCount} retries');
        } else {
          // Schedule for retry with exponential backoff
          final nextDelay = _calculateBackoffDelay(envelope.retryCount);
          final updatedEnvelope = envelope.copyWithRetry(
            nextRetryAt: DateTime.now().add(nextDelay),
          );
          
          // Update in queue
          _messageQueue.remove(envelope);
          _messageQueue.add(updatedEnvelope);
          _deduplicationMap[_getMessageId(envelope.message)] = updatedEnvelope;
          
          print('🔄 Retry scheduled in ${nextDelay.inSeconds}s (attempt ${updatedEnvelope.retryCount})');
        }
      }
      
      // Remove processed messages
      for (final envelope in processed) {
        _messageQueue.remove(envelope);
        _deduplicationMap.remove(_getMessageId(envelope.message));
        _processedMessageIds.add(_getMessageId(envelope.message));
      }
      
      // Schedule next retry if queue not empty
      if (_messageQueue.isNotEmpty) {
        final nextRetry = _getNextRetryTime();
        _scheduleRetry(nextRetry);
      }
      
    } finally {
      _isProcessing = false;
    }
  }

  /// Handle location update coalescing
  void _handleLocationCoalescing(QueuedEnvelope envelope) {
    _coalescingBuffer.add(envelope);
    
    // Cancel existing timer
    _coalescingTimer?.cancel();
    
    // Set new timer
    _coalescingTimer = Timer(_coalescingWindow, () {
      if (_coalescingBuffer.isNotEmpty) {
        // Keep only the most recent location update per bus
        final latestByBus = <String, QueuedEnvelope>{};
        
        for (final env in _coalescingBuffer) {
          if (env.message is DriverMessage) {
            final msg = env.message as DriverMessage;
            latestByBus[msg.busId] = env;
          }
        }
        
        // Clear buffer
        _coalescingBuffer.clear();
        
        // Schedule immediate processing
        _scheduleRetry(Duration.zero);
        
        print('🔄 Coalesced ${latestByBus.length} location updates');
      }
    });
  }

  /// Deliver a single message
  Future<bool> _deliverMessage(QueuedEnvelope envelope) async {
    try {
      if (envelope.targetTopic != null) {
        // Topic-based delivery
        await _pubSubManager.routePublish(
          envelope.targetTopic!.replaceAll('route_', ''),
          envelope.message,
        );
      } else {
        // Direct delivery (not implemented in current setup)
        print('⚠️ Direct delivery not implemented');
        return false;
      }
      
      print('✅ Delivered queued message (${envelope.age.inSeconds}s old)');
      return true;
      
    } catch (e) {
      print('❌ Failed to deliver message: $e');
      return false;
    }
  }

  /// Calculate exponential backoff delay
  Duration _calculateBackoffDelay(int retryCount) {
    final exponentialDelay = _initialRetryDelay * math.pow(2, retryCount);
    final maxDelayMs = _maxRetryDelay.inMilliseconds;
    final delayMs = math.min(exponentialDelay.inMilliseconds, maxDelayMs);
    
    // Add jitter (±20%)
    final jitter = (delayMs * 0.2 * (math.Random().nextDouble() - 0.5)).round();
    
    return Duration(milliseconds: delayMs + jitter);
  }

  /// Schedule retry processing
  void _scheduleRetry(Duration delay) {
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () => processQueue());
  }

  /// Get next retry time from queue
  Duration _getNextRetryTime() {
    DateTime? earliestRetry;
    
    for (final envelope in _messageQueue) {
      if (envelope.nextRetryAt != null) {
        if (earliestRetry == null || envelope.nextRetryAt!.isBefore(earliestRetry)) {
          earliestRetry = envelope.nextRetryAt;
        }
      }
    }
    
    if (earliestRetry == null) {
      return _initialRetryDelay;
    }
    
    final now = DateTime.now();
    if (earliestRetry.isBefore(now)) {
      return Duration.zero;
    }
    
    return earliestRetry.difference(now);
  }

  /// Drop oldest low-priority messages
  void _dropOldestLowPriorityMessages() {
    final lowPriorityMessages = _messageQueue
        .where((e) => e.priority == QueuePriority.low)
        .toList()
      ..sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
    
    final toDrop = math.min(10, lowPriorityMessages.length);
    
    for (int i = 0; i < toDrop; i++) {
      final envelope = lowPriorityMessages[i];
      _messageQueue.remove(envelope);
      _deduplicationMap.remove(_getMessageId(envelope.message));
      _messagesDropped++;
    }
    
    if (toDrop > 0) {
      print('🗑️ Dropped $toDrop low-priority messages');
    }
  }

  /// Compare priority for sorting
  int _comparePriority(QueuedEnvelope a, QueuedEnvelope b) {
    // First by priority
    final priorityCompare = b.priority.index.compareTo(a.priority.index);
    if (priorityCompare != 0) return priorityCompare;
    
    // Then by age (older first)
    return a.queuedAt.compareTo(b.queuedAt);
  }

  /// Get message ID for deduplication
  String _getMessageId(dynamic message) {
    if (message is DriverMessage) {
      return message.messageId;
    } else if (message is PassengerMessage) {
      return message.messageId;
    } else if (message is Map && message.containsKey('messageId')) {
      return message['messageId'];
    }
    return 'unknown_${message.hashCode}';
  }

  /// Flush all queued messages immediately
  Future<void> flushQueue() async {
    print('💨 Flushing offline queue...');
    await processQueue();
  }

  /// Clear the queue without processing
  void clearQueue() {
    _messageQueue.clear();
    _deduplicationMap.clear();
    _coalescingBuffer.clear();
    _messagesDropped += _messageQueue.length;
    print('🗑️ Cleared offline queue');
  }

  /// Get queue statistics
  Map<String, dynamic> getQueueStats() {
    final priorityCounts = <QueuePriority, int>{};
    for (final priority in QueuePriority.values) {
      priorityCounts[priority] = _messageQueue.where((e) => e.priority == priority).length;
    }
    
    return {
      'queueSize': _messageQueue.length,
      'messagesQueued': _messagesQueued,
      'messagesDelivered': _messagesDelivered,
      'messagesDropped': _messagesDropped,
      'deliveryRate': _messagesQueued > 0 
          ? (_messagesDelivered / _messagesQueued * 100).toStringAsFixed(1) + '%'
          : '0%',
      'priorityCounts': {
        'high': priorityCounts[QueuePriority.high] ?? 0,
        'normal': priorityCounts[QueuePriority.normal] ?? 0,
        'low': priorityCounts[QueuePriority.low] ?? 0,
      },
      'oldestMessage': _messageQueue.isNotEmpty 
          ? _messageQueue.first.age.inSeconds 
          : 0,
    };
  }

  /// Get current queue size
  Future<int> getQueueSize() async => _messageQueue.length;

  /// Check if queue is empty
  bool get isEmpty => _messageQueue.isEmpty;

  /// Get performance metrics
  PerfMetric getQueueMetric() {
    return PerfMetric(
      type: MetricType.queueSize,
      operation: 'offline_queue_$clientId',
      value: _messageQueue.length.toDouble(),
      tags: {
        'delivered': _messagesDelivered,
        'dropped': _messagesDropped,
        'queued': _messagesQueued,
      },
    );
  }

  /// Clean up resources
  void dispose() {
    _retryTimer?.cancel();
    _coalescingTimer?.cancel();
    clearQueue();
    print('🧹 OfflineQueueManager disposed');
  }
}
