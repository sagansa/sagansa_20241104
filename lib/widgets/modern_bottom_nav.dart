import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/app_animations.dart';

class ModernBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<ModernBottomNavItem> items;

  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<ModernBottomNav> createState() => _ModernBottomNavState();
}

class _ModernBottomNavState extends State<ModernBottomNav>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: AppAnimations.durationMedium,
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: controller, curve: AppAnimations.curveElastic),
      );
    }).toList();

    _fadeAnimations = _animationControllers.map((controller) {
      return Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: AppAnimations.curveDefault),
      );
    }).toList();

    // Animate current index
    if (widget.currentIndex < _animationControllers.length) {
      _animationControllers[widget.currentIndex].forward();
    }
  }

  @override
  void didUpdateWidget(ModernBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Reset old animation
      if (oldWidget.currentIndex < _animationControllers.length) {
        _animationControllers[oldWidget.currentIndex].reverse();
      }
      // Start new animation
      if (widget.currentIndex < _animationControllers.length) {
        _animationControllers[widget.currentIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == widget.currentIndex) return;

    widget.onTap(index);

    // Handle navigation based on route
    final item = widget.items[index];
    if (item.route != null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        item.route!,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: AppSpacing.paddingHorizontalMD,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(widget.items.length, (index) {
              final item = widget.items[index];
              final isSelected = index == widget.currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _handleNavigation(context, index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _scaleAnimations[index],
                      _fadeAnimations[index],
                    ]),
                    builder: (context, child) {
                      return Container(
                        padding: AppSpacing.paddingVerticalSM,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.scale(
                              scale: isSelected
                                  ? _scaleAnimations[index].value
                                  : 1.0,
                              child: Container(
                                padding: AppSpacing.paddingXS,
                                decoration: isSelected
                                    ? BoxDecoration(
                                        color:
                                            AppColors.primary.withOpacity(0.1),
                                        borderRadius: AppSpacing.borderRadiusSM,
                                      )
                                    : null,
                                child: Icon(
                                  isSelected ? item.activeIcon : item.icon,
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.darkOnSurfaceVariant
                                          : AppColors.onSurfaceVariant),
                                  size: 24,
                                ),
                              ),
                            ),
                            AppSpacing.gapVerticalXS,
                            AnimatedOpacity(
                              opacity: isSelected
                                  ? _fadeAnimations[index].value
                                  : 0.6,
                              duration: AppAnimations.durationMedium,
                              child: Text(
                                item.label,
                                style: AppTypography.labelSmall.copyWith(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.darkOnSurfaceVariant
                                          : AppColors.onSurfaceVariant),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class ModernBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? route;

  const ModernBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.route,
  });
}

// Default navigation items
class DefaultBottomNavItems {
  static const List<ModernBottomNavItem> items = [
    ModernBottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      route: '/home',
    ),
    ModernBottomNavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Leave',
      route: '/leave',
    ),
    ModernBottomNavItem(
      icon: Icons.event_note_outlined,
      activeIcon: Icons.event_note,
      label: 'Calendar',
      route: '/calendar',
    ),
    ModernBottomNavItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: 'Salary',
      route: '/salary',
    ),
  ];
}
