import 'dart:async';
import 'driver_realtime_adapter.dart';
import 'passenger_realtime_adapter.dart';
import 'models/realtime_models.dart';
import '../location_service_demo.dart';

/// Demo integration showing how to use the mock real-time communication system
class MockRealtimeDemo {
  // Driver adapters
  final Map<String, DriverAppRealtimeAdapter> _drivers = {};
  
  // Passenger adapters
  final Map<String, PassengerAppRealtimeAdapter> _passengers = {};
  
  // Demo routes
  static const List<String> demoRoutes = ['route_1', 'route_2', 'route_3'];
  
  /// Initialize and start a simple demo
  Future<void> runSimpleDemo() async {
    print('🚀 Starting Mock Real-time Communication Demo');
    print('=' * 50);
    
    // 1. Create a driver on route_1
    final driver1 = DriverAppRealtimeAdapter(
      driverId: 'driver_demo_1',
      busId: 'bus_demo_1',
      routeId: 'route_1',
      updateInterval: const Duration(seconds: 2), // Update every 2 seconds
    );
    _drivers['driver_1'] = driver1;
    
    // 2. Create two passengers interested in route_1
    final passenger1 = PassengerAppRealtimeAdapter(passengerId: 'passenger_demo_1');
    final passenger2 = PassengerAppRealtimeAdapter(passengerId: 'passenger_demo_2');
    _passengers['passenger_1'] = passenger1;
    _passengers['passenger_2'] = passenger2;
    
    // 3. Initialize passengers
    await passenger1.initialize();
    await passenger2.initialize();
    
    // 4. Set up passenger location (for notifications)
    passenger1.updateUserLocation(Position(
      latitude: 28.6140,
      longitude: 77.2090,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ));
    
    // 5. Subscribe passengers to route
    print('\n📱 Subscribing passengers to route_1...');
    await passenger1.subscribeToRoute('route_1');
    await passenger2.subscribeToRoute('route_1');
    
    // 6. Set up listeners for passenger 1
    final routeStream = passenger1.getRouteStream('route_1');
    StreamSubscription<DriverMessage>? subscription;
    
    if (routeStream != null) {
      subscription = routeStream.listen((message) {
        print('\n📍 Passenger 1 received update:');
        print('   Bus: ${message.busId}');
        print('   Location: (${message.latitude.toStringAsFixed(4)}, ${message.longitude.toStringAsFixed(4)})');
        print('   Speed: ${message.speed?.toStringAsFixed(1)} km/h');
        print('   Passengers: ${message.passengerCount} (${message.crowdLevel})');
      });
    }
    
    // 7. Start driver broadcasting
    print('\n🚌 Starting driver broadcast...');
    await driver1.startBroadcasting();
    
    // 8. Run for 30 seconds
    print('\n⏱️ Running demo for 30 seconds...');
    await Future.delayed(const Duration(seconds: 30));
    
    // 9. Simulate passenger feedback
    print('\n📝 Passenger sending feedback...');
    await passenger1.sendFeedback(
      busId: 'bus_demo_1',
      type: 'cleanliness',
      data: {
        'rating': 4,
        'comment': 'Bus is clean and comfortable',
      },
    );
    
    // 10. Simulate crowding report
    print('\n👥 Passenger reporting crowding...');
    await passenger2.reportCrowding(
      busId: 'bus_demo_1',
      level: 'high',
    );
    
    // Wait a bit more
    await Future.delayed(const Duration(seconds: 10));
    
    // 11. Stop everything
    print('\n🛑 Stopping demo...');
    await driver1.stopBroadcasting();
    await passenger1.unsubscribeFromRoute('route_1');
    await passenger2.unsubscribeFromRoute('route_1');
    await subscription?.cancel();
    
    // 12. Show final stats
    print('\n📊 Final Statistics:');
    print('Driver status: ${driver1.getStatus()}');
    print('Passenger 1 status: ${passenger1.getStatus()}');
    print('Passenger 2 status: ${passenger2.getStatus()}');
    
    print('\n✅ Demo completed!');
  }
  
