class RouteModel {
  final String id;
  final String routeName;
  final String routeNumber;
  final List<BusStop> stops;
  final List<RouteLatLng> pathCoordinates;
  final double distance; // in kilometers
  final Duration estimatedDuration;
  final String startPoint;
  final String endPoint;
  final bool isActive;
  final Map<String, dynamic>? schedule; // Optional schedule data

  RouteModel({
    required this.id,
    required this.routeName,
    required this.routeNumber,
    required this.stops,
    required this.pathCoordinates,
    required this.distance,
    required this.estimatedDuration,
    required this.startPoint,
    required this.endPoint,
    this.isActive = true,
    this.schedule,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json, String id) {
    final stopsData = json['stops'] as List<dynamic>? ?? [];
    final pathData = json['pathCoordinates'] as List<dynamic>? ?? [];
    
    return RouteModel(
      id: id,
      routeName: json['routeName'] ?? '',
      routeNumber: json['routeNumber'] ?? '',
      stops: stopsData.map((stop) => BusStop.fromJson(stop)).toList(),
      pathCoordinates: pathData.map((coord) => RouteLatLng.fromJson(coord)).toList(),
      distance: (json['distance'] ?? 0.0).toDouble(),
      estimatedDuration: Duration(minutes: json['estimatedDurationMinutes'] ?? 0),
      startPoint: json['startPoint'] ?? '',
      endPoint: json['endPoint'] ?? '',
      isActive: json['isActive'] ?? true,
      schedule: json['schedule'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routeName': routeName,
      'routeNumber': routeNumber,
      'stops': stops.map((stop) => stop.toJson()).toList(),
      'pathCoordinates': pathCoordinates.map((coord) => coord.toJson()).toList(),
      'distance': distance,
      'estimatedDurationMinutes': estimatedDuration.inMinutes,
      'startPoint': startPoint,
      'endPoint': endPoint,
      'isActive': isActive,
      'schedule': schedule,
    };
  }

  @override
  String toString() {
    return 'RouteModel(id: $id, routeName: $routeName, routeNumber: $routeNumber)';
  }
}

class BusStop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int sequenceNumber;
  final Duration? estimatedArrivalFromStart;
  final bool isTerminal;

  BusStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.sequenceNumber,
    this.estimatedArrivalFromStart,
    this.isTerminal = false,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      sequenceNumber: json['sequenceNumber'] ?? 0,
      estimatedArrivalFromStart: json['estimatedArrivalMinutes'] != null 
          ? Duration(minutes: json['estimatedArrivalMinutes'])
          : null,
      isTerminal: json['isTerminal'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'sequenceNumber': sequenceNumber,
      'estimatedArrivalMinutes': estimatedArrivalFromStart?.inMinutes,
      'isTerminal': isTerminal,
    };
  }

  @override
  String toString() {
    return 'BusStop(id: $id, name: $name, sequence: $sequenceNumber)';
  }
}

class RouteLatLng {
  final double latitude;
  final double longitude;

  RouteLatLng({
    required this.latitude,
    required this.longitude,
  });

  factory RouteLatLng.fromJson(Map<String, dynamic> json) {
    return RouteLatLng(
      latitude: (json['lat'] ?? 0.0).toDouble(),
      longitude: (json['lng'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lng': longitude,
    };
  }

  @override
  String toString() {
    return 'RouteLatLng(lat: $latitude, lng: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteLatLng && 
           other.latitude == latitude && 
           other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}
