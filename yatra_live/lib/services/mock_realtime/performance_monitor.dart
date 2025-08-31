import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'models/realtime_models.dart';

/// Monitors and reports real-time performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // Metric tracking
  final Map<String, Queue<PerfMetric>> _metricQueues = {};
  final Map<String, Stopwatch> _activeStopwatches = {};
  final StreamController<PerfMetric> _metricStream = StreamController<PerfMetric>.broadcast();
  final StreamController<Map<String, dynamic>> _dashboardStream = StreamController<Map<String, dynamic>>.broadcast();
  
  // Configuration
  static const int _maxMetricsPerType = 1000;
  static const Duration _aggregationInterval = Duration(seconds: 30);
  static const Duration _dashboardUpdateInterval = Duration(seconds: 1);
  
  // Counters
  int _totalMessages = 0;
  int _droppedMessages = 0;
  int _successfulDeliveries = 0;
  int _activeConnections = 0;
  
  Timer? _aggregationTimer;
  Timer? _dashboardTimer;
  bool _isMonitoring = false;

  /// Start monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // Start aggregation timer
    _aggregationTimer = Timer.periodic(_aggregationInterval, (_) => _aggregateMetrics());
    
    // Start dashboard update timer
    _dashboardTimer = Timer.periodic(_dashboardUpdateInterval, (_) => _updateDashboard());
    
    print('📊 PerformanceMonitor started');
  }

  /// Record a metric
  void recordMetric(PerfMetric metric) {
    // Add to appropriate queue
    final key = '${metric.type}_${metric.operation}';
    _metricQueues.putIfAbsent(key, () => Queue<PerfMetric>());
    
    final queue = _metricQueues[key]!;
    queue.add(metric);
    
    // Maintain queue size
    while (queue.length > _maxMetricsPerType) {
      queue.removeFirst();
    }
    
    // Emit to stream
    _metricStream.add(metric);
    
    // Update counters based on metric type
    _updateCounters(metric);
  }

  /// Start timing an operation
  void startOperation(String operationId) {
    _activeStopwatches[operationId] = Stopwatch()..start();
  }

  /// End timing and record latency
  void endOperation(String operationId, String operationName, {Map<String, dynamic>? tags}) {
    final stopwatch = _activeStopwatches.remove(operationId);
    if (stopwatch == null) return;
    
    stopwatch.stop();
    
    recordMetric(PerfMetric(
      type: MetricType.latency,
      operation: operationName,
      value: stopwatch.elapsedMilliseconds.toDouble(),
      tags: tags,
    ));
  }

  /// Record throughput
  void recordThroughput(String operation, double messagesPerSecond) {
    recordMetric(PerfMetric(
      type: MetricType.throughput,
      operation: operation,
      value: messagesPerSecond,
      unit: 'msg/s',
    ));
  }

  /// Record queue size
  void recordQueueSize(String queueName, int size) {
    recordMetric(PerfMetric(
      type: MetricType.queueSize,
      operation: queueName,
      value: size.toDouble(),
      unit: 'messages',
    ));
  }

  /// Record message delivery
  void recordDelivery({required bool success, String? reason}) {
    _totalMessages++;
    if (success) {
      _successfulDeliveries++;
    } else {
      _droppedMessages++;
    }
    
    recordMetric(PerfMetric(
      type: MetricType.dropRate,
      operation: 'message_delivery',
      value: success ? 0.0 : 1.0,
      tags: {'reason': reason},
    ));
  }

  /// Update connection count
  void updateConnectionCount(int count) {
    _activeConnections = count;
    recordMetric(PerfMetric(
      type: MetricType.connectionCount,
      operation: 'websocket',
      value: count.toDouble(),
      unit: 'connections',
    ));
  }

  /// Get metrics stream
  Stream<PerfMetric> get metricStream => _metricStream.stream;

  /// Get dashboard stream
  Stream<Map<String, dynamic>> get dashboardStream => _dashboardStream.stream;

  /// Calculate statistics for a metric type
  Map<String, dynamic> calculateStats(MetricType type, String operation) {
    final key = '${type}_$operation';
    final metrics = _metricQueues[key]?.toList() ?? [];
    
    if (metrics.isEmpty) {
      return {
        'count': 0,
        'average': 0.0,
        'min': 0.0,
        'max': 0.0,
        'p50': 0.0,
        'p95': 0.0,
        'p99': 0.0,
      };
    }
    
    final values = metrics.map((m) => m.value).toList()..sort();
    final count = values.length;
    final sum = values.reduce((a, b) => a + b);
    
    return {
      'count': count,
      'average': sum / count,
      'min': values.first,
      'max': values.last,
      'p50': _percentile(values, 0.50),
      'p95': _percentile(values, 0.95),
      'p99': _percentile(values, 0.99),
      'recent': values.length > 10 ? values.sublist(values.length - 10) : values,
    };
  }

  /// Calculate percentile
  double _percentile(List<double> sortedValues, double percentile) {
    if (sortedValues.isEmpty) return 0.0;
    
    final index = (sortedValues.length * percentile).floor();
    return sortedValues[math.min(index, sortedValues.length - 1)];
  }

  /// Update counters based on metric
  void _updateCounters(PerfMetric metric) {
    // Additional counter updates based on metric type
    if (metric.type == MetricType.throughput) {
      // Track overall throughput
    }
  }

  /// Aggregate metrics periodically
  void _aggregateMetrics() {
    final now = DateTime.now();
    
    // Calculate aggregated metrics
    final latencyStats = calculateStats(MetricType.latency, 'websocket');
    final throughputStats = calculateStats(MetricType.throughput, 'route_publish');
    
    // Log summary
    print('📊 Performance Summary (${now.toIso8601String()}):');
    print('  Latency: avg=${latencyStats['average']?.toStringAsFixed(1)}ms, p95=${latencyStats['p95']?.toStringAsFixed(1)}ms');
    print('  Messages: total=$_totalMessages, delivered=$_successfulDeliveries, dropped=$_droppedMessages');
    print('  Connections: $_activeConnections active');
    
    // Calculate delivery rate
    final deliveryRate = _totalMessages > 0 
        ? (_successfulDeliveries / _totalMessages * 100) 
        : 100.0;
    print('  Delivery Rate: ${deliveryRate.toStringAsFixed(1)}%');
  }

  /// Update dashboard data
  void _updateDashboard() {
    final latencyStats = calculateStats(MetricType.latency, 'websocket');
    final throughputStats = calculateStats(MetricType.throughput, 'route_publish');
    final queueStats = calculateStats(MetricType.queueSize, 'offline_queue');
    
    final deliveryRate = _totalMessages > 0 
        ? (_successfulDeliveries / _totalMessages * 100) 
        : 100.0;
    
    final dashboard = {
      'timestamp': DateTime.now().toIso8601String(),
      'connections': _activeConnections,
      'latency': {
        'current': latencyStats['recent'] is List && (latencyStats['recent'] as List).isNotEmpty
            ? (latencyStats['recent'] as List).last
            : 0.0,
        'average': latencyStats['average'],
        'p95': latencyStats['p95'],
        'p99': latencyStats['p99'],
      },
      'throughput': {
        'current': throughputStats['recent'] is List && (throughputStats['recent'] as List).isNotEmpty
            ? (throughputStats['recent'] as List).last
            : 0.0,
        'average': throughputStats['average'],
      },
      'delivery': {
        'total': _totalMessages,
        'successful': _successfulDeliveries,
        'dropped': _droppedMessages,
        'rate': deliveryRate,
      },
      'queues': {
        'size': queueStats['recent'] is List && (queueStats['recent'] as List).isNotEmpty
            ? (queueStats['recent'] as List).last
            : 0.0,
        'average': queueStats['average'],
      },
      'health': _calculateHealthScore(),
    };
    
    _dashboardStream.add(dashboard);
  }

  /// Calculate overall system health score
  String _calculateHealthScore() {
    final latencyStats = calculateStats(MetricType.latency, 'websocket');
    final avgLatency = latencyStats['average'] as double? ?? 0.0;
    final deliveryRate = _totalMessages > 0 
        ? (_successfulDeliveries / _totalMessages * 100) 
        : 100.0;
    
    if (avgLatency < 100 && deliveryRate > 95) {
      return 'excellent';
    } else if (avgLatency < 500 && deliveryRate > 90) {
      return 'good';
    } else if (avgLatency < 1000 && deliveryRate > 80) {
      return 'fair';
    } else {
      return 'poor';
    }
  }

  /// Get current performance snapshot
  Map<String, dynamic> getSnapshot() {
    return {
      'metrics': {
        'latency': calculateStats(MetricType.latency, 'websocket'),
        'throughput': calculateStats(MetricType.throughput, 'route_publish'),
        'queueSize': calculateStats(MetricType.queueSize, 'offline_queue'),
        'dropRate': calculateStats(MetricType.dropRate, 'message_delivery'),
      },
      'counters': {
        'totalMessages': _totalMessages,
        'successfulDeliveries': _successfulDeliveries,
        'droppedMessages': _droppedMessages,
        'activeConnections': _activeConnections,
      },
      'health': _calculateHealthScore(),
    };
  }

  /// Reset all metrics
  void reset() {
    _metricQueues.clear();
    _activeStopwatches.clear();
    _totalMessages = 0;
    _droppedMessages = 0;
    _successfulDeliveries = 0;
    _activeConnections = 0;
    
    print('🔄 Performance metrics reset');
  }

  /// Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _aggregationTimer?.cancel();
    _dashboardTimer?.cancel();
    
    print('🛑 PerformanceMonitor stopped');
  }

  /// Clean up resources
  void dispose() {
    stopMonitoring();
    _metricStream.close();
    _dashboardStream.close();
  }
}
