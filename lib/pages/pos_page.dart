import 'package:flutter/material.dart';
import '../widgets/modern_bottom_nav.dart';
class POSPage extends StatefulWidget {
  const POSPage({super.key});

  @override
  POSPageState createState() => POSPageState();
}

class POSPageState extends State<POSPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sales'),
      ),
      body: const Center(
        child: Text(
          'POS',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
