import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider_minimal.dart';
import '../../theme/app_theme.dart';
import '../../models/route_model.dart';

class BusSearchWidget extends StatefulWidget {
  const BusSearchWidget({super.key});

  @override
  State<BusSearchWidget> createState() => _BusSearchWidgetState();
}

class _BusSearchWidgetState extends State<BusSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<RouteModel> _filteredRoutes = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    final appState = Provider.of<AppStateProviderMinimal>(context, listen: false);
    
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _filteredRoutes = [];
      });
      return;
    }

    setState(() {
      _showSuggestions = true;
      _filteredRoutes = appState.routes.where((route) {
        return route.routeName.toLowerCase().contains(query) ||
               route.routeNumber.toLowerCase().contains(query) ||
               route.startPoint.toLowerCase().contains(query) ||
               route.endPoint.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find Your Bus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search routes, destinations...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _showSuggestions = false;
                              });
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          
          // Search suggestions
          if (_showSuggestions) ...[
            const Divider(height: 1),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _filteredRoutes.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No routes found',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredRoutes.length,
                      itemBuilder: (context, index) {
                        final route = _filteredRoutes[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              route.routeNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(route.routeName),
                          subtitle: Text(
                            '${route.startPoint} → ${route.endPoint}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _selectRoute(route),
                        );
                      },
                    ),
            ),
          ],
          
          // Quick action buttons
          if (!_showSuggestions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showNearbyStops,
                      icon: const Icon(Icons.near_me),
                      label: const Text('Nearby Stops'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showAllRoutes,
                      icon: const Icon(Icons.map),
                      label: const Text('View Map'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _selectRoute(RouteModel route) {
    final appState = Provider.of<AppStateProviderMinimal>(context, listen: false);
    appState.selectRoute(route);
    
    _searchController.clear();
    setState(() {
      _showSuggestions = false;
    });
    
    // Navigate to map tab to show the selected route
    DefaultTabController.of(context).animateTo(1);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected ${route.routeName}'),
        backgroundColor: AppTheme.successColor,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Switch to map tab
          },
        ),
      ),
    );
  }

  void _showNearbyStops() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nearby Bus Stops'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNearbyStopItem('Central Park', '120m away', Icons.location_on),
            _buildNearbyStopItem('Shopping Mall', '350m away', Icons.store),
            _buildNearbyStopItem('Metro Station', '450m away', Icons.train),
            _buildNearbyStopItem('Hospital', '680m away', Icons.local_hospital),
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

  Widget _buildNearbyStopItem(String name, String distance, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(name),
      subtitle: Text(distance),
      trailing: const Icon(Icons.directions_walk, size: 16),
      contentPadding: EdgeInsets.zero,
      onTap: () {
        Navigator.of(context).pop();
        // Navigate to this stop
      },
    );
  }

  void _showAllRoutes() {
    // Switch to routes tab
    DefaultTabController.of(context).animateTo(2);
  }
}
