import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Stats horizontal strip di bawah AppBar halaman procurement workflow.
///
/// Menampilkan 3 metrik action (lihat spec section 4.2):
///   0 = pending approval (invoice dengan item cash-deviation pending)
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
    return Container(
      color: AppColors.primary.withValues(alpha: 0.95),
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
            color: Colors.yellow,
          ),
          const SizedBox(width: 10),
          _buildChip(
            context: context,
            index: 1,
            emoji: '🔵',
            count: siapInvoiceCount,
            label: 'siap invoice',
            color: Colors.lightBlue,
          ),
          const SizedBox(width: 10),
          _buildChip(
            context: context,
            index: 2,
            emoji: '🔴',
            count: siapBayarCount,
            label: 'siap bayar',
            color: Colors.red,
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
    return InkWell(
      onTap: hasCount ? () => onChipTap?.call(index) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: hasCount ? 0.25 : 0.1),
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
                color: Colors.white.withValues(alpha: hasCount ? 1.0 : 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: hasCount ? 1.0 : 0.5),
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
