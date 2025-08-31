import 'dart:math';
import '../models/bus_model.dart';
import '../models/route_model.dart';

class TestingUtils {
  static final Random _random = Random();
  
  // MARK: - Mock Data Generation
  static List<BusModel> generateMockBuses({int count = 5}) {
    final buses = <BusModel>[];
    final statuses = ['active', 'inactive', 'maintenance'];
    
    for (int i = 0; i < count; i++) {
      buses.add(BusModel(
        id: 'TEST_BUS_${i.toString().padLeft(3, '0')}',
        busNumber: 'T${100 + i}',
        routeId: 'route_${_random.nextInt(3).toString().padLeft(3, '0')}',
        driverId: 'driver_${i}',
        latitude: 28.6139 + (_random.nextDouble() - 0.5) * 0.1, // Delhi area
        longitude: 77.2090 + (_random.nextDouble() - 0.5) * 0.1,
        speed: _random.nextDouble() * 60, // 0-60 km/h
        heading: _random.nextDouble() * 360,
        status: statuses[_random.nextInt(statuses.length)],
        passengerCount: _random.nextInt(40),
        lastUpdated: DateTime.now().subtract(
          Duration(seconds: _random.nextInt(300))
        ),
      ));
    }
    
    return buses;
  }

  static List<RouteModel> generateMockRoutes({int count = 3}) {
    final routes = <RouteModel>[];
    final routeNames = [
      'City Center to Airport Express',
      'University Campus Shuttle', 
      'Metro Connect Service',
      'Shopping District Loop',
      'Hospital Emergency Route'
    ];
    
    for (int i = 0; i < count; i++) {
      final stops = generateMockBusStops(stopCount: 5 + _random.nextInt(8));
      
      routes.add(RouteModel(
        id: 'route_${i.toString().padLeft(3, '0')}',
        routeName: routeNames[i % routeNames.length],
        routeNumber: 'R${100 + i}',
        stops: stops,
        pathCoordinates: _generatePathCoordinates(stops),
        distance: 5.0 + _random.nextDouble() * 20, // 5-25 km
        estimatedDuration: Duration(minutes: 20 + _random.nextInt(60)),
        startPoint: stops.first.name,
        endPoint: stops.last.name,
        isActive: _random.nextBool(),
      ));
    }
    
    return routes;
  }

  static List<BusStop> generateMockBusStops({int stopCount = 6}) {
    final stopNames = [
      'Central Station', 'City Mall', 'University Gate', 'Hospital Complex',
      'IT Park', 'Shopping Center', 'Railway Junction', 'Airport Terminal',
      'Bus Depot', 'Government Office', 'Sports Complex', 'Market Square',
      'Tech Hub', 'Medical College', 'Metro Station', 'Convention Center'
    ];
    
    final stops = <BusStop>[];
    final shuffled = [...stopNames]..shuffle(_random);
    
    for (int i = 0; i < stopCount && i < shuffled.length; i++) {
      stops.add(BusStop(
        id: 'stop_${i.toString().padLeft(3, '0')}',
        name: shuffled[i],
        latitude: 28.6139 + (_random.nextDouble() - 0.5) * 0.2,
        longitude: 77.2090 + (_random.nextDouble() - 0.5) * 0.2,
        sequenceNumber: i + 1,
        isTerminal: i == 0 || i == stopCount - 1,
        estimatedArrivalFromStart: Duration(minutes: i * 8 + _random.nextInt(5)),
      ));
    }
    
    return stops;
  }

  static List<RouteLatLng> _generatePathCoordinates(List<BusStop> stops) {
    final coordinates = <RouteLatLng>[];
    
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      coordinates.add(RouteLatLng(
        latitude: stop.latitude,
        longitude: stop.longitude,
      ));
      
      // Add intermediate points between stops
      if (i < stops.length - 1) {
        final nextStop = stops[i + 1];
        final intermediatePoints = _generateIntermediatePoints(
          stop.latitude, stop.longitude,
          nextStop.latitude, nextStop.longitude,
        );
        coordinates.addAll(intermediatePoints);
      }
    }
    
