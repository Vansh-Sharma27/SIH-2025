# Mock Real-time Communication System for YatraLive

A complete WebSocket-like real-time communication system that simulates Firebase functionality without external dependencies. Perfect for hackathon demonstrations and offline development.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Mock Real-time System                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────┐         ┌─────────────────────────┐       │
│  │ Driver App      │         │ Passenger App           │       │
│  │                 │         │                         │       │
│  │ ┌─────────────┐ │         │ ┌────────────────────┐ │       │
│  │ │Driver       │ │         │ │Passenger           │ │       │
│  │ │Realtime     │ │         │ │Realtime            │ │       │
│  │ │Adapter      │ │         │ │Adapter             │ │       │
│  │ └──────┬──────┘ │         │ └─────────┬──────────┘ │       │
│  └────────┼────────┘         └───────────┼────────────┘       │
│           │                               │                     │
│           ▼                               ▼                     │
│  ┌────────────────────────────────────────────────────┐       │
│  │          TopicBasedPubSubManager                    │       │
│  │  ┌──────────────┐  ┌──────────────┐               │       │
│  │  │Route Topics  │  │Subscriptions │               │       │
│  │  │route_1 →[...]│  │passenger_1 → │               │       │
│  │  │route_2 →[...]│  │  [route_1,2] │               │       │
│  │  └──────────────┘  └──────────────┘               │       │
│  └────────────────────┬───────────────────────────────┘       │
│                       │                                         │
│                       ▼                                         │
│  ┌────────────────────────────────────────────────────┐       │
│  │         WebSocketSimulationService                  │       │
│  │  ┌──────────────┐  ┌──────────────┐               │       │
│  │  │Client        │  │Heartbeat &   │               │       │
│  │  │Channels      │  │Latency       │               │       │
│  │  └──────────────┘  └──────────────┘               │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                  │
│  Supporting Components:                                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────┐ │
│  │OfflineQueue     │  │Notification     │  │Performance     │ │
│  │Manager          │  │SimulationLayer  │  │Monitor         │ │
│  └─────────────────┘  └─────────────────┘  └────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 📦 Components

### 1. **WebSocketSimulationService**
- Simulates WebSocket connections without external dependencies
- Manages client channels and message routing
- Built-in heartbeat and latency measurement
- Guarantees <2 second message delivery

### 2. **TopicBasedPubSubManager**
- Route-based topic management (e.g., route_1, route_2)
- O(1) subscribe/unsubscribe operations
- Broadcasts messages to all route subscribers in <100ms
- Automatic cleanup of disconnected clients

### 3. **DriverAppRealtimeAdapter**
- Wraps LocationServiceDemo for real-time location updates
- Sends DriverMessage every N seconds (configurable)
- Handles offline queuing and retry logic
- Simulates passenger count and crowding levels

### 4. **PassengerAppRealtimeAdapter**
- Subscribes to route topics for bus updates
- Caches last 20 messages for offline mode
- Triggers notifications based on distance/delays
- Supports two-way communication (feedback, reports)

### 5. **OfflineQueueManager**
- Queues messages when offline (max 100)
- Exponential backoff retry strategy
- Message deduplication and coalescing
- Priority-based delivery (high/normal/low)

### 6. **NotificationSimulationLayer**
- Triggers push notifications based on conditions:
  - Bus arrival (within 300m)
  - Delays (>5 minutes from schedule)
  - High crowding (>85% capacity)

## 🚀 Quick Start

### Basic Usage

```dart
// 1. Create and start a driver
final driver = DriverAppRealtimeAdapter(
  driverId: 'driver_1',
  busId: 'bus_1',
  routeId: 'route_1',
  updateInterval: Duration(seconds: 1),
);
await driver.startBroadcasting();

// 2. Create and initialize a passenger
final passenger = PassengerAppRealtimeAdapter(
  passengerId: 'passenger_1',
);
await passenger.initialize();
await passenger.subscribeToRoute('route_1');

// 3. Listen for updates
final stream = passenger.getRouteStream('route_1');
stream?.listen((driverMessage) {
  print('Bus location: ${driverMessage.latitude}, ${driverMessage.longitude}');
  print('Passengers: ${driverMessage.passengerCount}');
});

// 4. Send feedback
await passenger.sendFeedback(
  busId: 'bus_1',
  type: 'cleanliness',
  data: {'rating': 5, 'comment': 'Very clean!'},
);

// 5. Clean up
await driver.stopBroadcasting();
passenger.dispose();
```

### Integration with Flutter UI

