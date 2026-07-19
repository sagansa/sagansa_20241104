import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Stats horizontal strip di bawah AppBar halaman procurement workflow.
///
/// Menampilkan 3 metrik action (lihat spec section 4.2):
///   0 = pending approval (request dengan item pending admin approval)
///   1 = siap invoice (request yang belum jadi invoice)
///   2 = siap bayar (invoice siap dibuat payment receipt)
class ProcurementStatsStrip extends StatelessWidget {
  final int pendingApprovalCount;
  final int siapInvoiceCount;
  final int siapBayarCount;
  final void Function(int chipIndex)? onChipTap;

  const ProcurementStatsStrip({
    super.key,
    required this.pendingApprovalCount,
    required this.siapInvoiceCount,
    required this.siapBayarCount,
    this.onChipTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      // Pakai surfaceContainerHighest agar konsisten light/dark mode,
      // tidak ada lagi "garis charcoal" yang kontras berlebihan di light.
      color: cs.surfaceContainerHighest,
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _buildChip(
            context: context,
            index: 0,
            emoji: '🟡',
            count: pendingApprovalCount,
            label: 'approval',
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          _buildChip(
            context: context,
            index: 1,
            emoji: '🔵',
            count: siapInvoiceCount,
            label: 'siap invoice',
            color: AppColors.info,
          ),
          const SizedBox(width: 10),
          _buildChip(
            context: context,
            index: 2,
            emoji: '🔴',
            count: siapBayarCount,
            label: 'siap bayar',
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required int index,
    required String emoji,
    required int count,
    required String label,
    required Color color,
  }) {
    final hasCount = count > 0;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: hasCount ? () => onChipTap?.call(index) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: hasCount ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                color: hasCount ? color : cs.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: hasCount ? cs.onSurface : cs.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
