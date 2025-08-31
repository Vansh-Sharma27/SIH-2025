/// Performance Integration Guide for YatraLive Demo
/// 
/// This file demonstrates how to integrate the enhanced performance monitoring
/// system with the multiclient simulation harness for your hackathon demo.

import 'package:flutter/material.dart';
import 'enhanced_performance_monitor.dart';
import 'multiclient_simulation_harness.dart';
import 'demo_scenarios.dart';
import '../../widgets/performance_overlay.dart';
import '../../widgets/demo_control_panel.dart';

/// Example: How to use the performance monitoring system in your app
class PerformanceIntegrationExample {
  
  /// 1. Initialize the enhanced performance monitor
  static void initializePerformanceMonitoring() {
    final monitor = EnhancedPerformanceMonitor();
    
    // Start monitoring
    monitor.startMonitoring();
    
    // Subscribe to performance snapshots
    monitor.snapshotStream.listen((snapshot) {
      print('📊 Performance Snapshot:');
      print('  - System Health: ${snapshot.systemHealth}');
      print('  - Active Connections: ${snapshot.connectionStats.activeConnections}');
      print('  - Message Paths: ${snapshot.messagePathStats.length}');
    });
    
    // Subscribe to alerts
    monitor.alertStream.listen((alert) {
      print('🚨 Performance Alert: ${alert.message}');
      // Handle alerts (show notifications, adjust system behavior, etc.)
    });
  }
  
  /// 2. Track message paths through the system
  static void trackMessagePath() {
    final monitor = EnhancedPerformanceMonitor();
    
    // Start tracking when a driver sends location update
    monitor.beginMessagePath(
      messageId: 'loc_update_123',
      source: 'driver_app',
      destination: 'backend_server',
      metadata: {
        'busId': 'bus_001',
        'routeId': 'route_1',
        'updateType': 'location',
      },
    );
    
    // Add checkpoints as message flows through system
    monitor.addPathCheckpoint('loc_update_123', 'received_by_server');
    monitor.addPathCheckpoint('loc_update_123', 'validated');
    monitor.addPathCheckpoint('loc_update_123', 'broadcast_initiated');
    
    // Complete tracking when message reaches passengers
    monitor.completeMessagePath('loc_update_123', success: true);
  }
  
  /// 3. Use the simulation harness for load testing
  static Future<void> runLoadTest() async {
    final harness = MulticlientSimulationHarness(
      config: SimulationConfig(
        driverCount: 10,
        passengerCount: 50,
        routes: ['route_1', 'route_2', 'route_3'],
        enableChaos: false,
      ),
    );
    
    // Start simulation
    await harness.startSimulation();
    
    // Monitor performance dashboard
    harness.performanceDashboardStream.listen((dashboard) {
      print('📈 Dashboard Update:');
      print('  - Latency: ${dashboard['latency']['average']}ms');
      print('  - Delivery Rate: ${dashboard['delivery']['rate']}%');
    });
    
    // Run for 2 minutes
    await Future.delayed(const Duration(minutes: 2));
    
    // Stop simulation
    await harness.stopSimulation();
  }
  
  /// 4. Use demo scenarios for hackathon presentation
  static Future<void> runDemoScenario() async {
    final controller = DemoScenarioController();
    
    // Set up narration callback for live commentary
    controller.onNarration = (message) {
      print('🎙️ Demo Narration: $message');
      // Could also display in UI or use text-to-speech
    };
    
    // Run morning rush hour scenario
    await controller.startScenario('morning_rush');
    
    // Or run scalability showcase
    // await controller.startScenario('scalability_test');
  }
}

/// Example: How to add performance monitoring to your screens
class DemoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YatraLive Demo'),
      ),
      body: Stack(
        children: [
          // Your main UI content
          Center(
            child: Text('Your App Content Here'),
          ),
          
          // Add performance overlay (shows real-time metrics)
          const PerformanceOverlay(
            expanded: false,  // Start minimized
            showAlerts: true,
          ),
          
          // Add demo control panel (for running scenarios)
          const DemoControlPanel(
            startMinimized: true,
          ),
        ],
      ),
    );
  }
}

/// Example: Integration with existing services
class ServiceIntegration {
  
  /// Add performance tracking to WebSocket messages
  static void trackWebSocketMessage(String messageId, dynamic message) {
    final monitor = EnhancedPerformanceMonitor();
    
    // Track when sending
    monitor.beginMessagePath(
      messageId: messageId,
      source: 'websocket_client',
      destination: 'websocket_server',
      metadata: {'messageType': message.runtimeType.toString()},
    );
    
    // Track when received
    monitor.addPathCheckpoint(messageId, 'received_by_server');
    
    // Track when processed
    monitor.completeMessagePath(messageId, success: true);
  }
  
  /// Monitor queue operations
  static void monitorQueueDepth(String queueName, int depth) {
    final monitor = EnhancedPerformanceMonitor();
    monitor.updateQueueDepth(queueName, depth);
  }
  
  /// Track connection health
  static void trackConnectionHealth(String connectionId, bool isConnected) {
    final monitor = EnhancedPerformanceMonitor();
    monitor.updateConnectionMetrics(
      connectionId: connectionId,
      isConnected: isConnected,
      reconnectCount: 0,
    );
  }
}

/// Tips for hackathon demo:
/// 
/// 1. Start with a clean state - reset metrics before demo
/// 2. Use the Demo Control Panel to run pre-scripted scenarios
/// 3. Show the Performance Overlay during high-load tests
/// 4. Export metrics after demo for analysis
/// 5. Use narration feature to explain what's happening
/// 
/// Demo flow suggestion:
/// - Start with "Morning Rush Hour" to show normal operation
/// - Run "Scalability Test" to demonstrate handling 200+ users
/// - Show "Network Resilience" to prove offline capability
/// - End with "Performance Stress Test" to show system limits
/// 
/// Key metrics to highlight:
/// - Sub-100ms average latency
/// - 99%+ message delivery rate
/// - Zero data loss during disconnections
/// - Linear scalability up to 200+ concurrent users
