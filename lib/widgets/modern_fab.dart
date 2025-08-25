import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_animations.dart';

enum ModernFABSize { small, regular, large, extended }

class ModernFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final ModernFABSize size;
  final bool isExtended;

  const ModernFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.size = ModernFABSize.regular,
    this.isExtended = false,
  });

  @override
  State<ModernFAB> createState() => _ModernFABState();
}

class _ModernFABState extends State<ModernFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.durationMedium,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppAnimations.curveDefault,
    ));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppAnimations.curveElastic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _resetAnimation();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _resetAnimation();
  }

  void _resetAnimation() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  double get _fabSize {
    switch (widget.size) {
      case ModernFABSize.small:
        return 40;
      case ModernFABSize.regular:
        return 56;
      case ModernFABSize.large:
        return 72;
      case ModernFABSize.extended:
        return 56;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case ModernFABSize.small:
        return 20;
      case ModernFABSize.regular:
        return 24;
      case ModernFABSize.large:
        return 32;
      case ModernFABSize.extended:
        return 24;
    }
  }

  Widget _buildFAB() {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? AppColors.primary;
    final foregroundColor = widget.foregroundColor ?? AppColors.onPrimary;

    if (widget.isExtended || widget.label != null) {
      return FloatingActionButton.extended(
        onPressed: null, // Handled by GestureDetector
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: _isPressed ? 2 : 6,
        tooltip: widget.tooltip,
        icon: Icon(widget.icon, size: _iconSize),
        label: Text(
          widget.label ?? '',
          style: theme.textTheme.labelLarge?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return FloatingActionButton(
      onPressed: null, // Handled by GestureDetector
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: _isPressed ? 2 : 6,
      tooltip: widget.tooltip,
      mini: widget.size == ModernFABSize.small,
      child: Icon(widget.icon, size: _iconSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    widget.isExtended || widget.label != null
                        ? 16
                        : _fabSize / 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withOpacity(0.2),
                      blurRadius: _isPressed ? 4 : 8,
                      offset: Offset(0, _isPressed ? 2 : 4),
                    ),
                  ],
                ),
                child: _buildFAB(),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Specialized FAB variants
class ModernSpeedDial extends StatefulWidget {
  final List<ModernSpeedDialChild> children;
  final IconData icon;
  final IconData? activeIcon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ModernSpeedDial({
    super.key,
    required this.children,
    required this.icon,
    this.activeIcon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<ModernSpeedDial> createState() => _ModernSpeedDialState();
}

class _ModernSpeedDialState extends State<ModernSpeedDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.durationMedium,
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppAnimations.curveDefault,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...widget.children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;

          return AppAnimations.staggeredAnimation(
            index: index,
            child: AppAnimations.animatedOpacity(
              opacity: _isOpen ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (child.label != null) ...[
                      Container(
                        padding: AppSpacing.paddingHorizontalMD +
                            AppSpacing.paddingVerticalSM,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppSpacing.borderRadiusSM,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          child.label!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      AppSpacing.gapHorizontalSM,
                    ],
                    ModernFAB(
                      onPressed: () {
                        _toggle();
                        child.onPressed();
                      },
                      icon: child.icon,
                      size: ModernFABSize.small,
                      backgroundColor: child.backgroundColor,
                      foregroundColor: child.foregroundColor,
                      tooltip: child.tooltip,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        ModernFAB(
          onPressed: _toggle,
          icon: widget.activeIcon ?? widget.icon,
          tooltip: widget.tooltip,
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
        ),
      ],
    );
  }
}

class ModernSpeedDialChild {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ModernSpeedDialChild({
    required this.onPressed,
    required this.icon,
    this.label,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });
}
