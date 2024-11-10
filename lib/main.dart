import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(MaterialApp(
    title: 'Sagansa App',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    initialRoute: '/login',
    routes: {
      '/login': (context) => LoginPage(),
      '/home': (context) => HomePage(),
    },
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      SfGlobalLocalizations.delegate,
    ],
    supportedLocales: [
      const Locale('id'),
      const Locale('en'),
    ],
    locale: const Locale('id'),
  ));
}
