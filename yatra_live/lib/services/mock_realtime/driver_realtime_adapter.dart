import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import '../location_service_demo.dart';
import '../database_service_demo.dart';
import 'models/realtime_models.dart';
import 'topic_pubsub_manager.dart';
import 'offline_queue_manager.dart';

/// Adapter that wraps LocationServiceDemo to send real-time updates
class DriverAppRealtimeAdapter {
  final String driverId;
  final String busId;
  final String routeId;
  
  // Dependencies
  final LocationServiceDemo _locationService = LocationServiceDemo();
  final DatabaseServiceDemo _databaseService = DatabaseServiceDemo();
  final TopicBasedPubSubManager _pubSubManager = TopicBasedPubSubManager();
  final OfflineQueueManager _offlineQueue = OfflineQueueManager();
  
  // Configuration
  final Duration updateInterval;
  final bool enableCrowdingUpdates;
  final bool enableETACalculation;
  
  // State management
  Timer? _updateTimer;
  StreamSubscription<Position>? _locationSubscription;
  bool _isActive = false;
  DateTime? _sessionStartTime;
  int _messagesSent = 0;
  
  // Crowding simulation
  int _currentPassengerCount = 15;
  final _random = math.Random();
  
  // Performance tracking
  final List<double> _updateLatencies = [];
  static const int _maxLatencyHistory = 100;

  DriverAppRealtimeAdapter({
    required this.driverId,
    required this.busId,
    required this.routeId,
    this.updateInterval = const Duration(seconds: 1),
    this.enableCrowdingUpdates = true,
    this.enableETACalculation = true,
  });

  /// Initialize the adapter and start broadcasting
  Future<void> startBroadcasting() async {
    if (_isActive) {
      print('⚠️ Driver $driverId already broadcasting');
      return;
    }
    
    try {
      // Initialize services
      await _pubSubManager.initialize();
      _databaseService.initialize();
      await _offlineQueue.initialize(clientId: 'driver_$driverId');
      
      // Start location tracking
      await _locationService.startTracking(
        busId: busId,
        routeId: routeId,
        onLocationUpdate: _handleLocationUpdate,
      );
      
      // Start update timer
      _updateTimer = Timer.periodic(updateInterval, (_) => _sendUpdate());
      
      // Update database status
      await _databaseService.startDriverSession(driverId, busId, routeId);
      
      _isActive = true;
      _sessionStartTime = DateTime.now();
      
      print('🚌 Driver $driverId started broadcasting for bus $busId on route $routeId');
      
      // Send initial status update
      await _sendUpdate();
      
    } catch (e) {
      print('❌ Failed to start driver broadcasting: $e');
      await stopBroadcasting();
      rethrow;
    }
  }

  /// Stop broadcasting and clean up
  Future<void> stopBroadcasting() async {
    if (!_isActive) return;
    
    _isActive = false;
    
    // Cancel timers
    _updateTimer?.cancel();
    _updateTimer = null;
    
    // Stop location tracking
    await _locationService.stopTracking(busId);
    await _locationSubscription?.cancel();
    
    // Update database
    await _databaseService.endDriverSession(busId);
    
    // Flush offline queue
    await _offlineQueue.flushQueue();
    
    // Log session stats
    _logSessionStats();
    
    print('🛑 Driver $driverId stopped broadcasting');
  }

  /// Handle location updates from LocationServiceDemo
  void _handleLocationUpdate(Position position) {
    // Location updates are handled by the periodic timer
    // This callback can be used for immediate critical updates if needed
  }

  /// Send periodic update
  Future<void> _sendUpdate() async {
    if (!_isActive) return;
    
    final stopwatch = Stopwatch()..start();
    
    try {
      // Get current location
      final position = _locationService.lastKnownPosition;
      if (position == null) {
        print('⚠️ No location available for driver $driverId');
        return;
      }
      
      // Simulate passenger count changes
      if (enableCrowdingUpdates) {
        _simulatePassengerChanges();
      }
      
      // Calculate crowd level
      final crowdLevel = _calculateCrowdLevel(_currentPassengerCount);
      
      // Create driver message
      final message = DriverMessage(
        busId: busId,
        routeId: routeId,
        driverId: driverId,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed != null ? position.speed! * 3.6 : null, // Convert m/s to km/h
        heading: position.heading,
        passengerCount: _currentPassengerCount,
        crowdLevel: crowdLevel,
        metadata: {
          'sessionDuration': _sessionStartTime != null 
              ? DateTime.now().difference(_sessionStartTime!).inSeconds 
              : 0,
          'messagesSent': _messagesSent,
          'updateInterval': updateInterval.inMilliseconds,
        },
      );
      
      // Check if online
      final isOnline = await _checkConnectivity();
      
      if (isOnline) {
        // Publish to route subscribers
        await _pubSubManager.routePublish(routeId, message.toJson());
        
        // Update database
        await _databaseService.updateBusLocation(
          busId,
          position.latitude,
          position.longitude,
          passengerCount: _currentPassengerCount,
          status: 'active',
        );
        
        // Process any queued messages
        await _offlineQueue.processQueue();
      } else {
        // Queue message for later delivery
        final envelope = QueuedEnvelope(
          clientId: 'driver_$driverId',
          message: message,
          priority: QueuePriority.high,
          targetTopic: 'route_$routeId',
        );
        
        await _offlineQueue.enqueue(envelope);
        print('📦 Queued update for offline delivery (queue size: ${await _offlineQueue.getQueueSize()})');
      }
      
      _messagesSent++;
      
      // Record latency
      stopwatch.stop();
      _recordLatency(stopwatch.elapsedMilliseconds.toDouble());
      
    } catch (e) {
      print('❌ Error sending driver update: $e');
      
      // Queue for retry
      if (_locationService.lastKnownPosition != null) {
        final failedMessage = DriverMessage(
          busId: busId,
          routeId: routeId,
          driverId: driverId,
          latitude: _locationService.lastKnownPosition!.latitude,
          longitude: _locationService.lastKnownPosition!.longitude,
        );
        
        await _offlineQueue.enqueue(QueuedEnvelope(
          clientId: 'driver_$driverId',
          message: failedMessage,
          priority: QueuePriority.normal,
          targetTopic: 'route_$routeId',
        ));
      }
    }
  }

