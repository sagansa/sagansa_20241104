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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        try {
          // Show loading screen while checking authentication or during login
          if (authProvider.authState == AuthState.checking ||
              authProvider.authState == AuthState.loading ||
              !authProvider.hasInitialized) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              ),
            );
          }

          // Show error screen if initialization failed
          if (authProvider.authState == AuthState.error &&
              authProvider.errorMessage.contains('initialize')) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Failed to initialize app'),
                    Text(authProvider.errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        authProvider.reinitialize();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Navigate based on authentication status
          if (authProvider.isAuthenticated) {
            return HomePage();
          } else {
            return LoginPage();
          }
        } catch (e) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error loading app'),
                  Text('$e'),
                  ElevatedButton(
                    onPressed: () {
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
