// Mock Real-time Communication Models
// These models define the data contracts for the simulated WebSocket-like real-time system

import 'dart:convert';

/// Topic identifier for bus route subscriptions
class BusRouteTopic {
  final String routeId;
  final String topicName;
  final DateTime createdAt;
  final Set<String> subscribers;

  BusRouteTopic({
    required this.routeId,
    String? topicName,
    DateTime? createdAt,
    Set<String>? subscribers,
  })  : topicName = topicName ?? 'route_$routeId',
        createdAt = createdAt ?? DateTime.now(),
        subscribers = subscribers ?? {};

  bool hasSubscriber(String clientId) => subscribers.contains(clientId);
  
  void addSubscriber(String clientId) => subscribers.add(clientId);
  
  void removeSubscriber(String clientId) => subscribers.remove(clientId);
  
  int get subscriberCount => subscribers.length;
}

/// Message sent by driver app with location and status updates
class DriverMessage {
  final String messageId;
  final String busId;
  final String routeId;
  final String driverId;
  final double latitude;
  final double longitude;
  final double? speed; // km/h
  final double? heading; // degrees
  final int? passengerCount;
  final String? crowdLevel; // low, medium, high
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  DriverMessage({
    String? messageId,
    required this.busId,
    required this.routeId,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    this.passengerCount,
    this.crowdLevel,
    DateTime? timestamp,
    this.metadata,
  })  : messageId = messageId ?? _generateMessageId(),
        timestamp = timestamp ?? DateTime.now();

