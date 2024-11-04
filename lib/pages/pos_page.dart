import 'package:flutter/material.dart';

class POSPage extends StatefulWidget {
  @override
  _POSPageState createState() => _POSPageState();
}

class _POSPageState extends State<POSPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Point of Sales'),
      ),
      body: Center(
        child: Text(
          'POS',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
