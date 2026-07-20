import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_dashboard_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/format_utils.dart';

/// Card ringkasan sales & anomaly di Home.
class HomeSalesAnomalyCard extends StatelessWidget {
  const HomeSalesAnomalyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final sales = context.select<HomeDashboardProvider, HomeSalesState>(
        (p) => p.sales);
    final anomaly = context.select<HomeDashboardProvider, HomeAnomalyState>(
        (p) => p.anomaly);

    if (sales.isLoading || anomaly.isLoading) {
      return const _SalesSkeleton();
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
                Icon(Icons.trending_up, color: AppColors.info),
                SizedBox(width: AppSpacing.sm),
                Text('Penjualan & Anomali',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Omzet Kemarin',
                    value: sales.yesterdayOmzet != null
                        ? FormatUtils.formatCurrencyCompact(
                            sales.yesterdayOmzet!)
                        : '-',
                    icon: Icons.attach_money,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatItem(
                    label: 'Anomali',
                    value: '${anomaly.mismatchCount ?? 0}',
                    icon: Icons.warning_amber,
                    color: (anomaly.mismatchCount ?? 0) > 0
                        ? AppColors.error
                        : AppColors.success,
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppColors.onSurfaceVariant, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
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

class _SalesSkeleton extends StatelessWidget {
  const _SalesSkeleton();
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
                Icon(Icons.trending_up, color: AppColors.info),
                SizedBox(width: AppSpacing.sm),
                Text('Penjualan & Anomali',
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
