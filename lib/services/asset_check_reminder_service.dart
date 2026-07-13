// ====================================================================
// Reminder pemeriksaan aset — penanganan FCM tipe 'asset_check_due'.
//
// Backend mengirim push data-only ke user ber-role terkait saat aset jatuh
// tempo. File ini:
//   - [AssetCheckReminderService]: singleton menyiapkan channel notif lokal
//     'sagansa_asset_check' & menampilkan notif saat push diterima (fg/bg).
//   - Top-level helper [handleAssetCheckDueFcm]: dipanggil oleh
//     firebaseMessagingBackgroundHandler di location_tracking_service.dart.
// ====================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Tipe payload FCM untuk pengingat check aset (konvensi sama dengan backend
/// AssetCheckDueService).
const String kFcmTypeAssetCheckDue = 'asset_check_due';

/// ID channel notifikasi Android untuk pengingat aset.
const String kAssetCheckChannelId = 'sagansa_asset_check';

/// ID notifikasi yang dipakai untuk pengingat aset (id tetap per asset_id
/// agar notifikasi baru menimpa yang lama untuk aset yang sama).
int _assetNotificationId(int assetId) => 9000 + (assetId % 1000);

/// Top-level: handle FCM 'asset_check_due'. Dipanggil dari background handler
/// maupun foreground listener. Hanya menampilkan notifikasi lokal — TIDAK
/// boleh menangkap state widget tree (background isolate).
@pragma('vm:entry-point')
Future<void> handleAssetCheckDueFcm(Map<String, dynamic> data) async {
  if (data['type'] != kFcmTypeAssetCheckDue) return;

  final assetId = int.tryParse(data['asset_id']?.toString() ?? '');
  if (assetId == null) return;

  final title = data['title'] as String? ?? 'Pemeriksaan Aset Jatuh Tempo';
  final body = data['body'] as String? ?? 'Ada aset yang perlu diperiksa.';

  await AssetCheckReminderService.instance.showNotification(
    assetId: assetId,
    title: title,
    body: body,
  );
}

/// Singleton untuk channel notifikasi pengingat aset & tampilan notif lokal.
class AssetCheckReminderService {
  AssetCheckReminderService._();
  static final AssetCheckReminderService instance = AssetCheckReminderService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _channelReady = false;

  /// Buat channel Android untuk notifikasi aset. Idempoten.
  Future<void> ensureChannel() async {
    if (_channelReady) return;
    try {
      const channel = AndroidNotificationChannel(
        kAssetCheckChannelId,
        'Pemeriksaan Aset',
        description: 'Pengingat pemeriksaan aset berkala',
        importance: Importance.high,
        showBadge: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      _channelReady = true;
    } catch (e) {
      debugPrint('AssetCheckReminderService.ensureChannel gagal: $e');
    }
  }

  /// Tampilkan notifikasi pengingat untuk aset tertentu. Id notifikasi tetap
  /// berdasarkan assetId supaya menimpa (tidak menumpuk) bila aset yang sama
  /// diingatkan berkali-kali.
  Future<void> showNotification({
    required int assetId,
    required String title,
    required String body,
  }) async {
    await ensureChannel();
    try {
      const androidDetails = AndroidNotificationDetails(
        kAssetCheckChannelId,
        'Pemeriksaan Aset',
        channelDescription: 'Pengingat pemeriksaan aset berkala',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      );
      const notifDetails = NotificationDetails(android: androidDetails);
      await _localNotifications.show(
        id: _assetNotificationId(assetId),
        title: title,
        body: body,
        notificationDetails: notifDetails,
        payload: assetId.toString(),
      );
    } catch (e) {
      debugPrint('AssetCheckReminderService.showNotification gagal: $e');
    }
  }
}
