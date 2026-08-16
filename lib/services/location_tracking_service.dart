// ====================================================================
// Employee location tracking — bootstrap, FCM & workmanager wiring.
//
// File ini berisi:
//   - [LocationTrackingService]: singleton yang diinisialisasi di main()
//     (Firebase init, FCM foreground/listeners, register periodic task).
//   - Top-level functions wajib (HARUS top-level, bukan method/class):
//       * firebaseMessagingBackgroundHandler  (FCM onBackgroundMessage)
//       * callbackDispatcher                   (workmanager)
//     Background isolate mengeksekusi keduanya di luar instance aplikasi,
//     sehingga tidak boleh menangkap state dari widget tree.
// ====================================================================

import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import 'asset_check_reminder_service.dart';
import 'location_service.dart';
import 'notification_router.dart';
import 'procurement_notification_service.dart';
import 'token_store.dart';

/// Nama unik periodic task workmanager.
const String _kLocationPeriodicTask = 'sagansa-location-ping';

/// Kill-switch background location tracking (workmanager periodic task).
///
/// DIMATIKAN atas permintaan user (kekhawatiran review iOS). Saat `false`,
/// Workmanager tidak di-initialize dan periodic task tidak diregistrasi —
/// GPS foreground (clock-in radius & ambil koordinat konsumen) tetap jalan
/// karena memakai `geolocator` langsung, bukan lewat service ini.
/// Set `true` untuk mengaktifkan kembali.
const bool backgroundTrackingEnabled = false;

/// Tipe payload FCM on-demand (konvensi sama dengan backend FcmService).
const String _kFcmTypeLocationRequest = 'location_request';

/// Mengambil satu titik GPS lalu mengunggahnya ke server. Dipakai bersama oleh
/// handler FCM on-demand dan workmanager periodic. Mengembalikan true bila
/// lokasi berhasil didapat & diunggah.
@pragma('vm:entry-point')
Future<bool> _captureAndUploadLocation({
  required String source,
  String? requestId,
}) async {
  // Pastikan layanan lokasi aktif & permission diberikan. Bila gagal, abort.
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return false;

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return false;
  }
  if (permission == LocationPermission.deniedForever) return false;

  final Position position;
  try {
    position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 25),
      ),
    );
  } catch (_) {
    return false;
  }

  return LocationService().sendLocation(
    latitude: position.latitude,
    longitude: position.longitude,
    accuracy: position.accuracy,
    source: source,
    requestId: requestId,
    capturedAt: position.timestamp,
  );
}

/// TOP-LEVEL: dipanggil oleh FCM saat push masuk saat app di-terminate/background.
/// Memerlukan anotasi @pragma('vm:entry-point') agar tidak di-tree-shake.
///
/// Saat Firebase tidak dikonfigurasi (rilis publik awal), handler ini tidak
/// akan pernah dipanggil oleh OS. Tetap di-guard dengan try/catch sebagai
/// pengaman bila kondisi berubah.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Background isolate wajib inisialisasi Firebase sebelum memakai SDK-nya.
    await Firebase.initializeApp();

    final data = message.data;
    final type = data['type'];

    // Routing berdasar tipe payload.
    if (type == _kFcmTypeLocationRequest) {
      final requestId = data['request_id'] as String?;
      if (requestId == null || requestId.isEmpty) return;
      // Ambil GPS lalu balas ke server dengan request_id korelasi.
      await _captureAndUploadLocation(source: 'on_demand', requestId: requestId);
      return;
    }

    if (type == kFcmTypeAssetCheckDue) {
      // Pengingat pemeriksaan aset → tampilkan notifikasi lokal.
      await handleAssetCheckDueFcm(data);
      return;
    }

    if (type == kFcmTypeInvoiceTransferCreated ||
        type == kFcmTypePaymentReceiptPaid ||
        type == kFcmTypeSalesOrderOnlineCreated) {
      // Notifikasi procurement & sales online → tampilkan notifikasi lokal.
      await handleNotificationFcm(data);
      return;
    }
  } catch (e) {
    // No-op bersih bila Firebase tidak tersedia di background isolate.
    debugPrint('firebaseMessagingBackgroundHandler: Firebase nonaktif ($e)');
  }
}

/// TOP-LEVEL: dispatcher workmanager. Menjalankan periodic task (kirim lokasi
/// ~tiap 2 jam) saat app di background.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case _kLocationPeriodicTask:
          await _captureAndUploadLocation(source: 'periodic');
          break;
      }
      return true;
    } catch (e) {
      debugPrint('workmanager task "$task" gagal: $e');
      return false;
    }
  });
}

