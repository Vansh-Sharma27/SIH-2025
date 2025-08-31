import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'models/realtime_models.dart';
import 'topic_pubsub_manager.dart';
import 'websocket_simulation_service.dart';
import 'notification_simulation_layer.dart';
import '../location_service_demo.dart';

/// Adapter for passenger app to receive real-time bus updates
class PassengerAppRealtimeAdapter {
  final String passengerId;
  
  // Dependencies
  final TopicBasedPubSubManager _pubSubManager = TopicBasedPubSubManager();
  final WebSocketSimulationService _webSocketService = WebSocketSimulationService();
  final NotificationSimulationLayer _notificationLayer = NotificationSimulationLayer();
  
  // State management
  final Map<String, Queue<DriverMessage>> _messageCache = {}; // routeId -> messages
  final Map<String, StreamController<DriverMessage>> _routeStreams = {};
  final Map<String, StreamSubscription<dynamic>> _subscriptions = {};
  
  String? _currentRouteId;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  
  // Configuration
  static const int _maxCacheSize = 20;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  
  // Location tracking for notifications
  Position? _userLocation;
  final Map<String, DateTime> _lastNotificationTime = {};
  
  PassengerAppRealtimeAdapter({required this.passengerId});

  /// Initialize the adapter
  Future<void> initialize() async {
    await _pubSubManager.initialize();
    await _notificationLayer.initialize(passengerId: passengerId);
    
    // Set up WebSocket listener
    _setupWebSocketListener();
    
    print('👤 PassengerAppRealtimeAdapter initialized for $passengerId');
  }

  /// Subscribe to a route for real-time updates
  Future<bool> subscribeToRoute(String routeId) async {
    try {
      // Unsubscribe from previous route if any
      if (_currentRouteId != null && _currentRouteId != routeId) {
        await unsubscribeFromRoute(_currentRouteId!);
      }
      
      _currentRouteId = routeId;
      
      // Create stream controller for this route
      if (!_routeStreams.containsKey(routeId)) {
        _routeStreams[routeId] = StreamController<DriverMessage>.broadcast();
      }
      
      // Initialize cache
      _messageCache.putIfAbsent(routeId, () => Queue());
      
      // Subscribe via PubSub manager
      final success = await _pubSubManager.subscribe(passengerId, routeId);
      
      if (success) {
        _isConnected = true;
        print('✅ Passenger $passengerId subscribed to route $routeId');
        
        // Send subscription message
        final subscribeMsg = PassengerMessage(
          passengerId: passengerId,
          routeId: routeId,
          type: MessageType.routeSubscribe,
          payload: {
            'timestamp': DateTime.now().toIso8601String(),
            'location': _userLocation != null ? {
              'latitude': _userLocation!.latitude,
              'longitude': _userLocation!.longitude,
            } : null,
          },
        );
        
        await _pubSubManager.routePublish(routeId, subscribeMsg.toJson());
      } else {
        // Switch to offline mode
        _handleOfflineMode(routeId);
      }
      
      return success;
    } catch (e) {
      print('❌ Error subscribing to route $routeId: $e');
      _handleOfflineMode(routeId);
      return false;
    }
  }

