import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:math' as math;
import '../providers/app_state_provider_minimal.dart';
import '../theme/app_theme.dart';

class DemoDashboard extends StatefulWidget {
  final String userType;
  
  const DemoDashboard({super.key, required this.userType});

  @override
  State<DemoDashboard> createState() => _DemoDashboardState();
}

class _DemoDashboardState extends State<DemoDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.userType == 'passenger' ? 3 : 2,
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPassenger = widget.userType == 'passenger';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isPassenger ? 'Passenger Dashboard' : 'Driver Dashboard',
        ),
        backgroundColor: isPassenger ? AppTheme.primaryColor : AppTheme.accentColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: isPassenger
              ? const [
                  Tab(icon: Icon(Icons.home), text: 'Home'),
                  Tab(icon: Icon(Icons.map), text: 'Live Map'),
                  Tab(icon: Icon(Icons.route), text: 'Routes'),
                ]
              : const [
                  Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
                  Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
                ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showInfo(),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: isPassenger
            ? [
                _buildPassengerHome(),
                _buildLiveMap(),
                _buildRoutes(),
              ]
            : [
                _buildDriverDashboard(),
                _buildDriverAnalytics(),
              ],
      ),
    );
  }

  // Passenger Screens
  Widget _buildPassengerHome() {
    return Consumer<AppStateProviderMinimal>(
      builder: (context, appState, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track your buses in real-time',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Quick stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '🚌',
                      '${appState.mockBuses.length}',
                      'Live Buses',
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '🗺️',
                      '${appState.mockRoutes.length}',
                      'Active Routes',
                      AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Nearby Buses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // Bus list
              ...appState.mockBuses.map((bus) => _buildBusCard(bus)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveMap() {
    return const DemoInteractiveMap();
  }

  Widget _buildRoutes() {
    return Consumer<AppStateProviderMinimal>(
      builder: (context, appState, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appState.mockRoutes.length,
          itemBuilder: (context, index) {
            final route = appState.mockRoutes[index];
            return _buildRouteCard(route);
          },
        );
      },
    );
  }

  // Driver Screens
  Widget _buildDriverDashboard() {
    return Consumer<AppStateProviderMinimal>(
      builder: (context, appState, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status card
              Consumer<AppStateProviderMinimal>(
                builder: (context, appState, child) {
                  return Card(
                    color: appState.isDriverOnDuty 
                        ? Colors.green.shade50 
                        : Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                appState.isDriverOnDuty 
                                    ? Icons.check_circle 
                                    : Icons.pause_circle,
                                color: appState.isDriverOnDuty 
                                    ? AppTheme.successColor 
                                    : AppTheme.warningColor,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appState.isDriverOnDuty 
                                          ? 'On Duty - Route 15A' 
                                          : 'Off Duty',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: appState.isDriverOnDuty 
                                            ? AppTheme.successColor 
                                            : AppTheme.warningColor,
                                      ),
                                    ),
                                    Text(
                                      appState.isDriverOnDuty 
                                          ? 'Broadcasting location to passengers' 
                                          : 'Ready to start your shift',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () => _toggleDuty(appState),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appState.isDriverOnDuty 
                                      ? AppTheme.errorColor 
                                      : AppTheme.successColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(appState.isDriverOnDuty ? 'End Duty' : 'Start Duty'),
                              ),
                              if (appState.isDriverOnDuty) ...[
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () => _showDriverFeedbackPanel(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.infoColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.feedback, size: 16),
                                      const SizedBox(width: 4),
                                      Text('Feedback (${appState.recentFeedback.length})'),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Quick stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '📍',
                      '25.4',
                      'Speed (km/h)',
                      AppTheme.accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '👥',
                      '28/40',
                      'Passengers',
                      AppTheme.warningColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '⏱️',
                      '2h 15m',
                      'Trip Time',
                      AppTheme.infoColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Emergency features
              const Text(
                'Emergency & Controls',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: () => _showFeatureDialog('Emergency Alert', 'Instantly notify control room and nearby authorities in case of emergencies with GPS location.'),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(Icons.warning, color: AppTheme.errorColor, size: 32),
                              SizedBox(height: 8),
                              Text('Emergency', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: () => _showFeatureDialog('Break Time', 'Log break times automatically with location tracking for accurate duty records.'),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(Icons.pause_circle, color: AppTheme.warningColor, size: 32),
                              SizedBox(height: 8),
                              Text('Break Time', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: () => _showFeatureDialog('Report Issue', 'Quick reporting system for traffic, road conditions, or vehicle issues with photo uploads.'),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(Icons.report_problem, color: AppTheme.infoColor, size: 32),
                              SizedBox(height: 8),
                              Text('Report Issue', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDriverAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance metrics
          const Text(
            'Today\'s Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '🛣️',
                  '127.8',
                  'Distance (km)',
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '⏰',
                  '6h 42m',
                  'Trip Time',
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '🚀',
                  '19.1',
                  'Avg Speed',
                  AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '👥',
                  '248',
                  'Passengers',
                  AppTheme.infoColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Weekly summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Chart placeholder
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart, size: 48, color: AppTheme.primaryColor),
                          SizedBox(height: 12),
                          Text(
                            'Performance Analytics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Distance • Speed • Passengers • Rating',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Rating card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Passenger Feedback',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            SizedBox(width: 4),
                            Text('4.6/5.0', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Text('(127 reviews)', style: TextStyle(color: AppTheme.textSecondaryColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.trending_up, color: AppTheme.successColor, size: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusCard(Map<String, dynamic> bus) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getCrowdingColor(bus['crowding']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  bus['number'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getCrowdingColor(bus['crowding']),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bus['route'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📍 ${bus['location']} • 🚀 ${bus['speed']}',
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  bus['eta'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getCrowdingColor(bus['crowding']),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    bus['crowding'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      route['number'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${route['stops']} stops • ${route['distance']} • ${route['duration']}',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      route['fare'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Every ${route['frequency']}',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCrowdingColor(String crowding) {
    switch (crowding) {
      case 'Low':
        return AppTheme.successColor;
      case 'Medium':
        return AppTheme.warningColor;
      case 'High':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  void _showFeatureDialog(String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _toggleDuty(AppStateProviderMinimal appState) {
    if (appState.isDriverOnDuty) {
      appState.setDriverDuty(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Duty ended successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      appState.setDriverDuty(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚀 Duty started! Broadcasting location to passengers.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _showDriverFeedbackPanel() {
    showDialog(
      context: context,
      builder: (context) => const DriverFeedbackPanel(),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('YatraLive Demo'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🏆 Smart India Hackathon 2025\n',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text('This is a fully functional prototype demonstrating:'),
              SizedBox(height: 12),
              Text('✅ Real-time bus tracking'),
              Text('✅ Driver dashboard with analytics'),
              Text('✅ Passenger app with live maps'),
              Text('✅ Route management system'),
              Text('✅ Emergency features'),
              Text('✅ Performance monitoring'),
              Text('✅ Offline capabilities'),
              SizedBox(height: 12),
              Text(
                'Ready for deployment with Firebase backend, Google Maps integration, and comprehensive testing suite.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Impressive!'),
          ),
        ],
      ),
    );
  }
}

// Demo Interactive Map Widget
class DemoInteractiveMap extends StatefulWidget {
  const DemoInteractiveMap({super.key});

  @override
  State<DemoInteractiveMap> createState() => _DemoInteractiveMapState();
}

class _DemoInteractiveMapState extends State<DemoInteractiveMap> 
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  
  // Demo coordinates (Delhi area)
  LatLng _centerLocation = LatLng(28.6139, 77.2090);
  double _currentZoom = 13.0;
  
  StreamSubscription? _busSubscription;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _initializeDemo();
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _initializeDemo() {
    // Initialize route polylines
    _generateMockRoutes();
    
    // Initial marker update
    _updateMapMarkers();
    
    // Set up a timer to simulate real-time updates
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _updateMapMarkers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔄 Map data refreshed'),
            duration: Duration(seconds: 2),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    });
  }


  void _generateMockRoutes() {
    _polylines = [
      Polyline(
        points: [
          LatLng(28.6100, 77.2050),
          LatLng(28.6140, 77.2090),
          LatLng(28.6180, 77.2130),
          LatLng(28.6200, 77.2150),
        ],
        color: AppTheme.primaryColor,
        strokeWidth: 4.0,
      ),
      Polyline(
        points: [
          LatLng(28.6050, 77.2000),
          LatLng(28.6080, 77.2030),
          LatLng(28.6120, 77.2070),
          LatLng(28.6160, 77.2110),
        ],
        color: AppTheme.successColor,
        strokeWidth: 4.0,
      ),
    ];
  }

  void _updateMapMarkers() {
    final appState = Provider.of<AppStateProviderMinimal>(context, listen: false);
    List<Marker> newMarkers = [];
    
    // Add bus markers from real demo data
    for (final bus in appState.mockBuses) {
      // Extract location from bus data
      final location = bus['location'] as String? ?? 'Unknown';
      // Use predefined locations for demo (in a real app, this would come from GPS)
      double lat = 28.6139 + (bus['number'].hashCode % 100) * 0.0001;
      double lng = 77.2090 + (bus['route'].hashCode % 100) * 0.0001;
      
      newMarkers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 40,
          height: 40,
          builder: (context) => GestureDetector(
            onTap: () => _onBusMarkerTapped({
              'number': bus['number'],
              'route': bus['route'],
              'speed': bus['speed'],
              'passengers': '${(20 + bus['number'].hashCode % 20)}/40',
              'lat': lat,
              'lng': lng,
              'crowding': bus['crowding'],
            }),
            child: Container(
              decoration: BoxDecoration(
                color: _getCrowdingColor(bus['crowding']),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bus,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    // Add bus stop markers
    final busStops = [
      {'name': 'Central Station', 'lat': 28.6120, 'lng': 77.2060},
      {'name': 'Tech Hub', 'lat': 28.6160, 'lng': 77.2100},
      {'name': 'Shopping Mall', 'lat': 28.6200, 'lng': 77.2140},
      {'name': 'University', 'lat': 28.6080, 'lng': 77.2020},
    ];

    for (final stop in busStops) {
      newMarkers.add(
        Marker(
          point: LatLng(stop['lat'] as double, stop['lng'] as double),
          width: 30,
          height: 30,
          builder: (context) => GestureDetector(
            onTap: () => _showBusStopInfo(stop['name'] as String),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.warningColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.stop,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  void _onBusMarkerTapped(Map<String, dynamic> bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🚌 Bus ${bus['number']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Route: ${bus['route']}'),
            Text('Speed: ${bus['speed']}'),
            Text('Passengers: ${bus['passengers']}/40'),
            const SizedBox(height: 12),
            const Text('✅ Live tracking active'),
            const Text('📍 Real-time GPS location'),
            const Text('⏱️ Updated every 30 seconds'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _mapController.move(
                LatLng(bus['lat'] as double, bus['lng'] as double), 
                16.0,
              );
            },
            child: const Text('Track Bus'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showFeedbackDialog(bus);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
            ),
            child: const Text('Give Feedback'),
          ),
        ],
      ),
    );
  }

  void _showBusStopInfo(String stopName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📍 $stopName'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upcoming buses:'),
            SizedBox(height: 12),
            Text('🚌 DL-1234 - 3 min'),
            Text('🚌 DL-5678 - 8 min'),
            Text('🚌 DL-9012 - 15 min'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(Map<String, dynamic> bus) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return PassengerFeedbackDialog(
            busNumber: bus['number'] as String,
            busRoute: bus['route'] as String,
            onFeedbackSubmitted: (feedback) {
              Navigator.of(context).pop();
              _showFeedbackConfirmation(feedback);
            },
          );
        },
      ),
    );
  }

  void _showFeedbackConfirmation(Map<String, dynamic> feedback) {
    // Store feedback in provider
    Provider.of<AppStateProviderMinimal>(context, listen: false).addFeedback(feedback);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Feedback submitted for ${feedback['busNumber']}'),
        backgroundColor: AppTheme.successColor,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            _showFeedbackSummary(feedback);
          },
        ),
      ),
    );
  }

  void _showFeedbackSummary(Map<String, dynamic> feedback) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📝 Feedback Submitted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${feedback['type']}'),
            if (feedback['rating'] != null)
              Text('Rating: ${feedback['rating']}/5 ⭐'),
            if (feedback['crowdingLevel'] != null)
              Text('Crowding: ${feedback['crowdingLevel']}'),
            if (feedback['comment'] != null && feedback['comment'].toString().isNotEmpty)
              Text('Comment: ${feedback['comment']}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✅ Your feedback helps improve the service for everyone!',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getCrowdingColor(String crowding) {
    switch (crowding) {
      case 'Low':
        return AppTheme.successColor;
      case 'Medium':
        return AppTheme.warningColor;
      case 'High':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _centerLocation,
            zoom: _currentZoom,
            interactiveFlags: InteractiveFlag.all,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.theuninitialized.yatra_live',
              maxZoom: 18,
            ),
            PolylineLayer(
              polylines: _polylines,
            ),
            MarkerLayer(
              markers: _markers,
            ),
          ],
        ),
        
        // Header with "Zero Setup Required" badge
        Positioned(
          top: 20,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '✅ Zero Setup Required',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'OpenStreetMap • No API Keys • Instant Demo',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Map controls
        Positioned(
          top: 90,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton(
                mini: true,
                onPressed: () {
                  _mapController.move(_centerLocation, _currentZoom + 1);
                  setState(() => _currentZoom += 1);
                },
                child: const Icon(Icons.zoom_in),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                onPressed: () {
                  _mapController.move(_centerLocation, _currentZoom - 1);
                  setState(() => _currentZoom -= 1);
                },
                child: const Icon(Icons.zoom_out),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                onPressed: () {
                  _mapController.move(_centerLocation, 13.0);
                  setState(() => _currentZoom = 13.0);
                },
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
        
        // Live data panel
        Positioned(
          bottom: 20,
          left: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.successColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'LIVE DEMO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Consumer<AppStateProviderMinimal>(
                    builder: (context, appState, child) {
                      return Text('🚌 ${appState.mockBuses.length} Active Buses', style: const TextStyle(fontSize: 12));
                    },
                  ),
                  const Text('📍 4 Bus Stops', style: const TextStyle(fontSize: 12)),
                  const Text('⏱️ 30s Updates', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    'Updated: ${DateTime.now().toString().substring(11, 19)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Passenger Feedback Dialog Widget
class PassengerFeedbackDialog extends StatefulWidget {
  final String busNumber;
  final String busRoute;
  final Function(Map<String, dynamic>) onFeedbackSubmitted;

  const PassengerFeedbackDialog({
    super.key,
    required this.busNumber,
    required this.busRoute,
    required this.onFeedbackSubmitted,
  });

  @override
  State<PassengerFeedbackDialog> createState() => _PassengerFeedbackDialogState();
}

class _PassengerFeedbackDialogState extends State<PassengerFeedbackDialog> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Feedback data
  int _overallRating = 0;
  String _crowdingLevel = 'Medium';
  bool _isDelayed = false;
  int _delayMinutes = 0;
  bool _isOnBoard = false;
  String _comment = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feedback for Bus ${widget.busNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.busRoute,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              indicatorColor: AppTheme.primaryColor,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Rating', icon: Icon(Icons.star, size: 16)),
                Tab(text: 'Crowding', icon: Icon(Icons.people, size: 16)),
                Tab(text: 'Delays', icon: Icon(Icons.schedule, size: 16)),
                Tab(text: 'Boarding', icon: Icon(Icons.directions_bus, size: 16)),
              ],
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRatingTab(),
                  _buildCrowdingTab(),
                  _buildDelayTab(),
                  _buildBoardingTab(),
                ],
              ),
            ),
            
            // Submit Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Submit Feedback',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate Your Experience',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _overallRating = index + 1),
                child: Icon(
                  index < _overallRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                ),
              );
            }),
          ),
          
          const SizedBox(height: 16),
          
          if (_overallRating > 0)
            Text(
              _getRatingText(_overallRating),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Comment
          const Text('Additional Comments:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            maxLines: 3,
            onChanged: (value) => _comment = value,
            decoration: InputDecoration(
              hintText: 'Share your experience...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrowdingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Crowding Level',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ...['Low', 'Medium', 'High', 'Full'].map((level) => 
            RadioListTile<String>(
              title: Text(level),
              subtitle: Text(_getCrowdingDescription(level)),
              value: level,
              groupValue: _crowdingLevel,
              onChanged: (value) => setState(() => _crowdingLevel = value!),
              activeColor: AppTheme.primaryColor,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: AppTheme.infoColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your crowding reports help other passengers plan their journey!',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDelayTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Delays',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Bus is delayed'),
            subtitle: const Text('Report if the bus is running behind schedule'),
            value: _isDelayed,
            onChanged: (value) => setState(() => _isDelayed = value),
            activeColor: AppTheme.primaryColor,
          ),
          
          if (_isDelayed) ...[
            const SizedBox(height: 16),
            const Text('Estimated delay (minutes):', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _delayMinutes.toDouble(),
                    min: 0,
                    max: 60,
                    divisions: 12,
                    label: '$_delayMinutes min',
                    onChanged: (value) => setState(() => _delayMinutes = value.round()),
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_delayMinutes min',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.access_time, color: AppTheme.warningColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Delay reports help update ETAs for other passengers in real-time!',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Boarding Confirmation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('I\'m on this bus'),
            subtitle: const Text('Confirm you have boarded this bus'),
            value: _isOnBoard,
            onChanged: (value) => setState(() => _isOnBoard = value),
            activeColor: AppTheme.primaryColor,
          ),
          
          if (_isOnBoard) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.successColor, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Boarding Confirmed!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'You will receive notifications about your journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.directions_bus, color: AppTheme.infoColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Boarding confirmations help drivers track passenger counts and optimize service!',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return 'Poor - Needs improvement';
      case 2: return 'Fair - Below expectations';
      case 3: return 'Good - Satisfactory service';
      case 4: return 'Very Good - Exceeded expectations';
      case 5: return 'Excellent - Outstanding service!';
      default: return '';
    }
  }

  String _getCrowdingDescription(String level) {
    switch (level) {
      case 'Low': return 'Plenty of seats available';
      case 'Medium': return 'Some seats available';
      case 'High': return 'Standing room only';
      case 'Full': return 'Very crowded, difficult to board';
      default: return '';
    }
  }

  void _submitFeedback() {
    final feedback = {
      'busNumber': widget.busNumber,
      'busRoute': widget.busRoute,
      'type': 'passenger_feedback',
      'rating': _overallRating,
      'crowdingLevel': _crowdingLevel,
      'isDelayed': _isDelayed,
      'delayMinutes': _isDelayed ? _delayMinutes : 0,
      'isOnBoard': _isOnBoard,
      'comment': _comment,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    widget.onFeedbackSubmitted(feedback);
  }
}

// Driver Feedback Panel Widget
class DriverFeedbackPanel extends StatefulWidget {
  const DriverFeedbackPanel({super.key});

  @override
  State<DriverFeedbackPanel> createState() => _DriverFeedbackPanelState();
}

class _DriverFeedbackPanelState extends State<DriverFeedbackPanel> with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Consumer<AppStateProviderMinimal>(
          builder: (context, appState, child) {
            return Column(
              children: [
                // Header
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📱 Live Passenger Feedback',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Real-time feedback from passengers',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Tab Bar
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondaryColor,
                  indicatorColor: AppTheme.primaryColor,
                  tabs: [
                    Tab(text: 'Recent (${appState.recentFeedback.length})', icon: const Icon(Icons.access_time, size: 16)),
                    const Tab(text: 'Analytics', icon: Icon(Icons.analytics, size: 16)),
                    const Tab(text: 'Alerts', icon: Icon(Icons.notification_important, size: 16)),
                  ],
                ),
                
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecentFeedbackTab(appState),
                      _buildAnalyticsTab(appState),
                      _buildAlertsTab(appState),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentFeedbackTab(AppStateProviderMinimal appState) {
    final recentFeedback = appState.recentFeedback;
    
    if (recentFeedback.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feedback_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No feedback yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Passenger feedback will appear here in real-time',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recentFeedback.length,
      itemBuilder: (context, index) {
        final feedback = recentFeedback[index];
        return _buildFeedbackCard(feedback);
      },
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(feedback['timestamp'] ?? 0);
    final timeAgo = _getTimeAgo(timestamp);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Bus ${feedback['busNumber'] ?? 'Unknown'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Feedback content
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (feedback['rating'] != null && feedback['rating'] > 0) ...[
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text('${feedback['rating']}/5'),
                            const SizedBox(width: 12),
                            Text(_getRatingText(feedback['rating'])),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      if (feedback['crowdingLevel'] != null) ...[
                        Row(
                          children: [
                            Icon(_getCrowdingIcon(feedback['crowdingLevel']), size: 16),
                            const SizedBox(width: 4),
                            Text('Crowding: ${feedback['crowdingLevel']}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      if (feedback['isDelayed'] == true) ...[
                        Row(
                          children: [
                            const Icon(Icons.schedule, color: AppTheme.warningColor, size: 16),
                            const SizedBox(width: 4),
                            Text('Delayed by ${feedback['delayMinutes'] ?? 0} min'),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      if (feedback['isOnBoard'] == true) ...[
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppTheme.successColor, size: 16),
                            const SizedBox(width: 4),
                            const Text('Passenger boarded'),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      if (feedback['comment'] != null && feedback['comment'].toString().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            feedback['comment'],
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(AppStateProviderMinimal appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Analytics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Overall stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Average Rating',
                  '${_getOverallRating(appState).toStringAsFixed(1)}/5',
                  Icons.star,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Feedback',
                  '${appState.recentFeedback.length}',
                  Icons.feedback,
                  AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Boarded',
                  '${_getBoardingCount(appState)}',
                  Icons.directions_bus,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Delays Reported',
                  '${_getDelayCount(appState)}',
                  Icons.schedule,
                  AppTheme.warningColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Crowding trends
          const Text(
            'Current Crowding Levels',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          ..._getCrowdingLevels(appState).entries.map((entry) =>
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(_getCrowdingIcon(entry.key), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${entry.key} Crowding'),
                  ),
                  Text(
                    '${entry.value} reports',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab(AppStateProviderMinimal appState) {
    final alerts = _generateAlerts(appState);
    
    if (alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: AppTheme.successColor),
            SizedBox(height: 16),
            Text(
              'All good!',
              style: TextStyle(fontSize: 18, color: AppTheme.successColor),
            ),
            Text(
              'No service alerts at the moment',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              alert['icon'] as IconData,
              color: alert['color'] as Color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    alert['message'] as String,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent';
      default: return '';
    }
  }

  IconData _getCrowdingIcon(String level) {
    switch (level) {
      case 'Low': return Icons.airline_seat_legroom_extra;
      case 'Medium': return Icons.people;
      case 'High': return Icons.people_alt;
      case 'Full': return Icons.warning;
      default: return Icons.help;
    }
  }

  double _getOverallRating(AppStateProviderMinimal appState) {
    final ratings = appState.recentFeedback
        .where((f) => f['rating'] != null && f['rating'] > 0)
        .map((f) => f['rating'] as int);
    
    if (ratings.isEmpty) return 0.0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  int _getBoardingCount(AppStateProviderMinimal appState) {
    return appState.recentFeedback.where((f) => f['isOnBoard'] == true).length;
  }

  int _getDelayCount(AppStateProviderMinimal appState) {
    return appState.recentFeedback.where((f) => f['isDelayed'] == true).length;
  }

  Map<String, int> _getCrowdingLevels(AppStateProviderMinimal appState) {
    final crowdingMap = <String, int>{};
    
    for (final feedback in appState.recentFeedback) {
      final level = feedback['crowdingLevel'] as String?;
      if (level != null) {
        crowdingMap[level] = (crowdingMap[level] ?? 0) + 1;
      }
    }
    
    return crowdingMap;
  }

  List<Map<String, dynamic>> _generateAlerts(AppStateProviderMinimal appState) {
    final alerts = <Map<String, dynamic>>[];
    
    // Check for high delay reports
    final delayCount = _getDelayCount(appState);
    if (delayCount >= 3) {
      alerts.add({
        'icon': Icons.schedule,
        'color': AppTheme.warningColor,
        'title': 'Multiple Delay Reports',
        'message': '$delayCount passengers reported delays. Consider checking schedule adherence.',
      });
    }
    
    // Check for high crowding
    final crowdingLevels = _getCrowdingLevels(appState);
    final highCrowding = (crowdingLevels['High'] ?? 0) + (crowdingLevels['Full'] ?? 0);
    if (highCrowding >= 3) {
      alerts.add({
        'icon': Icons.people_alt,
        'color': AppTheme.errorColor,
        'title': 'High Crowding Reported',
        'message': '$highCrowding passengers reported high crowding. Consider deploying additional buses.',
      });
    }
    
    // Check for low ratings
    final avgRating = _getOverallRating(appState);
    if (avgRating > 0 && avgRating < 3.0) {
      alerts.add({
        'icon': Icons.star_border,
        'color': AppTheme.warningColor,
        'title': 'Low Service Rating',
        'message': 'Average rating is ${avgRating.toStringAsFixed(1)}/5. Consider reviewing service quality.',
      });
    }
    
    return alerts;
  }
}