/// Singleton untuk menyiapkan pelacakan lokasi (Firebase + FCM + workmanager).
///
/// Inisialisasi sekali di main():
///   await LocationTrackingService.instance.initialize();
/// Setelah login:
///   await LocationTrackingService.instance.onLogin();
/// Saat logout:
///   await LocationTrackingService.instance.onLogout();
class LocationTrackingService {
  LocationTrackingService._();
  static final LocationTrackingService instance = LocationTrackingService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  // True bila Firebase/FCM berhasil diinisialisasi. Method FCM lainnya
  // (onLogin token register, onLogout deregister, dll.) hanya berjalan bila
  // true; bila false (mis. google-services.json belum ada) mereka no-op.
  bool _firebaseEnabled = false;

  /// Menyiapkan workmanager, notifikasi lokal, dan (bila tersedia) FCM.
  /// Aman dipanggil ulang (idempoten). Semua kegagalan di-silent (hanya log)
  /// supaya tidak mengganggu aplikasi utama.
  ///
  /// Firebase/FCM bersifat opsional: bila gagal diinisialisasi (mis. belum ada
  /// google-services.json), fitur FCM (push lokasi on-demand & pengingat aset)
  // dimatikan, tetapi Workmanager (periodic location) dan notifikasi lokal tetap
  // berjalan.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // --- Blok B: Workmanager + notifikasi lokal (MANDIRI dari Firebase) ---
    // Dipasang pertama dan terpisah dari blok Firebase agar periodic location
    // ping & channel notifikasi tetap aktif walau Firebase gagal.
    try {
      // Inisialisasi workmanager untuk periodic location ping — hanya bila
      // background tracking aktif (kill-switch). Bila nonaktif, Workmanager
      // tidak pernah di-initialize sehingga callbackDispatcher tidak jalan.
      if (backgroundTrackingEnabled) {
        await Workmanager().initialize(callbackDispatcher);
      }

      // Notifikasi lokal (channel) — butuh channel aktif di Android 8+.
      const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
      await _localNotifications.initialize(
        settings: const InitializationSettings(android: androidInit),
        // Tap notifikasi (foreground) → router deep-link ke halaman detail.
        onDidReceiveNotificationResponse: (response) {
          _handleLocalNotificationTap(response);
        },
      );
      await _ensureAndroidChannel();
      // Channel notifikasi untuk pengingat aset (dibuat idempoten di sini
      // agar siap saat push 'asset_check_due' masuk).
      await AssetCheckReminderService.instance.ensureChannel();
      // Channel notifikasi untuk procurement (invoice transfer & pembayaran).
      await ProcurementNotificationService.instance.ensureChannel();

      // Cold-start: bila app diluncurkan dari tap notifikasi, arahkan setelah
      // frame pertama (Navigator baru siap).
      await _handleAppLaunchNotification();
    } catch (e) {
      debugPrint('LocationTrackingService: init workmanager/notif gagal: $e');
    }

    // --- Blok A: Firebase/FCM (OPSIONAL) ---
    // Saat modul lokasi karyawan on-demand belum dirilis, Firebase sengaja
    // tidak dikonfigurasi (tidak ada google-services.json). Blok ini akan
    // throw dan ditangkap di sini — fitur FCM mati, sisanya tetap jalan.
    try {
      await Firebase.initializeApp();

      // Daftarkan background handler (harus top-level).
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Respons saat app foreground & push masuk (jarang: biasanya app di-bg).
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Refresh token → daftarkan ulang ke server.
      FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);

