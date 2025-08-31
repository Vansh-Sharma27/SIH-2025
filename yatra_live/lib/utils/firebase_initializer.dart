import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_options.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/real_time_service.dart';
import '../services/background_location_service.dart';

class FirebaseInitializer {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase Core initialized');

      // Configure Firebase Database for offline persistence
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000); // 10MB
      print('✅ Firebase Database configured with offline persistence');

      // Initialize all services
      await _initializeServices();

      // Set up sample data if database is empty
      await _setupSampleDataIfNeeded();

      _isInitialized = true;
      print('✅ Firebase initialization complete');

    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      throw FirebaseInitializationException('Failed to initialize Firebase: $e');
    }
  }

  static Future<void> _initializeServices() async {
    try {
      // Initialize database service
      DatabaseService().initialize();
      print('✅ Database service initialized');

      // Initialize location service
      await LocationService.initialize();
      print('✅ Location service initialized');

      // Initialize notification service
      await NotificationService.initialize();
      print('✅ Notification service initialized');

      // Initialize real-time service
      await RealTimeService().initialize();
      print('✅ Real-time service initialized');

      // Initialize background location service
      await BackgroundLocationService.initialize();
      print('✅ Background location service initialized');

    } catch (e) {
      print('❌ Service initialization failed: $e');
      throw ServiceInitializationException('Failed to initialize services: $e');
    }
  }

  static Future<void> _setupSampleDataIfNeeded() async {
    try {
      final database = FirebaseDatabase.instance;
      
      // Check if routes exist
      final routesSnapshot = await database.ref('routes').once();
      
      if (routesSnapshot.snapshot.value == null) {
        print('📊 Setting up sample data...');
        await _uploadSampleData();
        print('✅ Sample data uploaded successfully');
      } else {
        print('✅ Database already contains data');
      }
    } catch (e) {
      print('⚠️ Failed to setup sample data: $e');
      // Not critical for app functionality
    }
  }

  static Future<void> _uploadSampleData() async {
    final database = FirebaseDatabase.instance;

    // Sample routes data
    final routesData = {
      'route_001': {
        'routeName': 'City Center to Airport',
        'routeNumber': 'A1',
        'startPoint': 'City Center Bus Stand',
        'endPoint': 'Airport Terminal 1',
        'distance': 25.5,
        'estimatedDurationMinutes': 45,
        'isActive': true,
        'pathCoordinates': [
          {'lat': 28.6139, 'lng': 77.2090},
          {'lat': 28.6200, 'lng': 77.2100},
          {'lat': 28.6250, 'lng': 77.2150},
          {'lat': 28.6300, 'lng': 77.2200},
          {'lat': 28.5562, 'lng': 77.1000}
        ],
        'stops': {
          'stop_001': {
            'id': 'stop_001',
            'name': 'City Center Bus Stand',
            'latitude': 28.6139,
            'longitude': 77.2090,
            'sequenceNumber': 1,
            'estimatedArrivalMinutes': 0,
            'isTerminal': true
          },
          'stop_002': {
            'id': 'stop_002',
            'name': 'Central Park',
            'latitude': 28.6200,
            'longitude': 77.2100,
            'sequenceNumber': 2,
            'estimatedArrivalMinutes': 8,
            'isTerminal': false
          },
          'stop_003': {
            'id': 'stop_003',
            'name': 'Shopping Mall',
            'latitude': 28.6250,
            'longitude': 77.2150,
            'sequenceNumber': 3,
            'estimatedArrivalMinutes': 15,
            'isTerminal': false
          },
          'stop_004': {
            'id': 'stop_004',
            'name': 'IT Park',
            'latitude': 28.6300,
            'longitude': 77.2200,
            'sequenceNumber': 4,
            'estimatedArrivalMinutes': 25,
            'isTerminal': false
          },
          'stop_005': {
            'id': 'stop_005',
            'name': 'Airport Terminal 1',
            'latitude': 28.5562,
            'longitude': 77.1000,
            'sequenceNumber': 5,
            'estimatedArrivalMinutes': 45,
            'isTerminal': true
          }
        }
      },
      'route_002': {
        'routeName': 'University to Railway Station',
        'routeNumber': 'B2',
        'startPoint': 'University Main Gate',
        'endPoint': 'Railway Station',
        'distance': 18.2,
        'estimatedDurationMinutes': 35,
        'isActive': true,
        'pathCoordinates': [
          {'lat': 28.7041, 'lng': 77.1025},
          {'lat': 28.7000, 'lng': 77.1100},
          {'lat': 28.6950, 'lng': 77.1200},
          {'lat': 28.6900, 'lng': 77.1300},
          {'lat': 28.6414, 'lng': 77.2186}
        ],
        'stops': {
          'stop_006': {
            'id': 'stop_006',
            'name': 'University Main Gate',
            'latitude': 28.7041,
            'longitude': 77.1025,
            'sequenceNumber': 1,
            'estimatedArrivalMinutes': 0,
            'isTerminal': true
          },
          'stop_007': {
            'id': 'stop_007',
            'name': 'Hostel Complex',
            'latitude': 28.7000,
            'longitude': 77.1100,
            'sequenceNumber': 2,
            'estimatedArrivalMinutes': 5,
            'isTerminal': false
          },
          'stop_008': {
            'id': 'stop_008',
            'name': 'Medical College',
            'latitude': 28.6950,
            'longitude': 77.1200,
            'sequenceNumber': 3,
            'estimatedArrivalMinutes': 12,
            'isTerminal': false
          },
          'stop_009': {
            'id': 'stop_009',
            'name': 'Civil Lines',
            'latitude': 28.6900,
            'longitude': 77.1300,
            'sequenceNumber': 4,
            'estimatedArrivalMinutes': 20,
            'isTerminal': false
          },
          'stop_010': {
            'id': 'stop_010',
            'name': 'Railway Station',
            'latitude': 28.6414,
            'longitude': 77.2186,
            'sequenceNumber': 5,
            'estimatedArrivalMinutes': 35,
            'isTerminal': true
          }
        }
      }
    };

    // Sample buses data
    final busesData = {
      'bus_001': {
        'busNumber': 'DL-1PC-0101',
        'routeId': 'route_001',
        'latitude': 28.6139,
        'longitude': 77.2090,
        'status': 'active',
        'driverId': 'driver_001',
        'passengerCount': 25,
        'speed': 35.5,
        'heading': 45.2,
        'lastUpdated': ServerValue.timestamp,
        'sessionStarted': ServerValue.timestamp
      },
      'bus_002': {
        'busNumber': 'DL-1PC-0102',
        'routeId': 'route_001',
        'latitude': 28.6250,
        'longitude': 77.2150,
        'status': 'active',
        'driverId': 'driver_002',
        'passengerCount': 40,
        'speed': 28.0,
        'heading': 90.0,
        'lastUpdated': ServerValue.timestamp,
        'sessionStarted': ServerValue.timestamp
      },
      'bus_003': {
        'busNumber': 'DL-1PC-0201',
        'routeId': 'route_002',
        'latitude': 28.7000,
        'longitude': 77.1100,
        'status': 'active',
        'driverId': 'driver_003',
        'passengerCount': 18,
        'speed': 42.0,
        'heading': 180.0,
        'lastUpdated': ServerValue.timestamp,
        'sessionStarted': ServerValue.timestamp
      }
    };

    // Upload routes
    await database.ref('routes').set(routesData);
    
    // Upload buses
    await database.ref('buses').set(busesData);

    print('📊 Sample data uploaded to Firebase');
  }

  // Health check method
  static Future<bool> performHealthCheck() async {
    try {
      final database = FirebaseDatabase.instance;
      
      // Test database connection
      final testRef = database.ref('.info/connected');
      final snapshot = await testRef.once();
      final isConnected = snapshot.snapshot.value as bool? ?? false;
      
      if (!isConnected) {
        print('⚠️ Database connection failed');
        return false;
      }

      // Test data read
      final routesSnapshot = await database.ref('routes').limitToFirst(1).once();
      if (routesSnapshot.snapshot.value == null) {
        print('⚠️ No routes data found');
        return false;
      }

      print('✅ Firebase health check passed');
      return true;
    } catch (e) {
      print('❌ Firebase health check failed: $e');
      return false;
    }
  }

  // Cleanup method for testing
  static Future<void> clearTestData() async {
    try {
      final database = FirebaseDatabase.instance;
      
      // Only clear test data, not production data
      await database.ref('test').remove();
      print('🧹 Test data cleared');
    } catch (e) {
      print('❌ Failed to clear test data: $e');
    }
  }

  static bool get isInitialized => _isInitialized;
}

// Custom exceptions
class FirebaseInitializationException implements Exception {
  final String message;
  FirebaseInitializationException(this.message);
  
  @override
  String toString() => 'FirebaseInitializationException: $message';
}

class ServiceInitializationException implements Exception {
  final String message;
  ServiceInitializationException(this.message);
  
  @override
  String toString() => 'ServiceInitializationException: $message';
}
