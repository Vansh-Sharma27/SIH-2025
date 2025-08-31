import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider_minimal.dart';
import '../../theme/app_theme.dart';
import '../../services/location_service_demo.dart';
import '../../models/bus_model.dart';
import '../../models/route_model.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard>
    with WidgetsBindingObserver {
  final LocationServiceDemo _locationService = LocationServiceDemo();
  
  Position? _currentPosition;
  bool _isLocationEnabled = false;
  String _connectionStatus = 'Connecting...';
  DateTime? _lastLocationUpdate;
  int _tripDuration = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _startLocationTracking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLocationTracking();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is going to background - ensure background tracking continues
      _ensureBackgroundTracking();
    } else if (state == AppLifecycleState.resumed) {
      // App is back in foreground - refresh location
      _refreshLocation();
    }
  }

  Future<void> _initializeServices() async {
    // Real-time service initialization removed (using demo services)
    setState(() {
      _connectionStatus = 'Connected';
    });
  }

  void _startLocationTracking() async {
    final appState = Provider.of<AppStateProviderMinimal>(context, listen: false);
    
    if (appState.isDriverOnDuty && appState.driverBusId != null) {
      try {
        await _locationService.startTracking(
          busId: appState.driverBusId!,
          routeId: appState.driverRouteId,
          onLocationUpdate: (position) {
            setState(() {
              _currentPosition = position;
              _isLocationEnabled = true;
              _lastLocationUpdate = DateTime.now();
            });
          },
        );
      } catch (e) {
        _showError('Failed to start location tracking: $e');
      }
    }
  }

  void _stopLocationTracking() async {
    final appState = Provider.of<AppStateProviderMinimal>(context, listen: false);
    if (appState.driverBusId != null) {
      await _locationService.stopTracking(appState.driverBusId!);
    }
  }

  void _ensureBackgroundTracking() {
    // Ensure background location service continues
    print('Ensuring background tracking continues...');
  }

  void _refreshLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
        _lastLocationUpdate = DateTime.now();
      });
    } catch (e) {
      print('Failed to refresh location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          Consumer<AppStateProviderMinimal>(
            builder: (context, appState, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: appState.isDriverOnDuty 
                          ? AppTheme.successColor 
                          : AppTheme.textSecondaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          appState.isDriverOnDuty 
                              ? Icons.radio_button_checked 
                              : Icons.radio_button_unchecked,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appState.isDriverOnDuty ? 'ON DUTY' : 'OFF DUTY',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AppStateProviderMinimal>(
        builder: (context, appState, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Overview Card
                _buildStatusCard(appState),
                const SizedBox(height: 16),
                
                // Location Status Card
                _buildLocationCard(),
                const SizedBox(height: 16),
                
                // Trip Information Card
                if (appState.isDriverOnDuty) ...[
                  _buildTripInfoCard(appState),
                  const SizedBox(height: 16),
                ],
                
                // Action Buttons
                _buildActionButtons(appState),
                const SizedBox(height: 16),
                
                // Quick Actions
                _buildQuickActions(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(AppStateProviderMinimal appState) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: appState.isDriverOnDuty 
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.textSecondaryColor.withOpacity(0.1),
                  ),
                  child: Icon(
                    appState.isDriverOnDuty ? Icons.directions_bus : Icons.pause,
                    color: appState.isDriverOnDuty 
                        ? AppTheme.successColor 
                        : AppTheme.textSecondaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.isDriverOnDuty ? 'Active Duty' : 'Off Duty',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: appState.isDriverOnDuty 
                              ? AppTheme.successColor 
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        appState.isDriverOnDuty 
                            ? 'Broadcasting location to passengers'
                            : 'Ready to start your shift',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (appState.isDriverOnDuty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Bus ID',
                      appState.driverBusId ?? 'N/A',
                      Icons.directions_bus,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Route',
                      appState.driverRouteId ?? 'N/A',
                      Icons.route,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Status',
                      _connectionStatus,
                      Icons.wifi,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isLocationEnabled ? Icons.location_on : Icons.location_off,
                  color: _isLocationEnabled ? AppTheme.successColor : AppTheme.errorColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Location Services',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_currentPosition != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildLocationInfo(
                      'Latitude',
                      _currentPosition!.latitude.toStringAsFixed(6),
                    ),
                  ),
                  Expanded(
                    child: _buildLocationInfo(
                      'Longitude',
                      _currentPosition!.longitude.toStringAsFixed(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildLocationInfo(
                      'Speed',
                      '${(_currentPosition!.speed * 3.6).toStringAsFixed(1)} km/h',
                    ),
                  ),
                  Expanded(
                    child: _buildLocationInfo(
                      'Accuracy',
                      '${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_lastLocationUpdate != null)
                Text(
                  'Last updated: ${_formatTime(_lastLocationUpdate!)}',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: AppTheme.warningColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Location not available. Please check GPS settings.',
                        style: TextStyle(color: AppTheme.warningColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfoCard(AppStateProviderMinimal appState) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTripStat(
                    'Duration',
                    _formatDuration(_tripDuration),
                    Icons.timer,
                  ),
                ),
                Expanded(
                  child: _buildTripStat(
                    'Distance',
                    '12.5 km',  // This would be calculated in real implementation
                    Icons.straighten,
                  ),
                ),
                Expanded(
                  child: _buildTripStat(
                    'Passengers',
                    '24', // This would come from feedback data
                    Icons.people,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppStateProviderMinimal appState) {
    if (!appState.isDriverOnDuty) {
      return ElevatedButton.icon(
        onPressed: () => _startDuty(appState),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Duty'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );
    } else {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => _stopDuty(appState),
            icon: const Icon(Icons.stop),
            label: const Text('End Duty'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _refreshLocation,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Location'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPassengerCount(),
                  icon: const Icon(Icons.people),
                  label: const Text('Update Count'),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Report Issue',
                Icons.warning,
                AppTheme.warningColor,
                () => _showReportDialog(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Break Time',
                Icons.pause,
                AppTheme.infoColor,
                () => _showBreakDialog(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Emergency',
                Icons.emergency,
                AppTheme.errorColor,
                () => _showEmergencyDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTripStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
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

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  void _startDuty(AppStateProviderMinimal appState) async {
    // Show route selection dialog
    _showRouteSelectionDialog(appState);
  }

  void _stopDuty(AppStateProviderMinimal appState) async {
    try {
      await appState.stopDriverDuty();
      _stopLocationTracking();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Duty ended successfully!'),
            backgroundColor: AppTheme.infoColor,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to stop duty: $e');
    }
  }

  void _showRouteSelectionDialog(AppStateProviderMinimal appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Your Route'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Route A1 - City Center to Airport'),
              onTap: () {
                Navigator.of(context).pop();
                _confirmStartDuty(appState, 'BUS001', 'route_001');
              },
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Route B2 - University to Railway'),
              onTap: () {
                Navigator.of(context).pop();
                _confirmStartDuty(appState, 'BUS002', 'route_002');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmStartDuty(AppStateProviderMinimal appState, String busId, String routeId) async {
    try {
      await appState.startDriverDuty(busId, routeId);
      _startLocationTracking();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Duty started successfully! Location sharing is active.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to start duty: $e');
    }
  }

  void _showPassengerCount() {
    showDialog(
      context: context,
      builder: (context) {
        int passengerCount = 20; // Default value
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Passenger Count'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Current passenger count: $passengerCount'),
                  Slider(
                    value: passengerCount.toDouble(),
                    min: 0,
                    max: 50,
                    divisions: 50,
                    label: passengerCount.toString(),
                    onChanged: (value) {
                      setState(() {
                        passengerCount = value.round();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update passenger count in database
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Passenger count updated to $passengerCount')),
                    );
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.traffic),
              title: Text('Traffic Delay'),
            ),
            ListTile(
              leading: Icon(Icons.build),
              title: Text('Vehicle Issue'),
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: Text('Road Condition'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBreakDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Break Time'),
        content: const Text('Are you taking a scheduled break?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Break time logged')),
              );
            },
            child: const Text('Start Break'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Alert'),
        content: const Text('This will alert the control center immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency alert sent!'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
