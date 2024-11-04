import 'package:flutter/material.dart';
import '../widgets/modern_bottom_nav.dart';

class SalaryPage extends StatelessWidget {
  const SalaryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Salary'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Text('Salary Page'),
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 3,
        presences: [],
        onTap: (index) {
          // Handle navigasi di sini
        },
      ),
    );
  }
}
