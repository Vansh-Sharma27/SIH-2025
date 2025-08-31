import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider_minimal.dart';
import '../../models/bus_model.dart';
import '../../models/route_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_bus_icon.dart';
import 'dart:async';
import 'dart:math' as math;

class PassengerMap extends StatefulWidget {
  const PassengerMap({super.key});

  @override
  State<PassengerMap> createState() => _PassengerMapState();
}

class _PassengerMapState extends State<PassengerMap> 
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final RealTimeService _realTimeService = RealTimeService();
  late AnimationController _animationController;
  late Timer _updateTimer;
  
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  
  // Delhi coordinates for demo
  LatLng _centerLocation = LatLng(28.6139, 77.2090);
  double _currentZoom = 13.0;
  
  BusModel? _selectedBus;
  List<BusModel> _liveBuses = [];
  bool _isLoading = false;
  double _animationOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeDemo();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _updateTimer.cancel();
    super.dispose();
  }

  void _initializeDemo() {
    // Initialize animation for live demo
    _animationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _animationController.repeat();
    _animationController.addListener(() {
      setState(() {
        _animationOffset = _animationController.value;
      });
    });

    // Generate mock bus data
    _generateMockBuses();
    _generateMockRoutes();

    // Update every 30 seconds to show "live" updates
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _generateMockBuses();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Live data updated'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _generateMockBuses() {
    _liveBuses = [
      BusModel(
        id: 'bus_001',
        busNumber: 'DL-1234',
        routeId: 'route_001',
        latitude: 28.6139 + (math.sin(_animationOffset * 2 * math.pi) * 0.01),
        longitude: 77.2090 + (math.cos(_animationOffset * 2 * math.pi) * 0.01),
        speed: 25.0 + (math.sin(_animationOffset * math.pi) * 10),
        heading: _animationOffset * 360,
        passengerCount: 15 + (_animationOffset * 20).round(),
        status: 'active',
        lastUpdated: DateTime.now(),
      ),
      BusModel(
        id: 'bus_002',
        busNumber: 'DL-5678',
        routeId: 'route_001',
        latitude: 28.6200 + (math.cos(_animationOffset * 2 * math.pi) * 0.005),
        longitude: 77.2150 + (math.sin(_animationOffset * 2 * math.pi) * 0.005),
        speed: 30.0 + (math.cos(_animationOffset * math.pi) * 5),
        heading: (_animationOffset + 0.5) * 360,
        passengerCount: 8 + (_animationOffset * 15).round(),
        status: 'active',
        lastUpdated: DateTime.now(),
      ),
      BusModel(
        id: 'bus_003',
        busNumber: 'DL-9012',
        routeId: 'route_002',
        latitude: 28.6080 + (math.sin(_animationOffset * 1.5 * math.pi) * 0.008),
        longitude: 77.2030 + (math.cos(_animationOffset * 1.5 * math.pi) * 0.008),
        speed: 20.0 + (math.sin(_animationOffset * 1.5 * math.pi) * 8),
        heading: (_animationOffset + 0.3) * 360,
        passengerCount: 22 + (_animationOffset * 10).round(),
        status: 'active',
        lastUpdated: DateTime.now(),
      ),
    ];
    _updateMapMarkers();
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
        color: Colors.blue,
        strokeWidth: 4.0,
      ),
      Polyline(
        points: [
          LatLng(28.6050, 77.2000),
          LatLng(28.6080, 77.2030),
          LatLng(28.6120, 77.2070),
          LatLng(28.6160, 77.2110),
        ],
        color: Colors.green,
        strokeWidth: 4.0,
      ),
    ];
  }

  void _updateMapMarkers() {
    List<Marker> newMarkers = [];
    
    // Add bus markers
    for (int i = 0; i < _liveBuses.length; i++) {
      final bus = _liveBuses[i];
      newMarkers.add(
        Marker(
          point: LatLng(bus.latitude, bus.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _onBusMarkerTapped(bus),
            child: Container(
              decoration: BoxDecoration(
                color: _getBusColor(i),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
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
          child: GestureDetector(
            onTap: () => _showBusStopInfo(stop['name'] as String),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.stop,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  Color _getBusColor(int index) {
    final colors = [Colors.green, Colors.blue, Colors.purple];
    return colors[index % colors.length];
  }

  void _onBusMarkerTapped(BusModel bus) {
    setState(() {
      _selectedBus = bus;
    });
    
    _showBusDetailsBottomSheet(bus);
  }

  void _showBusDetailsBottomSheet(BusModel bus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Bus details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.directions_bus,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bus ${bus.busNumber}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Route ${bus.routeId ?? 'N/A'}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: bus.status == 'active' 
                                  ? AppTheme.successColor 
                                  : AppTheme.textSecondaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              bus.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Bus info grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildBusInfoItem(
                              'Speed',
                              '${bus.speed?.toStringAsFixed(1) ?? '0'} km/h',
                              Icons.speed,
                            ),
                          ),
                          Expanded(
                            child: _buildBusInfoItem(
                              'Passengers',
                              '${bus.passengerCount ?? 0}',
                              Icons.people,
                            ),
                          ),
                          Expanded(
                            child: _buildBusInfoItem(
                              'Updated',
                              _getTimeAgo(bus.lastUpdated),
                              Icons.update,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _trackBus(bus),
                              icon: const Icon(Icons.my_location),
                              label: const Text('Track Bus'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showETADialog(bus),
                              icon: const Icon(Icons.schedule),
                              label: const Text('ETA'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Crowding indicator
                      _buildCrowdingIndicator(bus.passengerCount ?? 0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCrowdingIndicator(int passengerCount) {
    String level = 'Low';
    Color color = AppTheme.successColor;
    
    if (passengerCount > 30) {
      level = 'High';
      color = AppTheme.errorColor;
    } else if (passengerCount > 15) {
      level = 'Medium';
      color = AppTheme.warningColor;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.people, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            'Crowding Level: $level',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
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

  void _trackBus(BusModel bus) {
    Navigator.of(context).pop(); // Close bottom sheet
    
    // Center map on bus
    _mapController.move(LatLng(bus.latitude, bus.longitude), 16);
    
    // Update app state
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    appState.trackBus(bus);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Now tracking Bus ${bus.busNumber}'),
        backgroundColor: AppTheme.successColor,
        action: SnackBarAction(
          label: 'Stop',
          textColor: Colors.white,
          onPressed: () {
            appState.stopTrackingBus();
          },
        ),
      ),
    );
  }

  void _showETADialog(BusModel bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ETA for Bus ${bus.busNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Estimated arrival times:'),
            const SizedBox(height: 16),
            _buildETAItem('Next Stop', '3 min'),
            _buildETAItem('Central Park', '8 min'),
            _buildETAItem('Shopping Mall', '15 min'),
            _buildETAItem('IT Park', '25 min'),
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
              _trackBus(bus);
            },
            child: const Text('Track Bus'),
          ),
        ],
      ),
    );
  }

  Widget _buildETAItem(String stop, String eta) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(stop),
          Text(
            eta,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upcoming buses:'),
            const SizedBox(height: 12),
            _buildUpcomingBusItem('DL-1234', '3 min', Colors.green),
            _buildUpcomingBusItem('DL-5678', '8 min', Colors.blue),
            _buildUpcomingBusItem('DL-9012', '15 min', Colors.purple),
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

  Widget _buildUpcomingBusItem(String busNumber, String eta, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_bus, color: color, size: 16),
          const SizedBox(width: 8),
          Text('Bus $busNumber'),
          const Spacer(),
          Text(
            eta,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showDemoInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚀 Zero-Setup Demo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDemoFeature('🗺️', 'OpenStreetMap integration - No API keys needed'),
            _buildDemoFeature('🚌', 'Live bus simulation with real movement'),
            _buildDemoFeature('📍', 'Interactive bus stops and routes'),
            _buildDemoFeature('⚡', 'Real-time updates every 30 seconds'),
            _buildDemoFeature('📱', 'Production-ready architecture'),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Text(
                '✅ Perfect for hackathon demos! In production, easily integrate with any preferred mapping service.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome! 🎉'),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoFeature(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main map content
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
            top: 50,
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
                        color: Colors.green,
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
            top: 120,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    _mapController.move(_centerLocation, _currentZoom + 1);
                  },
                  child: const Icon(Icons.zoom_in),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    _mapController.move(_centerLocation, _currentZoom - 1);
                  },
                  child: const Icon(Icons.zoom_out),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    _mapController.move(_centerLocation, 13.0);
                  },
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
          
          // Live data panel
          Positioned(
            bottom: 100,
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
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'LIVE DEMO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('🚌 ${_liveBuses.length} Active Buses', style: const TextStyle(fontSize: 12)),
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
          
          // Demo features showcase
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              color: AppTheme.primaryColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tap buses for details • Production-ready architecture',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _showDemoInfo,
                      icon: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