  /// Simulate passenger count changes
  void _simulatePassengerChanges() {
    // Simulate stops where passengers board/alight
    final change = _random.nextInt(11) - 5; // -5 to +5 passengers
    _currentPassengerCount = (_currentPassengerCount + change).clamp(0, 50);
    
    // Occasionally simulate major changes (bus stop)
    if (_random.nextDouble() < 0.1) { // 10% chance
      if (_random.nextBool()) {
        // Major boarding
        _currentPassengerCount = (_currentPassengerCount + _random.nextInt(10) + 5).clamp(0, 50);
      } else {
        // Major alighting
        _currentPassengerCount = (_currentPassengerCount - _random.nextInt(10) - 5).clamp(0, 50);
      }
    }
  }

  /// Calculate crowd level based on passenger count
  String _calculateCrowdLevel(int passengerCount) {
    if (passengerCount < 15) return 'low';
    if (passengerCount < 35) return 'medium';
    return 'high';
  }

  /// Check connectivity (mock implementation)
  Future<bool> _checkConnectivity() async {
    // Simulate occasional offline periods
    if (_random.nextDouble() < 0.05) { // 5% chance of being offline
      return false;
    }
    return true;
  }

  /// Record update latency
  void _recordLatency(double latency) {
    _updateLatencies.add(latency);
    if (_updateLatencies.length > _maxLatencyHistory) {
      _updateLatencies.removeAt(0);
    }
  }

  /// Get average update latency
  double getAverageLatency() {
    if (_updateLatencies.isEmpty) return 0.0;
    return _updateLatencies.reduce((a, b) => a + b) / _updateLatencies.length;
  }

  /// Log session statistics
  void _logSessionStats() {
    if (_sessionStartTime == null) return;
    
    final duration = DateTime.now().difference(_sessionStartTime!);
    final avgLatency = getAverageLatency();
    
    print('📊 Driver Session Stats:');
    print('   Duration: ${duration.inMinutes} minutes');
    print('   Messages sent: $_messagesSent');
    print('   Average latency: ${avgLatency.toStringAsFixed(2)}ms');
    print('   Final passenger count: $_currentPassengerCount');
  }

  /// Update passenger count manually
  Future<void> updatePassengerCount(int count) async {
    _currentPassengerCount = count.clamp(0, 50);
    
    // Send immediate update
    if (_isActive) {
      await _sendUpdate();
    }
  }

  /// Send emergency alert
  Future<void> sendEmergencyAlert(String message) async {
    final emergencyMessage = PassengerMessage(
      passengerId: driverId,
      busId: busId,
      routeId: routeId,
      type: MessageType.unknown, // Could add emergency type
      payload: {
        'emergency': true,
        'message': message,
        'location': {
          'latitude': _locationService.lastKnownPosition?.latitude,
          'longitude': _locationService.lastKnownPosition?.longitude,
        },
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    // Send with high priority
    if (await _checkConnectivity()) {
      await _pubSubManager.routePublish(routeId, emergencyMessage.toJson());
    } else {
      await _offlineQueue.enqueue(QueuedEnvelope(
        clientId: 'driver_$driverId',
        message: emergencyMessage,
        priority: QueuePriority.high,
        targetTopic: 'route_$routeId',
      ));
    }
    
    print('🚨 Emergency alert sent: $message');
  }

  /// Get adapter status
  Map<String, dynamic> getStatus() {
    return {
      'isActive': _isActive,
      'driverId': driverId,
      'busId': busId,
      'routeId': routeId,
      'sessionDuration': _sessionStartTime != null 
          ? DateTime.now().difference(_sessionStartTime!).inSeconds 
          : 0,
      'messagesSent': _messagesSent,
      'currentPassengerCount': _currentPassengerCount,
      'averageLatency': getAverageLatency(),
      'queueSize': _offlineQueue.getQueueSize(),
    };
  }

  /// Clean up resources
  void dispose() {
    stopBroadcasting();
  }
}
