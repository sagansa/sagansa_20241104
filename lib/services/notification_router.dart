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

import '../models/enums/order_mode.dart';
import '../pages/invoice_detail_page.dart';
import '../pages/payment_receipt_detail_page.dart';
import '../providers/delivery_provider.dart';
import '../widgets/delivery/order_detail_page.dart';
import 'auth_service.dart';
import 'navigator_service.dart';
import 'presence_service.dart';
import 'procurement_notification_service.dart';

/// Navigasi ke halaman detail berdasar payload notifikasi.
///
/// - `invoice_transfer_created`     → InvoiceDetailPage(invoiceId)
/// - `payment_receipt_paid`         → PaymentReceiptDetailPage(receiptId)
///   (uniform untuk ketiga payment_for; payment_for dibawa di payload untuk
///   kebutuhan future).
/// - `sales_order_online_created`   → fetch order via GET /sales-orders/online/{id}
///   lalu OrderDetailPage(orderMode: online).
///
/// Deep-link diabaikan (no-op) untuk user sales-only — mereka hanya berhak
/// membuka halaman penjualan/konsumen, bukan halaman yang dituju notifikasi.
Future<void> navigateToNotification(Map<String, dynamic> payload) async {
  final navigator = NavigatorService.navigatorKey.currentState;
  if (navigator == null) return;

  // Sales-only: abaikan semua deep-link notifikasi (no-op).
  if (await AuthService.isSalesOnlyUser()) return;

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
  } else if (type == kFcmTypeSalesOrderOnlineCreated) {
    await _openOnlineOrder(navigator, id);
  }
}

/// Buka halaman detail order online. Fetch order via endpoint detail baru
/// sambil menampilkan loading singkat; bila gagal, tampilkan snackbar.
Future<void> _openOnlineOrder(NavigatorState navigator, int orderId) async {
  if (navigator.mounted) {
    showDialog<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  Map<String, dynamic>? order;
  try {
    order = await PresenceService().getOnlineSalesOrder(orderId);
  } catch (_) {
    order = null;
  }

  if (navigator.mounted) Navigator.of(navigator.context).pop();

  if (order == null) {
    if (navigator.mounted) {
      ScaffoldMessenger.of(navigator.context).showSnackBar(
        const SnackBar(content: Text('Order online tidak ditemukan.')),
      );
    }
    return;
  }

  final resolvedOrder = order;

  // Provider baru per deep-link; di-dispose setelah halaman ditutup.
  final provider = DeliveryProvider(orderMode: OrderMode.online);
  navigator
      .push(
        MaterialPageRoute(
          builder: (_) => OrderDetailPage(
            order: resolvedOrder,
            orderMode: OrderMode.online,
            provider: provider,
          ),
        ),
      )
      .whenComplete(provider.dispose);
}