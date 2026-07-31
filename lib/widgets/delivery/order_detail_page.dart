import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums/delivery_status.dart';
import '../../models/enums/order_mode.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/printer_provider.dart';
import 'direct_order_detail_view.dart';
import 'online_order_detail_view.dart';

/// Halaman detail order generik (Online & Direct).
///
/// Membungkus [OnlineOrderDetailView] / [DirectOrderDetailView] dalam Scaffold
/// sendiri + menyediakan [DeliveryProvider] & [PrinterProvider] agar detail view
/// (yg memakai `context.watch<DeliveryProvider>()`) tetap reaktif.
///
/// Order yang akan ditampilkan di-seed ke provider via [DeliveryProvider.selectOrder]
/// pada [initState], sehingga `formState.selectedOrder` terisi sebelum build.
/// Saat halaman ditutup, [dispose] memanggil [DeliveryProvider.clearSelection]
/// agar state bersih bila provider dipakai ulang oleh parent (mis. SalesPage
/// masih memegang instance provider untuk list).
class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;
  final OrderMode orderMode;
  final DeliveryProvider provider;

  const OrderDetailPage({
    super.key,
    required this.order,
    required this.orderMode,
    required this.provider,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  @override
  void initState() {
    super.initState();
    // Pindahkan fokus ke order ini di provider agar detail view dapat data.
    // selectOrder() memanggil notifyListeners() — bila dipanggil sinkron di
    // initState saat provider ini juga dipakai parent yg sedang build
    // (SalesPage memegang instance yg sama), akan memicu
    // "setState/markNeedsBuild during build". Tunda ke post-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.provider.selectOrder(widget.order);
    });
  }

  @override
  void dispose() {
    // Bersihkan selection agar list tidak menganggap ada order terpilih
    // (relevan bila provider dipakai ulang oleh parent). clearSelection juga
    // notifyListeners — aman di dispose karena page sudah lepas dari tree.
    widget.provider.clearSelection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status =
        DeliveryStatus.fromCode(order['delivery_status'] ?? 1);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DeliveryProvider>.value(value: widget.provider),
        // PrinterProvider baru per-page (sama seperti pola di SalesPage/DeliveryPage).
        ChangeNotifierProvider<PrinterProvider>(
          create: (_) => PrinterProvider(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.orderMode.detailTitle),
        ),
        body: SafeArea(
          child: widget.orderMode.isOnline
              ? OnlineOrderDetailView(
                  order: order,
                  orderMode: widget.orderMode,
                  status: status,
                )
              : DirectOrderDetailView(
                  order: order,
                  orderMode: widget.orderMode,
                  status: status,
                ),
        ),
      ),
    );
  }
}
