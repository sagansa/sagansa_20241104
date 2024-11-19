import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/welcome_page.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/presence_provider.dart';
import '../pages/leave_page.dart';
import '../pages/calendar_page.dart';
import '../pages/salary_page.dart';
import 'providers/cart_provider.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => PresenceProvider()),
      ChangeNotifierProvider(create: (_) => CartProvider()),
    ],
    child: MaterialApp(
      title: 'Sagansa App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: Colors.black,
          secondary: Color(0xFF00ACC1),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/leave': (context) => LeavePage(),
        '/calendar': (context) => CalendarPage(),
        '/salary': (context) => SalaryPage(),
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
    ),
  ));
}