  static String _generateMessageId() {
    return 'drv_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
  }

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'type': 'driver_update',
    'busId': busId,
    'routeId': routeId,
    'driverId': driverId,
    'location': {
      'latitude': latitude,
      'longitude': longitude,
    },
    'speed': speed,
    'heading': heading,
    'passengerCount': passengerCount,
    'crowdLevel': crowdLevel,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  factory DriverMessage.fromJson(Map<String, dynamic> json) {
    return DriverMessage(
      messageId: json['messageId'],
      busId: json['busId'],
      routeId: json['routeId'],
      driverId: json['driverId'],
      latitude: json['location']['latitude'],
      longitude: json['location']['longitude'],
      speed: json['speed'],
      heading: json['heading'],
      passengerCount: json['passengerCount'],
      crowdLevel: json['crowdLevel'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }
}

/// Message sent by passenger app (feedback, boarding status, etc.)
class PassengerMessage {
  final String messageId;
  final String passengerId;
  final String? busId;
  final String? routeId;
  final MessageType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  PassengerMessage({
    String? messageId,
    required this.passengerId,
    this.busId,
    this.routeId,
    required this.type,
    required this.payload,
    DateTime? timestamp,
  })  : messageId = messageId ?? _generateMessageId(),
        timestamp = timestamp ?? DateTime.now();

  static String _generateMessageId() {
    return 'psg_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
  }

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'type': type.toString().split('.').last,
    'passengerId': passengerId,
    'busId': busId,
    'routeId': routeId,
    'payload': payload,
    'timestamp': timestamp.toIso8601String(),
  };

  factory PassengerMessage.fromJson(Map<String, dynamic> json) {
    return PassengerMessage(
      messageId: json['messageId'],
      passengerId: json['passengerId'],
      busId: json['busId'],
      routeId: json['routeId'],
      type: MessageType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
        orElse: () => MessageType.unknown,
      ),
      payload: json['payload'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

enum MessageType {
  boarding,
  alighting,
  crowdingReport,
  delayReport,
  feedback,
  routeSubscribe,
  routeUnsubscribe,
  unknown,
}

/// Wrapper for messages in the offline queue
class QueuedEnvelope {
  final String envelopeId;
  final String clientId;
  final dynamic message; // Can be DriverMessage or PassengerMessage
  final DateTime queuedAt;
  final int retryCount;
  final DateTime? nextRetryAt;
  final QueuePriority priority;
  final String? targetTopic;

  QueuedEnvelope({
    String? envelopeId,
    required this.clientId,
    required this.message,
    DateTime? queuedAt,
    this.retryCount = 0,
    this.nextRetryAt,
    this.priority = QueuePriority.normal,
    this.targetTopic,
  })  : envelopeId = envelopeId ?? _generateEnvelopeId(),
        queuedAt = queuedAt ?? DateTime.now();

  static String _generateEnvelopeId() {
    return 'env_${DateTime.now().millisecondsSinceEpoch}';
  }

  QueuedEnvelope copyWithRetry({required DateTime nextRetryAt}) {
    return QueuedEnvelope(
      envelopeId: envelopeId,
      clientId: clientId,
      message: message,
      queuedAt: queuedAt,
      retryCount: retryCount + 1,
      nextRetryAt: nextRetryAt,
      priority: priority,
      targetTopic: targetTopic,
    );
  }

  bool get canRetry => retryCount < 5; // Max 5 retries

  Duration get age => DateTime.now().difference(queuedAt);

  Map<String, dynamic> toJson() => {
    'envelopeId': envelopeId,
    'clientId': clientId,
    'message': message is DriverMessage 
        ? (message as DriverMessage).toJson()
        : (message as PassengerMessage).toJson(),
    'messageType': message is DriverMessage ? 'driver' : 'passenger',
    'queuedAt': queuedAt.toIso8601String(),
    'retryCount': retryCount,
    'nextRetryAt': nextRetryAt?.toIso8601String(),
    'priority': priority.toString().split('.').last,
    'targetTopic': targetTopic,
  };
}

enum QueuePriority {
  high,    // Emergency messages, critical updates
  normal,  // Regular location updates
  low,     // Analytics, non-critical feedback
}

/// Performance metrics for monitoring
class PerfMetric {
  final String metricId;
  final MetricType type;
  final String operation;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic>? tags;

  PerfMetric({
    String? metricId,
    required this.type,
    required this.operation,
    required this.value,
    this.unit = 'ms',
    DateTime? timestamp,
    this.tags,
  })  : metricId = metricId ?? _generateMetricId(),
        timestamp = timestamp ?? DateTime.now();

  static String _generateMetricId() {
    return 'perf_${DateTime.now().millisecondsSinceEpoch}';
  }

  Map<String, dynamic> toJson() => {
    'metricId': metricId,
    'type': type.toString().split('.').last,
    'operation': operation,
    'value': value,
    'unit': unit,
    'timestamp': timestamp.toIso8601String(),
    'tags': tags,
  };

  @override
  String toString() => '$operation: ${value.toStringAsFixed(2)}$unit';
}

enum MetricType {
  latency,
  throughput,
  queueSize,
  dropRate,
  connectionCount,
}

/// Connection state for WebSocket simulation
class ConnectionState {
  final String clientId;
  final bool isConnected;
  final DateTime? connectedAt;
  final DateTime? disconnectedAt;
  final int messagesReceived;
  final int messagesSent;
  final double averageLatency;

  ConnectionState({
    required this.clientId,
    required this.isConnected,
    this.connectedAt,
    this.disconnectedAt,
    this.messagesReceived = 0,
    this.messagesSent = 0,
    this.averageLatency = 0.0,
  });

  ConnectionState copyWith({
    bool? isConnected,
    DateTime? connectedAt,
    DateTime? disconnectedAt,
    int? messagesReceived,
    int? messagesSent,
    double? averageLatency,
  }) {
    return ConnectionState(
      clientId: clientId,
      isConnected: isConnected ?? this.isConnected,
      connectedAt: connectedAt ?? this.connectedAt,
      disconnectedAt: disconnectedAt ?? this.disconnectedAt,
      messagesReceived: messagesReceived ?? this.messagesReceived,
      messagesSent: messagesSent ?? this.messagesSent,
      averageLatency: averageLatency ?? this.averageLatency,
    );
  }

  Duration? get connectionDuration {
    if (connectedAt == null) return null;
    final endTime = disconnectedAt ?? DateTime.now();
    return endTime.difference(connectedAt!);
  }
}

/// Quality of Service levels for message delivery
enum QoS {
  atMostOnce,   // Fire and forget (0)
  atLeastOnce,  // Acknowledged delivery (1)
  exactlyOnce,  // Guaranteed unique delivery (2)
}
