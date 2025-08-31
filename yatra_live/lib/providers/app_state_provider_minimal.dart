import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/database_service_demo.dart';
import '../services/location_service_demo.dart';
import '../services/notification_service_demo.dart';
import '../services/api_service_demo.dart';
import '../models/bus_model.dart';
import '../models/route_model.dart';

class AppStateProviderMinimal extends ChangeNotifier {
  // Services
  final DatabaseServiceDemo _databaseService = DatabaseServiceDemo();
  final LocationServiceDemo _locationService = LocationServiceDemo();
  final NotificationServiceDemo _notificationService = NotificationServiceDemo();
  final ApiServiceDemo _apiService = ApiServiceDemo();
  
  // State variables
  bool _isLoading = false;
  String? _selectedUserType;
  bool _isDriverOnDuty = false;
  String? _driverBusId;
  String? _driverRouteId;
  List<Map<String, dynamic>> _recentFeedback = [];
  Map<String, List<Map<String, dynamic>>> _busFeedback = {};
  
  // Additional state for compatibility
  RouteModel? _selectedRoute;
  BusModel? _trackedBus;
  List<String> _favoriteRoutes = [];
  Map<String, dynamic> _notificationSettings = {
    'busArrival': true,
    'delays': true,
    'crowding': true,
  };
  dynamic _currentUser;
  
  // Real-time data from demo services
  List<BusModel> _activeBuses = [];
  List<RouteModel> _routes = [];
  StreamSubscription? _busSubscription;
  StreamSubscription? _routeSubscription;
  
  // Constructor - initialize services
  AppStateProviderMinimal() {
    _initializeServices();
  }
  
  // Getters
  bool get isLoading => _isLoading;
  String? get selectedUserType => _selectedUserType;
  bool get isDriverOnDuty => _isDriverOnDuty;
  String? get driverBusId => _driverBusId;
  String? get driverRouteId => _driverRouteId;
  List<Map<String, dynamic>> get recentFeedback => _recentFeedback;
  Map<String, List<Map<String, dynamic>>> get busFeedback => _busFeedback;
  
  // Real-time data getters
  List<BusModel> get activeBuses => _activeBuses;
  List<RouteModel> get routes => _routes;
  
  // Initialize demo services
  Future<void> _initializeServices() async {
    try {
      // Load routes
      _routes = await _databaseService.getRoutes();
      notifyListeners();
      
      // Subscribe to active buses stream
      _busSubscription = _databaseService.getAllActiveBuses().listen((buses) {
        _activeBuses = buses;
        notifyListeners();
      });
      
      // Set up notification listener
      _notificationService.onNotificationReceived = (notification) {
        print('📱 Notification received: ${notification.title}');
      };
    } catch (e) {
      print('Error initializing services: $e');
    }
  }
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setUserType(String userType) {
    _selectedUserType = userType;
    notifyListeners();
  }
  
  void setDriverDuty(bool onDuty) {
    _isDriverOnDuty = onDuty;
    notifyListeners();
  }
  
  // Mock data for demonstration
  List<Map<String, dynamic>> get mockBuses => [
    {
      'id': 'BUS001',
      'number': '15A',
      'route': 'City Center ↔ Airport',
      'eta': '5 min',
      'crowding': 'Low',
      'location': 'Main Street',
      'speed': '25 km/h',
      'passengers': '12/40',
    },
    {
      'id': 'BUS002', 
      'number': '42B',
      'route': 'University ↔ Mall',
      'eta': '8 min',
      'crowding': 'Medium',
      'location': 'Campus Road',
      'speed': '18 km/h',
      'passengers': '28/40',
    },
    {
      'id': 'BUS003',
      'number': '7C', 
      'route': 'Hospital ↔ Station',
      'eta': '12 min',
      'crowding': 'High',
      'location': 'Central Avenue', 
      'speed': '15 km/h',
      'passengers': '36/40',
    },
  ];
  
  List<Map<String, dynamic>> get mockRoutes => [
    {
      'id': 'ROUTE001',
      'name': 'City Center Express',
      'number': '15A',
      'stops': 8,
      'distance': '12.5 km',
      'duration': '35 min',
      'frequency': '5-7 min',
      'fare': '₹15',
      'isActive': true,
    },
    {
      'id': 'ROUTE002',
      'name': 'University Shuttle',
      'number': '42B', 
      'stops': 6,
      'distance': '8.2 km',
      'duration': '25 min',
      'frequency': '8-10 min',
      'fare': '₹12',
      'isActive': true,
    },
    {
      'id': 'ROUTE003',
      'name': 'Hospital Connect',
      'number': '7C',
      'stops': 10,
      'distance': '15.8 km', 
      'duration': '45 min',
      'frequency': '10-12 min',
      'fare': '₹20',
      'isActive': true,
    },
  ];
  
  void toggleDuty() {
    _isDriverOnDuty = !_isDriverOnDuty;
    notifyListeners();
  }
  
