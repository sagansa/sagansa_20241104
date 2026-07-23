import 'package:flutter/material.dart';
import '../../models/enums/order_mode.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/status_mappers.dart';
import '../../widgets/status_badge.dart';

class OrderListCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final OrderMode orderMode;
  final bool isAdmin;
  final bool isStickerPrinted;
  final bool isPrintingSticker;
  final VoidCallback onTap;
  final VoidCallback? onPrintSticker;

  const OrderListCard({
    super.key,
    required this.order,
    required this.orderMode,
    required this.isAdmin,
    required this.isStickerPrinted,
    required this.isPrintingSticker,
    required this.onTap,
    this.onPrintSticker,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final int? status = order['delivery_status'];

    return Card(
      color: colorScheme.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(colorScheme, textTheme, status),
              Divider(
                  height: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.1)),
              _buildInfoRow(
                  Icons.storefront, order['store_name'] ?? '-', colorScheme, textTheme),
              AppSpacing.gapVerticalXS,
              _buildDeliveryInfoRow(colorScheme, textTheme),
              if (order['delivery_date'] != null) ...[
                AppSpacing.gapVerticalXS,
                _buildDateRow(colorScheme, textTheme),
              ],
              if (orderMode.isDirect) ..._buildDirectOrderDetails(colorScheme, textTheme),
              if (orderMode.isOnline) ..._buildOnlineOrderExtras(colorScheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme, int? status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            orderMode.isDirect
                ? 'Order #${order['id']}'
                : (order['receipt_no'] ?? 'Tanpa Resi'),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Row(
          children: [
            StatusBadge(
              label: StatusMappers.deliveryLabel(status),
              type: StatusMappers.deliveryStatus(status),
            ),
            if (orderMode.isDirect) ...[
              AppSpacing.gapHorizontalXS,
              StatusBadge(
                label: StatusMappers.paymentLabel(order['payment_status']?.toString()),
                type: StatusMappers.paymentStatus(order['payment_status']?.toString()),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.info),
        AppSpacing.gapHorizontalSM,
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryInfoRow(ColorScheme colorScheme, TextTheme textTheme) {
    final info = orderMode.isOnline
        ? '${order['provider_name'] ?? '-'} • ${order['delivery_service_name'] ?? '-'}'
        : '${order['payment_method'] ?? '-'} • ${order['delivery_service_name'] ?? '-'}';
    return _buildInfoRow(Icons.local_shipping_outlined, info, colorScheme, textTheme);
  }

  Widget _buildDateRow(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 14, color: AppColors.info),
        AppSpacing.gapHorizontalSM,
        Text(
          order['delivery_date'],
          style: textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  List<Widget> _buildDirectOrderDetails(ColorScheme colorScheme, TextTheme textTheme) {
    final list = <Widget>[];
    if (order['ordered_by_name'] != null) {
      list.addAll([
        AppSpacing.gapVerticalXS,
        _buildInfoRow(Icons.person_outline, 'Order By: ${order['ordered_by_name']}', colorScheme, textTheme),
      ]);
    }
    list.addAll([
      AppSpacing.gapVerticalXS,
      _buildAddressRow(colorScheme, textTheme),
    ]);
    if (order['items'] != null && (order['items'] as List).isNotEmpty) {
      list.addAll([
        AppSpacing.gapVerticalXS,
        _buildItemsPreview(colorScheme, textTheme),
      ]);
    }
    return list;
  }

  Widget _buildAddressRow(ColorScheme colorScheme, TextTheme textTheme) {
    final addressDetail = order['address_detail'];
    final hasDetail = addressDetail != null && addressDetail.toString().trim().isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on_outlined, size: 16, color: AppColors.info),
        AppSpacing.gapHorizontalSM,
        Expanded(
          child: Text(
            hasDetail
                ? 'Penerima: ${order['address_recipient_name'] ?? ''} (${order['address_recipient_telp_no'] ?? ''})\n'
                    'Alamat: $addressDetail, ${order['address_subdistrict'] ?? ''}, ${order['address_district'] ?? ''}, ${order['address_city'] ?? ''}, ${order['address_province'] ?? ''}'
                : 'Alamat: -',
            style: textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsPreview(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingXS,
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: AppSpacing.borderRadiusSM,
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daftar Barang:',
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          AppSpacing.gapVerticalXS,
          ...(order['items'] as List).map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                '• ${item['product_name']} (${item['quantity']} ${item['product_unit'] ?? ''})',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _buildOnlineOrderExtras(ColorScheme colorScheme, TextTheme textTheme) {
    return [
      AppSpacing.gapVerticalXS,
      _buildPaymentProofStatus(colorScheme, textTheme),
          ...[
        AppSpacing.gapVerticalSM,
        _buildPrintStickerButton(colorScheme, textTheme),
      ],
    ];
  }

  Widget _buildPaymentProofStatus(ColorScheme colorScheme, TextTheme textTheme) {
    final isPrinted = order['payment_proof_printed_at'] != null &&
        order['payment_proof_printed_at'].toString().trim().isNotEmpty;
    final hasProof = order['image_payment_url'] != null &&
        order['image_payment_url'].toString().trim().isNotEmpty;
    final color = isPrinted
        ? AppColors.success
        : (colorScheme.brightness == Brightness.dark ? AppColors.darkPrimary : AppColors.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isPrinted
            ? AppColors.success.withValues(alpha: 0.15)
            : colorScheme.primaryContainer,
        borderRadius: AppSpacing.borderRadiusSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPrinted ? Icons.check_circle_outline : Icons.print_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              !hasProof
                  ? 'Bukti bayar belum ada'
                  : (isPrinted ? 'Bukti bayar sudah dicetak' : 'Bukti bayar belum dicetak'),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintStickerButton(ColorScheme colorScheme, TextTheme textTheme) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: isPrintingSticker ? null : onPrintSticker,
      icon: const Icon(Icons.print, size: 18),
      label: Text(isStickerPrinted ? 'Cetak Ulang Resi' : 'Cetak Resi'),
    );
  }
}
