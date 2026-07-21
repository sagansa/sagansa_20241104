import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/home_dashboard_provider.dart';
import '../home_compact_card.dart';

/// Admin card #6: Aset Jatuh Tempo.
/// Baca asset.dueTodayCount dari provider.
class HomeAssetDueCard extends StatelessWidget {
  const HomeAssetDueCard({super.key});

  @override
  Widget build(BuildContext context) {
    final asset = context.select<HomeDashboardProvider, HomeAssetState>(
        (p) => p.asset);

    return HomeCompactCard(
      icon: Icons.notification_important_outlined,
      iconColor: Theme.of(context).colorScheme.error,
      value: '${asset.dueTodayCount}',
      label: 'Aset Jatuh Tempo',
      isLoading: asset.isLoading,
    );
  }
}
