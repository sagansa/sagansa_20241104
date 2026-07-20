import 'package:flutter/material.dart';

import '../services/asset_service.dart';
import '../services/hygiene_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/dashboard_scaffold.dart';
import 'hygiene_list_page.dart';
import 'readiness_admin_list_page.dart';
import 'utility_usage_list_page.dart';

class OperationalDashboardPage extends StatefulWidget {
  const OperationalDashboardPage({super.key});

  @override
  State<OperationalDashboardPage> createState() =>
      _OperationalDashboardPageState();
}

class _OperationalDashboardPageState extends State<OperationalDashboardPage> {
  final HygieneService _hygieneService = HygieneService();
  bool _hasHygieneToday = false;
  bool _isLoadingHygiene = false;

  @override
  void initState() {
    super.initState();
    _checkHygiene();
  }

  Future<void> _checkHygiene() async {
    setState(() => _isLoadingHygiene = true);
    try {
      // Cek per-toko (bukan per-user): cukup satu laporan per toko per hari.
      final storeId = await AssetService().getCurrentStoreId();
      _hasHygieneToday = await _hygieneService.checkTodayStatus(
        storeId: storeId,
      );
      if (mounted) setState(() => _isLoadingHygiene = false);
    } catch (_) {
      if (mounted) setState(() => _isLoadingHygiene = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DashboardScaffold(
      currentIndex: 4,
      title: 'Menu Operasional',
      subtitle: 'Kelola kebersihan toko, kesiapan diri, dan closing store.',
      menuItems: [
        DashboardMenuItem(
          icon: Icons.checkroom_outlined,
          title: 'Kesiapan Diri',
          subtitle: 'Lihat & kelola kesiapan diri karyawan.',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReadinessAdminListPage(),
              ),
            );
          },
        ),
        DashboardMenuItem(
          icon: Icons.cleaning_services_outlined,
          title: 'Kebersihan Toko',
          subtitle: 'Inspeksi kebersihan ruangan toko.',
          trailing: _isLoadingHygiene
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: _hasHygieneToday
                        ? AppColors.success.withValues(alpha: 0.1)
                        : colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusMD,
                  ),
                  child: Text(
                    _hasHygieneToday ? 'Sudah' : 'Belum',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _hasHygieneToday
                          ? AppColors.success
                          : colorScheme.error,
                    ),
                  ),
                ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const HygieneListPage()),
            );
            _checkHygiene();
          },
        ),
        DashboardMenuItem(
          icon: Icons.electrical_services_rounded,
          title: 'Pemakaian Utility',
          subtitle: 'Catat pemakaian listrik, air, gas, dll.',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const UtilityUsageListPage()),
            );
          },
        ),
      ],
    );
  }
}
