import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/home_dashboard_provider.dart';
import '../home_compact_card.dart';

/// Admin card #5: Laporan Stok.
/// Baca storage.reportedStores/totalStores dari provider.
class HomeStockReportCard extends StatelessWidget {
  const HomeStockReportCard({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.select<HomeDashboardProvider, HomeStorageState>(
        (p) => p.storage);

    return HomeCompactCard(
      icon: Icons.inventory_2_outlined,
      iconColor: Theme.of(context).colorScheme.primary,
      value: '${storage.reportedStores}/${storage.totalStores}',
      label: 'Laporan Stok',
      isLoading: storage.isLoading,
    );
  }
}
