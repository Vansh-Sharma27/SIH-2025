import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

// Demo notification service that simulates push notifications
class NotificationServiceDemo {
  static final NotificationServiceDemo _instance = NotificationServiceDemo._internal();
  factory NotificationServiceDemo() => _instance;
  NotificationServiceDemo._internal();

  // Simulated notification queue
  final Queue<DemoNotification> _notificationQueue = Queue();
  final Map<String, List<String>> _topicSubscriptions = {}; // topic -> list of subscribers
  final Map<String, Set<String>> _userSubscriptions = {}; // userId -> set of topics
  
  Timer? _notificationTimer;
  bool _isInitialized = false;
  
  // Callbacks for UI updates
  Function(DemoNotification)? onNotificationReceived;
  
  static Future<void> initialize() async {
    await NotificationServiceDemo()._initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (_isInitialized) return;
    
    print('📱 NotificationServiceDemo initialized - No Firebase required!');
    print('✅ Demo notifications enabled');
    
    // Start notification processor
    _startNotificationProcessor();
    
    // Schedule some demo notifications
    _scheduleDemoNotifications();
    
    _isInitialized = true;
  }

  void _startNotificationProcessor() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_notificationQueue.isNotEmpty) {
        final notification = _notificationQueue.removeFirst();
        _processNotification(notification);
      }
    });
  }

  void _processNotification(DemoNotification notification) {
    print('🔔 Processing notification: ${notification.title}');
    
    // Call callback if UI is listening
    onNotificationReceived?.call(notification);
    
    // Simulate notification display
    _showInAppNotification(
      title: notification.title,
      body: notification.body,
      data: notification.data,
    );
  }

  void _scheduleDemoNotifications() {
    // Schedule some demo notifications for variety
    Timer.periodic(const Duration(seconds: 30), (timer) {
      final random = math.Random();
      final notificationType = random.nextInt(3);
      
      switch (notificationType) {
        case 0:
          _queueBusArrivalNotification();
          break;
        case 1:
          _queueDelayNotification();
          break;
        case 2:
          _queueCrowdingNotification();
          break;
      }
    });
  }

  void _queueBusArrivalNotification() {
    final busNumbers = ['DL01-1234', 'DL02-5678', 'DL03-9012'];
    final stops = ['Connaught Place', 'India Gate', 'Red Fort', 'Chandni Chowk'];
    final random = math.Random();
    
    final notification = createBusArrivalNotification(
      routeId: 'route_${random.nextInt(3) + 1}',
      busNumber: busNumbers[random.nextInt(busNumbers.length)],
      estimatedMinutes: random.nextInt(10) + 1,
      stopName: stops[random.nextInt(stops.length)],
    );
    
    _notificationQueue.add(notification);
  }

  void _queueDelayNotification() {
    final busNumbers = ['DL01-1234', 'DL02-5678', 'DL03-9012'];
    final reasons = ['Traffic congestion', 'Road work', 'Heavy rain', 'Technical issue'];
    final random = math.Random();
    
    final notification = createDelayNotification(
      routeId: 'route_${random.nextInt(3) + 1}',
      busNumber: busNumbers[random.nextInt(busNumbers.length)],
      delayMinutes: random.nextInt(15) + 5,
      reason: reasons[random.nextInt(reasons.length)],
    );
    
    _notificationQueue.add(notification);
  }

  void _queueCrowdingNotification() {
    final busNumbers = ['DL01-1234', 'DL02-5678', 'DL03-9012'];
    final crowdLevels = ['low', 'medium', 'high'];
    final random = math.Random();
    
    final notification = createCrowdingNotification(
      routeId: 'route_${random.nextInt(3) + 1}',
      busNumber: busNumbers[random.nextInt(busNumbers.length)],
      crowdLevel: crowdLevels[random.nextInt(crowdLevels.length)],
    );
    
    _notificationQueue.add(notification);
  }

  void _showInAppNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    print('📬 In-app notification: $title - $body');
    // In a real app, this would show a toast or snackbar
  }

  // Subscribe to topic for route-based notifications
  Future<void> subscribeToRoute(String routeId) async {
    final topic = 'route_$routeId';
    final userId = 'demo_user'; // In real app, get actual user ID
    
    // Add to topic subscriptions
    _topicSubscriptions.putIfAbsent(topic, () => []);
    if (!_topicSubscriptions[topic]!.contains(userId)) {
      _topicSubscriptions[topic]!.add(userId);
    }
    
    // Add to user subscriptions
    _userSubscriptions.putIfAbsent(userId, () => {});
    _userSubscriptions[userId]!.add(topic);
    
    print('✅ Subscribed to $topic');
    
    // Queue a welcome notification
    final notification = DemoNotification(
      title: 'Subscribed to Route! 🎉',
      body: 'You will now receive updates for Route ${routeId.replaceAll('route_', '')}',
      data: {'type': 'subscription', 'routeId': routeId},
      topic: topic,
    );
    _notificationQueue.add(notification);
  }

  // Unsubscribe from route notifications
  Future<void> unsubscribeFromRoute(String routeId) async {
    final topic = 'route_$routeId';
    final userId = 'demo_user';
    
    // Remove from topic subscriptions
    if (_topicSubscriptions.containsKey(topic)) {
      _topicSubscriptions[topic]!.remove(userId);
      if (_topicSubscriptions[topic]!.isEmpty) {
        _topicSubscriptions.remove(topic);
      }
    }
    
    // Remove from user subscriptions
    if (_userSubscriptions.containsKey(userId)) {
      _userSubscriptions[userId]!.remove(topic);
    }
    
    print('❌ Unsubscribed from $topic');
  }

  // Send notification templates
  static DemoNotification createBusArrivalNotification({
    required String routeId,
    required String busNumber,
    required int estimatedMinutes,
    required String stopName,
  }) {
    return DemoNotification(
      title: 'Bus Arriving Soon! 🚌',
      body: 'Bus $busNumber will arrive at $stopName in $estimatedMinutes minutes',
      data: {
        'type': 'bus_arrival',
        'routeId': routeId,
        'busNumber': busNumber,
        'estimatedMinutes': estimatedMinutes.toString(),
        'stopName': stopName,
      },
      topic: 'route_$routeId',
    );
  }

  static DemoNotification createDelayNotification({
    required String routeId,
    required String busNumber,
    required int delayMinutes,
    required String reason,
  }) {
    return DemoNotification(
      title: 'Bus Delayed ⏰',
      body: 'Bus $busNumber is delayed by $delayMinutes minutes. Reason: $reason',
      data: {
        'type': 'delay',
        'routeId': routeId,
        'busNumber': busNumber,
        'delayMinutes': delayMinutes.toString(),
        'reason': reason,
      },
      topic: 'route_$routeId',
    );
  }

  static DemoNotification createCrowdingNotification({
    required String routeId,
    required String busNumber,
    required String crowdLevel, // low, medium, high
  }) {
    String emoji = crowdLevel == 'low' ? '✅' : crowdLevel == 'medium' ? '⚠️' : '🔴';
    String message = crowdLevel == 'low' 
        ? 'Seats available' 
        : crowdLevel == 'medium' 
            ? 'Moderately crowded' 
            : 'Very crowded';
    
    return DemoNotification(
      title: 'Bus Occupancy Update $emoji',
      body: 'Bus $busNumber: $message',
      data: {
        'type': 'crowding',
        'routeId': routeId,
        'busNumber': busNumber,
        'crowdLevel': crowdLevel,
      },
      topic: 'route_$routeId',
    );
  }

  // Manual notification sending for testing
  void sendTestNotification(DemoNotification notification) {
    _notificationQueue.add(notification);
    print('📤 Test notification queued: ${notification.title}');
  }

  // Get notification history (for demo purposes)
  List<DemoNotification> getRecentNotifications() {
    return _notificationQueue.toList();
  }

  // Check if notifications are enabled (always true for demo)
  Future<bool> isNotificationEnabled() async => true;

  // Open notification settings (simulated)
  Future<void> openNotificationSettings() async {
    print('⚙️ Notification settings (simulated for demo)');
  }

  // Get subscribed topics
  Set<String> getUserSubscriptions(String userId) {
    return _userSubscriptions[userId] ?? {};
  }

  // Cleanup
  void dispose() {
    _notificationTimer?.cancel();
    _notificationQueue.clear();
    _topicSubscriptions.clear();
    _userSubscriptions.clear();
  }
}

// Demo notification model
class DemoNotification {
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String topic;
  final DateTime timestamp;

  DemoNotification({
    required this.title,
    required this.body,
    required this.data,
    required this.topic,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'DemoNotification($title, $body, topic: $topic)';
}
