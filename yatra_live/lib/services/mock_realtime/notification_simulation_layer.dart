import 'dart:async';
import 'dart:collection';
import '../notification_service_demo.dart';
import '../database_service_demo.dart';
import '../location_service_demo.dart';
import '../../models/route_model.dart';

/// Layer for simulating push notifications based on real-time data
class NotificationSimulationLayer {
  String? _passengerId;
  
  // Dependencies
  final NotificationServiceDemo _notificationService = NotificationServiceDemo();
  final DatabaseServiceDemo _databaseService = DatabaseServiceDemo();
  
  // State tracking
  final Map<String, DateTime> _lastETACheck = {}; // busId -> last check time
  final Map<String, int> _previousETA = {}; // busId -> previous ETA in minutes
  final Set<String> _notifiedArrivals = {}; // busIds already notified for arrival
  
  // Configuration
  static const Duration _etaCheckInterval = Duration(minutes: 1);
  static const int _delayThresholdMinutes = 5;
  static const double _arrivalDistanceMeters = 300.0;
  static const double _crowdingThreshold = 0.85; // 85% capacity
  
  NotificationSimulationLayer();

  /// Initialize the notification layer
  Future<void> initialize({required String passengerId}) async {
    _passengerId = passengerId;
    _databaseService.initialize();
    await NotificationServiceDemo.initialize();
    
    // Subscribe to demo notifications if needed
    _notificationService.onNotificationReceived = (notification) {
      print('🔔 Notification displayed: ${notification.title}');
    };
    
    print('🔔 NotificationSimulationLayer initialized for $passengerId');
  }

  /// Send bus arrival notification
  void sendBusArrivalNotification({
    required String busId,
    required String busNumber,
    required double distance,
    required int estimatedMinutes,
  }) {
    // Prevent duplicate notifications
    if (_notifiedArrivals.contains(busId)) {
      if (distance > _arrivalDistanceMeters * 2) {
        // Bus moved away, reset notification
        _notifiedArrivals.remove(busId);
      }
      return;
    }
    
    final notification = NotificationServiceDemo.createBusArrivalNotification(
      routeId: 'current_route', // Would be passed in real implementation
      busNumber: busNumber,
      estimatedMinutes: estimatedMinutes,
      stopName: 'Your stop', // Would be determined by user location
    );
    
    _notificationService.sendTestNotification(notification);
    _notifiedArrivals.add(busId);
    
    print('🚌 Sent arrival notification for bus $busNumber (${distance.toStringAsFixed(0)}m away)');
  }

  /// Send delay notification
  void sendDelayNotification({
    required String busId,
    required String busNumber,
    required String routeId,
    required int currentETA,
    required String reason,
  }) {
    final lastCheck = _lastETACheck[busId];
    final now = DateTime.now();
    
    // Check if enough time has passed since last check
    if (lastCheck != null && now.difference(lastCheck) < _etaCheckInterval) {
      return;
    }
    
    _lastETACheck[busId] = now;
    
    // Compare with previous ETA
    final prevETA = _previousETA[busId];
    if (prevETA != null) {
      final delayMinutes = currentETA - prevETA;
      
      if (delayMinutes >= _delayThresholdMinutes) {
        final notification = NotificationServiceDemo.createDelayNotification(
          routeId: routeId,
          busNumber: busNumber,
          delayMinutes: delayMinutes,
          reason: reason,
        );
        
        _notificationService.sendTestNotification(notification);
        print('⏰ Sent delay notification for bus $busNumber (+$delayMinutes minutes)');
      }
    }
    
    _previousETA[busId] = currentETA;
  }

  /// Send crowding notification
  void sendCrowdingNotification({
    required String busId,
    required String busNumber,
    required String crowdLevel,
    required int passengerCount,
    int maxCapacity = 50,
  }) {
    final occupancyRate = passengerCount / maxCapacity;
    
    if (occupancyRate >= _crowdingThreshold || crowdLevel == 'high') {
      final notification = NotificationServiceDemo.createCrowdingNotification(
        routeId: 'current_route',
        busNumber: busNumber,
        crowdLevel: crowdLevel,
      );
      
      _notificationService.sendTestNotification(notification);
      print('👥 Sent crowding notification for bus $busNumber ($passengerCount/$maxCapacity passengers)');
    }
  }

