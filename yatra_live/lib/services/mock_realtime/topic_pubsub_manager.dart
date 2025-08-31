import 'dart:async';
import 'dart:collection';
import 'models/realtime_models.dart';
import 'websocket_simulation_service.dart';
import 'performance_monitor.dart';

/// Manages topic-based publish-subscribe for bus routes
class TopicBasedPubSubManager {
  static final TopicBasedPubSubManager _instance = TopicBasedPubSubManager._internal();
  factory TopicBasedPubSubManager() => _instance;
  TopicBasedPubSubManager._internal();

  // Core dependencies
  final WebSocketSimulationService _webSocketService = WebSocketSimulationService();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  
  // Topic management - O(1) lookups
  final Map<String, BusRouteTopic> _topics = {};
  final Map<String, Set<String>> _clientSubscriptions = {}; // clientId -> Set<routeId>
  
  // Performance tracking
  final Map<String, Stopwatch> _broadcastTimers = {};
  final Queue<PerfMetric> _performanceMetrics = Queue();
  static const int _maxMetricsSize = 1000;
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize WebSocket service
    await _webSocketService.initialize();
    
    print('📡 TopicBasedPubSubManager initialized');
    _isInitialized = true;
  }

  /// Subscribe a client to a route topic
  Future<bool> subscribe(String clientId, String routeId) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Ensure client is connected to WebSocket
      if (!_webSocketService.isClientConnected(clientId)) {
        final connected = await _webSocketService.connect(clientId);
        if (!connected) {
          print('❌ Failed to connect client $clientId to WebSocket');
          return false;
        }
      }
      
      // Create topic if it doesn't exist
      if (!_topics.containsKey(routeId)) {
        _topics[routeId] = BusRouteTopic(routeId: routeId);
      }
      
      // Add subscriber to topic - O(1)
      final topic = _topics[routeId]!;
      topic.addSubscriber(clientId);
      
      // Track client subscriptions - O(1)
      _clientSubscriptions.putIfAbsent(clientId, () => {});
      _clientSubscriptions[clientId]!.add(routeId);
      
      // Send subscription confirmation
      await _webSocketService.send(clientId, {
        'type': 'subscription',
        'action': 'subscribed',
        'routeId': routeId,
        'subscriberCount': topic.subscriberCount,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      stopwatch.stop();
      _recordPerformanceMetric(
        type: MetricType.latency,
        operation: 'subscribe',
        value: stopwatch.elapsedMilliseconds.toDouble(),
      );
      
      print('✅ Client $clientId subscribed to route $routeId (${stopwatch.elapsedMilliseconds}ms)');
      return true;
    } catch (e) {
      print('❌ Error subscribing client $clientId to route $routeId: $e');
      return false;
    }
  }

  /// Unsubscribe a client from a route topic
  Future<bool> unsubscribe(String clientId, String routeId) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Check if topic exists
      if (!_topics.containsKey(routeId)) {
        print('⚠️ Topic for route $routeId does not exist');
        return false;
      }
      
      // Remove subscriber from topic - O(1)
      final topic = _topics[routeId]!;
      topic.removeSubscriber(clientId);
      
      // Update client subscriptions - O(1)
      if (_clientSubscriptions.containsKey(clientId)) {
        _clientSubscriptions[clientId]!.remove(routeId);
        
        // Clean up empty subscription sets
        if (_clientSubscriptions[clientId]!.isEmpty) {
          _clientSubscriptions.remove(clientId);
        }
      }
      
      // Clean up empty topics
      if (topic.subscriberCount == 0) {
        _topics.remove(routeId);
      }
      
      // Send unsubscription confirmation
      if (_webSocketService.isClientConnected(clientId)) {
        await _webSocketService.send(clientId, {
          'type': 'subscription',
          'action': 'unsubscribed',
          'routeId': routeId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
      
      stopwatch.stop();
      _recordPerformanceMetric(
        type: MetricType.latency,
        operation: 'unsubscribe',
        value: stopwatch.elapsedMilliseconds.toDouble(),
      );
      
      print('👋 Client $clientId unsubscribed from route $routeId (${stopwatch.elapsedMilliseconds}ms)');
      return true;
    } catch (e) {
      print('❌ Error unsubscribing client $clientId from route $routeId: $e');
      return false;
    }
  }

  /// Publish a message to all subscribers of a route
  Future<void> routePublish(String routeId, dynamic message) async {
    final broadcastId = 'broadcast_${DateTime.now().millisecondsSinceEpoch}';
    final stopwatch = Stopwatch()..start();
    _broadcastTimers[broadcastId] = stopwatch;
    
    try {
      // Check if topic exists
      if (!_topics.containsKey(routeId)) {
        print('⚠️ No subscribers for route $routeId');
        return;
      }
      
      final topic = _topics[routeId]!;
      final subscribers = topic.subscribers.toList(); // Copy to avoid concurrent modification
      
      if (subscribers.isEmpty) {
        print('⚠️ Route $routeId has no active subscribers');
        return;
      }
      
      print('📢 Publishing to ${subscribers.length} subscribers on route $routeId');
      
      // Wrap message with route metadata
      final envelope = {
        'routeId': routeId,
        'broadcastId': broadcastId,
        'data': message,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Broadcast to all subscribers in parallel
      final futures = <Future<bool>>[];
      for (final clientId in subscribers) {
        if (_webSocketService.isClientConnected(clientId)) {
          futures.add(_webSocketService.send(clientId, envelope));
        } else {
          // Remove disconnected clients
          topic.removeSubscriber(clientId);
          _clientSubscriptions[clientId]?.remove(routeId);
        }
      }
      
      // Wait for all sends to complete
      final results = await Future.wait(futures);
      final successCount = results.where((r) => r).length;
      
      stopwatch.stop();
      final broadcastTime = stopwatch.elapsedMilliseconds;
      
      // Record performance metrics
      _recordPerformanceMetric(
        type: MetricType.latency,
        operation: 'route_publish',
        value: broadcastTime.toDouble(),
        tags: {
          'routeId': routeId,
          'subscribers': subscribers.length,
          'successful': successCount,
        },
      );
      
      // Record to global performance monitor
      _performanceMonitor.recordMetric(PerfMetric(
        type: MetricType.latency,
        operation: 'route_publish',
        value: broadcastTime.toDouble(),
        tags: {
          'routeId': routeId,
          'subscribers': subscribers.length,
          'successful': successCount,
        },
      ));
      
      // Record throughput
      if (subscribers.isNotEmpty) {
        final throughput = (successCount / (broadcastTime / 1000.0)); // messages per second
        _performanceMonitor.recordThroughput('route_publish', throughput);
      }
      
      // Ensure broadcast completed within 100ms
      if (broadcastTime > 100) {
        print('⚠️ Broadcast took ${broadcastTime}ms - exceeds 100ms target');
      } else {
        print('✅ Broadcast completed in ${broadcastTime}ms (${successCount}/${subscribers.length} successful)');
      }
      
    } finally {
      _broadcastTimers.remove(broadcastId);
    }
  }

  /// Get all subscribers for a route
  Set<String> getRouteSubscribers(String routeId) {
    return _topics[routeId]?.subscribers ?? {};
  }

  /// Get all routes a client is subscribed to
  Set<String> getClientSubscriptions(String clientId) {
    return Set.from(_clientSubscriptions[clientId] ?? {});
  }

  /// Unsubscribe a client from all topics
  Future<void> unsubscribeAll(String clientId) async {
    final subscriptions = getClientSubscriptions(clientId);
    
    for (final routeId in subscriptions) {
      await unsubscribe(clientId, routeId);
    }
    
    // Disconnect from WebSocket
    await _webSocketService.disconnect(clientId);
  }

  /// Get topic statistics
  Map<String, dynamic> getTopicStats() {
    final stats = <String, dynamic>{};
    
    _topics.forEach((routeId, topic) {
      stats[routeId] = {
        'subscriberCount': topic.subscriberCount,
        'subscribers': topic.subscribers.toList(),
        'createdAt': topic.createdAt.toIso8601String(),
      };
    });
    
    return {
      'totalTopics': _topics.length,
      'totalSubscribers': _clientSubscriptions.length,
      'topics': stats,
    };
  }

  /// Get performance metrics
  List<PerfMetric> getPerformanceMetrics({int? limit}) {
    final metrics = _performanceMetrics.toList();
    if (limit != null && metrics.length > limit) {
      return metrics.sublist(metrics.length - limit);
    }
    return metrics;
  }

  /// Record performance metric
  void _recordPerformanceMetric({
    required MetricType type,
    required String operation,
    required double value,
    Map<String, dynamic>? tags,
  }) {
    final metric = PerfMetric(
      type: type,
      operation: operation,
      value: value,
      tags: tags,
    );
    
    _performanceMetrics.add(metric);
    
    // Keep metrics queue size limited
    while (_performanceMetrics.length > _maxMetricsSize) {
      _performanceMetrics.removeFirst();
    }
  }

  /// Broadcast system message to all clients
  Future<void> broadcastSystemMessage(String message, {String? severity}) async {
    final systemMessage = {
      'type': 'system',
      'message': message,
      'severity': severity ?? 'info',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Get all unique clients across all topics
    final allClients = <String>{};
    _clientSubscriptions.keys.forEach(allClients.add);
    
    print('📢 Broadcasting system message to ${allClients.length} clients');
    
    for (final clientId in allClients) {
      if (_webSocketService.isClientConnected(clientId)) {
        await _webSocketService.send(clientId, systemMessage);
      }
    }
  }

  /// Handle client disconnect - clean up subscriptions
  void handleClientDisconnect(String clientId) {
    final subscriptions = getClientSubscriptions(clientId);
    
    for (final routeId in subscriptions) {
      if (_topics.containsKey(routeId)) {
        _topics[routeId]!.removeSubscriber(clientId);
        
        // Clean up empty topics
        if (_topics[routeId]!.subscriberCount == 0) {
          _topics.remove(routeId);
        }
      }
    }
    
    _clientSubscriptions.remove(clientId);
    print('🧹 Cleaned up subscriptions for disconnected client $clientId');
  }

  /// Get average broadcast latency
  double getAverageBroadcastLatency() {
    final broadcastMetrics = _performanceMetrics
        .where((m) => m.type == MetricType.latency && m.operation == 'route_publish')
        .toList();
    
    if (broadcastMetrics.isEmpty) return 0.0;
    
    final sum = broadcastMetrics.fold<double>(0, (sum, m) => sum + m.value);
    return sum / broadcastMetrics.length;
  }

  /// Clean up resources
  void dispose() {
    _topics.clear();
    _clientSubscriptions.clear();
    _broadcastTimers.clear();
    _performanceMetrics.clear();
    
    _isInitialized = false;
    print('🧹 TopicBasedPubSubManager disposed');
  }
}
