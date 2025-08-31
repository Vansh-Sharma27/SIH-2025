import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'models/realtime_models.dart';

/// Advanced performance metrics for real-time monitoring
class EnhancedPerformanceMonitor {
  static final EnhancedPerformanceMonitor _instance = EnhancedPerformanceMonitor._internal();
  factory EnhancedPerformanceMonitor() => _instance;
  EnhancedPerformanceMonitor._internal();

  // Message path tracking
  final Map<String, MessagePath> _activeMessagePaths = {};
  final Queue<CompletedMessagePath> _completedPaths = Queue<CompletedMessagePath>();
  
  // Advanced metrics
  final Map<String, Queue<TimedMetric>> _timedMetrics = {};
  final Map<String, RollingAverage> _rollingAverages = {};
  final Map<String, ConnectionMetrics> _connectionMetrics = {};
  
  // Queue analysis
  final Map<String, QueueDepthHistory> _queueDepthHistory = {};
  
  // Streams
  final StreamController<PerformanceSnapshot> _snapshotStream = StreamController<PerformanceSnapshot>.broadcast();
  final StreamController<PerformanceAlert> _alertStream = StreamController<PerformanceAlert>.broadcast();
  
  // Configuration
  static const int _maxPathHistory = 1000;
  static const Duration _snapshotInterval = Duration(seconds: 1);
  static const Duration _alertCheckInterval = Duration(seconds: 5);
  
  // Thresholds
  static const double _latencyWarningThreshold = 500.0; // ms
  static const double _latencyCriticalThreshold = 1000.0; // ms
  static const double _dropRateWarningThreshold = 5.0; // %
  static const double _dropRateCriticalThreshold = 10.0; // %
  
  Timer? _snapshotTimer;
  Timer? _alertTimer;
  bool _isMonitoring = false;

  /// Start enhanced monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // Start snapshot generation
    _snapshotTimer = Timer.periodic(_snapshotInterval, (_) => _generateSnapshot());
    
    // Start alert checking
    _alertTimer = Timer.periodic(_alertCheckInterval, (_) => _checkAlerts());
    