    return coordinates;
  }

  static List<RouteLatLng> _generateIntermediatePoints(
    double lat1, double lon1, double lat2, double lon2
  ) {
    final points = <RouteLatLng>[];
    const int numPoints = 3; // Points between stops
    
    for (int i = 1; i <= numPoints; i++) {
      final ratio = i / (numPoints + 1);
      final lat = lat1 + (lat2 - lat1) * ratio;
      final lon = lon1 + (lon2 - lon1) * ratio;
      
      // Add some random variation for realistic path
      final variation = 0.001;
      points.add(RouteLatLng(
        latitude: lat + (_random.nextDouble() - 0.5) * variation,
        longitude: lon + (_random.nextDouble() - 0.5) * variation,
      ));
    }
    
    return points;
  }

  static List<String> _generateRandomAmenities() {
    final allAmenities = [
      'WiFi', 'AC', 'CCTV', 'GPS', 'Audio', 'Wheelchair Access',
      'USB Charging', 'Digital Display', 'Emergency Button'
    ];
    
    final count = _random.nextInt(4) + 2; // 2-5 amenities
    final shuffled = [...allAmenities]..shuffle(_random);
    
    return shuffled.take(count).toList();
  }

  // MARK: - Performance Testing
  static void simulateNetworkDelay({int minMs = 100, int maxMs = 2000}) {
    final delay = minMs + _random.nextInt(maxMs - minMs);
    print('🐌 Simulating network delay: ${delay}ms');
    // In real testing, you'd use Future.delayed(Duration(milliseconds: delay))
  }

  static void simulateLocationUpdate(BusModel bus) {
    // Simulate realistic movement
    final speedKmh = bus.speed ?? 20.0;
    final speedMs = speedKmh / 3.6; // Convert to m/s
    
    // Approximate degrees per meter at Delhi latitude
    const double degreesPerMeter = 1 / 111320.0;
    
    // Update every 5 seconds typically
    const updateIntervalSeconds = 5;
    final distanceMeters = speedMs * updateIntervalSeconds;
    
    // Calculate new position based on heading
    final headingRad = (bus.heading ?? 0) * (pi / 180);
    final deltaLat = distanceMeters * cos(headingRad) * degreesPerMeter;
    final deltaLng = distanceMeters * sin(headingRad) * degreesPerMeter;
    
    bus.latitude += deltaLat;
    bus.longitude += deltaLng;
    bus.lastUpdated = DateTime.now();
    
    // Add small random variations for realism  
    bus.speed = (speedKmh + (_random.nextDouble() - 0.5) * 5).clamp(0, 80);
    bus.heading = ((bus.heading ?? 0) + (_random.nextDouble() - 0.5) * 10) % 360;
    
    print('📍 Updated bus ${bus.busNumber}: ${bus.latitude.toStringAsFixed(6)}, ${bus.longitude.toStringAsFixed(6)}');
  }

  // MARK: - Testing Scenarios
  static Map<String, dynamic> getTestScenario(String scenarioName) {
    final scenarios = {
      'heavy_traffic': {
        'description': 'Simulate heavy traffic conditions',
        'busSpeed': 5.0, // Very slow
        'updateFrequency': 10, // Slower updates
        'passengerLoad': 'high',
      },
      
      'normal_operations': {
        'description': 'Normal operating conditions',
        'busSpeed': 25.0,
        'updateFrequency': 5,
        'passengerLoad': 'medium',
      },
      
      'peak_hours': {
        'description': 'Rush hour with many active buses',
        'busCount': 15,
        'busSpeed': 15.0,
        'updateFrequency': 3,
        'passengerLoad': 'high',
      },
      
      'network_issues': {
        'description': 'Intermittent connectivity',
        'networkSuccess': 0.7, // 70% success rate
        'retryDelay': 5000, // 5 second delays
        'useCache': true,
      },
      
      'battery_optimization': {
        'description': 'Low power mode testing',
        'locationAccuracy': 'low',
        'updateFrequency': 30, // 30 second intervals
        'backgroundMode': true,
      }
    };
    
    return scenarios[scenarioName] ?? scenarios['normal_operations']!;
  }

  // MARK: - Validation Helpers
  static bool validateBusData(BusModel bus) {
    final validations = [
      bus.id.isNotEmpty,
      bus.busNumber.isNotEmpty,
      bus.latitude >= -90 && bus.latitude <= 90,
      bus.longitude >= -180 && bus.longitude <= 180,
      bus.speed == null || bus.speed! >= 0,
      bus.passengerCount == null || bus.passengerCount! >= 0,
    ];
    
    return validations.every((validation) => validation);
  }

  static bool validateRouteData(RouteModel route) {
    final validations = [
      route.id.isNotEmpty,
      route.routeName.isNotEmpty,
      route.routeNumber.isNotEmpty,
      route.stops.isNotEmpty,
      route.distance > 0,
      route.stops.first.sequenceNumber == 1,
      route.stops.last.sequenceNumber == route.stops.length,
    ];
    
    return validations.every((validation) => validation);
  }

  // MARK: - Performance Metrics
  static void logPerformanceMetric(String operation, Duration duration) {
    final ms = duration.inMilliseconds;
    String level = '✅';
    
    if (ms > 1000) level = '🐌';
    else if (ms > 500) level = '⚠️';
    
    print('$level $operation took ${ms}ms');
  }

  static Future<T> measurePerformance<T>(
    String operationName, 
    Future<T> Function() operation
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      logPerformanceMetric(operationName, stopwatch.elapsed);
      return result;
    } catch (e) {
      stopwatch.stop();
      print('❌ $operationName failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }
}
