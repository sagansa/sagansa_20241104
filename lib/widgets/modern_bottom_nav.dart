import 'package:flutter/material.dart';
import '../models/presence_model.dart';
import '../pages/home_page.dart';
import '../pages/leave_page.dart';
import '../pages/calendar_page.dart';
import '../pages/salary_page.dart';

class ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<PresenceModel>? presences;

  const ModernBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.presences,
  }) : super(key: key);

  void _handleNavigation(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LeavePage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CalendarPage(presences: presences ?? []),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SalaryPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_busy),
          label: 'Leave',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Salary',
        ),
      ],
      currentIndex: currentIndex,
      selectedItemColor: Colors.black,
      onTap: (index) => _handleNavigation(context, index),
    );
  }
}
