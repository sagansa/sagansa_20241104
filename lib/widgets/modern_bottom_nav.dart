import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/presence_model.dart';
import '../pages/home_page.dart';
import '../pages/hrd_dashboard_page.dart';
import '../pages/operational_dashboard_page.dart';
import '../pages/stock_dashboard_page.dart';
import '../pages/transaction_dashboard_page.dart';
import '../theme/app_colors.dart';

class ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<PresenceModel>? presences;

  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.presences,
  });

  void _handleNavigation(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HRDDashboardPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StockDashboardPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TransactionDashboardPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OperationalDashboardPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pakai colorScheme.primary (bukan Theme.primaryColor) agar konsisten
    // dengan Material 3 dan terlihat di light & dark mode. Icon selected
    // dibuat sedikit lebih besar & tebal untuk feedback visual yang jelas.
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurfaceVariant;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.78),
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: CupertinoTabBar(
              currentIndex: currentIndex,
              activeColor: selectedColor,
              inactiveColor: unselectedColor,
              backgroundColor: CupertinoColors.transparent,
              border: null,
              iconSize: 23,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.house),
                  activeIcon: Icon(CupertinoIcons.house_fill),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.person_2),
                  activeIcon: Icon(CupertinoIcons.person_2_fill),
                  label: 'HRD',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.cube_box),
                  activeIcon: Icon(CupertinoIcons.cube_box_fill),
                  label: 'Stock',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.doc_text),
                  activeIcon: Icon(CupertinoIcons.doc_text_fill),
                  label: 'Transaction',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.gear),
                  activeIcon: Icon(CupertinoIcons.gear_solid),
                  label: 'Ops',
                ),
              ],
              onTap: (index) => _handleNavigation(context, index),
            ),
          ),
        ),
      ),
    );
  }
}
