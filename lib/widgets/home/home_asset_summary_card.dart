import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_dashboard_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Card ringkasan aset di Home.
class HomeAssetSummaryCard extends StatelessWidget {
  const HomeAssetSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final asset = context.select<HomeDashboardProvider, HomeAssetState>(
        (p) => p.asset);

    if (asset.isLoading) {
      return const _AssetSkeleton();
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
                Icon(Icons.inventory_2, color: AppColors.secondary),
                SizedBox(width: AppSpacing.sm),
                Text('Aset',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Hari Ini',
                    value: asset.dueTodayCount,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Terlambat',
                    value: asset.overdueCount,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Minggu Ini',
                    value: asset.dueThisWeekCount,
                  ),
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

class _AssetSkeleton extends StatelessWidget {
  const _AssetSkeleton();
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
                Icon(Icons.inventory_2, color: AppColors.secondary),
                SizedBox(width: AppSpacing.sm),
                Text('Aset',
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