  /// Unsubscribe from a route
  Future<void> unsubscribeFromRoute(String routeId) async {
    try {
      await _pubSubManager.unsubscribe(passengerId, routeId);
      
      // Send unsubscribe message
      final unsubscribeMsg = PassengerMessage(
        passengerId: passengerId,
        routeId: routeId,
        type: MessageType.routeUnsubscribe,
        payload: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      await _pubSubManager.routePublish(routeId, unsubscribeMsg.toJson());
      
      // Clean up
      await _routeStreams[routeId]?.close();
      _routeStreams.remove(routeId);
      
      if (_currentRouteId == routeId) {
        _currentRouteId = null;
      }
      
      print('👋 Passenger $passengerId unsubscribed from route $routeId');
    } catch (e) {
      print('❌ Error unsubscribing from route $routeId: $e');
    }
  }

  /// Set up WebSocket listener
  void _setupWebSocketListener() {
    final clientStream = _webSocketService.getClientStream(passengerId);
    if (clientStream == null) return;
    
    _subscriptions['websocket'] = clientStream.listen(
      (message) => _handleIncomingMessage(message),
      onError: (error) => _handleConnectionError(error),
      onDone: () => _handleConnectionClosed(),
    );
  }

  /// Handle incoming WebSocket messages
  void _handleIncomingMessage(dynamic message) {
    try {
      if (message is Map && message.containsKey('data')) {
        final data = message['data'];
        
        // Parse driver message
        if (data is Map && data['type'] == 'driver_update') {
          final driverMessage = DriverMessage.fromJson(data);
          _processDriverMessage(driverMessage);
        }
      }
    } catch (e) {
      print('❌ Error processing incoming message: $e');
    }
  }

  /// Process driver message
  void _processDriverMessage(DriverMessage message) {
    // Add to cache
    _addToCache(message.routeId, message);
    
    // Emit to stream
    if (_routeStreams.containsKey(message.routeId)) {
      _routeStreams[message.routeId]!.add(message);
    }
    
    // Check for notifications
    _checkNotificationTriggers(message);
    
    print('📍 Received update: Bus ${message.busId} at (${message.latitude.toStringAsFixed(4)}, ${message.longitude.toStringAsFixed(4)})');
  }

  /// Add message to cache
  void _addToCache(String routeId, DriverMessage message) {
    final cache = _messageCache.putIfAbsent(routeId, () => Queue());
    
    // Remove duplicates from same bus
    cache.removeWhere((m) => m.busId == message.busId && 
                            m.timestamp.isBefore(message.timestamp));
    
    cache.add(message);
    
    // Maintain cache size
    while (cache.length > _maxCacheSize) {
      cache.removeFirst();
    }
  }

  /// Check and trigger notifications
  void _checkNotificationTriggers(DriverMessage message) {
    if (_userLocation == null) return;
    
    // Calculate distance to bus
    final distance = LocationServiceDemo.calculateDistance(
      _userLocation!.latitude,
      _userLocation!.longitude,
      message.latitude,
      message.longitude,
    );
    
    // Bus arrival notification
    if (distance < 300) { // Within 300 meters
      final notificationKey = 'arrival_${message.busId}';
      if (_shouldSendNotification(notificationKey, Duration(minutes: 5))) {
        _notificationLayer.sendBusArrivalNotification(
          busId: message.busId,
          busNumber: 'Bus ${message.busId}',
          distance: distance,
          estimatedMinutes: (distance / 250).round(), // Rough estimate
        );
        _lastNotificationTime[notificationKey] = DateTime.now();
      }
    }
    
    // Crowding notification
    if (message.crowdLevel == 'high' && message.passengerCount != null && 
        message.passengerCount! > 42) { // >85% of 50 capacity
      final notificationKey = 'crowding_${message.busId}';
      if (_shouldSendNotification(notificationKey, Duration(minutes: 10))) {
        _notificationLayer.sendCrowdingNotification(
          busId: message.busId,
          busNumber: 'Bus ${message.busId}',
          crowdLevel: message.crowdLevel!,
          passengerCount: message.passengerCount!,
        );
        _lastNotificationTime[notificationKey] = DateTime.now();
      }
    }
  }

  /// Check if notification should be sent
  bool _shouldSendNotification(String key, Duration minInterval) {
    final lastTime = _lastNotificationTime[key];
    if (lastTime == null) return true;
    
    return DateTime.now().difference(lastTime) > minInterval;
  }

  /// Handle offline mode
  void _handleOfflineMode(String routeId) {
    _isConnected = false;
    print('📴 Switching to offline mode for route $routeId');
    
    // Use cached data
    final cache = _messageCache[routeId];
    if (cache != null && cache.isNotEmpty) {
      print('📱 Using ${cache.length} cached messages');
      
      // Emit cached messages to stream
      for (final message in cache) {
        _routeStreams[routeId]?.add(message);
      }
    }
    
    // Schedule reconnection
    _scheduleReconnect();
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () async {
      if (_currentRouteId != null && !_isConnected) {
        print('🔄 Attempting to reconnect...');
        final success = await subscribeToRoute(_currentRouteId!);
        
        if (success) {
          // Send acknowledgment with cached message count
          await _sendReconnectAcknowledgment();
        } else {
          // Retry again
          _scheduleReconnect();
        }
      }
    });
  }

