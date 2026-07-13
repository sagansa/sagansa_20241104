import 'package:flutter/material.dart';
import '../models/presence_model.dart';
import '../pages/home_page.dart';
import '../pages/hrd_dashboard_page.dart';
import '../pages/stock_dashboard_page.dart';
import '../pages/transaction_dashboard_page.dart';
import '../pages/operational_dashboard_page.dart';

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

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      selectedIconTheme: IconThemeData(
        color: selectedColor,
        size: 26,
      ),
      unselectedIconTheme: IconThemeData(
        color: unselectedColor,
        size: 24,
      ),
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 12,
      ),
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.badge_outlined),
          activeIcon: Icon(Icons.badge),
          label: 'HRD',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'Stock',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Transaction',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.engineering_outlined),
          activeIcon: Icon(Icons.engineering),
          label: 'Ops',
        ),
      ],
      onTap: (index) => _handleNavigation(context, index),
    );
  }
}
