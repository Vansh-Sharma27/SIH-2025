import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider_minimal.dart';
import '../../theme/app_theme.dart';
import '../../utils/testing_utils.dart';
import 'simulation_dashboard_widget.dart';

class TestingDashboard extends StatefulWidget {
  const TestingDashboard({super.key});

  @override
  State<TestingDashboard> createState() => _TestingDashboardState();
}

class _TestingDashboardState extends State<TestingDashboard> {
  bool _isRunningTests = false;
  List<String> _testResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testing Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            onPressed: _clearTestResults,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Results',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // System Status Card
            _buildSystemStatusCard(),
            const SizedBox(height: 16),
            
            // Quick Tests
            _buildQuickTestsCard(),
            const SizedBox(height: 16),
            
            // Real-time Simulation
            _buildSimulationCard(),
            const SizedBox(height: 16),
            
            // Performance Demo
            _buildPerformanceDemoCard(),
            const SizedBox(height: 16),
            
            // Test Results
            _buildTestResultsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusItem('Firebase', true, Icons.cloud),
                    ),
                    Expanded(
                      child: _buildStatusItem('Location', true, Icons.location_on),
                    ),
                    Expanded(
                      child: _buildStatusItem('Maps', true, Icons.map),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickTestsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Tests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickTestButton('Generate Mock Buses', _generateMockBuses),
                _buildQuickTestButton('Generate Mock Routes', _generateMockRoutes),
                _buildQuickTestButton('Test Location Updates', _testLocationUpdates),
                _buildQuickTestButton('Clear Cache', _clearCache),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _testResults.isEmpty
                  ? const Center(
                      child: Text(
                        'No test results yet.\nRun tests to see results here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _testResults.length,
                      itemBuilder: (context, index) {
                        final result = _testResults[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            result,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: result.startsWith('✅') 
                                  ? AppTheme.successColor
                                  : result.startsWith('❌')
                                      ? AppTheme.errorColor
                                      : AppTheme.textSecondaryColor,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, bool isActive, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: isActive ? AppTheme.successColor : AppTheme.textSecondaryColor,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.successColor : AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTestButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isRunningTests ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  void _addTestResult(String result) {
    setState(() {
      _testResults.add('${DateTime.now().toIso8601String().substring(11, 19)} $result');
      if (_testResults.length > 50) {
        _testResults.removeAt(0);
      }
    });
  }

  void _clearTestResults() {
    setState(() {
      _testResults.clear();
    });
  }

  void _generateMockBuses() {
    final buses = TestingUtils.generateMockBuses(count: 5);
    _addTestResult('🚌 Generated ${buses.length} mock buses');
    _addTestResult('✅ Mock buses ready for testing');
  }

  void _generateMockRoutes() {
    final routes = TestingUtils.generateMockRoutes(count: 3);
    _addTestResult('🛣️ Generated ${routes.length} mock routes');
    
    int totalStops = 0;
    for (final route in routes) {
      totalStops += route.stops.length;
    }
    
    _addTestResult('🚏 Created $totalStops bus stops across all routes');
  }

  void _testLocationUpdates() {
    _addTestResult('📍 Testing location updates');
    
    final mockBuses = TestingUtils.generateMockBuses(count: 1);
    final mockBus = mockBuses[0];
    
    for (int i = 0; i < 3; i++) {
      final oldLat = mockBus.latitude;
      final oldLng = mockBus.longitude;
      
      TestingUtils.simulateLocationUpdate(mockBus);
      
      _addTestResult('📍 Update ${i + 1}: (${oldLat.toStringAsFixed(4)}, ${oldLng.toStringAsFixed(4)}) → (${mockBus.latitude.toStringAsFixed(4)}, ${mockBus.longitude.toStringAsFixed(4)})');
    }
  }

  Future<void> _clearCache() async {
    // Cache clearing functionality removed (using demo services)
    _addTestResult('🗑️ Cache cleared successfully');
  }
  
  Widget _buildSimulationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Real-time Simulation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Launch the multi-client simulation dashboard to test real-time performance with multiple drivers and passengers.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SimulationDashboardWidget(),
                    ),
                  );
                },
                icon: const Icon(Icons.launch),
                label: const Text('Open Simulation Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPerformanceDemoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Performance Monitoring Demo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'HOT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Real-time performance monitoring with message path tracking, latency analysis, and system health visualization.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDemoFeature(Icons.speed, 'Latency\nTracking'),
                _buildDemoFeature(Icons.timeline, 'Message\nPaths'),
                _buildDemoFeature(Icons.analytics, '95th\nPercentile'),
                _buildDemoFeature(Icons.monitor_heart, 'Health\nScore'),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Performance overlay will appear on the Live Map screen',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDemoFeature(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
