import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'driver_realtime_adapter.dart';
import 'passenger_realtime_adapter.dart';
import 'performance_monitor.dart';
import 'models/realtime_models.dart';
import '../location_service_demo.dart';
import '../database_service_demo.dart';

/// Simulation configuration
class SimulationConfig {
  final int driverCount;
  final int passengerCount;
  final List<String> routes;
  final Duration driverUpdateInterval;
  final bool enableChaos; // Random disconnections, delays
  final bool showPerformanceOverlay;
  
  const SimulationConfig({
    this.driverCount = 5,
    this.passengerCount = 20,
    this.routes = const ['route_1', 'route_2', 'route_3'],
    this.driverUpdateInterval = const Duration(seconds: 1),
    this.enableChaos = false,
    this.showPerformanceOverlay = true,
  });
}

/// Multi-client simulation harness for stress testing and demos
class MulticlientSimulationHarness {
  final SimulationConfig config;
  
  // Active instances
  final Map<String, DriverAppRealtimeAdapter> _drivers = {};
  final Map<String, PassengerAppRealtimeAdapter> _passengers = {};
  final Map<String, SimulationEntity> _entities = {};
  
  // Performance monitoring
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  
  // Simulation state
  bool _isRunning = false;
  Timer? _chaosTimer;
  Timer? _statusTimer;
  final _random = math.Random();
  
  // UI callback
  Function(SimulationState)? onStateUpdate;
  
  MulticlientSimulationHarness({
    this.config = const SimulationConfig(),
  });

  /// Start the simulation
  Future<void> startSimulation() async {
    if (_isRunning) {
      print('⚠️ Simulation already running');
      return;
    }
    
    _isRunning = true;
    _performanceMonitor.startMonitoring();
    
    print('🚀 Starting Multi-client Simulation');
    print('Configuration:');
    print('  Drivers: ${config.driverCount}');
    print('  Passengers: ${config.passengerCount}');
    print('  Routes: ${config.routes.join(', ')}');
    print('  Chaos Mode: ${config.enableChaos ? "ENABLED" : "DISABLED"}');
    
    // Initialize database
    DatabaseServiceDemo().initialize();
    
    // Spawn drivers
    await _spawnDrivers();
    
    // Spawn passengers
    await _spawnPassengers();
    
    // Start chaos mode if enabled
    if (config.enableChaos) {
      _startChaosMode();
    }
    
    // Start status reporting
    _startStatusReporting();
    
    // Notify UI
    _updateState();
    
    print('✅ Simulation started successfully');
  }

  /// Spawn driver instances
  Future<void> _spawnDrivers() async {
    for (int i = 0; i < config.driverCount; i++) {
      final driverId = 'sim_driver_$i';
      final busId = 'sim_bus_$i';
      final routeId = config.routes[i % config.routes.length];
      
      final driver = DriverAppRealtimeAdapter(
        driverId: driverId,
        busId: busId,
        routeId: routeId,
        updateInterval: config.driverUpdateInterval,
      );
      
      _drivers[driverId] = driver;
      _entities[driverId] = SimulationEntity(
        id: driverId,
        type: EntityType.driver,
        routeId: routeId,
        status: EntityStatus.starting,
        metadata: {
          'busId': busId,
          'startTime': DateTime.now().toIso8601String(),
        },
      );
      
      // Start with slight delay to avoid thundering herd
      await Future.delayed(Duration(milliseconds: 100 * i));
      
      try {
        await driver.startBroadcasting();
        _entities[driverId]!.status = EntityStatus.active;
        
        // Track performance
        _performanceMonitor.recordDelivery(success: true);
        _performanceMonitor.updateConnectionCount(_drivers.length + _passengers.length);
        
        print('🚌 Spawned driver $i on $routeId');
      } catch (e) {
        _entities[driverId]!.status = EntityStatus.error;
        print('❌ Failed to spawn driver $i: $e');
      }
    }
  }

