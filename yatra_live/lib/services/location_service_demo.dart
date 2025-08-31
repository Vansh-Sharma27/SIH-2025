import 'dart:async';
import 'dart:math' as math;

// Demo GPS coordinates for Delhi region
class DemoLocation {
  final double latitude;
  final double longitude;
  
  DemoLocation(this.latitude, this.longitude);
}

class LocationServiceDemo {
  static final LocationServiceDemo _instance = LocationServiceDemo._internal();
  factory LocationServiceDemo() => _instance;
  LocationServiceDemo._internal();

  // Demo route coordinates (Delhi area)
  static final List<DemoLocation> demoRoute1 = [
    DemoLocation(28.6139, 77.2090), // Connaught Place
    DemoLocation(28.6129, 77.2295), // India Gate area
    DemoLocation(28.6144, 77.2190), // Rajpath
    DemoLocation(28.6280, 77.2185), // Pragati Maidan
  ];

  static final List<DemoLocation> demoRoute2 = [
    DemoLocation(28.6562, 77.2410), // Red Fort
    DemoLocation(28.6506, 77.2344), // Chandni Chowk
    DemoLocation(28.6392, 77.2400), // Jama Masjid
    DemoLocation(28.6262, 77.2428), // Delhi Gate
  ];

  Timer? _locationUpdateTimer;
  StreamController<Position>? _positionStreamController;
  Position? _lastKnownPosition;
  bool _isTracking = false;
  int _currentLocationIndex = 0;
  List<DemoLocation> _currentRoute = demoRoute1;
  
  // Simulated speed in km/h
  double _currentSpeed = 25.0;

  static Future<void> initialize() async {
    print('📍 LocationServiceDemo initialized - No permissions required!');
  }

  // Simulate permission request - always returns true for demo
  Future<bool> _requestPermissions() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate delay
    print('✅ Demo permissions granted');
    return true;
  }

  // Get current location - returns demo location
  Future<Position?> getCurrentLocation() async {
    try {
      await _requestPermissions();
      
      final currentLoc = _currentRoute[_currentLocationIndex];
      _lastKnownPosition = Position(
        latitude: currentLoc.latitude,
        longitude: currentLoc.longitude,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: _calculateHeading(),
        headingAccuracy: 5.0,
        speed: _currentSpeed / 3.6, // Convert km/h to m/s
        speedAccuracy: 2.0,
      );
      
      return _lastKnownPosition;
    } catch (e) {
      print('Error getting demo location: $e');
      return null;
    }
  }

  // Start location tracking simulation
  Future<void> startTracking({
    required String busId,
    String? routeId,
    Function(Position)? onLocationUpdate,
  }) async {
    if (_isTracking) return;

    try {
      await _requestPermissions();
      _isTracking = true;
      
      // Select route based on busId for variety
      _currentRoute = busId.hashCode % 2 == 0 ? demoRoute1 : demoRoute2;
      _currentLocationIndex = 0;
      
      _positionStreamController = StreamController<Position>.broadcast();
      
      // Start location update timer
      _locationUpdateTimer = Timer.periodic(
        const Duration(seconds: 3), // Update every 3 seconds for smooth movement
        (timer) {
          if (!_isTracking) return;
          
          _updateDemoLocation();
          
          if (_lastKnownPosition != null && onLocationUpdate != null) {
            onLocationUpdate(_lastKnownPosition!);
          }
        },
      );
      
      print('🚌 Started tracking bus: $busId on ${busId.hashCode % 2 == 0 ? "Route 1" : "Route 2"}');
    } catch (e) {
      _isTracking = false;
      print('Error starting demo tracking: $e');
    }
  }

  // Stop location tracking
  Future<void> stopTracking(String busId) async {
    if (!_isTracking) return;

    _isTracking = false;
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    await _positionStreamController?.close();
    _positionStreamController = null;
    
    print('🛑 Stopped tracking bus: $busId');
  }

  // Update demo location with interpolation
  void _updateDemoLocation() {
    if (_currentRoute.isEmpty) return;

    // Get current and next location
    final currentLoc = _currentRoute[_currentLocationIndex];
    final nextIndex = (_currentLocationIndex + 1) % _currentRoute.length;
    final nextLoc = _currentRoute[nextIndex];
    
    // Interpolate between points for smooth movement
    final progress = (DateTime.now().millisecondsSinceEpoch % 10000) / 10000.0;
    
    final lat = currentLoc.latitude + (nextLoc.latitude - currentLoc.latitude) * progress;
    final lng = currentLoc.longitude + (nextLoc.longitude - currentLoc.longitude) * progress;
    
    // Add slight randomization for realism
    final random = math.Random();
    final latOffset = (random.nextDouble() - 0.5) * 0.0001;
    final lngOffset = (random.nextDouble() - 0.5) * 0.0001;
    
    // Vary speed slightly
    _currentSpeed = 20.0 + random.nextDouble() * 15.0; // 20-35 km/h
    
    _lastKnownPosition = Position(
      latitude: lat + latOffset,
      longitude: lng + lngOffset,
      timestamp: DateTime.now(),
      accuracy: 5.0 + random.nextDouble() * 10.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: _calculateHeading(),
      headingAccuracy: 5.0,
      speed: _currentSpeed / 3.6,
      speedAccuracy: 2.0,
    );
    
    // Move to next point when close enough
    if (progress > 0.9) {
      _currentLocationIndex = nextIndex;
    }
    
    // Broadcast the update
    _positionStreamController?.add(_lastKnownPosition!);
  }

  double _calculateHeading() {
    if (_currentRoute.length < 2) return 0.0;
    
    final currentLoc = _currentRoute[_currentLocationIndex];
    final nextIndex = (_currentLocationIndex + 1) % _currentRoute.length;
    final nextLoc = _currentRoute[nextIndex];
    
    final deltaLng = nextLoc.longitude - currentLoc.longitude;
    final deltaLat = nextLoc.latitude - currentLoc.latitude;
    
    final angle = math.atan2(deltaLng, deltaLat);
    final degrees = angle * 180 / math.pi;
    
    return degrees >= 0 ? degrees : 360 + degrees;
  }

  // Calculate distance between two points
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(endLatitude - startLatitude);
    final double dLon = _toRadians(endLongitude - startLongitude);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(startLatitude)) *
        math.cos(_toRadians(endLatitude)) *
        math.sin(dLon / 2) *
        math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  // Estimate arrival time
  static Duration estimateArrivalTime(
    Position currentPosition,
    double destinationLat,
    double destinationLng,
    {double averageSpeedKmh = 25.0}
  ) {
    final distance = calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      destinationLat,
      destinationLng,
    );
    
    final distanceKm = distance / 1000;
    final timeHours = distanceKm / averageSpeedKmh;
    
    return Duration(minutes: (timeHours * 60).round());
  }

  Position? get lastKnownPosition => _lastKnownPosition;
  bool get isTracking => _isTracking;
  
  Future<bool> isLocationServiceEnabled() async => true; // Always enabled for demo
  
  Future<void> openLocationSettings() async {
    print('📍 Location settings (simulated for demo)');
  }

  Stream<Position>? get positionStream => _positionStreamController?.stream;
}

// Mock Position class for demo - exported for use in other files
class Position {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;
  final double altitude;
  final double altitudeAccuracy;
  final double heading;
  final double headingAccuracy;
  final double speed;
  final double speedAccuracy;

  Position({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
    required this.altitude,
    required this.altitudeAccuracy,
    required this.heading,
    required this.headingAccuracy,
    required this.speed,
    required this.speedAccuracy,
  });
}
