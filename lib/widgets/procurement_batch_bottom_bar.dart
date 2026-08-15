import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';
import 'glass_container.dart';

/// Bottom bar untuk aksi batch di halaman procurement workflow.
///
/// Dua mode (per spec section 4.6):
///   - requestMode: "Gabung N Request jadi 1 Invoice"
///   - invoiceMode: "Bayar Sekaligus (Rp X)"
class ProcurementBatchBottomBar extends StatelessWidget {
  final int selectedCount;
  final String actionLabel;
  final String? infoLine;
  final String? amountLine;
  final IconData actionIcon;
  final Color actionColor;
  final VoidCallback? onAction;
  final VoidCallback? onClear;

  const ProcurementBatchBottomBar({
    super.key,
    required this.selectedCount,
    required this.actionLabel,
    this.infoLine,
    this.amountLine,
    required this.actionIcon,
    required this.actionColor,
    this.onAction,
    this.onClear,
  });

  /// Mode untuk tab Request: gabung N request → 1 invoice.
  factory ProcurementBatchBottomBar.requestMode({
    required int selectedCount,
    VoidCallback? onAction,
    VoidCallback? onClear,
  }) {
    return ProcurementBatchBottomBar(
      selectedCount: selectedCount,
      actionLabel: 'Gabung jadi 1 Invoice',
      infoLine: '$selectedCount Request terpilih',
      actionIcon: Icons.merge_outlined,
      actionColor: AppColors.primary,
      onAction: onAction,
      onClear: onClear,
    );
  }

  /// Mode untuk tab Invoice: bayar beberapa invoice sekaligus.
  factory ProcurementBatchBottomBar.invoiceMode({
    required int selectedCount,
    required int totalAmount,
    VoidCallback? onAction,
    VoidCallback? onClear,
  }) {
    return ProcurementBatchBottomBar(
      selectedCount: selectedCount,
      actionLabel: 'Bayar Sekaligus',
      infoLine: '$selectedCount Invoice terpilih',
      amountLine: FormatUtils.formatCurrency(totalAmount),
      actionIcon: Icons.payment,
      actionColor: AppColors.info,
      onAction: onAction,
      onClear: onClear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer.bottomBar(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (infoLine != null)
                  Text(
                    infoLine!,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                if (amountLine != null)
                  Text(
                    amountLine!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: actionColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          if (onClear != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onClear,
              tooltip: 'Batal',
            ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon, size: 18),
            label: Text(actionLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