  /// Spawn passenger instances
  Future<void> _spawnPassengers() async {
    for (int i = 0; i < config.passengerCount; i++) {
      final passengerId = 'sim_passenger_$i';
      final routeId = config.routes[i % config.routes.length];
      
      final passenger = PassengerAppRealtimeAdapter(passengerId: passengerId);
      _passengers[passengerId] = passenger;
      
      _entities[passengerId] = SimulationEntity(
        id: passengerId,
        type: EntityType.passenger,
        routeId: routeId,
        status: EntityStatus.starting,
        metadata: {
          'subscribedAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Initialize with delay
      await Future.delayed(Duration(milliseconds: 50 * i));
      
      try {
        await passenger.initialize();
        
        // Set random passenger location
        passenger.updateUserLocation(Position(
          latitude: 28.6139 + (_random.nextDouble() - 0.5) * 0.05,
          longitude: 77.2090 + (_random.nextDouble() - 0.5) * 0.05,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ));
        
        // Subscribe to route
        await passenger.subscribeToRoute(routeId);
        _entities[passengerId]!.status = EntityStatus.active;
        
        // Set up message counter
        int messageCount = 0;
        passenger.getRouteStream(routeId)?.listen((message) {
          messageCount++;
          _entities[passengerId]!.metadata['messageCount'] = messageCount;
          _entities[passengerId]!.metadata['lastMessageTime'] = DateTime.now().toIso8601String();
          
          // Record performance metric
          _performanceMonitor.recordDelivery(success: true);
        });
        
        _performanceMonitor.updateConnectionCount(_drivers.length + _passengers.length);
        
        print('👤 Spawned passenger $i on $routeId');
      } catch (e) {
        _entities[passengerId]!.status = EntityStatus.error;
        print('❌ Failed to spawn passenger $i: $e');
      }
    }
  }

  /// Start chaos mode for testing resilience
  void _startChaosMode() {
    _chaosTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final chaosType = _random.nextInt(4);
      
      switch (chaosType) {
        case 0:
          _simulateDriverDisconnect();
          break;
        case 1:
          _simulatePassengerReconnect();
          break;
        case 2:
          _simulateHighLoad();
          break;
        case 3:
          _simulateNetworkDelay();
          break;
      }
    });
  }

  /// Simulate driver disconnect
  void _simulateDriverDisconnect() {
    if (_drivers.isEmpty) return;
    
    final drivers = _drivers.entries.toList();
    final victim = drivers[_random.nextInt(drivers.length)];
    
    print('💥 CHAOS: Disconnecting driver ${victim.key}');
    _entities[victim.key]!.status = EntityStatus.disconnected;
    
    // Reconnect after delay
    Future.delayed(Duration(seconds: 5 + _random.nextInt(10)), () async {
      if (_isRunning && _drivers.containsKey(victim.key)) {
        await victim.value.startBroadcasting();
        _entities[victim.key]!.status = EntityStatus.active;
        print('🔄 CHAOS: Reconnected driver ${victim.key}');
      }
    });
  }

  /// Simulate passenger reconnect
  void _simulatePassengerReconnect() {
    if (_passengers.isEmpty) return;
    
    final passengers = _passengers.entries.toList();
    final victim = passengers[_random.nextInt(passengers.length)];
    
    print('💥 CHAOS: Passenger ${victim.key} experiencing connection issues');
    _entities[victim.key]!.status = EntityStatus.reconnecting;
    
    Future.delayed(const Duration(seconds: 3), () {
      if (_isRunning) {
        _entities[victim.key]!.status = EntityStatus.active;
      }
    });
  }

  /// Simulate high load
  void _simulateHighLoad() {
    print('💥 CHAOS: Simulating high load burst');
    
    // Send multiple messages rapidly
    for (final driver in _drivers.values) {
      for (int i = 0; i < 10; i++) {
        driver.updatePassengerCount(20 + _random.nextInt(30));
      }
    }
  }

  /// Simulate network delay
  void _simulateNetworkDelay() {
    print('💥 CHAOS: Simulating network congestion');
    // This would affect the underlying WebSocket simulation
    // For now, just log it
  }

