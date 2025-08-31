import 'dart:async';
import 'package:flutter/material.dart';
import '../services/mock_realtime/enhanced_performance_monitor.dart';
import '../theme/app_theme.dart';

/// Real-time performance overlay widget for demos
class PerformanceOverlay extends StatefulWidget {
  final bool expanded;
  final bool showAlerts;
  final EdgeInsets padding;
  
  const PerformanceOverlay({
    Key? key,
    this.expanded = false,
    this.showAlerts = true,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay>
    with SingleTickerProviderStateMixin {
  final EnhancedPerformanceMonitor _monitor = EnhancedPerformanceMonitor();
  
  StreamSubscription<PerformanceSnapshot>? _snapshotSubscription;
  StreamSubscription<PerformanceAlert>? _alertSubscription;
  
  PerformanceSnapshot? _currentSnapshot;
  final List<PerformanceAlert> _recentAlerts = [];
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _subscribeToPerformance();
  }

  void _subscribeToPerformance() {
    _snapshotSubscription = _monitor.snapshotStream.listen((snapshot) {
      if (mounted) {
        setState(() => _currentSnapshot = snapshot);
      }
    });
    
    _alertSubscription = _monitor.alertStream.listen((alert) {
      if (mounted) {
        setState(() {
          _recentAlerts.insert(0, alert);
          if (_recentAlerts.length > 5) {
            _recentAlerts.removeLast();
          }
        });
        
        // Show snackbar for critical alerts
        if (alert.type == AlertType.latencyCritical ||
            alert.type == AlertType.dropRateCritical) {
          _showAlertSnackbar(alert);
        }
      }
    });
  }

  void _showAlertSnackbar(PerformanceAlert alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(alert.message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _snapshotSubscription?.cancel();
    _alertSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSnapshot == null) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      top: widget.padding.top,
      right: widget.padding.right,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isMinimized ? 60 : (widget.expanded ? 350 : 250),
        child: _isMinimized ? _buildMinimized() : _buildExpanded(),
      ),
    );
  }

  Widget _buildMinimized() {
    final health = _currentSnapshot?.systemHealth ?? SystemHealth.unknown;
    final healthColor = _getHealthColor(health);
    
    return GestureDetector(
      onTap: () => setState(() => _isMinimized = false),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: healthColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: healthColor.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Icon(
              Icons.speed,
              color: healthColor.withOpacity(_pulseAnimation.value),
              size: 30,
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildMetrics(),
          if (widget.expanded) _buildDetailedStats(),
          if (widget.showAlerts && _recentAlerts.isNotEmpty) _buildAlerts(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final health = _currentSnapshot?.systemHealth ?? SystemHealth.unknown;
    final healthColor = _getHealthColor(health);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: healthColor.withOpacity(0.2),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: healthColor.withOpacity(_pulseAnimation.value),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            'Performance Monitor',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            health.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              color: healthColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => setState(() => _isMinimized = true),
            child: Icon(
              Icons.minimize,
              color: Colors.white.withOpacity(0.6),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    final connectionStats = _currentSnapshot?.connectionStats;
    final avgLatency = _getAverageLatency();
    final successRate = _getSuccessRate();
    
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildMetricRow(
            icon: Icons.link,
            label: 'Connections',
            value: '${connectionStats?.activeConnections ?? 0}/${connectionStats?.totalConnections ?? 0}',
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            icon: Icons.speed,
            label: 'Avg Latency',
            value: '${avgLatency.toStringAsFixed(0)}ms',
            color: _getLatencyColor(avgLatency),
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            icon: Icons.check_circle,
            label: 'Success Rate',
            value: '${successRate.toStringAsFixed(1)}%',
            color: _getSuccessRateColor(successRate),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStats() {
    final pathStats = _currentSnapshot?.messagePathStats ?? {};
    if (pathStats.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message Paths',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ...pathStats.entries.take(3).map((entry) {
            final stats = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key.replaceAll('_', ' → '),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'P95: ${stats.p95Latency.toStringAsFixed(0)}ms',
                    style: TextStyle(
                      color: _getLatencyColor(stats.p95Latency),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAlerts() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Recent Alerts',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ..._recentAlerts.take(3).map((alert) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                alert.message,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  double _getAverageLatency() {
    final pathStats = _currentSnapshot?.messagePathStats ?? {};
    if (pathStats.isEmpty) return 0;
    
    final totalLatency = pathStats.values
        .map((s) => s.averageLatency)
        .reduce((a, b) => a + b);
    
    return totalLatency / pathStats.length;
  }

  double _getSuccessRate() {
    final pathStats = _currentSnapshot?.messagePathStats ?? {};
    if (pathStats.isEmpty) return 100;
    
    final totalMessages = pathStats.values
        .map((s) => s.totalMessages)
        .reduce((a, b) => a + b);
    
    final successfulMessages = pathStats.values
        .map((s) => s.successfulMessages)
        .reduce((a, b) => a + b);
    
    return totalMessages > 0 ? successfulMessages / totalMessages * 100 : 100;
  }

  Color _getHealthColor(SystemHealth health) {
    switch (health) {
      case SystemHealth.excellent:
        return Colors.green;
      case SystemHealth.good:
        return Colors.lightGreen;
      case SystemHealth.fair:
        return Colors.orange;
      case SystemHealth.poor:
        return Colors.red;
      case SystemHealth.unknown:
        return Colors.grey;
    }
  }

  Color _getLatencyColor(double latency) {
    if (latency < 100) return Colors.green;
    if (latency < 500) return Colors.orange;
    return Colors.red;
  }

  Color _getSuccessRateColor(double rate) {
    if (rate > 95) return Colors.green;
    if (rate > 90) return Colors.orange;
    return Colors.red;
  }
}

/// Floating performance badge for minimal display
class PerformanceBadge extends StatelessWidget {
  final SystemHealth health;
  final VoidCallback? onTap;
  
  const PerformanceBadge({
    Key? key,
    required this.health,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = _getHealthColor(health);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'System: ${health.toString().split('.').last}',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getHealthColor(SystemHealth health) {
    switch (health) {
      case SystemHealth.excellent:
        return Colors.green;
      case SystemHealth.good:
        return Colors.lightGreen;
      case SystemHealth.fair:
        return Colors.orange;
      case SystemHealth.poor:
        return Colors.red;
      case SystemHealth.unknown:
        return Colors.grey;
    }
  }
}
