import 'dart:async';
import 'dart:math' as math;
import '../models/bus_model.dart';
import '../models/route_model.dart';
import '../models/user_model.dart';

// Demo database service that simulates Firebase with in-memory data
class DatabaseServiceDemo {
  static final DatabaseServiceDemo _instance = DatabaseServiceDemo._internal();
  factory DatabaseServiceDemo() => _instance;
  DatabaseServiceDemo._internal();

  // In-memory data store
  final Map<String, Map<String, dynamic>> _buses = {};
  final Map<String, Map<String, dynamic>> _routes = {};
  final Map<String, Map<String, dynamic>> _users = {};
  final List<Map<String, dynamic>> _feedback = [];
  
  // Stream controllers for real-time updates
  final Map<String, StreamController<Map<String, dynamic>>> _busStreamControllers = {};
  final StreamController<List<BusModel>> _allBusesStreamController = StreamController.broadcast();
  
  Timer? _dataUpdateTimer;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    
    print('🗄️ DatabaseServiceDemo initialized - No Firebase required!');
    
    // Initialize demo data
    _initializeDemoData();
    
    // Start data update simulation
    _startDataUpdates();
    
    _isInitialized = true;
  }

  void _initializeDemoData() {
    // Initialize demo buses
    _buses['bus_1'] = {
      'busNumber': 'DL01-1234',
      'routeId': 'route_1',
      'latitude': 28.6139,
      'longitude': 77.2090,
      'status': 'active',
      'passengerCount': 25,
      'driverId': 'driver_1',
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      'speed': 25.5,
      'heading': 45.0,
    };
    
    _buses['bus_2'] = {
      'busNumber': 'DL02-5678',
      'routeId': 'route_2',
      'latitude': 28.6562,
      'longitude': 77.2410,
      'status': 'active',
      'passengerCount': 35,
      'driverId': 'driver_2',
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      'speed': 30.0,
      'heading': 180.0,
    };
    
    _buses['bus_3'] = {
      'busNumber': 'DL03-9012',
      'routeId': 'route_1',
      'latitude': 28.6280,
      'longitude': 77.2185,
      'status': 'active',
      'passengerCount': 15,
      'driverId': 'driver_3',
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      'speed': 22.0,
      'heading': 270.0,
    };

    // Initialize demo routes
    _routes['route_1'] = {
      'routeName': 'Connaught Place - Pragati Maidan',
      'routeNumber': 'R1',
      'stops': [
        {
          'id': 'stop_1',
          'name': 'Connaught Place',
          'latitude': 28.6139,
          'longitude': 77.2090,
          'sequenceNumber': 1,
          'estimatedArrivalMinutes': 0,
          'isTerminal': true,
        },
        {
          'id': 'stop_2',
          'name': 'India Gate',
          'latitude': 28.6129,
          'longitude': 77.2295,
          'sequenceNumber': 2,
          'estimatedArrivalMinutes': 10,
        },
        {
          'id': 'stop_3',
          'name': 'Rajpath',
          'latitude': 28.6144,
          'longitude': 77.2190,
          'sequenceNumber': 3,
          'estimatedArrivalMinutes': 15,
        },
        {
          'id': 'stop_4',
          'name': 'Pragati Maidan',
          'latitude': 28.6280,
          'longitude': 77.2185,
          'sequenceNumber': 4,
          'estimatedArrivalMinutes': 25,
          'isTerminal': true,
        },
      ],
      'pathCoordinates': [
        {'lat': 28.6139, 'lng': 77.2090},
        {'lat': 28.6129, 'lng': 77.2295},
        {'lat': 28.6144, 'lng': 77.2190},
        {'lat': 28.6280, 'lng': 77.2185},
      ],
      'distance': 8.5,
      'estimatedDurationMinutes': 30,
      'startPoint': 'Connaught Place',
      'endPoint': 'Pragati Maidan',
      'isActive': true,
    };
    
    _routes['route_2'] = {
      'routeName': 'Red Fort - Delhi Gate',
      'routeNumber': 'R2',
      'stops': [
        {
          'id': 'stop_5',
          'name': 'Red Fort',
          'latitude': 28.6562,
          'longitude': 77.2410,
          'sequenceNumber': 1,
          'estimatedArrivalMinutes': 0,
          'isTerminal': true,
        },
        {
          'id': 'stop_6',
          'name': 'Chandni Chowk',
          'latitude': 28.6506,
          'longitude': 77.2344,
          'sequenceNumber': 2,
          'estimatedArrivalMinutes': 8,
        },
        {
          'id': 'stop_7',
          'name': 'Jama Masjid',
          'latitude': 28.6392,
          'longitude': 77.2400,
          'sequenceNumber': 3,
          'estimatedArrivalMinutes': 15,
        },
        {
          'id': 'stop_8',
          'name': 'Delhi Gate',
          'latitude': 28.6262,
          'longitude': 77.2428,
          'sequenceNumber': 4,
          'estimatedArrivalMinutes': 22,
          'isTerminal': true,
        },
      ],
      'pathCoordinates': [
        {'lat': 28.6562, 'lng': 77.2410},
        {'lat': 28.6506, 'lng': 77.2344},
        {'lat': 28.6392, 'lng': 77.2400},
        {'lat': 28.6262, 'lng': 77.2428},
      ],
      'distance': 6.8,
      'estimatedDurationMinutes': 25,
      'startPoint': 'Red Fort',
      'endPoint': 'Delhi Gate',
      'isActive': true,
    };

    // Initialize demo users
    _users['demo_user'] = {
      'name': 'Demo Passenger',
      'email': 'passenger@demo.com',
      'phoneNumber': '+91 9876543210',
      'userType': 'passenger',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'favoriteRoutes': ['route_1'],
      'notificationPreferences': {
        'busArrival': true,
        'delays': true,
        'crowding': true,
      },
    };
    
    _users['driver_1'] = {
      'name': 'Demo Driver 1',
      'email': 'driver1@demo.com',
      'phoneNumber': '+91 9876543211',
      'userType': 'driver',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'licenseNumber': 'DL-2021-001234',
      'busId': 'bus_1',
      'isOnDuty': true,
    };
  }

  void _startDataUpdates() {
    _dataUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateBusLocations();
      _broadcastAllBuses();
    });
  }

  void _updateBusLocations() {
    final random = math.Random();
    
    _buses.forEach((busId, busData) {
      if (busData['status'] == 'active') {
        // Simulate movement
        final latChange = (random.nextDouble() - 0.5) * 0.001;
        final lngChange = (random.nextDouble() - 0.5) * 0.001;
        
        busData['latitude'] = (busData['latitude'] as double) + latChange;
        busData['longitude'] = (busData['longitude'] as double) + lngChange;
        busData['lastUpdated'] = DateTime.now().millisecondsSinceEpoch;
        busData['speed'] = 20.0 + random.nextDouble() * 15.0;
        busData['heading'] = (busData['heading'] as double) + (random.nextDouble() - 0.5) * 10;
        
        // Vary passenger count
        final passengerChange = random.nextInt(5) - 2;
        busData['passengerCount'] = math.max(0, 
          math.min(50, (busData['passengerCount'] as int) + passengerChange));
        
        // Broadcast update to specific bus stream
        if (_busStreamControllers.containsKey(busId)) {
          _busStreamControllers[busId]!.add(Map<String, dynamic>.from(busData));
        }
      }
    });
  }

  void _broadcastAllBuses() {
    final allBuses = _buses.entries
        .where((entry) => entry.value['status'] == 'active')
        .map((entry) => BusModel.fromJson(entry.value, entry.key))
        .toList();
    
    _allBusesStreamController.add(allBuses);
  }

  // Bus location operations
  Future<void> updateBusLocation(String busId, double latitude, double longitude, {
    String? routeId,
    int? passengerCount,
    String? status,
  }) async {
    try {
      if (!_buses.containsKey(busId)) {
        _buses[busId] = {};
      }
      
      _buses[busId]!.addAll({
        'latitude': latitude,
        'longitude': longitude,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        if (routeId != null) 'routeId': routeId,
        if (passengerCount != null) 'passengerCount': passengerCount,
        if (status != null) 'status': status,
      });
      
      print('📍 Updated bus $busId location: ($latitude, $longitude)');
    } catch (e) {
      throw Exception('Failed to update bus location: $e');
    }
  }

  // Real-time bus location stream
  Stream<List<BusModel>> getBusesOnRoute(String routeId) {
    return _allBusesStreamController.stream
        .map((buses) => buses.where((bus) => bus.routeId == routeId).toList());
  }

  // Get all active buses
  Stream<List<BusModel>> getAllActiveBuses() {
    return _allBusesStreamController.stream;
  }

  // Get single bus stream
  Stream<BusModel> getBusStream(String busId) {
    if (!_busStreamControllers.containsKey(busId)) {
      _busStreamControllers[busId] = StreamController<Map<String, dynamic>>.broadcast();
    }
    
    return _busStreamControllers[busId]!.stream
        .map((data) => BusModel.fromJson(data, busId));
  }

  // Route operations
  Future<List<RouteModel>> getRoutes() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      
      return _routes.entries
          .map((entry) => RouteModel.fromJson(entry.value, entry.key))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch routes: $e');
    }
  }

  // User operations
  Future<void> saveUserData(UserModel user) async {
    try {
      _users[user.id] = user.toJson();
      print('💾 Saved user data for ${user.name}');
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  Future<UserModel?> getUserData(String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
      
      if (_users.containsKey(userId)) {
        return UserModel.fromJson(_users[userId]!, userId);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  // Feedback operations
  Future<void> submitFeedback({
    required String userId,
    required String busId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      _feedback.add({
        'userId': userId,
        'busId': busId,
        'type': type,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      print('📝 Feedback submitted: $type for bus $busId');
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  // Driver operations
  Future<void> startDriverSession(String driverId, String busId, String routeId) async {
    try {
      if (!_buses.containsKey(busId)) {
        _buses[busId] = {'busNumber': 'DL-NEW-${busId.substring(4)}'};
      }
      
      _buses[busId]!.addAll({
        'driverId': driverId,
        'routeId': routeId,
        'status': 'active',
        'sessionStarted': DateTime.now().millisecondsSinceEpoch,
      });
      
      print('🚌 Driver $driverId started session on bus $busId');
    } catch (e) {
      throw Exception('Failed to start driver session: $e');
    }
  }

  Future<void> endDriverSession(String busId) async {
    try {
      if (_buses.containsKey(busId)) {
        _buses[busId]!.addAll({
          'status': 'inactive',
          'sessionEnded': DateTime.now().millisecondsSinceEpoch,
        });
      }
      
      print('🛑 Ended session for bus $busId');
    } catch (e) {
      throw Exception('Failed to end driver session: $e');
    }
  }

  // Get demo statistics
  Map<String, dynamic> getDemoStatistics() {
    return {
      'totalBuses': _buses.length,
      'activeBuses': _buses.values.where((b) => b['status'] == 'active').length,
      'totalRoutes': _routes.length,
      'totalUsers': _users.length,
      'feedbackCount': _feedback.length,
    };
  }

  // Cleanup
  void dispose() {
    _dataUpdateTimer?.cancel();
    _allBusesStreamController.close();
    _busStreamControllers.forEach((_, controller) => controller.close());
    _busStreamControllers.clear();
  }
}
