import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

// Demo API service that simulates RESTful endpoints
class ApiServiceDemo {
  static final ApiServiceDemo _instance = ApiServiceDemo._internal();
  factory ApiServiceDemo() => _instance;
  ApiServiceDemo._internal();

  final _random = math.Random();
  
  // Simulated API delay
  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(Duration(milliseconds: 200 + _random.nextInt(300)));
  }

  // API Response wrapper
  ApiResponse<T> _createResponse<T>({
    required T data,
    String message = 'Success',
    int statusCode = 200,
  }) {
    return ApiResponse<T>(
      data: data,
      message: message,
      statusCode: statusCode,
      timestamp: DateTime.now(),
    );
  }

  ApiResponse<T> _createErrorResponse<T>({
    required String message,
    int statusCode = 400,
  }) {
    return ApiResponse<T>(
      data: null,
      message: message,
      statusCode: statusCode,
      timestamp: DateTime.now(),
      isError: true,
    );
  }

  // Bus-related endpoints
  Future<ApiResponse<Map<String, dynamic>>> getBusDetails(String busId) async {
    await _simulateNetworkDelay();
    
    try {
      final busData = {
        'id': busId,
        'busNumber': 'DL0${busId.substring(4)}-${1000 + _random.nextInt(9000)}',
        'status': 'active',
        'currentLocation': {
          'latitude': 28.6139 + (_random.nextDouble() - 0.5) * 0.1,
          'longitude': 77.2090 + (_random.nextDouble() - 0.5) * 0.1,
        },
        'speed': 20 + _random.nextDouble() * 20,
        'passengerCount': _random.nextInt(40) + 10,
        'maxCapacity': 50,
        'driverInfo': {
          'name': 'Driver ${_random.nextInt(100)}',
          'rating': 3.5 + _random.nextDouble() * 1.5,
          'experience': '${_random.nextInt(10) + 1} years',
        },
      };
      
      return _createResponse(data: busData);
    } catch (e) {
      return _createErrorResponse(message: 'Bus not found');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getNearbyBuses({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    await _simulateNetworkDelay();
    
    final nearbyBuses = List.generate(5, (index) {
      final distance = _random.nextDouble() * radiusKm;
      return {
        'id': 'bus_${index + 1}',
        'busNumber': 'DL0${index + 1}-${1000 + _random.nextInt(9000)}',
        'distance': distance,
        'estimatedArrival': (distance * 3).round(), // minutes
        'currentLocation': {
          'latitude': latitude + (_random.nextDouble() - 0.5) * 0.05,
          'longitude': longitude + (_random.nextDouble() - 0.5) * 0.05,
        },
        'routeName': 'Route ${index + 1}',
        'crowdLevel': ['low', 'medium', 'high'][_random.nextInt(3)],
      };
    });
    
    // Sort by distance
    nearbyBuses.sort((a, b) => (a['distance'] as num).compareTo(b['distance'] as num));
    
    return _createResponse(data: nearbyBuses);
  }

  // Route-related endpoints
  Future<ApiResponse<Map<String, dynamic>>> getRouteDetails(String routeId) async {
    await _simulateNetworkDelay();
    
    final routeData = {
      'id': routeId,
      'name': 'Route ${routeId.substring(6)}',
      'totalDistance': 5 + _random.nextDouble() * 15, // km
      'estimatedDuration': 20 + _random.nextInt(40), // minutes
      'activeBuses': _random.nextInt(5) + 1,
      'fare': {
        'adult': 10 + _random.nextInt(20),
        'child': 5 + _random.nextInt(10),
        'student': 5 + _random.nextInt(15),
      },
      'schedule': {
        'firstBus': '06:00 AM',
        'lastBus': '10:00 PM',
        'frequency': '${10 + _random.nextInt(20)} minutes',
      },
      'popularity': _random.nextDouble() * 100,
    };
    
    return _createResponse(data: routeData);
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> searchRoutes(String query) async {
    await _simulateNetworkDelay();
    
    final routes = [
      {'id': 'route_1', 'name': 'Connaught Place - Pragati Maidan', 'match': 95},
      {'id': 'route_2', 'name': 'Red Fort - Delhi Gate', 'match': 85},
      {'id': 'route_3', 'name': 'India Gate - Rajpath', 'match': 75},
      {'id': 'route_4', 'name': 'Chandni Chowk - Karol Bagh', 'match': 65},
    ];
    
    // Filter based on query
    final filteredRoutes = routes
        .where((route) => 
            route['name'].toString().toLowerCase().contains(query.toLowerCase()))
        .map((route) => {
          ...route,
          'estimatedDuration': 20 + _random.nextInt(40),
          'distance': 5 + _random.nextDouble() * 15,
          'activeBuses': _random.nextInt(5) + 1,
        })
        .toList();
    
    return _createResponse(data: filteredRoutes);
  }

  // ETA calculation endpoint
  Future<ApiResponse<Map<String, dynamic>>> calculateETA({
    required String busId,
    required String stopId,
  }) async {
    await _simulateNetworkDelay();
    
    final etaData = {
      'busId': busId,
      'stopId': stopId,
      'estimatedTime': 5 + _random.nextInt(25), // minutes
      'distance': 1 + _random.nextDouble() * 10, // km
      'trafficCondition': ['light', 'moderate', 'heavy'][_random.nextInt(3)],
      'confidence': 70 + _random.nextDouble() * 30, // percentage
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    
    return _createResponse(data: etaData);
  }

  // Feedback endpoints
  Future<ApiResponse<Map<String, dynamic>>> submitFeedback({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    await _simulateNetworkDelay();
    
    final feedbackId = 'fb_${DateTime.now().millisecondsSinceEpoch}';
    
    return _createResponse(
      data: {
        'feedbackId': feedbackId,
        'status': 'submitted',
        'message': 'Thank you for your feedback!',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Analytics endpoints
  Future<ApiResponse<Map<String, dynamic>>> getRouteAnalytics(String routeId) async {
    await _simulateNetworkDelay();
    
    final analytics = {
      'routeId': routeId,
      'dailyRidership': 500 + _random.nextInt(1500),
      'averageDelay': _random.nextInt(10), // minutes
      'peakHours': ['8-10 AM', '5-7 PM'],
      'satisfactionScore': 3.5 + _random.nextDouble() * 1.5,
      'crowdingStats': {
        'morning': ['high', 'very high'][_random.nextInt(2)],
        'afternoon': ['medium', 'high'][_random.nextInt(2)],
        'evening': ['high', 'very high'][_random.nextInt(2)],
      },
      'popularStops': [
        'Connaught Place',
        'India Gate',
        'Pragati Maidan',
      ],
    };
    
    return _createResponse(data: analytics);
  }

  // User preferences
  Future<ApiResponse<Map<String, dynamic>>> updateUserPreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    await _simulateNetworkDelay();
    
    return _createResponse(
      data: {
        'userId': userId,
        'preferences': preferences,
        'status': 'updated',
        'timestamp': DateTime.now().toIso8601String(),
      },
      message: 'Preferences updated successfully',
    );
  }

  // Weather integration (mock)
  Future<ApiResponse<Map<String, dynamic>>> getWeatherImpact() async {
    await _simulateNetworkDelay();
    
    final weatherData = {
      'condition': ['Clear', 'Rainy', 'Foggy'][_random.nextInt(3)],
      'temperature': 20 + _random.nextInt(20),
      'impact': {
        'delayFactor': 1.0 + _random.nextDouble() * 0.5,
        'message': 'Slight delays expected due to weather conditions',
        'severity': ['low', 'medium', 'high'][_random.nextInt(3)],
      },
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    
    return _createResponse(data: weatherData);
  }

  // Batch operations
  Future<ApiResponse<List<Map<String, dynamic>>>> batchGetBusLocations(
    List<String> busIds,
  ) async {
    await _simulateNetworkDelay();
    
    final locations = busIds.map((busId) => {
      'busId': busId,
      'location': {
        'latitude': 28.6139 + (_random.nextDouble() - 0.5) * 0.1,
        'longitude': 77.2090 + (_random.nextDouble() - 0.5) * 0.1,
      },
      'speed': 20 + _random.nextDouble() * 20,
      'heading': _random.nextDouble() * 360,
      'lastUpdated': DateTime.now().toIso8601String(),
    }).toList();
    
    return _createResponse(data: locations);
  }

  // Health check endpoint
  Future<ApiResponse<Map<String, dynamic>>> healthCheck() async {
    await _simulateNetworkDelay();
    
    return _createResponse(
      data: {
        'status': 'healthy',
        'version': '1.0.0',
        'services': {
          'database': 'connected',
          'notifications': 'active',
          'location': 'tracking',
          'analytics': 'running',
        },
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}

// API Response model
class ApiResponse<T> {
  final T? data;
  final String message;
  final int statusCode;
  final DateTime timestamp;
  final bool isError;

  ApiResponse({
    required this.data,
    required this.message,
    required this.statusCode,
    required this.timestamp,
    this.isError = false,
  });

  bool get isSuccess => !isError && statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> toJson() => {
    'data': data,
    'message': message,
    'statusCode': statusCode,
    'timestamp': timestamp.toIso8601String(),
    'isError': isError,
  };

  @override
  String toString() => 'ApiResponse(status: $statusCode, message: $message)';
}