  /// Send reconnect acknowledgment
  Future<void> _sendReconnectAcknowledgment() async {
    if (_currentRouteId == null) return;
    
    final cache = _messageCache[_currentRouteId];
    final ackMessage = PassengerMessage(
      passengerId: passengerId,
      routeId: _currentRouteId,
      type: MessageType.unknown,
      payload: {
        'event': 'reconnect',
        'cachedMessages': cache?.length ?? 0,
        'lastMessageTime': cache?.isNotEmpty == true 
            ? cache!.last.timestamp.toIso8601String() 
            : null,
      },
    );
    
    await _pubSubManager.routePublish(_currentRouteId!, ackMessage.toJson());
    print('✅ Sent reconnect acknowledgment');
  }

  /// Handle connection error
  void _handleConnectionError(dynamic error) {
    print('❌ Connection error: $error');
    if (_currentRouteId != null) {
      _handleOfflineMode(_currentRouteId!);
    }
  }

  /// Handle connection closed
  void _handleConnectionClosed() {
    print('🔌 Connection closed');
    _isConnected = false;
    if (_currentRouteId != null) {
      _handleOfflineMode(_currentRouteId!);
    }
  }

  /// Update user location
  void updateUserLocation(Position location) {
    _userLocation = location;
  }

  /// Get stream for a route
  Stream<DriverMessage>? getRouteStream(String routeId) {
    return _routeStreams[routeId]?.stream;
  }

  /// Get cached messages for a route
  List<DriverMessage> getCachedMessages(String routeId) {
    return _messageCache[routeId]?.toList() ?? [];
  }

  /// Send feedback
  Future<void> sendFeedback({
    required String busId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final feedbackMessage = PassengerMessage(
      passengerId: passengerId,
      busId: busId,
      routeId: _currentRouteId,
      type: MessageType.feedback,
      payload: {
        'feedbackType': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    if (_currentRouteId != null) {
      await _pubSubManager.routePublish(_currentRouteId!, feedbackMessage.toJson());
      print('📝 Feedback sent for bus $busId');
    }
  }

  /// Report crowding
  Future<void> reportCrowding({
    required String busId,
    required String level,
  }) async {
    final crowdingMessage = PassengerMessage(
      passengerId: passengerId,
      busId: busId,
      routeId: _currentRouteId,
      type: MessageType.crowdingReport,
      payload: {
        'crowdLevel': level,
        'reportedAt': DateTime.now().toIso8601String(),
        'location': _userLocation != null ? {
          'latitude': _userLocation!.latitude,
          'longitude': _userLocation!.longitude,
        } : null,
      },
    );
    
    if (_currentRouteId != null) {
      await _pubSubManager.routePublish(_currentRouteId!, crowdingMessage.toJson());
      print('👥 Crowding report sent for bus $busId: $level');
    }
  }

  /// Get adapter status
  Map<String, dynamic> getStatus() {
    return {
      'passengerId': passengerId,
      'isConnected': _isConnected,
      'currentRoute': _currentRouteId,
      'cachedMessages': _messageCache.map((k, v) => MapEntry(k, v.length)),
      'activeStreams': _routeStreams.keys.toList(),
    };
  }

  /// Clean up resources
  void dispose() {
    _reconnectTimer?.cancel();
    
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    for (final controller in _routeStreams.values) {
      controller.close();
    }
    _routeStreams.clear();
    
    _messageCache.clear();
    
    if (_currentRouteId != null) {
      _pubSubManager.unsubscribeAll(passengerId);
    }
    
    print('🧹 PassengerAppRealtimeAdapter disposed');
  }
}
