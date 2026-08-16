// ====================================================================
// Notifikasi procurement & sales online — penanganan FCM tipe
// 'invoice_transfer_created', 'payment_receipt_paid', dan
// 'sales_order_online_created'.
//
// Backend mengirim push data-only ke app mobile saat:
//   - invoice Transfer dibuat (ke admin/super_admin),
//   - payment receipt dibuat (ke created_by tiap record ter-attach), atau
//   - sales order online dibuat (ke storage-staff, kecuali pembuat).
//
// File ini:
//   - [ProcurementNotificationService]: singleton menyiapkan channel notif
//     lokal 'sagansa_procurement' & menampilkan notif saat push diterima.
//   - Top-level helper [handleNotificationFcm]: dipanggil oleh
//     firebaseMessagingBackgroundHandler di location_tracking_service.dart.
// ====================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Tipe payload FCM untuk notifikasi procurement & sales (konvensi sama dengan
/// backend ProcurementNotificationService / SalesOrderNotificationService).
const String kFcmTypeInvoiceTransferCreated = 'invoice_transfer_created';
const String kFcmTypePaymentReceiptPaid = 'payment_receipt_paid';
const String kFcmTypeSalesOrderOnlineCreated = 'sales_order_online_created';

/// ID channel notifikasi Android untuk procurement.
const String kProcurementChannelId = 'sagansa_procurement';

/// ID notifikasi stabil berbasis record id supaya notif baru
/// menimpa (tidak menumpuk) untuk record yang sama.
int _procurementNotificationId(int recordId) => 7000 + (recordId % 1000);

/// Ekstrak id record terkait (invoice_id / receipt_id / sales_order_id) dari
/// payload notifikasi.
int? extractRecordId(Map<String, dynamic> payload) {
  final type = payload['type'];
  final raw = switch (type) {
    kFcmTypeInvoiceTransferCreated => payload['invoice_id'],
    kFcmTypeSalesOrderOnlineCreated => payload['sales_order_id'],
    _ => payload['receipt_id'],
  };
  return int.tryParse(raw?.toString() ?? '');
}

/// Top-level: handle FCM notifikasi procurement & sales online. Dipanggil dari
/// background handler maupun foreground listener. Hanya menampilkan notifikasi
/// lokal — TIDAK boleh menangkap state widget tree (background isolate).
@pragma('vm:entry-point')
Future<void> handleNotificationFcm(Map<String, dynamic> data) async {
  final type = data['type'];
  if (type != kFcmTypeInvoiceTransferCreated &&
      type != kFcmTypePaymentReceiptPaid &&
      type != kFcmTypeSalesOrderOnlineCreated) {
    return;
  }

  // Tentukan id notifikasi stabil dari payload (invoice_id / receipt_id /
  // sales_order_id).
  final recordId = extractRecordId(data);
  if (recordId == null) return;

  final title = data['title'] as String? ?? 'Notifikasi Procurement';
  final body = data['body'] as String? ?? '';

  // Simpan SELURUH payload (type, id, dsb.) sebagai JSON agar saat
  // di-tap bisa di-router ke halaman detail terkait.
  await ProcurementNotificationService.instance.showNotification(
    payload: data,
    title: title,
    body: body,
  );
}

/// Singleton untuk channel notifikasi procurement & tampilan notif lokal.
class ProcurementNotificationService {
  ProcurementNotificationService._();
  static final ProcurementNotificationService instance =
      ProcurementNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _channelReady = false;

  /// Buat channel Android untuk notifikasi procurement. Idempoten.
  Future<void> ensureChannel() async {
    if (_channelReady) return;
    try {
      const channel = AndroidNotificationChannel(
        kProcurementChannelId,
        'Notifikasi Procurement',
        description: 'Notifikasi invoice transfer & pembayaran procurement',
        importance: Importance.high,
        showBadge: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      _channelReady = true;
    } catch (e) {
      debugPrint('ProcurementNotificationService.ensureChannel gagal: $e');
    }
  }

  /// Tampilkan notifikasi procurement. Id notifikasi tetap berdasarkan
  /// recordId supaya menimpa (tidak menumpuk) bila record yang sama dikirim
  /// berkali-kali. Payload disimpan sebagai JSON (type, id, payment_for)
  /// agar saat di-tap bisa di-router ke halaman detail.
  Future<void> showNotification({
    required Map<String, dynamic> payload,
    required String title,
    required String body,
  }) async {
    await ensureChannel();
    try {
      final recordId = extractRecordId(payload);
      final notifId = recordId != null
          ? _procurementNotificationId(recordId)
          : 7000;

      const androidDetails = AndroidNotificationDetails(
        kProcurementChannelId,
        'Notifikasi Procurement',
        channelDescription: 'Notifikasi invoice transfer & pembayaran procurement',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      );
      const notifDetails = NotificationDetails(android: androidDetails);
      await _localNotifications.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: notifDetails,
        payload: jsonEncode(payload),
      );
    } catch (e) {
      debugPrint('ProcurementNotificationService.showNotification gagal: $e');
    }
  }
}
