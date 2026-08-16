import 'package:flutter/material.dart';
import '../models/procurement_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/format_utils.dart';
import 'list_thumbnail.dart';

class PaymentReceiptCard extends StatelessWidget {
  final PaymentReceipt receipt;
  final VoidCallback onTap;

  /// Menu tambahan (opsional): bila salah satu disediakan, kartu menampilkan
  /// popup menu ⋮ (mirror pola kartu daily salary).
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PaymentReceiptCard({
    super.key,
    required this.receipt,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  String _getPaymentForLabel(String paymentFor) {
    switch (paymentFor) {
      case '1':
        return 'Fuel Service';
      case '2':
        return 'Gaji Harian';
      case '3':
        return 'Invoice Supplier';
      default:
        return 'Lainnya';
    }
  }

  Color _getPaymentForColor(String paymentFor) {
    switch (paymentFor) {
      case '1':
        return const Color(0xFFE53935); // red accent
      case '2':
        return const Color(0xFF1E88E5); // blue accent
      case '3':
        return const Color(0xFF43A047); // green accent
      default:
        return AppColors.secondary;
    }
  }

  /// Judul kartu: nama karyawan untuk receipt gaji harian (payment_for == '2'),
  /// nama supplier untuk invoice, fallback ke Receipt #id.
  String _getTitle() {
    if (receipt.paymentFor == '2') {
      final employeeName =
          receipt.dailySalaries.isNotEmpty ? receipt.dailySalaries.first.createdByName : null;
      if (employeeName != null && employeeName.isNotEmpty) {
        return employeeName;
      }
      return 'Receipt #${receipt.id}';
    }
    if (receipt.supplierName != null && receipt.supplierName!.isNotEmpty) {
      return receipt.supplierName!;
    }
    return 'Receipt #${receipt.id}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final typeLabel = _getPaymentForLabel(receipt.paymentFor);
    final typeColor = _getPaymentForColor(receipt.paymentFor);
    final formattedDate = receipt.createdAt.length >= 10
        ? receipt.createdAt.substring(0, 10)
        : receipt.createdAt;
    final formattedAmount = FormatUtils.formatCurrency(receipt.transferAmount);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(
          color: isDark
              ? Colors.white12
              : AppColors.secondaryContainer.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail preview if available, else placeholder icon
                ListThumbnail(
                  imageUrl: receipt.imageUrl,
                  size: 56,
                  placeholderIcon: Icons.receipt_long_rounded,
                ),
                AppSpacing.gapHorizontalMD,
                // Content section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: typeColor.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                              ),
                            ),
                          ),
                          // Date
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapVerticalXS,
                      // Receipt ID / Supplier Name / Employee Name
                      Text(
                        _getTitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (receipt.notes != null && receipt.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          receipt.notes!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      AppSpacing.gapVerticalSM,
                      // Transfer Amount Highlight
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Transfer:',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            formattedAmount,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.gold : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        color: colorScheme.onSurfaceVariant),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.delete_outline),
                            title: Text('Hapus'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