  /// Start status reporting
  void _startStatusReporting() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _printStatus();
      _updateState();
    });
  }

  /// Print current status
  void _printStatus() {
    final activeDrivers = _entities.values
        .where((e) => e.type == EntityType.driver && e.status == EntityStatus.active)
        .length;
    final activePassengers = _entities.values
        .where((e) => e.type == EntityType.passenger && e.status == EntityStatus.active)
        .length;
    
    print('\n📊 Simulation Status:');
    print('  Active Drivers: $activeDrivers/${config.driverCount}');
    print('  Active Passengers: $activePassengers/${config.passengerCount}');
    
    // Route distribution
    final routeStats = <String, int>{};
    for (final entity in _entities.values) {
      if (entity.status == EntityStatus.active) {
        routeStats[entity.routeId] = (routeStats[entity.routeId] ?? 0) + 1;
      }
    }
    print('  Route Distribution: $routeStats');
    
    // Performance snapshot
    final perfSnapshot = _performanceMonitor.getSnapshot();
    final latency = perfSnapshot['metrics']['latency']['average'];
    final deliveryRate = perfSnapshot['counters']['deliveryRate'] ?? 100.0;
    print('  Avg Latency: ${latency?.toStringAsFixed(1)}ms');
    print('  Delivery Rate: ${deliveryRate.toStringAsFixed(1)}%');
    print('  System Health: ${perfSnapshot['health']}');
  }

  /// Update simulation state for UI
  void _updateState() {
    final state = SimulationState(
      isRunning: _isRunning,
      entities: Map.from(_entities),
      performanceSnapshot: _performanceMonitor.getSnapshot(),
      config: config,
    );
    
    onStateUpdate?.call(state);
  }

  /// Add a new driver dynamically
  Future<void> addDriver({String? routeId}) async {
    final id = 'sim_driver_${_drivers.length}';
    final busId = 'sim_bus_${_drivers.length}';
    final route = routeId ?? config.routes[_random.nextInt(config.routes.length)];
    
    final driver = DriverAppRealtimeAdapter(
      driverId: id,
      busId: busId,
      routeId: route,
      updateInterval: config.driverUpdateInterval,
    );
    
    _drivers[id] = driver;
    _entities[id] = SimulationEntity(
      id: id,
      type: EntityType.driver,
      routeId: route,
      status: EntityStatus.starting,
      metadata: {'busId': busId},
    );
    
    await driver.startBroadcasting();
    _entities[id]!.status = EntityStatus.active;
    
    _performanceMonitor.updateConnectionCount(_drivers.length + _passengers.length);
    _updateState();
    
    print('➕ Added new driver: $id on $route');
  }

  /// Add a new passenger dynamically
  Future<void> addPassenger({String? routeId}) async {
    final id = 'sim_passenger_${_passengers.length}';
    final route = routeId ?? config.routes[_random.nextInt(config.routes.length)];
    
    final passenger = PassengerAppRealtimeAdapter(passengerId: id);
    _passengers[id] = passenger;
    _entities[id] = SimulationEntity(
      id: id,
      type: EntityType.passenger,
      routeId: route,
      status: EntityStatus.starting,
      metadata: {},
    );
    
    await passenger.initialize();
    await passenger.subscribeToRoute(route);
    _entities[id]!.status = EntityStatus.active;
    
    _performanceMonitor.updateConnectionCount(_drivers.length + _passengers.length);
    _updateState();
    
    print('➕ Added new passenger: $id on $route');
  }

  /// Remove an entity
  Future<void> removeEntity(String entityId) async {
    if (_drivers.containsKey(entityId)) {
      await _drivers[entityId]!.stopBroadcasting();
      _drivers.remove(entityId);
    } else if (_passengers.containsKey(entityId)) {
      _passengers[entityId]!.dispose();
      _passengers.remove(entityId);
    }
    
    _entities.remove(entityId);
    _performanceMonitor.updateConnectionCount(_drivers.length + _passengers.length);
    _updateState();
    
    print('➖ Removed entity: $entityId');
  }

  /// Stop the simulation
  Future<void> stopSimulation() async {
    if (!_isRunning) return;
    
    _isRunning = false;
    
    print('🛑 Stopping simulation...');
    
    // Cancel timers
    _chaosTimer?.cancel();
    _statusTimer?.cancel();
    
    // Stop all drivers
    for (final driver in _drivers.values) {
      await driver.stopBroadcasting();
    }
    
    // Dispose all passengers
    for (final passenger in _passengers.values) {
      passenger.dispose();
    }
    
    // Clear collections
    _drivers.clear();
    _passengers.clear();
    _entities.clear();
    
    // Stop performance monitoring
    _performanceMonitor.stopMonitoring();
    
    _updateState();
    
    print('✅ Simulation stopped');
  }

  /// Get performance dashboard stream
  Stream<Map<String, dynamic>> get performanceDashboardStream => 
      _performanceMonitor.dashboardStream;

  /// Clean up resources
  void dispose() {
    stopSimulation();
    _performanceMonitor.dispose();
  }
}

/// Simulation entity representation
class SimulationEntity {
  final String id;
  final EntityType type;
  final String routeId;
  EntityStatus status;
  final Map<String, dynamic> metadata;
  
  SimulationEntity({
    required this.id,
    required this.type,
    required this.routeId,
    required this.status,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};
}

enum EntityType { driver, passenger }
enum EntityStatus { starting, active, disconnected, reconnecting, error }

/// Simulation state for UI
class SimulationState {
  final bool isRunning;
  final Map<String, SimulationEntity> entities;
  final Map<String, dynamic> performanceSnapshot;
  final SimulationConfig config;
  
  const SimulationState({
    required this.isRunning,
    required this.entities,
    required this.performanceSnapshot,
    required this.config,
  });
}
