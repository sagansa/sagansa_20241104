// ====================================================================
// Router deep-link notifikasi — mengubah payload notifikasi menjadi
// navigasi ke halaman detail terkait.
//
// Dipanggil saat user men-tap notifikasi (foreground via
// onDidReceiveNotificationResponse, atau cold-start via
// getNotificationAppLaunchDetails). Berjalan di main isolate (boleh
// memegang Navigator).
// ====================================================================

import 'package:flutter/material.dart';

import '../pages/invoice_detail_page.dart';
import '../pages/payment_receipt_detail_page.dart';
import 'navigator_service.dart';
import 'procurement_notification_service.dart';

/// Navigasi ke halaman detail berdasar payload notifikasi.
///
/// - `invoice_transfer_created` → InvoiceDetailPage(invoiceId)
/// - `payment_receipt_paid`    → PaymentReceiptDetailPage(receiptId)
///   (uniform untuk ketiga payment_for; payment_for dibawa di payload untuk
///   kebutuhan future).
void navigateToNotification(Map<String, dynamic> payload) {
  final navigator = NavigatorService.navigatorKey.currentState;
  if (navigator == null) return;

  final type = payload['type'] as String?;
  final id = extractRecordId(payload);
  if (id == null) return;

  if (type == kFcmTypeInvoiceTransferCreated) {
    navigator.push(
      MaterialPageRoute(builder: (_) => InvoiceDetailPage(invoiceId: id)),
    );
  } else if (type == kFcmTypePaymentReceiptPaid) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => PaymentReceiptDetailPage(receiptId: id),
        ),
      );
  }
}