  /// Run a multi-route demo with multiple drivers and passengers
  Future<void> runMultiRouteDemo() async {
    print('🚀 Starting Multi-Route Real-time Demo');
    print('=' * 50);
    
    // Create multiple drivers
    for (int i = 0; i < 3; i++) {
      final driver = DriverAppRealtimeAdapter(
        driverId: 'driver_$i',
        busId: 'bus_$i',
        routeId: demoRoutes[i % demoRoutes.length],
        updateInterval: Duration(seconds: 1 + i), // Vary update rates
      );
      _drivers['driver_$i'] = driver;
      await driver.startBroadcasting();
      print('🚌 Started driver $i on ${demoRoutes[i % demoRoutes.length]}');
    }
    
    // Create multiple passengers
    for (int i = 0; i < 5; i++) {
      final passenger = PassengerAppRealtimeAdapter(passengerId: 'passenger_$i');
      await passenger.initialize();
      
      // Subscribe to random route
      final routeIndex = i % demoRoutes.length;
      await passenger.subscribeToRoute(demoRoutes[routeIndex]);
      
      _passengers['passenger_$i'] = passenger;
      print('👤 Passenger $i subscribed to ${demoRoutes[routeIndex]}');
    }
    
    // Run for 1 minute
    print('\n⏱️ Running multi-route demo for 1 minute...');
    
    // Periodic status updates
    Timer.periodic(const Duration(seconds: 15), (timer) {
      print('\n📊 System Status at ${DateTime.now().toIso8601String()}:');
      print('Active drivers: ${_drivers.length}');
      print('Active passengers: ${_passengers.length}');
      
      // Show sample driver status
      final sampleDriver = _drivers.values.first;
      print('Sample driver status: ${sampleDriver.getStatus()}');
    });
    
    await Future.delayed(const Duration(minutes: 1));
    
    // Clean up
    print('\n🧹 Cleaning up...');
    for (final driver in _drivers.values) {
      await driver.stopBroadcasting();
    }
    
    for (final passenger in _passengers.values) {
      passenger.dispose();
    }
    
    print('\n✅ Multi-route demo completed!');
  }
  
  /// Demonstrate offline/online scenarios
  Future<void> runOfflineScenarioDemo() async {
    print('🚀 Starting Offline/Online Scenario Demo');
    print('=' * 50);
    
    // Create driver with frequent updates
    final driver = DriverAppRealtimeAdapter(
      driverId: 'driver_offline_demo',
      busId: 'bus_offline_demo',
      routeId: 'route_1',
      updateInterval: const Duration(seconds: 1),
    );
    
    // Create passenger
    final passenger = PassengerAppRealtimeAdapter(passengerId: 'passenger_offline_demo');
    await passenger.initialize();
    await passenger.subscribeToRoute('route_1');
    
    // Start driver
    await driver.startBroadcasting();
    print('🚌 Driver started broadcasting');
    
    // Run normally for 10 seconds
    print('\n✅ Running with good connectivity for 10 seconds...');
    await Future.delayed(const Duration(seconds: 10));
    
    // Simulate offline period
    print('\n📴 Simulating offline period for 15 seconds...');
    // In real scenario, this would be network disconnection
    // The offline queue will automatically handle this
    
    await Future.delayed(const Duration(seconds: 15));
    
    // Back online
    print('\n📶 Back online - queue should flush automatically');
    await Future.delayed(const Duration(seconds: 10));
    
    // Check offline queue stats
    print('\n📊 Offline Queue Statistics:');
    final driverStatus = driver.getStatus();
    print('Driver queue size: ${driverStatus['queueSize']}');
    
    // Clean up
    await driver.stopBroadcasting();
    passenger.dispose();
    
    print('\n✅ Offline scenario demo completed!');
  }
  
  /// Clean up all resources
  void dispose() {
    for (final driver in _drivers.values) {
      driver.dispose();
    }
    _drivers.clear();
    
    for (final passenger in _passengers.values) {
      passenger.dispose();
    }
    _passengers.clear();
  }
}

/// Example usage in a Flutter app
void main() async {
  final demo = MockRealtimeDemo();
  
  // Run different demo scenarios
  try {
    // Simple demo
    await demo.runSimpleDemo();
    
    print('\n' + '=' * 50 + '\n');
    
    // Multi-route demo
    await demo.runMultiRouteDemo();
    
    print('\n' + '=' * 50 + '\n');
    
    // Offline scenario
    await demo.runOfflineScenarioDemo();
    
  } finally {
    demo.dispose();
  }
}

/// Example integration with Flutter UI
class RealtimeTrackingWidget extends StatefulWidget {
  final String routeId;
  final String passengerId;
  
  const RealtimeTrackingWidget({
    Key? key,
    required this.routeId,
    required this.passengerId,
  }) : super(key: key);
  
  @override
  _RealtimeTrackingWidgetState createState() => _RealtimeTrackingWidgetState();
}

class _RealtimeTrackingWidgetState extends State<RealtimeTrackingWidget> {
  late PassengerAppRealtimeAdapter _adapter;
  StreamSubscription<DriverMessage>? _subscription;
  final List<DriverMessage> _recentMessages = [];
  
  @override
  void initState() {
    super.initState();
    _initializeRealtime();
  }
  
  Future<void> _initializeRealtime() async {
    _adapter = PassengerAppRealtimeAdapter(passengerId: widget.passengerId);
    await _adapter.initialize();
    await _adapter.subscribeToRoute(widget.routeId);
    
    final stream = _adapter.getRouteStream(widget.routeId);
    if (stream != null) {
      _subscription = stream.listen((message) {
        setState(() {
          _recentMessages.add(message);
          if (_recentMessages.length > 10) {
            _recentMessages.removeAt(0);
          }
        });
      });
    }
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    _adapter.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Build UI showing real-time bus updates
    return Container();
  }
}

// Note: Import these at the top of your actual implementation file:
// import 'package:flutter/material.dart';
// import 'dart:async';
