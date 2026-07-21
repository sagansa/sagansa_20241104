import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../pages/storage_stock_list_page.dart';
import '../../../providers/home_dashboard_provider.dart';
import '../../../theme/app_colors.dart';
import '../home_dashboard_card.dart';

/// Staff "Stok Gudang" dashboard card.
/// Baca storage.reportedStores/totalStores/hasReportedToday dari provider.
class HomeStockWarehouseCard extends StatelessWidget {
  const HomeStockWarehouseCard({super.key});

  @override
  Widget build(BuildContext context) {
    final storage =
        context.select<HomeDashboardProvider, HomeStorageState>((p) => p.storage);
    final colorScheme = Theme.of(context).colorScheme;
    final hasReported = storage.hasReportedToday;

    return HomeDashboardCard(
      icon: hasReported ? Icons.check_circle : Icons.warning_amber_rounded,
      iconColor: hasReported ? AppColors.success : colorScheme.error,
      title: 'Stok Gudang',
      value: '${storage.reportedStores}/${storage.totalStores}',
      subtitle: storage.totalStores > 0
          ? (storage.reportedStores == storage.totalStores
              ? 'Semua sudah laporan'
              : '${storage.reportedStores} store sudah laporan')
          : 'Belum ada laporan',
      onTap: () {
        final provider = context.read<HomeDashboardProvider>();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StorageStockListPage()),
        ).then((_) {
          // Refresh storage state via provider after returning from list page.
          provider.loadStorage();
        });
      },
    );
  }
}
