import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/enums/delivery_status.dart';
import '../../models/enums/order_mode.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/printer_provider.dart';
import '../../services/image_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/status_mappers.dart';
import '../../widgets/photo_uploader.dart';
import '../../widgets/status_badge.dart';
import 'delivery_actions.dart';
import 'delivery_stepper.dart';
import 'sticker_print_button.dart';

class OnlineOrderDetailView extends StatelessWidget {
  final Map<String, dynamic> order;
  final OrderMode orderMode;
  final DeliveryStatus status;

  const OnlineOrderDetailView({
    super.key,
    required this.order,
    required this.orderMode,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<DeliveryProvider>();
    final formState = provider.formState;
    final listState = provider.listState;

    final deliveryStatus = status;
    final canMarkReadyToShip = deliveryStatus.canMarkReady;
    final canSubmitDelivery = deliveryStatus.canSubmitDelivery;

    return SingleChildScrollView(
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DeliveryStepper(
            status: status,
            orderMode: orderMode,
            isStickerPrinted: provider.isStickerPrinted(
              int.tryParse(order['id']?.toString() ?? '') ?? 0,
            ),
          ),
          AppSpacing.gapVerticalMD,
          _buildTransactionInfoCard(context, textTheme, colorScheme),
          AppSpacing.gapVerticalMD,
          _buildRecipientCard(context, textTheme, colorScheme),
          AppSpacing.gapVerticalMD,
          _buildLogisticsCard(context, textTheme, colorScheme),
          AppSpacing.gapVerticalMD,
          _buildProductsCard(context, textTheme, colorScheme, listState),
          AppSpacing.gapVerticalMD,
          if (order['image_payment_url'] != null) ...[
            _buildPaymentProofCard(context, textTheme, colorScheme),
            AppSpacing.gapVerticalMD,
            if (provider.hasPaymentProof(order))
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: formState.isPrintingPaymentProof
                      ? null
                      : () {
                          provider.printPaymentProof(order).catchError((e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e'.replaceAll('Exception: ', ''))),
                              );
                            }
                          });
                        },
                  icon: formState.isPrintingPaymentProof
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.image_outlined),
                  label: Text(formState.isPrintingPaymentProof ? 'Mencetak...' : 'Cetak Bukti Bayar'),
                ),
              ),
            AppSpacing.gapVerticalMD,
            StickerPrintButton(
              order: order,
              isPrinting: formState.isPrintingSticker,
              onPrint: () {
                final printerProvider = context.read<PrinterProvider>();
                provider.printSticker(order, printerProvider);
              },
            ),
          ],
          AppSpacing.gapVerticalMD,
          if (order['image_delivery_url'] != null) ...[
            _buildDeliveryPhotoCard(context, textTheme, colorScheme),
            AppSpacing.gapVerticalMD,
          ],
          if (canMarkReadyToShip)
            MarkReadyToShipCard(
              isLoading: formState.isMarkingReady,
              onMarkReady: () {
                provider.markReadyToShip().catchError((e) {
                  if (context.mounted) _showError(context, e);
                });
              },
            )
          else if (canSubmitDelivery) ...[
            _buildDeliveryForm(context, provider, textTheme, colorScheme),
            AppSpacing.gapVerticalMD,
            _buildRefundButton(context, provider, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionInfoCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final receiptNo = order['receipt_no'] ?? '-';
    final providerName = order['provider_name'] ?? '-';
    final storeName = order['store_name'] ?? '-';

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildProviderBadge(providerName, colorScheme, textTheme),
                    StatusBadge(
                      label: StatusMappers.deliveryLabel(order['delivery_status']),
                      type: StatusMappers.deliveryStatus(order['delivery_status']),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NOMOR RESI',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            receiptNo,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (receiptNo != '-')
                      IconButton(
                        icon: Icon(Icons.copy, size: 18, color: AppColors.info),
                        tooltip: 'Salin Resi',
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: receiptNo));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Nomor resi disalin ke clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          _buildDashedLine(colorScheme),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOKO ASAL',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        storeName,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (order['ordered_by_name'] != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DIPESAN OLEH',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order['ordered_by_name'],
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderBadge(
      String providerName, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag, size: 12, color: AppColors.info),
          const SizedBox(width: 6),
          Text(
            providerName,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 5.0;
          const dashHeight = 1.0;
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant
                        .withValues(alpha: 0.5),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildRecipientCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final recipientName =
        order['address_recipient_name'] ?? order['received_by'] ?? '-';
    final recipientPhone = order['address_recipient_telp_no'] ?? '-';
    final addressName = order['address_name'] ?? '';
    final fullAddress = [
      if (order['address_detail'] != null &&
          order['address_detail'].toString().trim().isNotEmpty)
        order['address_detail'].toString().trim(),
      if (order['address_subdistrict'] != null &&
          order['address_subdistrict'].toString().trim().isNotEmpty)
        'Kec. ${order['address_subdistrict']}',
      if (order['address_district'] != null &&
          order['address_district'].toString().trim().isNotEmpty)
        order['address_district'].toString().trim(),
      if (order['address_city'] != null &&
          order['address_city'].toString().trim().isNotEmpty)
        order['address_city'].toString().trim(),
      if (order['address_province'] != null &&
          order['address_province'].toString().trim().isNotEmpty)
        order['address_province'].toString().trim(),
    ].join(', ');

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_pin_circle,
                      color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Penerima & Alamat Kirim',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NAMA PENERIMA',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipientName,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (recipientPhone != '-' && recipientPhone.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.copy, size: 18, color: AppColors.info),
                    tooltip: 'Salin Telepon',
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: recipientPhone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Nomor telepon disalin ke clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOMOR TELEPON',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipientPhone,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ALAMAT PENGIRIMAN',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (addressName.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.secondary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                addressName,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.secondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fullAddress.isEmpty ? '-' : fullAddress,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (fullAddress.isNotEmpty && fullAddress != '-')
                  IconButton(
                    icon: Icon(Icons.copy, size: 18, color: AppColors.info),
                    tooltip: 'Salin Alamat',
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: fullAddress));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Alamat lengkap disalin ke clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogisticsCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final deliveryServiceName =
        order['delivery_service_name'] ?? '-';
    final deliveryDate = order['delivery_date'] ?? '-';
    final provider = context.read<DeliveryProvider>();

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_shipping,
                      color: colorScheme.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Informasi Logistik',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
                height: 1,
                color: colorScheme.outlineVariant
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildLogisticField(
                      'EKSPEDISI / JASA KIRIM',
                      deliveryServiceName,
                      textTheme,
                      colorScheme),
                ),
                Expanded(
                  child: _buildLogisticField(
                      'TANGGAL KIRIM',
                      deliveryDate,
                      textTheme,
                      colorScheme),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildLogisticField(
                      'STATUS CETAK LABEL',
                      provider.paymentProofPrintStatusText(order),
                      textTheme,
                      colorScheme),
                ),
                if (status.isLocked)
                  Expanded(
                    child: _buildLogisticField(
                        'PENERIMA LAPANGAN',
                        order['received_by'] ?? '-',
                        textTheme,
                        colorScheme),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogisticField(String label, String value,
      TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant
                .withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
    DeliveryListState listState,
  ) {
    final provider = context.read<DeliveryProvider>();

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Rincian Produk',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
                height: 1,
                color: colorScheme.outlineVariant
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            if (order['items'] != null &&
                (order['items'] as List).isNotEmpty) ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: (order['items'] as List).length,
                separatorBuilder: (context, index) => Divider(
                    height: 16,
                    color: colorScheme.outlineVariant
                        .withValues(alpha: 0.2)),
                itemBuilder: (context, index) {
                  final item = order['items'][index];
                  final unitPrice = item['unit_price'] ?? 0;
                  final subtotalPrice = item['subtotal_price'] ?? 0;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: colorScheme.primary
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '${item['quantity']} ${item['product_unit'] ?? 'pcs'}',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['product_name'] ?? '-',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (listState.isAdmin) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${provider.formatPrice(unitPrice)} x ${item['quantity']} = ${provider.formatPrice(subtotalPrice)}',
                                style: textTheme.bodySmall?.copyWith(
                                  color:
                                      colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (listState.isAdmin) ...[
                const SizedBox(height: 16),
                Divider(
                    height: 1,
                    color: colorScheme.outlineVariant
                        .withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Harga',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      provider.formatPrice(order['total_price']),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Tidak ada rincian produk.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentProofCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment,
                    color: colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Resi',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNetworkImage(context,
              imageUrl: order['image_payment_url'],
              errorText: 'Gagal memuat bukti pembayaran',
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryPhotoCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo,
                    color: colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Foto Bukti Pengiriman',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNetworkImage(context,
              imageUrl: order['image_delivery_url'],
              errorText: 'Gagal memuat bukti pengiriman',
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkImage(
    BuildContext context, {
    required String? imageUrl,
    required String errorText,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    // Normalisasi URL: backend mungkin mengirim path relatif (mis. hasil
    // decode JSON yang gagal) atau URL absolut. buildUrl menangani keduanya
    // dan menjamin host img.sagansa.id yang benar. Null/empty → placeholder.
    final resolvedUrl = ImageService.buildUrl(imageUrl);
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      return _buildImagePlaceholder(colorScheme, textTheme, errorText, 200);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  InteractiveViewer(
                    child: Image.network(
                      resolvedUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: progress.cumulativeBytesLoaded /
                                (progress.expectedTotalBytes ?? 1),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          color: Colors.black54,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.broken_image,
                                  color: Colors.white70, size: 48),
                              const SizedBox(height: 12),
                              Text(errorText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          );
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Image.network(
              resolvedUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildImagePlaceholder(
                    colorScheme, textTheme, errorText, 120);
              },
            ),
            Container(
              width: double.infinity,
              color: Colors.black.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.zoom_in,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Ketuk untuk memperbesar gambar',
                    style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(
    ColorScheme colorScheme,
    TextTheme textTheme,
    String errorText,
    double height,
  ) {
    return Container(
      height: height,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, color: Colors.grey, size: 36),
          const SizedBox(height: 8),
          Text(errorText, style: textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildDeliveryForm(
    BuildContext context,
    DeliveryProvider provider,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final formState = provider.formState;

    return SubmitDeliveryCard(
      selectedStatus: formState.selectedStatus,
      isSubmitting: formState.isSubmitting,
      hasPhotos: provider.imageFiles.isNotEmpty,
      receiverField: _buildGoldTextField(
        labelText: 'Nama Penerima (Wajib)',
        controller: provider.receiverController,
        prefixIcon: Icons.person_outline,
        colorScheme: colorScheme,
      ),
      notesField: _buildGoldTextField(
        labelText: 'Alasan Pengembalian (Wajib)',
        controller: provider.notesController,
        prefixIcon: Icons.notes_outlined,
        colorScheme: colorScheme,
      ),
      photoUploader: PhotoUploader(
        photos: provider.imageFiles,
        onChanged: provider.setPhotos,
        layout: PhotoUploaderLayout.grid,
        maxPhotos: 999,
        label: formState.selectedStatus == 6
            ? 'Ambil Foto Bukti Retur'
            : 'Ambil Foto Bukti Pengiriman',
      ),
      onStatusChanged: (status) => provider.setStatus(status),
      onSubmit: () {
        _showDeliveryConfirmDialog(
          context,
          provider,
          formState.selectedStatus,
        );
      },
    );
  }

  void _showDeliveryConfirmDialog(
    BuildContext context,
    DeliveryProvider provider,
    int selectedStatus,
  ) {
    if (selectedStatus == 3 &&
        provider.receiverController.text.trim().isEmpty) {
      _showError(context, 'Harap isi nama penerima terlebih dahulu.');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pengiriman'),
        content: const Text(
          'Apakah Anda yakin ingin mengirim bukti pengiriman ini? '
          'Status pengiriman akan diubah menjadi "Sudah Dikirim" dan tidak dapat diubah lagi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.submitDelivery(onSuccess: () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Status pengiriman berhasil diperbarui.'),
                      backgroundColor: Colors.green.shade600,
                    ),
                  );
                }
              }).catchError((e) {
                if (context.mounted) _showError(context, e);
              });
            },
            child: const Text('Ya, Kirim'),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundButton(
    BuildContext context,
    DeliveryProvider provider,
    ColorScheme colorScheme,
  ) {
    return RefundButton(
      onRefund: () => _showRefundDialog(context, provider),
    );
  }

  void _showRefundDialog(
      BuildContext context, DeliveryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        final dialogColorScheme = Theme.of(ctx).colorScheme;
        final dialogTextTheme = Theme.of(ctx).textTheme;

        return AlertDialog(
          backgroundColor: dialogColorScheme.surface,
          title: Row(
            children: [
              Icon(Icons.assignment_return, color: AppColors.error),
              const SizedBox(width: 10),
              Text(
                'Konfirmasi Refund / Kembalikan',
                style: dialogTextTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: dialogColorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin mengembalikan order ini? '
            'Status pengiriman akan diubah menjadi "Dikembalikan" dan tidak dapat diubah lagi.',
            style: dialogTextTheme.bodyMedium?.copyWith(
              color: dialogColorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal',
                  style: TextStyle(
                      color: dialogColorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogColorScheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                provider.setStatus(6);
                provider.imageFiles.clear();
                provider.notesController.text =
                    'Refund oleh storage staff';
                provider.submitDelivery(onSuccess: () {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Status pengiriman berhasil diperbarui.'),
                        backgroundColor: Colors.green.shade600,
                      ),
                    );
                  }
                }).catchError((e) {
                  if (context.mounted) _showError(context, e);
                });
              },
              child: const Text('Ya, Kembalikan'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoldTextField({
    required String labelText,
    required TextEditingController controller,
    required IconData prefixIcon,
    required ColorScheme colorScheme,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle:
            TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon:
            Icon(prefixIcon, color: AppColors.info),
      ),
    );
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.toString().replaceAll('Exception: ', ''),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