  /// Check for delay based on schedule
  Future<void> checkScheduleDelay({
    required String busId,
    required String busNumber,
    required String routeId,
    required double currentLat,
    required double currentLng,
    required BusStop targetStop,
    required DateTime scheduledArrival,
  }) async {
    // Calculate current distance to stop
    final distance = LocationServiceDemo.calculateDistance(
      currentLat,
      currentLng,
      targetStop.latitude,
      targetStop.longitude,
    );
    
    // Estimate arrival time based on distance
    final estimatedDuration = LocationServiceDemo.estimateArrivalTime(
      Position(
        latitude: currentLat,
        longitude: currentLng,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 25 / 3.6, // 25 km/h in m/s
        speedAccuracy: 2,
      ),
      targetStop.latitude,
      targetStop.longitude,
    );
    
    final estimatedArrival = DateTime.now().add(estimatedDuration);
    final delayMinutes = estimatedArrival.difference(scheduledArrival).inMinutes;
    
    if (delayMinutes >= _delayThresholdMinutes) {
      sendDelayNotification(
        busId: busId,
        busNumber: busNumber,
        routeId: routeId,
        currentETA: estimatedDuration.inMinutes,
        reason: 'Traffic conditions',
      );
    }
  }

  /// Send route update notification
  void sendRouteUpdateNotification({
    required String routeId,
    required String message,
    String severity = 'info',
  }) {
    final notification = DemoNotification(
      title: 'Route Update 📢',
      body: message,
      data: {
        'type': 'route_update',
        'routeId': routeId,
        'severity': severity,
      },
      topic: 'route_$routeId',
    );
    
    _notificationService.sendTestNotification(notification);
    print('📢 Sent route update: $message');
  }

  /// Send emergency notification
  void sendEmergencyNotification({
    required String busId,
    required String busNumber,
    required String message,
    required double? latitude,
    required double? longitude,
  }) {
    final notification = DemoNotification(
      title: 'Emergency Alert 🚨',
      body: 'Bus $busNumber: $message',
      data: {
        'type': 'emergency',
        'busId': busId,
        'busNumber': busNumber,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'timestamp': DateTime.now().toIso8601String(),
      },
      topic: 'emergency',
    );
    
    _notificationService.sendTestNotification(notification);
    print('🚨 Sent emergency notification for bus $busNumber');
  }

  /// Subscribe to route for notifications
  Future<void> subscribeToRouteNotifications(String routeId) async {
    await _notificationService.subscribeToRoute(routeId);
    print('🔔 Subscribed to notifications for route $routeId');
  }

  /// Unsubscribe from route notifications
  Future<void> unsubscribeFromRouteNotifications(String routeId) async {
    await _notificationService.unsubscribeFromRoute(routeId);
    
    // Clean up tracking data for buses on this route
    _lastETACheck.removeWhere((busId, _) => busId.contains(routeId));
    _previousETA.removeWhere((busId, _) => busId.contains(routeId));
    _notifiedArrivals.removeWhere((busId) => busId.contains(routeId));
    
    print('🔕 Unsubscribed from notifications for route $routeId');
  }

  /// Get notification history
  List<DemoNotification> getRecentNotifications() {
    return _notificationService.getRecentNotifications();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await _notificationService.isNotificationEnabled();
  }

  /// Open notification settings
  Future<void> openNotificationSettings() async {
    await _notificationService.openNotificationSettings();
  }

  /// Get notification stats
  Map<String, dynamic> getNotificationStats() {
    final recentNotifications = getRecentNotifications();
    final typeCount = <String, int>{};
    
    for (final notification in recentNotifications) {
      final type = notification.data['type'] as String? ?? 'unknown';
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }
    
    return {
      'totalNotifications': recentNotifications.length,
      'notificationsByType': typeCount,
      'trackedBuses': _previousETA.length,
      'notifiedArrivals': _notifiedArrivals.length,
      'lastNotification': recentNotifications.isNotEmpty 
          ? recentNotifications.last.timestamp.toIso8601String()
          : null,
    };
  }

  /// Simulate notification scenarios for testing
  void simulateNotificationScenarios() {
    // Simulate various notification types
    Timer.periodic(const Duration(seconds: 30), (timer) {
      final scenarios = [
        () => sendBusArrivalNotification(
          busId: 'bus_test_1',
          busNumber: 'TEST-001',
          distance: 250,
          estimatedMinutes: 2,
        ),
        () => sendDelayNotification(
          busId: 'bus_test_2',
          busNumber: 'TEST-002',
          routeId: 'route_test',
          currentETA: 25,
          reason: 'Heavy traffic',
        ),
        () => sendCrowdingNotification(
          busId: 'bus_test_3',
          busNumber: 'TEST-003',
          crowdLevel: 'high',
          passengerCount: 45,
        ),
      ];
      
      // Pick a random scenario
      if (scenarios.isNotEmpty) {
        scenarios[DateTime.now().millisecond % scenarios.length]();
      }
    });
  }

  /// Clear notification state
  void clearNotificationState() {
    _lastETACheck.clear();
    _previousETA.clear();
    _notifiedArrivals.clear();
    print('🧹 Cleared notification state');
  }

  /// Dispose resources
  void dispose() {
    clearNotificationState();
    _notificationService.dispose();
    print('🧹 NotificationSimulationLayer disposed');
  }
}