```dart
class BusTrackingScreen extends StatefulWidget {
  @override
  _BusTrackingScreenState createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  late PassengerAppRealtimeAdapter _adapter;
  final List<DriverMessage> _busUpdates = [];
  
  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }
  
  Future<void> _initializeTracking() async {
    _adapter = PassengerAppRealtimeAdapter(passengerId: 'user_123');
    await _adapter.initialize();
    await _adapter.subscribeToRoute('route_1');
    
    _adapter.getRouteStream('route_1')?.listen((update) {
      setState(() {
        _busUpdates.add(update);
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _busUpdates.length,
      itemBuilder: (context, index) {
        final update = _busUpdates[index];
        return ListTile(
          title: Text('Bus ${update.busId}'),
          subtitle: Text('${update.passengerCount} passengers'),
          trailing: Text('${update.speed?.toStringAsFixed(1)} km/h'),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _adapter.dispose();
    super.dispose();
  }
}
```

## 🧪 Demo Scenarios

### 1. Simple Demo
```dart
final demo = MockRealtimeDemo();
await demo.runSimpleDemo();
```
- Creates 1 driver and 2 passengers on the same route
- Shows real-time location updates
- Demonstrates feedback and crowding reports

### 2. Multi-Route Demo
```dart
await demo.runMultiRouteDemo();
```
- 3 drivers on different routes
- 5 passengers subscribing to various routes
- Shows system scalability

### 3. Offline Scenario
```dart
await demo.runOfflineScenarioDemo();
```
- Simulates network disconnection
- Shows offline queue behavior
- Demonstrates automatic reconnection

## 📊 Performance Metrics

The system tracks various performance metrics:

- **Message Latency**: Average time from send to receive
- **Queue Size**: Number of messages waiting for delivery
- **Drop Rate**: Percentage of messages that couldn't be delivered
- **Connection Count**: Active WebSocket connections
- **Throughput**: Messages per second

Access metrics via:
```dart
final stats = pubSubManager.getTopicStats();
final queueStats = offlineQueue.getQueueStats();
final perfMetrics = pubSubManager.getPerformanceMetrics();
```

## 🔧 Configuration

### Driver Update Interval
```dart
DriverAppRealtimeAdapter(
  updateInterval: Duration(seconds: 2), // Default: 1 second
)
```

### Offline Queue Settings
- Max queue size: 100 messages
- Max retries: 5 attempts
- Initial retry delay: 1 second
- Max retry delay: 5 minutes
- Coalescing window: 500ms

### Notification Thresholds
- Arrival distance: 300 meters
- Delay threshold: 5 minutes
- Crowding threshold: 85% capacity

## 🌟 Features

✅ **No External Dependencies**: Works without Firebase or internet
✅ **Real-time Updates**: <2 second latency guaranteed
✅ **Offline Support**: Automatic queuing and retry
✅ **Two-way Communication**: Driver ↔ Passenger messaging
✅ **Push Notifications**: Smart triggers based on conditions
✅ **Performance Monitoring**: Built-in metrics and analytics
✅ **Scalable**: Handles multiple routes and clients
✅ **Battery Efficient**: Coalescing and smart updates

## 🚦 Testing

Run the included demo scenarios:
```bash
flutter run lib/services/mock_realtime/demo_integration.dart
```

Or integrate with your existing tests:
```dart
testWidgets('Real-time updates test', (tester) async {
  final driver = DriverAppRealtimeAdapter(...);
  final passenger = PassengerAppRealtimeAdapter(...);
  
  await driver.startBroadcasting();
  await passenger.subscribeToRoute('route_1');
  
  // Verify updates are received
  final updates = <DriverMessage>[];
  passenger.getRouteStream('route_1')?.listen(updates.add);
  
  await Future.delayed(Duration(seconds: 5));
  expect(updates.length, greaterThan(0));
});
```

## 📱 Hackathon Demo Tips

1. **Start Multiple Drivers**: Show scalability with 3-5 active buses
2. **Simulate Offline**: Demonstrate queue and reconnection
3. **Show Notifications**: Walk through arrival/delay/crowding alerts
4. **Two-way Feedback**: Have passengers report issues in real-time
5. **Performance Dashboard**: Display latency and throughput metrics

## 🐛 Troubleshooting

**Q: Messages not being received?**
- Check if passenger is subscribed to the correct route
- Verify WebSocket connection is active
- Look for errors in console output

**Q: Notifications not appearing?**
- Ensure passenger location is set
- Check notification thresholds
- Verify NotificationServiceDemo is initialized

**Q: High latency?**
- Check update interval settings
- Monitor queue size (might be backing up)
- Verify no infinite loops in listeners

## 📄 License

This mock real-time system is part of the YatraLive project for Smart India Hackathon 2025.
