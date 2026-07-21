import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../pages/inventory_anomaly_page.dart';
import '../../../providers/home_dashboard_provider.dart';
import '../../../theme/app_colors.dart';
import '../home_compact_card.dart';

/// Admin card #3: Selisih Stok (Anomali).
/// Baca anomaly.mismatchCount + anomaly.matchCount dari provider.
class HomeAnomalyCard extends StatelessWidget {
  const HomeAnomalyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final anomaly = context.select<HomeDashboardProvider, HomeAnomalyState>(
        (p) => p.anomaly);

    final displayValue = anomaly.mismatchCount == null
        ? '-'
        : '${anomaly.mismatchCount}';

    return HomeCompactCard(
      icon: Icons.compare_arrows,
      iconColor: Theme.of(context).colorScheme.error,
      value: displayValue,
      label: 'Selisih Stok',
      badge: anomaly.matchCount > 0 ? '${anomaly.matchCount} cocok' : null,
      badgeColor: AppColors.success,
      isLoading: anomaly.isLoading,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InventoryAnomalyPage()),
      ),
    );
  }
}
