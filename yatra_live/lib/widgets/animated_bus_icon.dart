import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedBusIcon extends StatefulWidget {
  final bool isMoving;
  final Color color;
  final double size;
  final double? speed; // km/h

  const AnimatedBusIcon({
    super.key,
    required this.isMoving,
    this.color = AppTheme.primaryColor,
    this.size = 24,
    this.speed,
  });

  @override
  State<AnimatedBusIcon> createState() => _AnimatedBusIconState();
}

class _AnimatedBusIconState extends State<AnimatedBusIcon>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _rotateController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));

    _startAnimations();
  }

  @override
  void didUpdateWidget(AnimatedBusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMoving != oldWidget.isMoving) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    if (widget.isMoving) {
      _bounceController.repeat();
      _rotateController.repeat();
    } else {
      _bounceController.stop();
      _rotateController.stop();
      _bounceController.reset();
      _rotateController.reset();
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Speed indicator (subtle pulse when moving fast)
        if (widget.isMoving && (widget.speed ?? 0) > 30)
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Container(
                width: widget.size * (1.2 + _bounceAnimation.value * 0.3),
                height: widget.size * (1.2 + _bounceAnimation.value * 0.3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.2 * (1 - _bounceAnimation.value)),
                ),
              );
            },
          ),
        
        // Main bus icon
        AnimatedBuilder(
          animation: widget.isMoving ? _bounceAnimation : _rotateController,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isMoving ? (0.9 + _bounceAnimation.value * 0.1) : 1.0,
              child: Transform.rotate(
                angle: widget.isMoving ? (_bounceAnimation.value * 0.1) : 0.0,
                child: Icon(
                  Icons.directions_bus,
                  size: widget.size,
                  color: widget.color,
                ),
              ),
            );
          },
        ),
        
        // Status indicator dot
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: widget.size * 0.25,
            height: widget.size * 0.25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isMoving 
                  ? AppTheme.successColor 
                  : AppTheme.textSecondaryColor,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class PulsatingDot extends StatefulWidget {
  final Color color;
  final double size;
  final bool isActive;

  const PulsatingDot({
    super.key,
    required this.color,
    this.size = 8,
    this.isActive = true,
  });

  @override
  State<PulsatingDot> createState() => _PulsatingDotState();
}

class _PulsatingDotState extends State<PulsatingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsatingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(_animation.value),
          ),
        );
      },
    );
  }
}

class LoadingBusAnimation extends StatefulWidget {
  final String message;
  final Color primaryColor;
  final Color backgroundColor;

  const LoadingBusAnimation({
    super.key,
    this.message = 'Loading...',
    this.primaryColor = AppTheme.primaryColor,
    this.backgroundColor = AppTheme.backgroundColor,
  });

  @override
  State<LoadingBusAnimation> createState() => _LoadingBusAnimationState();
}

class _LoadingBusAnimationState extends State<LoadingBusAnimation>
    with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _bounceController;
  late Animation<double> _moveAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    _moveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _moveAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _startAnimation();
  }

  void _startAnimation() {
    _moveController.repeat(reverse: true);
    _bounceController.repeat();
  }

  @override
  void dispose() {
    _moveController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated bus
            Container(
              width: 200,
              height: 60,
              child: Stack(
                children: [
                  // Road line
                  Positioned(
                    bottom: 15,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                  ),
                  
                  // Moving bus
                  AnimatedBuilder(
                    animation: _moveAnimation,
                    builder: (context, child) {
                      return Positioned(
                        left: (200 / 2) + (_moveAnimation.value * 60) - 15,
                        bottom: 5,
                        child: AnimatedBuilder(
                          animation: _bounceAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, -_bounceAnimation.value * 3),
                              child: Icon(
                                Icons.directions_bus,
                                size: 30,
                                color: widget.primaryColor,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              widget.message,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Loading dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PulsatingDot(color: widget.primaryColor),
                const SizedBox(width: 8),
                PulsatingDot(color: widget.primaryColor),
                const SizedBox(width: 8),
                PulsatingDot(color: widget.primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
