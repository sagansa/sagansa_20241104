import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:provider/provider.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/welcome_page.dart';
import 'pages/leave_page.dart';
import 'pages/calendar_page.dart';
import 'pages/design_demo_page.dart';
import 'providers/presence_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Add error handling for uncaught exceptions
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    }
  };

  try {
    if (kDebugMode) {
      debugPrint('Starting Sagansa App...');
    }

    runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          if (kDebugMode) {
            debugPrint('Creating ThemeProvider...');
          }
          final themeProvider = ThemeProvider();
          themeProvider.initialize();
          return themeProvider;
        }),
        ChangeNotifierProvider(create: (_) {
          if (kDebugMode) {
            debugPrint('Creating AuthProvider...');
          }
          return AuthProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          if (kDebugMode) {
            debugPrint('Creating PresenceProvider...');
          }
          return PresenceProvider();
        }),
      ],
      child: const MyApp(),
    ));

    if (kDebugMode) {
      debugPrint('App started successfully');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('Error in main: $e');
      debugPrint('Stack trace: $stackTrace');
    }

    // Fallback app with better error display
    runApp(MaterialApp(
      title: 'Sagansa App - Error',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Application Error'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to start application',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Sagansa App',
          theme: ThemeProvider.lightTheme,
          darkTheme: ThemeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AuthWrapper(),
          routes: {
            '/welcome': (context) => const WelcomePage(),
            '/login': (context) => LoginPage(),
            '/home': (context) => HomePage(),
            '/leave': (context) => const LeavePage(),
            '/calendar': (context) => const CalendarPage(),
            '/design-demo': (context) => const DesignDemoPage(),
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
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('AuthWrapper build called');
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        try {
          // Show loading screen while checking authentication or during login
          if (authProvider.authState == AuthState.loading) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(fontSize: 16),
                    ),
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
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to initialize app',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authProvider.errorMessage,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          authProvider.reinitialize();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Navigate based on authentication status
          if (authProvider.isAuthenticated) {
            if (kDebugMode) {
              debugPrint('User authenticated, showing HomePage');
            }
            return HomePage();
          } else {
            if (kDebugMode) {
              debugPrint('User not authenticated, showing LoginPage');
            }
            return LoginPage();
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error in AuthWrapper: $e');
          }

          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading app',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$e',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Try to restart by navigating to login
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