  // Feedback methods
  void addFeedback(Map<String, dynamic> feedback) {
    _recentFeedback.insert(0, feedback);
    
    // Store feedback by bus number
    String busNumber = feedback['busNumber'] ?? 'Unknown';
    if (!_busFeedback.containsKey(busNumber)) {
      _busFeedback[busNumber] = [];
    }
    _busFeedback[busNumber]!.insert(0, feedback);
    
    // Keep only last 50 feedback items
    if (_recentFeedback.length > 50) {
      _recentFeedback.removeLast();
    }
    
    // Keep only last 20 feedback items per bus
    if (_busFeedback[busNumber]!.length > 20) {
      _busFeedback[busNumber]!.removeLast();
    }
    
    notifyListeners();
  }
  
  List<Map<String, dynamic>> getFeedbackForBus(String busNumber) {
    return _busFeedback[busNumber] ?? [];
  }
  
  double getAverageRatingForBus(String busNumber) {
    final feedback = getFeedbackForBus(busNumber);
    if (feedback.isEmpty) return 0.0;
    
    final ratingsWithValues = feedback.where((f) => f['rating'] != null && f['rating'] > 0);
    if (ratingsWithValues.isEmpty) return 0.0;
    
    final totalRating = ratingsWithValues.fold<int>(0, (sum, f) => sum + (f['rating'] as int));
    return totalRating / ratingsWithValues.length;
  }
  
  String getMostRecentCrowdingLevel(String busNumber) {
    final feedback = getFeedbackForBus(busNumber);
    final crowdingFeedback = feedback.where((f) => f['crowdingLevel'] != null);
    if (crowdingFeedback.isEmpty) return 'Unknown';
    return crowdingFeedback.first['crowdingLevel'] as String;
  }
  
  bool hasBusReportedDelays(String busNumber) {
    final feedback = getFeedbackForBus(busNumber);
    return feedback.any((f) => f['isDelayed'] == true);
  }
  
  int getBoardingCount(String busNumber) {
    final feedback = getFeedbackForBus(busNumber);
    return feedback.where((f) => f['isOnBoard'] == true).length;
  }
  
  // Driver functionality with demo services
  Future<void> startDriverDuty(String busId, String routeId) async {
    try {
      await _locationService.startTracking(
        busId: busId,
        routeId: routeId,
        onLocationUpdate: (position) {
          // Update bus location in database
          _databaseService.updateBusLocation(
            busId,
            position.latitude,
            position.longitude,
            routeId: routeId,
            status: 'active',
          );
        },
      );
      
      await _databaseService.startDriverSession('demo_driver', busId, routeId);
      _driverBusId = busId;
      _driverRouteId = routeId;
      setDriverDuty(true);
    } catch (e) {
      print('Error starting driver duty: $e');
    }
  }
  
  Future<void> stopDriverDuty() async {
    try {
      if (_driverBusId != null) {
        await _locationService.stopTracking(_driverBusId!);
        await _databaseService.endDriverSession(_driverBusId!);
      }
      _driverBusId = null;
      _driverRouteId = null;
      setDriverDuty(false);
    } catch (e) {
      print('Error stopping driver duty: $e');
    }
  }
  
  // Submit feedback to demo database
  Future<void> submitFeedbackToDatabase(Map<String, dynamic> feedback) async {
    try {
      await _databaseService.submitFeedback(
        userId: 'demo_user',
        busId: feedback['busId'] ?? 'unknown',
        type: feedback['type'] ?? 'general',
        data: feedback,
      );
      
      // Also add to local feedback
      addFeedback(feedback);
    } catch (e) {
      print('Error submitting feedback: $e');
    }
  }
  
  // Additional methods for compatibility
  RouteModel? get selectedRoute => _selectedRoute;
  BusModel? get trackedBus => _trackedBus;
  List<String> get favoriteRoutes => _favoriteRoutes;
  Map<String, dynamic> get notificationSettings => _notificationSettings;
  dynamic get currentUser => _currentUser;
  bool get isAuthenticated => _selectedUserType != null;
  
  void selectRoute(RouteModel route) {
    _selectedRoute = route;
    notifyListeners();
  }
  
  void trackBus(BusModel bus) {
    _trackedBus = bus;
    notifyListeners();
  }
  
  void stopTrackingBus() {
    _trackedBus = null;
    notifyListeners();
  }
  
  bool isRouteFavorite(String routeId) {
    return _favoriteRoutes.contains(routeId);
  }
  
  Future<void> addToFavorites(String routeId) async {
    if (!_favoriteRoutes.contains(routeId)) {
      _favoriteRoutes.add(routeId);
      notifyListeners();
    }
  }
  
  Future<void> removeFromFavorites(String routeId) async {
    _favoriteRoutes.remove(routeId);
    notifyListeners();
  }
  
  List<BusModel> getBusesForRoute(String routeId) {
    return _activeBuses.where((bus) => bus.routeId == routeId).toList();
  }
  
  void updateNotificationSettings(Map<String, dynamic> updates) {
    _notificationSettings.addAll(updates);
    notifyListeners();
  }
  
  Future<void> signOut() async {
    _selectedUserType = null;
    _currentUser = null;
    _isDriverOnDuty = false;
    _driverBusId = null;
    _driverRouteId = null;
    _selectedRoute = null;
    _trackedBus = null;
    _favoriteRoutes.clear();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _busSubscription?.cancel();
    _routeSubscription?.cancel();
    super.dispose();
  }
}
