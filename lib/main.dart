import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

import '../pages/home_page.dart';
import '../pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'providers/fuel_service_payment_provider.dart';
import 'providers/home_dashboard_provider.dart';
import 'providers/printer_provider.dart';
import 'providers/theme_provider.dart';
import 'services/asset_service.dart';
import 'services/inventory_anomaly_service.dart';
import 'services/location_tracking_service.dart';
import 'services/procurement_service.dart';
import 'services/sales_dashboard_service.dart';
import 'theme/app_colors.dart';

// Custom error widget to show instead of the default red screen
class CustomErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const CustomErrorWidget({
    super.key,
    required this.errorDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Terjadi kesalahan pada aplikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      errorDetails.toString(),
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restart app
                  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                },
                child: const Text('Tutup Aplikasi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorBoundaryWidget extends StatefulWidget {
  final Widget child;

  const ErrorBoundaryWidget({super.key, required this.child});

  @override
  ErrorBoundaryWidgetState createState() => ErrorBoundaryWidgetState();
}

class ErrorBoundaryWidgetState extends State<ErrorBoundaryWidget>
    with WidgetsBindingObserver {
  bool hasError = false;
  FlutterErrorDetails? errorDetails;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set up error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      developer.log(
        'Flutter Error',
        error: details.exception,
        stackTrace: details.stack,
      );
      setState(() {
        hasError = true;
        errorDetails = details;
      });
    };

    // Handle platform channel errors
    PlatformDispatcher.instance.onError = (error, stack) {
      developer.log(
        'Platform Dispatcher Error',
        error: error,
        stackTrace: stack,
      );
      return true;
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    developer.log('App lifecycle state changed to: $state');
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return CustomErrorWidget(errorDetails: errorDetails!);
    }
    return widget.child;
  }
}

void main() {
  runZonedGuarded(() async {
    // Tahan splash native sampai kita lepas secara eksplisit (1 detik).
    FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

    // Set up global error handler untuk menampilkan CustomErrorWidget
    // alih-alih red screen default di release build.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return CustomErrorWidget(errorDetails: details);
    };

    // Set orientasi ke portrait
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Cek apakah token tersimpan untuk auto login
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    final String initialRoute = (token != null && token.isNotEmpty) ? '/home' : '/login';

    // Inisialisasi pelacakan lokasi (Firebase + FCM + workmanager) dipindah
    // ke pasca-runApp agar tidak menahan splash native saat cold start.
    runApp(ErrorBoundaryWidget(child: MyApp(initialRoute: initialRoute)));

    // Lepas splash setelah tepat 1 detik (menutupi jeda cold start).
    await Future.delayed(const Duration(milliseconds: 1000));
    FlutterNativeSplash.remove();

    // Jalankan init berat di frame berikutnya, setelah UI pertama tampil.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Bila Firebase belum dikonfigurasi (mis. google-services.json belum ada),
      // di-silent agar tidak mengganggu aplikasi utama.
      await LocationTrackingService.instance.initialize();
      // Auto-login: pastikan FCM token & periodic task aktif.
      if (token != null && token.isNotEmpty) {
        await LocationTrackingService.instance.onLogin();
      }
    });
  }, (error, stackTrace) {
    developer.log(
      'Uncaught error',
      error: error,
      stackTrace: stackTrace,
    );
  });
}

class MyApp extends StatefulWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeProvider _themeProvider = ThemeProvider();
  final PrinterProvider _printerProvider = PrinterProvider();
  final AuthProvider _authProvider = AuthProvider();
  final FuelServicePaymentProvider _fuelServicePaymentProvider =
      FuelServicePaymentProvider();

  @override
  void initState() {
    super.initState();
    _themeProvider.initialize();
    // PrinterProvider melakukan load di constructor, tidak perlu await.
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider),
        ChangeNotifierProvider<PrinterProvider>.value(value: _printerProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<FuelServicePaymentProvider>.value(
            value: _fuelServicePaymentProvider),
        ChangeNotifierProvider<HomeDashboardProvider>(
          create: (_) => HomeDashboardProvider(
            procurementService: ProcurementService(),
            assetService: AssetService(),
            salesDashboardService: SalesDashboardService(),
            anomalyService: InventoryAnomalyService(),
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Ambil tema berdasarkan mode. Gunakan tema sistem (biasanya
          // light) sebagai default selama inisialisasi agar tidak ada
          // transisi warna yang mencolok (flash) dari tema gelap lama.
          final isDark = themeProvider.isDarkMode;
          final ThemeData themeData =
              isDark ? ThemeProvider.darkTheme : ThemeProvider.lightTheme;
          final overlayStyle = SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          );

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlayStyle,
            child: MaterialApp(
              restorationScopeId: 'sagansa',
              title: 'Sagansa',
              theme: themeData,
              darkTheme: ThemeProvider.darkTheme,
              themeMode: themeProvider.themeMode,
              initialRoute: widget.initialRoute,
              routes: {
                '/login': (context) => const LoginPage(),
                '/home': (context) => const HomePage(),
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
              locale: const Locale('id'),
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.0)),
                  child: child!,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
