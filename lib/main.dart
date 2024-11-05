import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Sagansa App',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    initialRoute: '/login',
    routes: {
      '/login': (context) => LoginPage(),
      '/home': (context) => HomePage(),
    },
  ));
}
