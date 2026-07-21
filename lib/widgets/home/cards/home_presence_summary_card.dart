import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/home_dashboard_provider.dart';
import '../../../theme/app_colors.dart';
import '../home_compact_card.dart';

/// Admin card #1: Presensi.
/// Baca adminPresence.todayPresences/totalEmployees/lateCount dari provider.
///
/// [onTap] dibawa dari parent (home_page) karena sheet detail presensi
/// dibangun di sana, menggunakan state yang sama dari provider.
class HomePresenceSummaryCard extends StatelessWidget {
  final VoidCallback? onTap;
  const HomePresenceSummaryCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final presence = context.select<HomeDashboardProvider,
        HomeAdminPresenceState>((p) => p.adminPresence);

    return HomeCompactCard(
      icon: Icons.fingerprint,
      iconColor: AppColors.success,
      value: '${presence.todayPresences.length}/${presence.totalEmployees}',
      label: 'Presensi',
      badge: presence.lateCount > 0 ? '${presence.lateCount} telat' : null,
      badgeColor: Theme.of(context).colorScheme.error,
      isLoading: presence.isLoading,
      onTap: onTap,
    );
  }
}
