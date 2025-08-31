class BusModel {
  final String id;
  final String busNumber;
  final String? routeId;
  final double latitude;
  final double longitude;
  final String status; // active, inactive, maintenance
  final int? passengerCount;
  final String? driverId;
  final DateTime lastUpdated;
  final DateTime? sessionStarted;
  final DateTime? sessionEnded;
  final double? speed;
  final double? heading;

  BusModel({
    required this.id,
    required this.busNumber,
    this.routeId,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.passengerCount,
    this.driverId,
    required this.lastUpdated,
    this.sessionStarted,
    this.sessionEnded,
    this.speed,
    this.heading,
  });

  factory BusModel.fromJson(Map<String, dynamic> json, String id) {
    return BusModel(
      id: id,
      busNumber: json['busNumber'] ?? '',
      routeId: json['routeId'],
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'inactive',
      passengerCount: json['passengerCount'],
      driverId: json['driverId'],
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'])
          : DateTime.now(),
      sessionStarted: json['sessionStarted'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['sessionStarted'])
          : null,
      sessionEnded: json['sessionEnded'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['sessionEnded'])
          : null,
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busNumber': busNumber,
      'routeId': routeId,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'passengerCount': passengerCount,
      'driverId': driverId,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'sessionStarted': sessionStarted?.millisecondsSinceEpoch,
      'sessionEnded': sessionEnded?.millisecondsSinceEpoch,
      'speed': speed,
      'heading': heading,
    };
  }

  BusModel copyWith({
    String? busNumber,
    String? routeId,
    double? latitude,
    double? longitude,
    String? status,
    int? passengerCount,
    String? driverId,
    DateTime? lastUpdated,
    DateTime? sessionStarted,
    DateTime? sessionEnded,
    double? speed,
    double? heading,
  }) {
    return BusModel(
      id: id,
      busNumber: busNumber ?? this.busNumber,
      routeId: routeId ?? this.routeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      passengerCount: passengerCount ?? this.passengerCount,
      driverId: driverId ?? this.driverId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      sessionStarted: sessionStarted ?? this.sessionStarted,
      sessionEnded: sessionEnded ?? this.sessionEnded,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
    );
  }

  @override
  String toString() {
    return 'BusModel(id: $id, busNumber: $busNumber, status: $status, location: ($latitude, $longitude))';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
