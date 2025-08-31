import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider_minimal.dart';
import '../../theme/app_theme.dart';
import 'driver_dashboard.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Driver Portal'),
          backgroundColor: AppTheme.primaryColor,
          actions: [
            IconButton(
              onPressed: () => _showLogoutDialog(),
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const DriverDashboard(),
            _buildAnalyticsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<AppStateProviderMinimal>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Analytics Cards
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today\'s Performance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticItem(
                              'Total Distance',
                              '127.8 km',
                              Icons.straighten,
                              AppTheme.primaryColor,
                            ),
                          ),
                          Expanded(
                            child: _buildAnalyticItem(
                              'Trip Time',
                              '6h 42m',
                              Icons.timer,
                              AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticItem(
                              'Avg Speed',
                              '19.1 km/h',
                              Icons.speed,
                              AppTheme.warningColor,
                            ),
                          ),
                          Expanded(
                            child: _buildAnalyticItem(
                              'Passengers',
                              '248',
                              Icons.people,
                              AppTheme.infoColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Weekly Summary
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
                      const SizedBox(height: 20),
                      _buildWeeklyStat('Monday', 45, 0.9),
                      _buildWeeklyStat('Tuesday', 52, 0.85),
                      _buildWeeklyStat('Wednesday', 48, 0.92),
                      _buildWeeklyStat('Thursday', 38, 0.78),
                      _buildWeeklyStat('Friday', 55, 0.88),
                      _buildWeeklyStat('Saturday', 42, 0.95),
                      _buildWeeklyStat('Sunday', 36, 0.82),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Feedback Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Passenger Feedback',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          const Text('4.6/5.0'),
                          const Spacer(),
                          Text('Based on 127 reviews', 
                               style: TextStyle(color: AppTheme.textSecondaryColor)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(
                        value: 0.92,
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
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
        ),
      ],
    );
  }

  Widget _buildWeeklyStat(String day, int passengers, double onTimePercent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$passengers passengers'),
                LinearProgressIndicator(
                  value: passengers / 60,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.infoColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${(onTimePercent * 100).toStringAsFixed(0)}% on-time',
              style: TextStyle(
                color: onTimePercent > 0.85 ? AppTheme.successColor : AppTheme.warningColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }



  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    final appState = Provider.of<AppStateProviderMinimal>(context, listen: false);
    await appState.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}
