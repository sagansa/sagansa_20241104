import 'package:flutter/material.dart';
import '../services/presence_service.dart';

class ModernBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  _ModernBottomNavState createState() => _ModernBottomNavState();
}

class _ModernBottomNavState extends State<ModernBottomNav> {
  bool hasPresenceToday = false;

  @override
  void initState() {
    super.initState();
    _fetchPresenceStatus();
  }

  void _fetchPresenceStatus() async {
    try {
      final presenceStatus = await PresenceService.hasCheckedInToday();
      setState(() {
        hasPresenceToday = presenceStatus.hasCheckedIn;
      });
      print('Has presence today: $hasPresenceToday');
    } catch (e) {
      print('Error fetching presence status: $e');
    }
  }

  void _handleNavigation(BuildContext context, int index) async {
    print('Navigating to index: $index, hasPresenceToday: $hasPresenceToday');

    if (index == widget.currentIndex) return;

    if (index == 2 && !hasPresenceToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus melakukan presensi terlebih dahulu'),
        ),
      );
      return;
    }

    if (index == 2 && hasPresenceToday) {
      Navigator.pushNamedAndRemoveUntil(context, '/pos', (route) => false);
      return;
    }

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(context, '/leave', (route) => false);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(context, '/pos', (route) => false);
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(
            context, '/calendar', (route) => false);
        break;
      case 4:
        Navigator.pushNamedAndRemoveUntil(context, '/salary', (route) => false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: (index) => _handleNavigation(context, index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Leave',
        ),
        BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 28,
            ),
          ),
          label: 'POS',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.event_note_outlined),
          activeIcon: Icon(Icons.event_note),
          label: 'Calendar',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          activeIcon: Icon(Icons.account_balance_wallet),
          label: 'Salary',
        ),
      ],
    );
  }
}