    print('🚀 Enhanced Performance Monitor started');
  }

  /// Begin tracking a message path
  void beginMessagePath({
    required String messageId,
    required String source,
    required String destination,
    Map<String, dynamic>? metadata,
  }) {
    _activeMessagePaths[messageId] = MessagePath(
      messageId: messageId,
      source: source,
      destination: destination,
      startTime: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  /// Add a checkpoint to message path
  void addPathCheckpoint(String messageId, String checkpoint) {
    final path = _activeMessagePaths[messageId];
    if (path != null) {
      path.checkpoints.add(PathCheckpoint(
        name: checkpoint,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Complete tracking a message path
  void completeMessagePath(String messageId, {bool success = true, String? error}) {
    final path = _activeMessagePaths.remove(messageId);
    if (path == null) return;
    
    final completed = CompletedMessagePath(
      path: path,
      endTime: DateTime.now(),
      success: success,
      error: error,
    );
    
    _completedPaths.add(completed);
    while (_completedPaths.length > _maxPathHistory) {
      _completedPaths.removeFirst();
    }
    
    // Record latency metric
    _recordTimedMetric(
      'message_path_${path.source}_to_${path.destination}',
      completed.totalLatency.toDouble(),
    );
  }

  /// Record a timed metric
  void _recordTimedMetric(String key, double value) {
    _timedMetrics.putIfAbsent(key, () => Queue<TimedMetric>());
    
    final metric = TimedMetric(
      value: value,
      timestamp: DateTime.now(),
    );
    
    _timedMetrics[key]!.add(metric);
    
    // Update rolling average
    _rollingAverages.putIfAbsent(key, () => RollingAverage());
    _rollingAverages[key]!.add(value);
    
    // Maintain queue size
    while (_timedMetrics[key]!.length > 1000) {
      _timedMetrics[key]!.removeFirst();
    }
  }

  /// Track connection metrics
  void updateConnectionMetrics({
    required String connectionId,
    required bool isConnected,
    int? messagesReceived,
    int? messagesSent,
    int? reconnectCount,
    double? lastPingLatency,
  }) {
    _connectionMetrics.putIfAbsent(connectionId, () => ConnectionMetrics(
      connectionId: connectionId,
      firstSeen: DateTime.now(),
    ));
    
    final metrics = _connectionMetrics[connectionId]!;
    metrics.isConnected = isConnected;
    metrics.lastSeen = DateTime.now();
    
    if (messagesReceived != null) metrics.messagesReceived = messagesReceived;
    if (messagesSent != null) metrics.messagesSent = messagesSent;
    if (reconnectCount != null) metrics.reconnectCount = reconnectCount;
    if (lastPingLatency != null) metrics.lastPingLatency = lastPingLatency;
    
    if (isConnected && !metrics.wasConnected) {
      metrics.connectionCount++;
    }
    metrics.wasConnected = isConnected;
  }

  /// Track queue depth
  void updateQueueDepth(String queueName, int depth) {
    _queueDepthHistory.putIfAbsent(queueName, () => QueueDepthHistory(queueName));
    _queueDepthHistory[queueName]!.addMeasurement(depth);
  }

  /// Generate performance snapshot
  void _generateSnapshot() {
    final snapshot = PerformanceSnapshot(
      timestamp: DateTime.now(),
      messagePathStats: _calculateMessagePathStats(),
      connectionStats: _calculateConnectionStats(),
      queueStats: _calculateQueueStats(),
      systemHealth: _calculateSystemHealth(),
      alerts: _checkForAlerts(),
    );
    
    _snapshotStream.add(snapshot);
  }

  /// Calculate message path statistics
  Map<String, PathStatistics> _calculateMessagePathStats() {
    final stats = <String, PathStatistics>{};
    
    // Group completed paths by route
    final pathsByRoute = <String, List<CompletedMessagePath>>{};
    for (final path in _completedPaths) {
      final key = '${path.path.source}_to_${path.path.destination}';
      pathsByRoute.putIfAbsent(key, () => []).add(path);
    }
    
    // Calculate statistics for each route
    for (final entry in pathsByRoute.entries) {
      final paths = entry.value;
      final latencies = paths.map((p) => p.totalLatency.toDouble()).toList()..sort();
      
      stats[entry.key] = PathStatistics(
        totalMessages: paths.length,
        successfulMessages: paths.where((p) => p.success).length,
        averageLatency: _calculateAverage(latencies),
        p50Latency: _calculatePercentile(latencies, 0.5),
        p95Latency: _calculatePercentile(latencies, 0.95),
        p99Latency: _calculatePercentile(latencies, 0.99),
        minLatency: latencies.isNotEmpty ? latencies.first : 0,
        maxLatency: latencies.isNotEmpty ? latencies.last : 0,
      );
    }
    
    return stats;
  }

  /// Calculate connection statistics
  ConnectionStatistics _calculateConnectionStats() {
    final activeConnections = _connectionMetrics.values.where((c) => c.isConnected).length;
    final totalConnections = _connectionMetrics.length;
    
    final allLatencies = _connectionMetrics.values
        .where((c) => c.lastPingLatency != null)
        .map((c) => c.lastPingLatency!)
        .toList()..sort();
    
    return ConnectionStatistics(
      activeConnections: activeConnections,
      totalConnections: totalConnections,
      averagePingLatency: _calculateAverage(allLatencies),
      totalReconnects: _connectionMetrics.values.fold(0, (sum, c) => sum + c.reconnectCount),
      connectionStability: activeConnections > 0 ? activeConnections / totalConnections : 0,
    );
  }

  /// Calculate queue statistics
  Map<String, QueueStatistics> _calculateQueueStats() {
    final stats = <String, QueueStatistics>{};
    
    for (final entry in _queueDepthHistory.entries) {
      final history = entry.value;
      stats[entry.key] = QueueStatistics(
        currentDepth: history.currentDepth,
        averageDepth: history.averageDepth,
        maxDepth: history.maxDepth,
        growthRate: history.growthRate,
      );
    }
    
    return stats;
  }

  /// Calculate system health score
  SystemHealth _calculateSystemHealth() {
    // Get recent metrics
    final recentPaths = _completedPaths.where((p) => 
      DateTime.now().difference(p.endTime) < const Duration(minutes: 1)
    ).toList();
    
    if (recentPaths.isEmpty) {
      return SystemHealth.unknown;
    }
    
    // Calculate success rate
    final successRate = recentPaths.where((p) => p.success).length / recentPaths.length * 100;
    
    // Calculate average latency
    final avgLatency = recentPaths.map((p) => p.totalLatency).reduce((a, b) => a + b) / recentPaths.length;
    
    // Determine health
    if (successRate > 95 && avgLatency < 100) {
      return SystemHealth.excellent;
    } else if (successRate > 90 && avgLatency < 500) {
      return SystemHealth.good;
    } else if (successRate > 80 && avgLatency < 1000) {
      return SystemHealth.fair;
    } else {
      return SystemHealth.poor;
    }
  }

  /// Check for alerts
  List<PerformanceAlert> _checkForAlerts() {
    final alerts = <PerformanceAlert>[];
    
    // Check latency alerts
    for (final entry in _rollingAverages.entries) {
      final avg = entry.value.average;
      if (avg > _latencyCriticalThreshold) {
        alerts.add(PerformanceAlert(
          type: AlertType.latencyCritical,
          metric: entry.key,
          value: avg,
          threshold: _latencyCriticalThreshold,
          message: 'Critical latency detected: ${avg.toStringAsFixed(0)}ms',
        ));
      } else if (avg > _latencyWarningThreshold) {
        alerts.add(PerformanceAlert(
          type: AlertType.latencyWarning,
          metric: entry.key,
          value: avg,
          threshold: _latencyWarningThreshold,
          message: 'High latency detected: ${avg.toStringAsFixed(0)}ms',
        ));
      }
    }
    
    // Check drop rate
    final pathStats = _calculateMessagePathStats();
    for (final entry in pathStats.entries) {
      final stats = entry.value;
      final dropRate = 100 - (stats.successfulMessages / stats.totalMessages * 100);
      
      if (dropRate > _dropRateCriticalThreshold) {
        alerts.add(PerformanceAlert(
          type: AlertType.dropRateCritical,
          metric: entry.key,
          value: dropRate,
          threshold: _dropRateCriticalThreshold,
          message: 'Critical drop rate: ${dropRate.toStringAsFixed(1)}%',
        ));
      } else if (dropRate > _dropRateWarningThreshold) {
        alerts.add(PerformanceAlert(
          type: AlertType.dropRateWarning,
          metric: entry.key,
          value: dropRate,
          threshold: _dropRateWarningThreshold,
          message: 'High drop rate: ${dropRate.toStringAsFixed(1)}%',
        ));
      }
    }
    
    return alerts;
  }

  /// Check alerts periodically
  void _checkAlerts() {
    final alerts = _checkForAlerts();
    for (final alert in alerts) {
      _alertStream.add(alert);
    }
  }

  /// Calculate average
  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Calculate percentile
  double _calculatePercentile(List<double> sortedValues, double percentile) {
    if (sortedValues.isEmpty) return 0;
    final index = (sortedValues.length * percentile).floor();
    return sortedValues[math.min(index, sortedValues.length - 1)];
  }

  /// Get performance snapshot stream
  Stream<PerformanceSnapshot> get snapshotStream => _snapshotStream.stream;

  /// Get alert stream
  Stream<PerformanceAlert> get alertStream => _alertStream.stream;

  /// Get current snapshot
  Future<PerformanceSnapshot> getCurrentSnapshot() async {
    _generateSnapshot();
    return _snapshotStream.stream.first;
  }

  /// Export metrics for analysis
  Map<String, dynamic> exportMetrics() {
    return {
      'exportTime': DateTime.now().toIso8601String(),
      'completedPaths': _completedPaths.map((p) => p.toJson()).toList(),
      'connectionMetrics': _connectionMetrics.map((k, v) => MapEntry(k, v.toJson())),
      'queueDepthHistory': _queueDepthHistory.map((k, v) => MapEntry(k, v.toJson())),
      'rollingAverages': _rollingAverages.map((k, v) => MapEntry(k, {
        'average': v.average,
        'count': v.count,
      })),
    };
  }

  /// Reset all metrics
  void reset() {
    _activeMessagePaths.clear();
    _completedPaths.clear();
    _timedMetrics.clear();
    _rollingAverages.clear();
    _connectionMetrics.clear();
    _queueDepthHistory.clear();
    
    print('🔄 Enhanced performance metrics reset');
  }

  /// Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _snapshotTimer?.cancel();
    _alertTimer?.cancel();
    
    print('🛑 Enhanced Performance Monitor stopped');
  }

  /// Clean up resources
  void dispose() {
    stopMonitoring();
    _snapshotStream.close();
    _alertStream.close();
  }
}

// Supporting classes

class MessagePath {
  final String messageId;
  final String source;
  final String destination;
  final DateTime startTime;
  final List<PathCheckpoint> checkpoints = [];
  final Map<String, dynamic> metadata;

  MessagePath({
    required this.messageId,
    required this.source,
    required this.destination,
    required this.startTime,
    required this.metadata,
  });
}

class PathCheckpoint {
  final String name;
  final DateTime timestamp;

  PathCheckpoint({
    required this.name,
    required this.timestamp,
  });
}

class CompletedMessagePath {
  final MessagePath path;
  final DateTime endTime;
  final bool success;
  final String? error;

  CompletedMessagePath({
    required this.path,
    required this.endTime,
    required this.success,
    this.error,
  });

  int get totalLatency => endTime.difference(path.startTime).inMilliseconds;

  Map<String, dynamic> toJson() => {
    'messageId': path.messageId,
    'source': path.source,
    'destination': path.destination,
    'startTime': path.startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'totalLatency': totalLatency,
    'success': success,
    'error': error,
    'checkpoints': path.checkpoints.map((c) => {
      'name': c.name,
      'timestamp': c.timestamp.toIso8601String(),
    }).toList(),
    'metadata': path.metadata,
  };
}

class TimedMetric {
  final double value;
  final DateTime timestamp;

  TimedMetric({
    required this.value,
    required this.timestamp,
  });
}

class RollingAverage {
  final int windowSize;
  final Queue<double> _values = Queue<double>();
  double _sum = 0;

  RollingAverage({this.windowSize = 100});

  void add(double value) {
    _values.add(value);
    _sum += value;

    while (_values.length > windowSize) {
      _sum -= _values.removeFirst();
    }
  }

  double get average => _values.isEmpty ? 0 : _sum / _values.length;
  int get count => _values.length;
}

class ConnectionMetrics {
  final String connectionId;
  final DateTime firstSeen;
  DateTime lastSeen;
  bool isConnected = false;
  bool wasConnected = false;
  int messagesReceived = 0;
  int messagesSent = 0;
  int reconnectCount = 0;
  int connectionCount = 0;
  double? lastPingLatency;

  ConnectionMetrics({
    required this.connectionId,
    required this.firstSeen,
  }) : lastSeen = firstSeen;

  Map<String, dynamic> toJson() => {
    'connectionId': connectionId,
    'firstSeen': firstSeen.toIso8601String(),
    'lastSeen': lastSeen.toIso8601String(),
    'isConnected': isConnected,
    'messagesReceived': messagesReceived,
    'messagesSent': messagesSent,
    'reconnectCount': reconnectCount,
    'connectionCount': connectionCount,
    'lastPingLatency': lastPingLatency,
    'uptime': isConnected ? DateTime.now().difference(firstSeen).inSeconds : 0,
  };
}

class QueueDepthHistory {
  final String queueName;
  final Queue<QueueMeasurement> measurements = Queue<QueueMeasurement>();
  int maxDepth = 0;

  QueueDepthHistory(this.queueName);

  void addMeasurement(int depth) {
    measurements.add(QueueMeasurement(
      depth: depth,
      timestamp: DateTime.now(),
    ));

    if (depth > maxDepth) maxDepth = depth;

    // Keep only last 1000 measurements
    while (measurements.length > 1000) {
      measurements.removeFirst();
    }
  }

  int get currentDepth => measurements.isEmpty ? 0 : measurements.last.depth;

  double get averageDepth {
    if (measurements.isEmpty) return 0;
    final sum = measurements.fold(0, (sum, m) => sum + m.depth);
    return sum / measurements.length;
  }

  double get growthRate {
    if (measurements.length < 2) return 0;
    
    final recent = measurements.toList().reversed.take(10).toList();
    if (recent.length < 2) return 0;
    
    final firstDepth = recent.last.depth;
    final lastDepth = recent.first.depth;
    final timeDiff = recent.first.timestamp.difference(recent.last.timestamp).inSeconds;
    
    if (timeDiff == 0) return 0;
    return (lastDepth - firstDepth) / timeDiff;
  }

  Map<String, dynamic> toJson() => {
    'queueName': queueName,
    'currentDepth': currentDepth,
    'averageDepth': averageDepth,
    'maxDepth': maxDepth,
    'growthRate': growthRate,
    'measurementCount': measurements.length,
  };
}

class QueueMeasurement {
  final int depth;
  final DateTime timestamp;

  QueueMeasurement({
    required this.depth,
    required this.timestamp,
  });
}

// Performance snapshot models

class PerformanceSnapshot {
  final DateTime timestamp;
  final Map<String, PathStatistics> messagePathStats;
  final ConnectionStatistics connectionStats;
  final Map<String, QueueStatistics> queueStats;
  final SystemHealth systemHealth;
  final List<PerformanceAlert> alerts;

  PerformanceSnapshot({
    required this.timestamp,
    required this.messagePathStats,
    required this.connectionStats,
    required this.queueStats,
    required this.systemHealth,
    required this.alerts,
  });
}

class PathStatistics {
  final int totalMessages;
  final int successfulMessages;
  final double averageLatency;
  final double p50Latency;
  final double p95Latency;
  final double p99Latency;
  final double minLatency;
  final double maxLatency;

  PathStatistics({
    required this.totalMessages,
    required this.successfulMessages,
    required this.averageLatency,
    required this.p50Latency,
    required this.p95Latency,
    required this.p99Latency,
    required this.minLatency,
    required this.maxLatency,
  });

  double get successRate => totalMessages > 0 ? successfulMessages / totalMessages * 100 : 100;
}

class ConnectionStatistics {
  final int activeConnections;
  final int totalConnections;
  final double averagePingLatency;
  final int totalReconnects;
  final double connectionStability;

  ConnectionStatistics({
    required this.activeConnections,
    required this.totalConnections,
    required this.averagePingLatency,
    required this.totalReconnects,
    required this.connectionStability,
  });
}

class QueueStatistics {
  final int currentDepth;
  final double averageDepth;
  final int maxDepth;
  final double growthRate;

  QueueStatistics({
    required this.currentDepth,
    required this.averageDepth,
    required this.maxDepth,
    required this.growthRate,
  });
}

enum SystemHealth {
  excellent,
  good,
  fair,
  poor,
  unknown,
}

class PerformanceAlert {
  final AlertType type;
  final String metric;
  final double value;
  final double threshold;
  final String message;
  final DateTime timestamp;

  PerformanceAlert({
    required this.type,
    required this.metric,
    required this.value,
    required this.threshold,
    required this.message,
  }) : timestamp = DateTime.now();
}

enum AlertType {
  latencyWarning,
  latencyCritical,
  dropRateWarning,
  dropRateCritical,
  queueOverflow,
  connectionInstability,
}
