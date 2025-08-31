import 'dart:async';
import 'package:flutter/material.dart';
import '../services/mock_realtime/demo_scenarios.dart';
import '../services/mock_realtime/enhanced_performance_monitor.dart';
import '../theme/app_theme.dart';

/// Demo control panel for hackathon presentations
class DemoControlPanel extends StatefulWidget {
  final bool startMinimized;
  
  const DemoControlPanel({
    Key? key,
    this.startMinimized = true,
  }) : super(key: key);

  @override
  State<DemoControlPanel> createState() => _DemoControlPanelState();
}

class _DemoControlPanelState extends State<DemoControlPanel>
    with SingleTickerProviderStateMixin {
  final DemoScenarioController _controller = DemoScenarioController();
  
  ScenarioState? _currentState;
  String? _currentNarration;
  bool _isExpanded = false;
  Timer? _narrationTimer;
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _isExpanded = !widget.startMinimized;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (_isExpanded) {
      _animationController.forward();
    }
    
    // Set up callbacks
    _controller.onStateUpdate = (state) {
      if (mounted) {
        setState(() => _currentState = state);
      }
    };
    
    _controller.onNarration = (message) {
      if (mounted) {
        setState(() => _currentNarration = message);
        
        // Clear narration after delay
        _narrationTimer?.cancel();
        _narrationTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() => _currentNarration = null);
          }
        });
      }
    };
  }

  @override
  void dispose() {
    _animationController.dispose();
    _narrationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Container(
            width: _isExpanded ? 400 : 60,
            height: _isExpanded ? 500 : 60,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(_isExpanded ? 16 : 30),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: _isExpanded ? _buildExpandedPanel() : _buildCollapsedPanel(),
          );
        },
      ),
    );
  }

  Widget _buildCollapsedPanel() {
    final isRunning = _currentState?.isRunning ?? false;
    
    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(
          isRunning ? Icons.play_circle_filled : Icons.science,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildExpandedPanel() {
    return Column(
      children: [
        _buildHeader(),
        if (_currentNarration != null) _buildNarration(),
        Expanded(
          child: _currentState == null
              ? _buildScenarioSelector()
              : _buildScenarioProgress(),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.science,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Demo Control Panel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _toggleExpanded,
            icon: Icon(Icons.minimize),
            color: Colors.white,
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildNarration() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.mic,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _currentNarration!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Demo Scenario',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: DemoScenarioController.scenarios.entries.map((entry) {
                return _buildScenarioCard(entry.value);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(Scenario scenario) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _controller.startScenario(scenario.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  scenario.icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scenario.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: Colors.white.withOpacity(0.4),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${scenario.duration.inMinutes}:${(scenario.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_outline,
                color: AppTheme.primaryColor,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioProgress() {
    final state = _currentState!;
    final scenario = state.scenario;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(scenario.icon, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      scenario.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _controller.stopScenario(),
                    icon: Icon(Icons.stop),
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMetricsOverview(state.currentMetrics),
            ],
          ),
        ),
        Expanded(
          child: _buildEventLog(state.eventLog),
        ),
      ],
    );
  }

  Widget _buildMetricsOverview(Map<String, dynamic> metrics) {
    final connections = metrics['counters']?['activeConnections'] ?? 0;
    final latency = metrics['metrics']?['latency']?['average'] ?? 0.0;
    final health = metrics['health'] ?? 'unknown';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric('Connections', connections.toString(), Colors.blue),
          _buildMetric('Latency', '${latency.toStringAsFixed(0)}ms', Colors.orange),
          _buildMetric('Health', health.toString().toUpperCase(), _getHealthColor(health)),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEventLog(List<ScenarioEvent> events) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Log',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[events.length - 1 - index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${event.timestamp.toIso8601String().substring(11, 19)} - ${event.message}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.white.withOpacity(0.4),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'YatraLive Demo - SIH 2025',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(String health) {
    switch (health.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
