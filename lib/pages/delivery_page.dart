import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums/delivery_status.dart';
import '../models/enums/order_mode.dart';
import '../providers/delivery_provider.dart';
import '../widgets/delivery/barcode_scanner_page.dart';
import '../widgets/delivery/direct_order_detail_view.dart';
import '../widgets/delivery/online_order_detail_view.dart';
import '../widgets/delivery/order_list_view.dart';
import '../widgets/modern_bottom_nav.dart';
import 'create_sales_order_online_page.dart';

class DeliveryPage extends StatelessWidget {
  final OrderMode orderMode;

  const DeliveryPage({super.key, this.orderMode = OrderMode.online});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DeliveryProvider(orderMode: orderMode)..initialize(),
      child: _DeliveryScaffold(orderMode: orderMode),
    );
  }
}

class _DeliveryScaffold extends StatelessWidget {
  final OrderMode orderMode;

  const _DeliveryScaffold({required this.orderMode});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<DeliveryProvider>();
    final formState = provider.formState;
    final listState = provider.listState;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          formState.hasSelection ? orderMode.detailTitle : orderMode.title,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        leading: formState.hasSelection
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: provider.clearSelection,
              )
            : null,
      ),
      body: SafeArea(
        child: formState.hasSelection
            ? _buildDetailView(context, provider, formState, listState)
            : OrderListView(
                orderMode: orderMode,
                onScanBarcode: () => _scanBarcode(context, provider),
              ),
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) Navigator.pop(context);
        },
      ),
      floatingActionButton: _buildFab(context, provider, listState),
    );
  }

  Widget _buildDetailView(
    BuildContext context,
    DeliveryProvider provider,
    DeliveryFormState formState,
    DeliveryListState listState,
  ) {
    final order = formState.selectedOrder!;
    final status = DeliveryStatus.fromCode(order['delivery_status'] ?? 1);

    if (orderMode.isOnline) {
      return OnlineOrderDetailView(
        order: order,
        orderMode: orderMode,
        status: status,
      );
    }

    return DirectOrderDetailView(
      order: order,
      orderMode: orderMode,
      status: status,
    );
  }

  Widget? _buildFab(
    BuildContext context,
    DeliveryProvider provider,
    DeliveryListState listState,
  ) {
    if (!listState.isAdmin || !orderMode.isOnline || provider.formState.hasSelection) {
      return null;
    }

    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateSalesOrderOnlinePage(),
          ),
        ).then((_) => provider.loadInitialOrders());
      },
      child: const Icon(Icons.add),
    );
  }

  static Future<void> _scanBarcode(
    BuildContext context,
    DeliveryProvider provider,
  ) async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
    );
    if (scannedCode != null && scannedCode.isNotEmpty) {
      provider.receiptController.text = scannedCode;
      provider.searchOrder().catchError((e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().replaceAll('Exception: ', ''),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      });
    }
  }
}
