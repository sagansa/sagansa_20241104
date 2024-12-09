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
import 'pages/transaction_history_page.dart';
import 'pages/transaction_detail_page.dart';
import '../pages/settings_page.dart';
import '../pages/settings_printer_page.dart';
import '../pages/pos_page.dart';

void main() {
<<<<<<< HEAD
<<<<<<< HEAD
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
        '/transaction-history': (context) => TransactionHistoryPage(),
        '/pos': (context) => POSPage(),
        '/settings': (context) => const SettingsPage(),
        '/settings/printer': (context) => const SettingsPrinterPage(),
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
      onGenerateRoute: (settings) {
        if (settings.name == '/transaction-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => TransactionDetailPage(
              transactionId: args['transactionId'],
            ),
          );
        }
        return null;
      },
    ),
  ));
=======
=======
>>>>>>> parent of 1f06ce8 (version: 1.0.0+2)
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sagansa App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
<<<<<<< HEAD
>>>>>>> parent of 1f06ce8 (version: 1.0.0+2)
=======
>>>>>>> parent of 1f06ce8 (version: 1.0.0+2)
}
