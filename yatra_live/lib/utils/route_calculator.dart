import 'dart:math' as math;
import '../models/bus_model.dart';
import '../models/route_model.dart';

class RouteCalculator {
  static const double earthRadiusKm = 6371.0;

  // Calculate distance between two coordinates using Haversine formula
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lng2 - lng1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
        math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) *
        math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }
  
  static double _toRadians(double degrees) => degrees * math.pi / 180;

  // Calculate bearing between two points
  static double calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final deltaLng = (lng2 - lng1) * math.pi / 180;

    final y = math.sin(deltaLng) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) - 
              math.sin(phi1) * math.cos(phi2) * math.cos(deltaLng);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360; // Normalize to 0-360 degrees
  }

  // Find the nearest stop to a given position
  static BusStop? findNearestStop(double latitude, double longitude, List<BusStop> stops) {
    if (stops.isEmpty) return null;

    BusStop nearestStop = stops.first;
    double minDistance = calculateDistance(
      latitude, longitude,
      nearestStop.latitude, nearestStop.longitude,
    );

    for (final stop in stops.skip(1)) {
      final distance = calculateDistance(
        latitude, longitude,
        stop.latitude, stop.longitude,
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestStop = stop;
      }
    }

    return nearestStop;
  }

  // Calculate progress along route (0.0 to 1.0)
  static double calculateRouteProgress(BusModel bus, RouteModel route) {
    if (route.stops.isEmpty) return 0.0;

    final nearestStop = findNearestStop(
      bus.latitude, 
      bus.longitude, 
      route.stops,
    );

    if (nearestStop == null) return 0.0;

    // Simple progress based on stop sequence
    final progress = (nearestStop.sequenceNumber - 1) / (route.stops.length - 1);
    return math.max(0.0, math.min(1.0, progress));
  }

  // Estimate arrival time at a specific stop
  static Duration estimateArrivalTime(
    BusModel bus,
    BusStop targetStop,
    RouteModel route, {
    double averageSpeedKmh = 25.0,
    double trafficFactor = 1.0,
  }) {
    // Find the nearest stop to current bus location
    final nearestStop = findNearestStop(
      bus.latitude,
      bus.longitude,
      route.stops,
    );

    if (nearestStop == null) {
      return const Duration(minutes: 0);
    }

    // Calculate remaining distance
    double remainingDistance = 0.0;

    // If bus hasn't reached the target stop yet
    if (nearestStop.sequenceNumber <= targetStop.sequenceNumber) {
      // Distance from bus to nearest stop
      remainingDistance += calculateDistance(
        bus.latitude,
        bus.longitude,
        nearestStop.latitude,
        nearestStop.longitude,
      );

      // Distance between stops
      for (int i = nearestStop.sequenceNumber; i < targetStop.sequenceNumber; i++) {
        if (i < route.stops.length) {
          final currentStop = route.stops[i - 1];
          final nextStop = route.stops[i];
          remainingDistance += calculateDistance(
            currentStop.latitude,
            currentStop.longitude,
            nextStop.latitude,
            nextStop.longitude,
          );
        }
      }
    }

    // Apply speed and traffic factors
    final effectiveSpeed = (bus.speed ?? averageSpeedKmh) * trafficFactor;
    final remainingDistanceKm = remainingDistance / 1000;
    
    // Add buffer time for stops
    final numberOfStops = math.max(0, targetStop.sequenceNumber - nearestStop.sequenceNumber);
    final stopBuffer = numberOfStops * 2; // 2 minutes per stop

    // Calculate time
    final travelTimeHours = remainingDistanceKm / effectiveSpeed;
    final totalMinutes = (travelTimeHours * 60) + stopBuffer;

    return Duration(minutes: totalMinutes.round());
  }

  // Get traffic factor based on time and day
  static double getTrafficFactor() {
    final now = DateTime.now();
    final hour = now.hour;
    final dayOfWeek = now.weekday;

    // Weekend traffic is generally lighter
    if (dayOfWeek >= 6) {
      if (hour >= 10 && hour <= 22) {
        return 0.8; // Moderate traffic on weekends
      } else {
        return 1.0; // Light traffic
      }
    }

    // Weekday traffic patterns
    if ((hour >= 7 && hour <= 10) || (hour >= 17 && hour <= 20)) {
      return 0.5; // Heavy traffic during rush hours
    } else if (hour >= 11 && hour <= 16) {
      return 0.7; // Moderate traffic during day
    } else {
      return 1.0; // Light traffic at night/early morning
    }
  }

  // Calculate ETA for all stops on a route
  static List<StopETA> calculateAllStopETAs(
    BusModel bus,
    RouteModel route, {
    double averageSpeedKmh = 25.0,
  }) {
    final trafficFactor = getTrafficFactor();
    final List<StopETA> etas = [];

    for (final stop in route.stops) {
      final eta = estimateArrivalTime(
        bus,
        stop,
        route,
        averageSpeedKmh: averageSpeedKmh,
        trafficFactor: trafficFactor,
      );

      etas.add(StopETA(
        stop: stop,
        eta: eta,
        estimatedArrivalTime: DateTime.now().add(eta),
      ));
    }

    return etas;
  }

  // Check if bus is moving in the correct direction
  static bool isBusOnCorrectPath(BusModel bus, RouteModel route) {
    if (route.pathCoordinates.length < 2) return true;

    final nearestPathPoint = findNearestPathPoint(
      bus.latitude,
      bus.longitude,
      route.pathCoordinates,
    );

    if (nearestPathPoint == null) return false;

    // Find the next point on the path
    final pathIndex = route.pathCoordinates.indexOf(nearestPathPoint);
    if (pathIndex >= route.pathCoordinates.length - 1) return true;

    final nextPoint = route.pathCoordinates[pathIndex + 1];
    
    // Calculate expected bearing
    final expectedBearing = calculateBearing(
      nearestPathPoint.latitude,
      nearestPathPoint.longitude,
      nextPoint.latitude,
      nextPoint.longitude,
    );

    // Compare with bus heading (allowing for some deviation)
    final busHeading = bus.heading ?? 0.0;
    final bearingDifference = (expectedBearing - busHeading).abs();
    
    return bearingDifference <= 45.0 || bearingDifference >= 315.0;
  }

  // Find nearest point on the route path
  static LatLng? findNearestPathPoint(
    double latitude,
    double longitude,
    List<LatLng> pathPoints,
  ) {
    if (pathPoints.isEmpty) return null;

    LatLng nearestPoint = pathPoints.first;
    double minDistance = calculateDistance(
      latitude, longitude,
      nearestPoint.latitude, nearestPoint.longitude,
    );

    for (final point in pathPoints.skip(1)) {
      final distance = calculateDistance(
        latitude, longitude,
        point.latitude, point.longitude,
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = point;
      }
    }

    return nearestPoint;
  }

  // Calculate route efficiency metrics
  static RouteMetrics calculateRouteMetrics(
    List<BusModel> busesOnRoute,
    RouteModel route,
  ) {
    if (busesOnRoute.isEmpty) {
      return RouteMetrics(
        averageSpeed: 0.0,
        onTimePerformance: 0.0,
        crowdingLevel: 'low',
        totalPassengers: 0,
        activeBuses: 0,
      );
    }

    final activeBuses = busesOnRoute.where((bus) => bus.status == 'active').toList();
    
    // Calculate average speed
    final speeds = activeBuses
        .where((bus) => bus.speed != null && bus.speed! > 0)
        .map((bus) => bus.speed!)
        .toList();
    
    final averageSpeed = speeds.isEmpty ? 0.0 : speeds.reduce((a, b) => a + b) / speeds.length;

    // Calculate total passengers
    final totalPassengers = busesOnRoute.fold(0, (sum, bus) => sum + (bus.passengerCount ?? 0));

    // Determine overall crowding level
    final averagePassengers = activeBuses.isEmpty ? 0 : totalPassengers / activeBuses.length;
    String crowdingLevel = 'low';
    if (averagePassengers > 30) {
      crowdingLevel = 'high';
    } else if (averagePassengers > 15) {
      crowdingLevel = 'medium';
    }

    return RouteMetrics(
      averageSpeed: averageSpeed,
      onTimePerformance: 0.85, // This would be calculated based on schedule data
      crowdingLevel: crowdingLevel,
      totalPassengers: totalPassengers,
      activeBuses: activeBuses.length,
    );
  }
}

// Helper classes
class StopETA {
  final BusStop stop;
  final Duration eta;
  final DateTime estimatedArrivalTime;

  StopETA({
    required this.stop,
    required this.eta,
    required this.estimatedArrivalTime,
  });

  @override
  String toString() {
    return 'StopETA(stop: ${stop.name}, eta: ${eta.inMinutes} min)';
  }
}

class RouteMetrics {
  final double averageSpeed;
  final double onTimePerformance;
  final String crowdingLevel;
  final int totalPassengers;
  final int activeBuses;

  RouteMetrics({
    required this.averageSpeed,
    required this.onTimePerformance,
    required this.crowdingLevel,
    required this.totalPassengers,
    required this.activeBuses,
  });

  @override
  String toString() {
    return 'RouteMetrics(avgSpeed: ${averageSpeed.toStringAsFixed(1)} km/h, '
           'onTime: ${(onTimePerformance * 100).toStringAsFixed(1)}%, '
           'crowding: $crowdingLevel, '
           'passengers: $totalPassengers, '
           'buses: $activeBuses)';
  }
}
