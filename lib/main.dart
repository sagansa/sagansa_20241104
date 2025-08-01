import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:provider/provider.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/welcome_page.dart';
import 'pages/leave_page.dart';
import 'pages/calendar_page.dart';
// import 'pages/salary_page.dart';
import 'providers/presence_provider.dart';
import 'providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Add error handling for uncaught exceptions
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  try {
    print('Starting Sagansa App...');
    runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          print('Creating AuthProvider...');
          return AuthProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          print('Creating PresenceProvider...');
          return PresenceProvider();
        }),
      ],
      child: const MyApp(),
    ));
    print('App started successfully');
  } catch (e, stackTrace) {
    print('Error in main: $e');
    print('Stack trace: $stackTrace');
    // Fallback app
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sagansa App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: Colors.black,
          secondary: const Color(0xFF00ACC1),
        ),
        appBarTheme: const AppBarTheme(
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
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/leave': (context) => const LeavePage(),
        '/calendar': (context) => const CalendarPage(),
        // '/salary': (context) => const SalaryPage(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        SfGlobalLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id'),
        Locale('en'),
      ],
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    print('AuthWrapper build called');
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('AuthWrapper Consumer builder called');
        print('Auth state: ${authProvider.authState}');
        print('Is authenticated: ${authProvider.isAuthenticated}');

        try {
          // Show loading screen while checking authentication
          if (authProvider.authState == AuthState.loading) {
            print('Showing loading screen');
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (authProvider.isAuthenticated) {
            print('User authenticated, showing HomePage');
            return HomePage();
          } else {
            print('User not authenticated, showing LoginPage');
            return LoginPage();
          }
        } catch (e) {
          print('Error in AuthWrapper: $e');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error loading app'),
                  Text('$e'),
                  ElevatedButton(
                    onPressed: () {
                      // Try to restart
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
