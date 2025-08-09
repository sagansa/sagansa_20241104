import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:provider/provider.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/welcome_page.dart';
import 'pages/leave_page.dart';
import 'pages/calendar_page.dart';
import 'pages/design_demo_page.dart';
// import 'pages/salary_page.dart';
import 'providers/presence_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Add error handling for uncaught exceptions
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  try {
    debugPrint('Starting Sagansa App...');
    runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating ThemeProvider...');
          final themeProvider = ThemeProvider();
          themeProvider.initialize();
          return themeProvider;
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating AuthProvider...');
          return AuthProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating PresenceProvider...');
          return PresenceProvider();
        }),
      ],
      child: const MyApp(),
    ));
    debugPrint('App started successfully');
  } catch (e, stackTrace) {
    debugPrint('Error in main: $e');
    debugPrint('Stack trace: $stackTrace');
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
    print('AuthWrapper build called');
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('AuthWrapper Consumer builder called');
        print('Auth state: ${authProvider.authState}');
        print('Is authenticated: ${authProvider.isAuthenticated}');

        try {
<<<<<<< HEAD
          // Show loading screen while checking authentication or during login
          if (authProvider.authState == AuthState.checking ||
              authProvider.authState == AuthState.loading ||
              !authProvider.hasInitialized) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
=======
          // Show loading screen while checking authentication
          if (authProvider.authState == AuthState.loading) {
            print('Showing loading screen');
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
>>>>>>> parent of f54562b (update token, password remember, logo)
              ),
            );
          }

<<<<<<< HEAD
          // Show error screen if initialization failed
          if (authProvider.authState == AuthState.error &&
              authProvider.errorMessage.contains('initialize')) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to initialize app',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      authProvider.errorMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
=======
>>>>>>> parent of f54562b (update token, password remember, logo)
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
                  Text(
                    'Error loading app',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '$e',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
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