      _firebaseEnabled = true;
    } catch (e) {
      // Firebase opsional untuk rilis publik awal. Bukan error fatal.
      debugPrint('LocationTrackingService: Firebase nonaktif ($e). '
          'Fitur FCM (lokasi on-demand & pengingat aset via push) dimatikan.');
    }
  }

  /// Dipanggil setelah login berhasil. Mendaftarkan FCM token (bila aktif) &
  /// memulai periodic location ping.
  Future<void> onLogin() async {
    await initialize();
    if (_firebaseEnabled) {
      try {
        await _registerCurrentToken();
      } catch (e) {
        debugPrint('LocationTrackingService.onLogin: register token gagal: $e');
      }
    }
    try {
      // Periodic task hanya diregistrasi bila background tracking aktif.
      // Bila nonaktif (kill-switch), onLogin ini no-op untuk Workmanager —
      // FCM token tetap didaftarkan bila Firebase aktif.
      if (backgroundTrackingEnabled) {
        await Workmanager().registerPeriodicTask(
          _kLocationPeriodicTask,
          _kLocationPeriodicTask,
          frequency: const Duration(hours: 2),
          // Android Doze membatasi minimal 15 menit; 2 jam diterima sebagai
          // "minimal". keepExisting mempertahankan jadwal walau app restart.
          // (workmanager 0.9:ExistingWorkPolicy → ExistingPeriodicWorkPolicy.)
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
          backoffPolicy: BackoffPolicy.exponential,
        );
      }
    } catch (e) {
      debugPrint('LocationTrackingService.onLogin: register periodic gagal: $e');
    }
  }

  /// Dipanggil saat logout. Menghapus token device (bila FCM aktif) &
  /// membatalkan periodic task.
  Future<void> onLogout() async {
    if (_firebaseEnabled) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await LocationService().deregisterDeviceToken(token);
        }
      } catch (_) {/* abaikan */}
    }
    try {
      await Workmanager().cancelByUniqueName(_kLocationPeriodicTask);
    } catch (_) {/* abaikan */}
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final type = message.data['type'];
    // On-demand saat app terbuka: ambil & kirim lokasi langsung.
    if (type == _kFcmTypeLocationRequest) {
      final requestId = message.data['request_id'] as String?;
      _captureAndUploadLocation(source: 'on_demand', requestId: requestId);
      return;
    }
    // Pengingat check aset → tampilkan notifikasi lokal saat app di foreground.
    if (type == kFcmTypeAssetCheckDue) {
      handleAssetCheckDueFcm(message.data);
      return;
    }
    // Notifikasi procurement & sales online → tampilkan notifikasi lokal
    // saat app di foreground.
    if (type == kFcmTypeInvoiceTransferCreated ||
        type == kFcmTypePaymentReceiptPaid ||
        type == kFcmTypeSalesOrderOnlineCreated) {
      handleNotificationFcm(message.data);
      return;
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    await LocationService().registerDeviceToken(token);
  }

  /// Tap notifikasi saat app sedang jalan (foreground/background hidup).
  /// Payload berupa JSON (type, id, payment_for) → router deep-link.
  void _handleLocalNotificationTap(NotificationResponse response) {
    final payloadStr = response.payload;
    if (payloadStr == null || payloadStr.isEmpty) return;
    try {
      final payload = jsonDecode(payloadStr);
      if (payload is Map<String, dynamic>) {
        _navigateFromNotification(payload);
      }
    } catch (e) {
      debugPrint('LocationTrackingService: decode payload notif gagal: $e');
    }
  }

  /// Cold-start: bila app diluncurkan dari tap notifikasi, navigasi ke
  /// halaman detail terkait setelah frame pertama.
  Future<void> _handleAppLaunchNotification() async {
    try {
      final details = await _localNotifications.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp != true) return;
      final payloadStr = details?.notificationResponse?.payload;
      if (payloadStr == null || payloadStr.isEmpty) return;
      final payload = jsonDecode(payloadStr);
      if (payload is Map<String, dynamic>) {
        // Tunggu frame pertama agar Navigator sudah ter-attach ke widget tree.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateFromNotification(payload);
        });
      }
    } catch (e) {
      debugPrint('LocationTrackingService: cek app launch notif gagal: $e');
    }
  }

  /// Navigasi dari notifikasi hanya bila user sudah login (token ada).
  /// readToken() async (flutter_secure_storage) → guard harus di-await.
  Future<void> _navigateFromNotification(Map<String, dynamic> payload) async {
    final token = await TokenStore.instance.readToken();
    if (token == null || token.isEmpty) return;
    navigateToNotification(payload);
  }

  Future<void> _registerCurrentToken() async {
    try {
      // Minta permission notifikasi (Android 13+). Bila ditolak, FCM tetap
      // menerima data-message (yang tidak butuh permission notifikasi).
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: false,
        badge: false,
        sound: false,
      );
      debugPrint('FCM permission: ${settings.authorizationStatus}');

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await LocationService().registerDeviceToken(token);
      }
    } catch (e) {
      debugPrint('_registerCurrentToken gagal: $e');
    }
  }

  Future<void> _ensureAndroidChannel() async {
    try {
      const channel = AndroidNotificationChannel(
        'sagansa_location',
        'Lokasi',
        description: 'Channel untuk pembaruan lokasi pegawai',
        importance: Importance.low,
        showBadge: false,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (_) {/* abaikan */}
  }
}
