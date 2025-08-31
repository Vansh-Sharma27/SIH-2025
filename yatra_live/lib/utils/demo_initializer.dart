import '../services/location_service_demo.dart';
import '../services/notification_service_demo.dart';
import '../services/database_service_demo.dart';
import '../services/api_service_demo.dart';

/// Demo initializer for YatraLive hackathon presentation
/// This initializer sets up all demo services without requiring Firebase or external APIs
class DemoInitializer {
  static bool _isInitialized = false;

  /// Initialize all demo services
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('✅ Demo services already initialized');
      return;
    }

    print('🚀 Initializing YatraLive Demo Services...');
    print('📍 Smart India Hackathon 2025 - Zero Setup Demo Mode');
    print('');

    try {
      // Initialize location service demo
      await LocationServiceDemo.initialize();
      print('✅ Location Service Demo - Ready');
      print('   • GPS simulation active');
      print('   • No permissions required');
      print('   • 2 demo routes configured');

      // Initialize notification service demo
      await NotificationServiceDemo.initialize();
      print('✅ Notification Service Demo - Ready');
      print('   • Push notifications simulated');
      print('   • Auto-generated demo notifications');
      print('   • Topic subscriptions working');

      // Initialize database service demo
      DatabaseServiceDemo().initialize();
      print('✅ Database Service Demo - Ready');
      print('   • In-memory data store active');
      print('   • Real-time updates simulated');
      print('   • 3 active buses, 2 routes loaded');

      // Initialize API service demo
      // ApiServiceDemo is stateless, just log initialization
      print('✅ API Service Demo - Ready');
      print('   • RESTful endpoints simulated');
      print('   • Mock data generation active');
      print('   • Response formatting enabled');

      print('');
      print('🎯 Demo Statistics:');
      final stats = DatabaseServiceDemo().getDemoStatistics();
      print('   • Active Buses: ${stats['activeBuses']}');
      print('   • Total Routes: ${stats['totalRoutes']}');
      print('   • Registered Users: ${stats['totalUsers']}');
      
      print('');
      print('🎉 YatraLive Demo Ready for Hackathon Presentation!');
      print('🌐 Using OpenStreetMap - No API keys required');
      print('⚡ Real-time features working with simulated data');
      print('🏆 Good luck at Smart India Hackathon 2025!');
      
      _isInitialized = true;
    } catch (e) {
      print('❌ Error initializing demo services: $e');
      rethrow;
    }
  }

  /// Check if demo services are initialized
  static bool get isInitialized => _isInitialized;

  /// Perform health check on all demo services
  static Future<Map<String, bool>> performHealthCheck() async {
    final healthStatus = <String, bool>{};

    try {
      // Check location service
      final locationService = LocationServiceDemo();
      healthStatus['location'] = await locationService.isLocationServiceEnabled();

      // Check notification service
      final notificationService = NotificationServiceDemo();
      healthStatus['notifications'] = await notificationService.isNotificationEnabled();

      // Check database service
      final dbService = DatabaseServiceDemo();
      final stats = dbService.getDemoStatistics();
      healthStatus['database'] = stats['activeBuses'] > 0;

      // Check API service
      final apiService = ApiServiceDemo();
      final apiHealth = await apiService.healthCheck();
      healthStatus['api'] = apiHealth.isSuccess;

      // Overall health
      healthStatus['overall'] = healthStatus.values.every((status) => status);

      return healthStatus;
    } catch (e) {
      print('❌ Health check failed: $e');
      return {
        'location': false,
        'notifications': false,
        'database': false,
        'api': false,
        'overall': false,
      };
    }
  }

  /// Get demo configuration details
  static Map<String, dynamic> getDemoConfiguration() {
    return {
      'mode': 'hackathon_demo',
      'mapProvider': 'OpenStreetMap',
      'dataSource': 'In-memory simulation',
      'updateFrequency': '3 seconds',
      'notificationInterval': '30 seconds',
      'features': {
        'realTimeTracking': true,
        'pushNotifications': true,
        'offlineMode': true,
        'twoWayFeedback': true,
        'routeOptimization': true,
      },
      'limitations': {
        'requiresInternet': false,
        'requiresApiKeys': false,
        'requiresFirebase': false,
        'requiresPermissions': false,
      },
    };
  }

  /// Reset demo data to initial state
  static Future<void> resetDemoData() async {
    print('🔄 Resetting demo data...');
    
    // Re-initialize all services
    _isInitialized = false;
    await initialize();
    
    print('✅ Demo data reset complete');
  }

  /// Cleanup demo services
  static void cleanup() {
    if (!_isInitialized) return;

    print('🧹 Cleaning up demo services...');
    
    // Cleanup database service
    DatabaseServiceDemo().dispose();
    
    // Cleanup notification service
    NotificationServiceDemo().dispose();
    
    // Note: Location service cleanup is handled internally
    
    _isInitialized = false;
    print('✅ Demo services cleaned up');
  }
}
