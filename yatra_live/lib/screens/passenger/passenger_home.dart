import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider_minimal.dart';
import '../../theme/app_theme.dart';
import 'passenger_map.dart';
import '../widgets/bus_search_widget.dart';
import '../widgets/route_list_widget.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('YatraLive'),
          backgroundColor: AppTheme.primaryColor,
          actions: [
            IconButton(
              onPressed: () => _showNotificationSettings(),
              icon: const Icon(Icons.notifications),
            ),
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
              Tab(icon: Icon(Icons.home), text: 'Home'),
              Tab(icon: Icon(Icons.map), text: 'Map'),
              Tab(icon: Icon(Icons.route), text: 'Routes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHomeTab(),
            const PassengerMap(),
            const RouteListWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
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
              // Welcome card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back!',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  appState.currentUser?.name ?? 'Passenger',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Quick search
              const BusSearchWidget(),
              
              const SizedBox(height: 24),
              
              // Live buses section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Live Buses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showAllBuses(),
                    child: const Text('View All'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Demo buses
              _buildBusCard('Bus 101', 'Route A', '5 min away', true),
              _buildBusCard('Bus 205', 'Route B', '12 min away', false),
              _buildBusCard('Bus 309', 'Route C', '8 min away', true),
              
              const SizedBox(height: 24),
              
              // Quick actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      'View Map',
                      Icons.map,
                      AppTheme.primaryColor,
                      () => _showMapDialog(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionCard(
                      'Favorites',
                      Icons.favorite,
                      AppTheme.errorColor,
                      () => _showFavoritesDialog(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionCard(
                      'Notifications',
                      Icons.notifications,
                      AppTheme.warningColor,
                      () => _showNotificationsDialog(),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Recent activity
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildActivityItem(
                        'Tracked Bus 101 on Route A',
                        '2 hours ago',
                        Icons.directions_bus,
                      ),
                      const Divider(),
                      _buildActivityItem(
                        'Added Route B to favorites',
                        '1 day ago',
                        Icons.favorite,
                      ),
                      const Divider(),
                      _buildActivityItem(
                        'Received arrival notification',
                        '2 days ago',
                        Icons.notifications,
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

  Widget _buildBusCard(String busNumber, String route, String eta, bool isActive) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? AppTheme.successColor : AppTheme.textSecondaryColor,
          child: const Icon(
            Icons.directions_bus,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(busNumber),
        subtitle: Text(route),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              eta,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.successColor : AppTheme.textSecondaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'LIVE' : 'OFFLINE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _trackBus(busNumber),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
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

  Widget _buildActivityItem(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _trackBus(String busNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Now tracking $busNumber'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Consumer<AppStateProviderMinimal>(
          builder: (context, appState, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Bus Arrival Alerts'),
                  subtitle: const Text('Get notified when your bus is approaching'),
                  value: appState.notificationSettings['busArrival'] ?? true,
                  onChanged: (value) {
                    appState.updateNotificationSettings({'busArrival': value});
                  },
                ),
                SwitchListTile(
                  title: const Text('Delay Notifications'),
                  subtitle: const Text('Receive updates about bus delays'),
                  value: appState.notificationSettings['delays'] ?? true,
                  onChanged: (value) {
                    appState.updateNotificationSettings({'delays': value});
                  },
                ),
                SwitchListTile(
                  title: const Text('Crowding Updates'),
                  subtitle: const Text('Know about bus occupancy levels'),
                  value: appState.notificationSettings['crowding'] ?? true,
                  onChanged: (value) {
                    appState.updateNotificationSettings({'crowding': value});
                  },
                ),
              ],
            );
          },
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

  void _showAllBuses() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Buses'),
        content: const Text('Bus list view will be implemented in Phase 3'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMapDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map View'),
        content: const Text('Interactive map will be implemented in Phase 3'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFavoritesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Favorite Routes'),
        content: const Text('Favorites management will be implemented in Phase 2'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('Notification settings will be implemented in Phase 2'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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
