import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums/order_mode.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/printer_provider.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/paged_body_view.dart';
import '../../widgets/search_text_field.dart';
import 'order_list_card.dart';

class OrderListView extends StatelessWidget {
  final OrderMode orderMode;
  final VoidCallback onScanBarcode;

  const OrderListView({
    super.key,
    required this.orderMode,
    required this.onScanBarcode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<DeliveryProvider>(
      builder: (context, provider, _) {
        final listState = provider.listState;
        final formState = provider.formState;

        return PagedBodyView<Map<String, dynamic>>(
          controller: provider.scrollController,
          isLoading: listState.isLoading,
          error: listState.error,
          items: provider.filteredOrders,
          hasMore: listState.hasMore,
          onRefresh: provider.loadInitialOrders,
          onLoadMore: provider.loadMoreOrders,
          emptyIcon: Icons.local_shipping_outlined,
          emptyTitle: 'Belum Ada Data Pengiriman',
          emptySubtitle:
              'Silakan ketik atau scan nomor resi pesanan di kolom pencarian di atas.',
          sliverHeader: SliverToBoxAdapter(
            child: _buildHeader(context, provider, colorScheme, textTheme),
          ),
          itemBuilder: (context, index) {
            final order = provider.filteredOrders[index];
            final orderId = int.tryParse(order['id']?.toString() ?? '') ?? -1;

            return OrderListCard(
              order: order,
              orderMode: orderMode,
              isAdmin: listState.isAdmin,
              isStickerPrinted: provider.isStickerPrinted(orderId),
              isPrintingSticker: formState.isPrintingSticker,
              onTap: () => provider.selectOrder(order),
              onPrintSticker: () {
                final printerProvider =
                    context.read<PrinterProvider>();
                provider.printSticker(order, printerProvider);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DeliveryProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final listState = provider.listState;

    return Padding(
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (orderMode.isOnline) ...[
            _buildSearchBar(context, provider, colorScheme),
            AppSpacing.gapVerticalMD,
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Pengiriman',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (listState.isLoading && listState.currentPage == 1)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: colorScheme.primary, strokeWidth: 2),
                ),
            ],
          ),
          AppSpacing.gapVerticalXS,
          if (orderMode.isOnline) _buildPrintAllButton(context, provider, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    DeliveryProvider provider,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: SearchTextField(
            controller: provider.receiptController,
            hintText: 'Cari Nomor Resi / Scan QR & Barcode',
            onSubmitted: (_) {
              if (!provider.listState.isLoadingSearch) {
                provider.searchOrder().catchError((e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', ''),
                            style: const TextStyle(color: Colors.white)),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                  }
                });
              }
            },
            suffixWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (provider.receiptController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: provider.clearSearch,
                  ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  tooltip: 'Scan QR/Barcode',
                  onPressed: onScanBarcode,
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward,
                      color: colorScheme.primary, size: 20),
                  tooltip: 'Cari',
                  onPressed: () {
                    if (!provider.listState.isLoadingSearch) {
                      provider.searchOrder().catchError((e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                  style:
                                      const TextStyle(color: Colors.white)),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        if (provider.listState.isLoadingSearch) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: colorScheme.primary,
              strokeWidth: 2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrintAllButton(
    BuildContext context,
    DeliveryProvider provider,
    ColorScheme colorScheme,
  ) {
    final listState = provider.listState;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: listState.isPrintingPaymentProof
          ? null
          : () {
              provider.printAllPendingPaymentProofs().catchError((e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              });
            },
      icon: listState.isPrintingPaymentProof
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: colorScheme.onPrimary,
                strokeWidth: 2,
              ),
            )
          : Icon(Icons.print, color: colorScheme.onPrimary),
      label: Text(
        listState.isPrintingPaymentProof
            ? 'Menyiapkan Resi...'
            : 'Cetak Resi Belum Dikirim Seluruhnya',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }
}
