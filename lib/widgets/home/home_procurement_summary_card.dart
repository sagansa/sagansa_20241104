import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_dashboard_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Card ringkasan procurement di Home.
///
/// Subscribe ke [HomeDashboardProvider.procurement] via `context.select`
/// agar hanya rebuild saat state procurement berubah.
class HomeProcurementSummaryCard extends StatelessWidget {
  const HomeProcurementSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final procurement = context.select<HomeDashboardProvider,
        HomeProcurementState>((p) => p.procurement);

    if (procurement.isLoading) {
      return const _ProcurementSkeleton();
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.shopping_cart, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
                Text('Procurement',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                      label: 'Pending', value: procurement.pendingCount),
                ),
                Expanded(
                  child: _Stat(
                      label: 'Approved',
                      value: procurement.approvedCount),
                ),
                Expanded(
                  child: _Stat(
                      label: 'Invoice Draft',
                      value: procurement.invoiceDraftCount),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                      label: 'Invoice Done',
                      value: procurement.invoiceDoneCount),
                ),
                Expanded(
                  child: _Stat(
                      label: 'Unpaid',
                      value: procurement.unpaidInvoicesCount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ProcurementSkeleton extends StatelessWidget {
  const _ProcurementSkeleton();
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.shopping_cart, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
                Text('Procurement',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
