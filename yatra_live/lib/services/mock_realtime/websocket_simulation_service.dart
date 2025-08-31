import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'models/realtime_models.dart';
import 'performance_monitor.dart';

/// Simulates WebSocket-like real-time communication without external dependencies
class WebSocketSimulationService {
  static final WebSocketSimulationService _instance = WebSocketSimulationService._internal();
  factory WebSocketSimulationService() => _instance;
  WebSocketSimulationService._internal();

  // Core components
  final StreamController<dynamic> _inboundHub = StreamController<dynamic>.broadcast();
  final Map<String, StreamController<dynamic>> _clientChannels = {};
  final Map<String, ConnectionState> _connectionStates = {};
  
  // Performance monitoring
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  
  // Performance tracking
  final Map<String, List<double>> _latencyHistory = {};
  final Map<String, Stopwatch> _messageTimers = {};
  Timer? _heartbeatTimer;
  Timer? _latencyTimer;
  
  // Configuration
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _latencyCheckInterval = Duration(seconds: 5);
  static const Duration _maxLatency = Duration(seconds: 2);
  static const int _latencyHistorySize = 100;
  
  bool _isInitialized = false;
  final _random = math.Random();

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🌐 WebSocketSimulationService initialized');
    
    // Start heartbeat timer
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) => _sendHeartbeat());
    
    // Start latency measurement timer
    _latencyTimer = Timer.periodic(_latencyCheckInterval, (_) => _measureLatency());
    
    _isInitialized = true;
  }

  /// Connect a client to the simulated WebSocket
  Future<bool> connect(String clientId) async {
    try {
      // Simulate connection delay
      await Future.delayed(Duration(milliseconds: 100 + _random.nextInt(200)));
      
      if (_clientChannels.containsKey(clientId)) {
        print('⚠️ Client $clientId already connected');
        return true;
      }
      
      // Create client channel
      _clientChannels[clientId] = StreamController<dynamic>.broadcast();
      
      // Initialize connection state
      _connectionStates[clientId] = ConnectionState(
        clientId: clientId,
        isConnected: true,
        connectedAt: DateTime.now(),
      );
      
      // Initialize latency tracking
      _latencyHistory[clientId] = [];
      
      print('✅ Client $clientId connected to WebSocket simulation');
      
      // Send connection acknowledgment
      _dispatchToClient(clientId, {
        'type': 'connection',
        'status': 'connected',
        'clientId': clientId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      print('❌ Error connecting client $clientId: $e');
      return false;
    }
  }

  /// Disconnect a client from the simulated WebSocket
  Future<void> disconnect(String clientId) async {
    try {
      if (!_clientChannels.containsKey(clientId)) {
        print('⚠️ Client $clientId not connected');
        return;
      }
      
      // Update connection state
      final state = _connectionStates[clientId];
      if (state != null) {
        _connectionStates[clientId] = state.copyWith(
          isConnected: false,
          disconnectedAt: DateTime.now(),
        );
      }
      
      // Send disconnection message
      _dispatchToClient(clientId, {
        'type': 'connection',
        'status': 'disconnecting',
        'clientId': clientId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Simulate disconnection delay
      await Future.delayed(Duration(milliseconds: 50 + _random.nextInt(100)));
      
      // Close and remove channel
      await _clientChannels[clientId]?.close();
      _clientChannels.remove(clientId);
      _latencyHistory.remove(clientId);
      
      print('👋 Client $clientId disconnected from WebSocket simulation');
    } catch (e) {
      print('❌ Error disconnecting client $clientId: $e');
    }
  }

  /// Send a message to a specific client
  Future<bool> send(String clientId, dynamic message) async {
    final operationId = 'send_${DateTime.now().microsecondsSinceEpoch}';
    _performanceMonitor.startOperation(operationId);
    
    try {
      if (!_clientChannels.containsKey(clientId)) {
        print('⚠️ Cannot send message - client $clientId not connected');
        _performanceMonitor.recordDelivery(success: false, reason: 'client_not_connected');
        return false;
      }
      
      // Start latency measurement
      final messageId = _generateMessageId();
      _messageTimers[messageId] = Stopwatch()..start();
      
      // Simulate network delay (0-500ms)
      final networkDelay = _random.nextInt(500);
      await Future.delayed(Duration(milliseconds: networkDelay));
      
      // Wrap message with metadata
      final envelope = {
        'messageId': messageId,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'networkDelay': networkDelay,
      };
      
      // Dispatch to client
      _dispatchToClient(clientId, envelope);
      
      // Update connection state
      final state = _connectionStates[clientId];
      if (state != null) {
        _connectionStates[clientId] = state.copyWith(
          messagesSent: state.messagesSent + 1,
        );
      }
      
      // Stop latency measurement
      _recordLatency(clientId, messageId);
      
      // Record performance metrics
      _performanceMonitor.endOperation(operationId, 'websocket_send', tags: {
        'clientId': clientId,
        'networkDelay': networkDelay,
      });
      _performanceMonitor.recordDelivery(success: true);
      
      return true;
    } catch (e) {
      print('❌ Error sending message to client $clientId: $e');
      _performanceMonitor.recordDelivery(success: false, reason: e.toString());
      return false;
    }
  }

  /// Broadcast a message to all connected clients
  Future<void> broadcast(dynamic message) async {
    final connectedClients = _clientChannels.keys.toList();
    
    print('📢 Broadcasting to ${connectedClients.length} clients');
    
    await Future.wait(
      connectedClients.map((clientId) => send(clientId, message)),
    );
  }

  /// Get stream for a specific client
  Stream<dynamic>? getClientStream(String clientId) {
    return _clientChannels[clientId]?.stream;
  }

  /// Get the main inbound hub stream
  Stream<dynamic> get inboundHub => _inboundHub.stream;

  /// Internal dispatch method
  void _dispatchToClient(String clientId, dynamic message) {
    if (_clientChannels.containsKey(clientId)) {
      _clientChannels[clientId]!.add(message);
      
      // Also add to inbound hub for monitoring
      _inboundHub.add({
        'targetClient': clientId,
        'message': message,
        'dispatchedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Send heartbeat to all connected clients
  void _sendHeartbeat() {
    final connectedClients = _clientChannels.keys.toList();
    
    for (final clientId in connectedClients) {
      _dispatchToClient(clientId, {
        'type': 'heartbeat',
        'timestamp': DateTime.now().toIso8601String(),
        'serverTime': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  /// Measure and report latency
  void _measureLatency() {
    _latencyHistory.forEach((clientId, history) {
      if (history.isNotEmpty) {
        final avgLatency = history.reduce((a, b) => a + b) / history.length;
        final state = _connectionStates[clientId];
        
        if (state != null) {
          _connectionStates[clientId] = state.copyWith(
            averageLatency: avgLatency,
          );
        }
        
        // Record to performance monitor
        _performanceMonitor.recordMetric(PerfMetric(
          type: MetricType.latency,
          operation: 'websocket',
          value: avgLatency,
          tags: {'clientId': clientId},
        ));
      }
    });
    
    // Update connection count
    _performanceMonitor.updateConnectionCount(_clientChannels.length);
  }

  /// Record latency for a message
  void _recordLatency(String clientId, String messageId) {
    final timer = _messageTimers[messageId];
    if (timer != null) {
      timer.stop();
      final latency = timer.elapsedMilliseconds.toDouble();
      
      // Add to history
      final history = _latencyHistory[clientId] ?? [];
      history.add(latency);
      
      // Keep history size limited
      if (history.length > _latencyHistorySize) {
        history.removeAt(0);
      }
      
      _latencyHistory[clientId] = history;
      _messageTimers.remove(messageId);
    }
  }

  /// Generate unique message ID
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}';
  }

  /// Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    final stats = <String, dynamic>{};
    
    _connectionStates.forEach((clientId, state) {
      stats[clientId] = {
        'isConnected': state.isConnected,
        'connectionDuration': state.connectionDuration?.inSeconds,
        'messagesSent': state.messagesSent,
        'messagesReceived': state.messagesReceived,
        'averageLatency': state.averageLatency,
      };
    });
    
    return {
      'totalClients': _clientChannels.length,
      'activeConnections': _connectionStates.values.where((s) => s.isConnected).length,
      'clients': stats,
    };
  }

  /// Simulate connection drop
  Future<void> simulateConnectionDrop(String clientId, {Duration? duration}) async {
    if (!_clientChannels.containsKey(clientId)) return;
    
    print('🔌 Simulating connection drop for client $clientId');
    
    // Temporarily disconnect
    await disconnect(clientId);
    
    // Reconnect after duration
    if (duration != null) {
      await Future.delayed(duration);
      await connect(clientId);
      print('🔄 Client $clientId reconnected after ${duration.inSeconds}s');
    }
  }

  /// Simulate network congestion
  void simulateNetworkCongestion({double severity = 0.5}) {
    print('🌊 Simulating network congestion (severity: ${(severity * 100).toStringAsFixed(0)}%)');
    
    // This would affect the network delay calculation in send()
    // For demonstration, we're just logging it
  }

  /// Clean up resources
  void dispose() {
    _heartbeatTimer?.cancel();
    _latencyTimer?.cancel();
    
    // Close all client channels
    _clientChannels.forEach((_, controller) => controller.close());
    _clientChannels.clear();
    
    _connectionStates.clear();
    _latencyHistory.clear();
    _messageTimers.clear();
    
    _inboundHub.close();
    
    _isInitialized = false;
    
    print('🧹 WebSocketSimulationService disposed');
  }

  /// Check if a client is connected
  bool isClientConnected(String clientId) {
    return _clientChannels.containsKey(clientId) && 
           (_connectionStates[clientId]?.isConnected ?? false);
  }

  /// Get connected client IDs
  List<String> getConnectedClients() {
    return _clientChannels.keys.toList();
  }

  /// Get performance metrics
  PerfMetric getLatencyMetric(String clientId) {
    final history = _latencyHistory[clientId] ?? [];
    if (history.isEmpty) {
      return PerfMetric(
        type: MetricType.latency,
        operation: 'websocket_$clientId',
        value: 0.0,
      );
    }
    
    // Calculate percentiles
    final sorted = List<double>.from(history)..sort();
    final p50 = sorted[sorted.length ~/ 2];
    final p95 = sorted[(sorted.length * 0.95).floor()];
    final avg = sorted.reduce((a, b) => a + b) / sorted.length;
    
    return PerfMetric(
      type: MetricType.latency,
      operation: 'websocket_$clientId',
      value: avg,
      tags: {
        'p50': p50,
        'p95': p95,
        'samples': sorted.length,
      },
    );
  }
}
