import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider_minimal.dart';
import '../../theme/app_theme.dart';
import '../../models/route_model.dart';
import '../../models/bus_model.dart';

class RouteListWidget extends StatefulWidget {
  const RouteListWidget({super.key});

  @override
  State<RouteListWidget> createState() => _RouteListWidgetState();
}

class _RouteListWidgetState extends State<RouteListWidget> {
  String _selectedFilter = 'all';
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProviderMinimal>(
      builder: (context, appState, child) {
        final filteredRoutes = _filterRoutes(appState.routes);
        
        return Column(
          children: [
            // Filter tabs
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All Routes', 'all', appState.routes.length),
                          const SizedBox(width: 8),
                          _buildFilterChip('Favorites', 'favorites', appState.favoriteRoutes.length),
                          const SizedBox(width: 8),
                          _buildFilterChip('Active', 'active', _getActiveBusCount(appState)),
                          const SizedBox(width: 8),
                          _buildFilterChip('Nearby', 'nearby', 3), // Mock nearby count
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _showSortOptions,
                    icon: const Icon(Icons.sort),
                  ),
                ],
              ),
            ),
            
            // Route list
            Expanded(
              child: filteredRoutes.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredRoutes.length,
                      itemBuilder: (context, index) {
                        final route = filteredRoutes[index];
                        final buses = appState.getBusesForRoute(route.id);
                        return _buildRouteCard(route, buses, appState);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  List<RouteModel> _filterRoutes(List<RouteModel> routes) {
    switch (_selectedFilter) {
      case 'favorites':
        final appState = Provider.of<AppStateProviderMinimal>(context, listen: false);
        return routes.where((route) => appState.isRouteFavorite(route.id)).toList();
      case 'active':
        final appState = Provider.of<AppStateProviderMinimal>(context, listen: false);
        return routes.where((route) {
          final buses = appState.getBusesForRoute(route.id);
          return buses.any((bus) => bus.status == 'active');
        }).toList();
      case 'nearby':
        // Mock nearby filter - in real app, this would use location
        return routes.take(3).toList();
      default:
        return routes;
    }
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildRouteCard(RouteModel route, List<BusModel> buses, AppStateProviderMinimal appState) {
    final activeBuses = buses.where((bus) => bus.status == 'active').toList();
    final isFavorite = appState.isRouteFavorite(route.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showRouteDetails(route, buses, appState),
        borderRadius: BorderRadius.circular(12),
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
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      route.routeNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      route.routeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _toggleFavorite(route.id, appState),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? AppTheme.errorColor : AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Route info
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: AppTheme.successColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      route.startPoint,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: AppTheme.errorColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      route.endPoint,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Bus status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: activeBuses.isEmpty 
                          ? AppTheme.textSecondaryColor.withOpacity(0.1)
                          : AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_bus,
                          size: 14,
                          color: activeBuses.isEmpty 
                              ? AppTheme.textSecondaryColor
                              : AppTheme.successColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${activeBuses.length} active',
                          style: TextStyle(
                            fontSize: 12,
                            color: activeBuses.isEmpty 
                                ? AppTheme.textSecondaryColor
                                : AppTheme.successColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${route.distance.toStringAsFixed(1)} km • ${route.estimatedDuration.inMinutes} min',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const Spacer(),
                  if (activeBuses.isNotEmpty)
                    Text(
                      'Next: ${_getNextBusETA(activeBuses.first)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route,
            size: 64,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'favorites' 
                ? 'No favorite routes yet'
                : 'No routes found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'favorites'
                ? 'Add routes to favorites by tapping the heart icon'
                : 'Try adjusting your filter or search criteria',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondaryColor.withOpacity(0.7),
            ),
          ),
          if (_selectedFilter == 'favorites') ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'all';
                });
              },
              child: const Text('Browse All Routes'),
            ),
          ],
        ],
      ),
    );
  }

  void _toggleFavorite(String routeId, AppStateProviderMinimal appState) async {
    if (appState.isRouteFavorite(routeId)) {
      await appState.removeFromFavorites(routeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: AppTheme.infoColor,
          ),
        );
      }
    } else {
      await appState.addToFavorites(routeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to favorites'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  void _showRouteDetails(RouteModel route, List<BusModel> buses, AppStateProviderMinimal appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Route header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              route.routeNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              route.routeName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Active buses
                      const Text(
                        'Active Buses',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      if (buses.isEmpty)
                        const Text('No buses currently active on this route')
                      else
                        ...buses.map((bus) => _buildBusListItem(bus)),
                      
                      const SizedBox(height: 20),
                      
                      // Route stops
                      const Text(
                        'Bus Stops',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      ...route.stops.asMap().entries.map((entry) {
                        final index = entry.key;
                        final stop = entry.value;
                        final isLast = index == route.stops.length - 1;
                        
                        return _buildStopListItem(stop, isLast);
                      }),
                      
                      const SizedBox(height: 20),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                appState.selectRoute(route);
                                DefaultTabController.of(context).animateTo(1);
                              },
                              icon: const Icon(Icons.map),
                              label: const Text('View on Map'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _toggleFavorite(route.id, appState),
                              icon: Icon(
                                appState.isRouteFavorite(route.id)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                              ),
                              label: Text(
                                appState.isRouteFavorite(route.id)
                                    ? 'Unfavorite'
                                    : 'Favorite',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusListItem(BusModel bus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bus.status == 'active' 
                  ? AppTheme.successColor.withOpacity(0.1)
                  : AppTheme.textSecondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.directions_bus,
              color: bus.status == 'active' 
                  ? AppTheme.successColor
                  : AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bus.busNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'ETA: ${_getNextBusETA(bus)}',
                  style: const TextStyle(
                    fontSize: 12,
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
    );
  }

  Widget _buildStopListItem(BusStop stop, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: stop.isTerminal ? AppTheme.primaryColor : AppTheme.successColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (stop.estimatedArrivalFromStart != null)
                  Text(
                    '${stop.estimatedArrivalFromStart!.inMinutes} min from start',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getNextBusETA(BusModel bus) {
    // Mock ETA calculation - in real app, this would use actual calculations
    return '${5 + (bus.hashCode % 10)} min';
  }

  int _getActiveBusCount(AppStateProviderMinimal appState) {
    return appState.activeBuses.where((bus) => bus.status == 'active').length;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort Routes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Alphabetical'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('By Frequency'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.straighten),
              title: const Text('By Distance'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.near_me),
              title: const Text('Nearest First'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
