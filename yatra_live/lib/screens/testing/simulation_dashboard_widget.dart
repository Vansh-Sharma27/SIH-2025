import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/mock_realtime/multiclient_simulation_harness.dart';
import '../../services/mock_realtime/performance_monitor.dart';
import '../../services/mock_realtime/enhanced_performance_monitor.dart';
import '../../widgets/performance_overlay.dart';
import '../../widgets/demo_control_panel.dart';
import '../../theme/app_theme.dart';

/// Visual dashboard for monitoring multi-client simulation
class SimulationDashboardWidget extends StatefulWidget {
  const SimulationDashboardWidget({Key? key}) : super(key: key);

  @override
  State<SimulationDashboardWidget> createState() => _SimulationDashboardWidgetState();
}

class _SimulationDashboardWidgetState extends State<SimulationDashboardWidget> 
    with SingleTickerProviderStateMixin {
  // Simulation harness
  late MulticlientSimulationHarness _simulationHarness;
  SimulationState? _simulationState;
  Map<String, dynamic>? _performanceDashboard;
  
  // Streams
  StreamSubscription<SimulationState>? _stateSubscription;
  StreamSubscription<Map<String, dynamic>>? _performanceSubscription;
  
  // Animation
  late AnimationController _animationController;
  
  // Configuration
  final _driverCountController = TextEditingController(text: '5');
  final _passengerCountController = TextEditingController(text: '20');
  bool _chaosMode = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _initializeSimulation();
  }

  void _initializeSimulation() {
    _simulationHarness = MulticlientSimulationHarness(
      config: SimulationConfig(
        driverCount: int.tryParse(_driverCountController.text) ?? 5,
        passengerCount: int.tryParse(_passengerCountController.text) ?? 20,
        enableChaos: _chaosMode,
      ),
    );
    
    _simulationHarness.onStateUpdate = (state) {
      if (mounted) {
        setState(() => _simulationState = state);
      }
    };
    
    _performanceSubscription = _simulationHarness.performanceDashboardStream.listen((dashboard) {
      if (mounted) {
        setState(() => _performanceDashboard = dashboard);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stateSubscription?.cancel();
    _performanceSubscription?.cancel();
    _simulationHarness.dispose();
    _driverCountController.dispose();
    _passengerCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Simulation Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          if (_simulationState?.isRunning ?? false)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: _buildLiveIndicator(),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Configuration Panel
              _buildConfigurationPanel(),
              
              // Main Dashboard
              Expanded(
                child: _simulationState == null
                    ? _buildWelcomeScreen()
                    : _buildDashboard(),
              ),
              
              // Performance Metrics Bar
              if (_performanceDashboard != null) _buildPerformanceBar(),
            ],
          ),
          
          // Performance Overlay
          if (_simulationState?.isRunning ?? false)
            const PerformanceOverlay(
              expanded: true,
              showAlerts: true,
            ),
          
          // Demo Control Panel
          const DemoControlPanel(
            startMinimized: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.8 + 0.2 * _animationController.value),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfigurationPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _driverCountController,
                  decoration: const InputDecoration(
                    labelText: 'Drivers',
                    prefixIcon: Icon(Icons.directions_bus),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !(_simulationState?.isRunning ?? false),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _passengerCountController,
                  decoration: const InputDecoration(
                    labelText: 'Passengers',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !(_simulationState?.isRunning ?? false),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  const Text('Chaos Mode'),
                  Switch(
                    value: _chaosMode,
                    onChanged: (_simulationState?.isRunning ?? false) ? null : (value) {
                      setState(() => _chaosMode = value);
                    },
                  ),
                ],
              ),
              const SizedBox(width: 32),
              ElevatedButton.icon(
                onPressed: _toggleSimulation,
                icon: Icon(
                  (_simulationState?.isRunning ?? false) ? Icons.stop : Icons.play_arrow,
                ),
                label: Text(
                  (_simulationState?.isRunning ?? false) ? 'Stop' : 'Start',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_simulationState?.isRunning ?? false) 
                      ? Colors.red 
                      : AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
          if (_simulationState?.isRunning ?? false) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _simulationHarness.addDriver(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Driver'),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => _simulationHarness.addPassenger(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Passenger'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.speed,
            size: 100,
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Multi-client Real-time Simulation',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Configure and start the simulation to see real-time performance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final entities = _simulationState?.entities ?? {};
    final drivers = entities.values.where((e) => e.type == EntityType.driver).toList();
    final passengers = entities.values.where((e) => e.type == EntityType.passenger).toList();
    
    return Row(
      children: [
        // Entity List
        Container(
          width: 300,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Column(
            children: [
              _buildEntityHeader('Drivers', drivers.length, Icons.directions_bus),
              Expanded(
                child: ListView.builder(
                  itemCount: drivers.length,
                  itemBuilder: (context, index) => _buildEntityTile(drivers[index]),
                ),
              ),
              const Divider(height: 1),
              _buildEntityHeader('Passengers', passengers.length, Icons.person),
              Expanded(
                child: ListView.builder(
                  itemCount: passengers.length,
                  itemBuilder: (context, index) => _buildEntityTile(passengers[index]),
                ),
              ),
            ],
          ),
        ),
        
        // Main View
        Expanded(
          child: Column(
            children: [
              // Route Distribution
              _buildRouteDistribution(),
              
              // Performance Graphs
              Expanded(
                child: _buildPerformanceGraphs(),
              ),
              
              // System Health
              _buildSystemHealth(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEntityHeader(String title, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[200],
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityTile(SimulationEntity entity) {
    Color statusColor;
    IconData statusIcon;
    
    switch (entity.status) {
      case EntityStatus.active:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case EntityStatus.disconnected:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case EntityStatus.reconnecting:
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        break;
      case EntityStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }
    
    final messageCount = entity.metadata['messageCount'] as int?;
    
    return ListTile(
      dense: true,
      leading: Icon(statusIcon, color: statusColor, size: 20),
      title: Text(entity.id, style: const TextStyle(fontSize: 14)),
      subtitle: Text('Route: ${entity.routeId}', style: const TextStyle(fontSize: 12)),
      trailing: messageCount != null 
          ? Text('$messageCount msgs', style: const TextStyle(fontSize: 12))
          : null,
      onTap: () => _showEntityDetails(entity),
    );
  }

  Widget _buildRouteDistribution() {
    final entities = _simulationState?.entities ?? {};
    final routeStats = <String, Map<String, int>>{};
    
    for (final entity in entities.values) {
      if (entity.status == EntityStatus.active) {
        routeStats.putIfAbsent(entity.routeId, () => {'drivers': 0, 'passengers': 0});
        if (entity.type == EntityType.driver) {
          routeStats[entity.routeId]!['drivers'] = routeStats[entity.routeId]!['drivers']! + 1;
        } else {
          routeStats[entity.routeId]!['passengers'] = routeStats[entity.routeId]!['passengers']! + 1;
        }
      }
    }
    
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: routeStats.entries.map((entry) {
          return Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildRouteCount(
                          Icons.directions_bus,
                          entry.value['drivers'] ?? 0,
                          Colors.blue,
                        ),
                        _buildRouteCount(
                          Icons.person,
                          entry.value['passengers'] ?? 0,
                          Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRouteCount(IconData icon, int count, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceGraphs() {
    if (_performanceDashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final latency = _performanceDashboard!['latency'] as Map<String, dynamic>?;
    final delivery = _performanceDashboard!['delivery'] as Map<String, dynamic>?;
    final connections = _performanceDashboard!['connections'] as int?;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              title: 'Latency',
              value: '${latency?['current']?.toStringAsFixed(0) ?? '0'}ms',
              subtitle: 'Avg: ${latency?['average']?.toStringAsFixed(0) ?? '0'}ms',
              color: _getLatencyColor(latency?['current'] ?? 0),
              icon: Icons.speed,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildMetricCard(
              title: 'Delivery Rate',
              value: '${delivery?['rate']?.toStringAsFixed(1) ?? '100'}%',
              subtitle: '${delivery?['successful'] ?? 0}/${delivery?['total'] ?? 0}',
              color: _getDeliveryRateColor(delivery?['rate'] ?? 100),
              icon: Icons.check_circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildMetricCard(
              title: 'Connections',
              value: '${connections ?? 0}',
              subtitle: 'Active',
              color: Colors.blue,
              icon: Icons.link,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemHealth() {
    final health = _performanceDashboard?['health'] as String? ?? 'unknown';
    Color healthColor;
    IconData healthIcon;
    
    switch (health) {
      case 'excellent':
        healthColor = Colors.green;
        healthIcon = Icons.sentiment_very_satisfied;
        break;
      case 'good':
        healthColor = Colors.lightGreen;
        healthIcon = Icons.sentiment_satisfied;
        break;
      case 'fair':
        healthColor = Colors.orange;
        healthIcon = Icons.sentiment_neutral;
        break;
      case 'poor':
        healthColor = Colors.red;
        healthIcon = Icons.sentiment_dissatisfied;
        break;
      default:
        healthColor = Colors.grey;
        healthIcon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: healthColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(healthIcon, color: healthColor, size: 32),
          const SizedBox(width: 12),
          Text(
            'System Health: ${health.toUpperCase()}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: healthColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBar() {
    final latency = _performanceDashboard?['latency'] as Map<String, dynamic>?;
    final p95 = latency?['p95'] as double? ?? 0;
    final p99 = latency?['p99'] as double? ?? 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPerformanceItem('P95 Latency', '${p95.toStringAsFixed(0)}ms'),
          _buildPerformanceItem('P99 Latency', '${p99.toStringAsFixed(0)}ms'),
          const Spacer(),
          Text(
            'Real-time Performance Monitor',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSimulation() async {
    if (_simulationState?.isRunning ?? false) {
      await _simulationHarness.stopSimulation();
    } else {
      // Recreate harness with new config
      _simulationHarness.dispose();
      _initializeSimulation();
      await _simulationHarness.startSimulation();
    }
  }

  void _showEntityDetails(SimulationEntity entity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entity.id),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${entity.type.toString().split('.').last}'),
            Text('Route: ${entity.routeId}'),
            Text('Status: ${entity.status.toString().split('.').last}'),
            const SizedBox(height: 8),
            const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...entity.metadata.entries.map((e) => Text('${e.key}: ${e.value}')),
          ],
        ),
        actions: [
          if (_simulationState?.isRunning ?? false)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _simulationHarness.removeEntity(entity.id);
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getLatencyColor(double latency) {
    if (latency < 100) return Colors.green;
    if (latency < 500) return Colors.orange;
    return Colors.red;
  }

  Color _getDeliveryRateColor(double rate) {
    if (rate > 95) return Colors.green;
    if (rate > 90) return Colors.orange;
    return Colors.red;
  }
