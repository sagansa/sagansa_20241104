import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../pages/asset_dashboard_page.dart';
import '../../../providers/home_dashboard_provider.dart';
import '../../../theme/app_colors.dart';
import '../home_dashboard_card.dart';

/// Staff "Manajemen Aset" dashboard card.
/// Baca asset.dueTodayCount dari provider.
class HomeAssetCard extends StatelessWidget {
  const HomeAssetCard({super.key});

  @override
  Widget build(BuildContext context) {
    final asset =
        context.select<HomeDashboardProvider, HomeAssetState>((p) => p.asset);

    return HomeDashboardCard(
      icon: Icons.inventory_2_outlined,
      iconColor: AppColors.warning,
      title: 'Manajemen Aset',
      value: asset.isLoading
          ? 'Loading...'
          : (asset.dueTodayCount > 0
              ? '${asset.dueTodayCount} Jatuh Tempo'
              : 'Aman'),
      subtitle: 'Aset yang ditugaskan ke Anda',
      onTap: () {
        final provider = context.read<HomeDashboardProvider>();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AssetDashboardPage()),
        ).then((_) {
          // Refresh asset state via provider after returning.
          provider.loadAsset();
        });
      },
    );
  }
}
