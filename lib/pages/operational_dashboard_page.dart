import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import 'home_page.dart';
import 'printer_settings_page.dart';
import 'readiness_page.dart';
import 'hygiene_page.dart';
import 'utility_usage_list_page.dart';
import '../services/readiness_service.dart';
import '../services/hygiene_service.dart';

class OperationalDashboardPage extends StatefulWidget {
  const OperationalDashboardPage({super.key});

  @override
  State<OperationalDashboardPage> createState() => _OperationalDashboardPageState();
}

class _OperationalDashboardPageState extends State<OperationalDashboardPage> {
  String userName = '';
  String companyName = 'SAGANSA';

  final ReadinessService _readinessService = ReadinessService();
  final HygieneService _hygieneService = HygieneService();
  bool _hasReadinessToday = false;
  bool _hasHygieneToday = false;
  bool _isLoadingReadiness = false;
  bool _isLoadingHygiene = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkStatuses();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = json.decode(userString);
        setState(() {
          userName = userData['name'] ?? '';
          companyName = userData['company']?['name'] ?? 'SAGANSA';
        });
      }
    } catch (_) {}
  }

  Future<void> _checkStatuses() async {
    _checkReadiness();
    _checkHygiene();
  }

  Future<void> _checkReadiness() async {
    setState(() => _isLoadingReadiness = true);
    try {
      final status = await _readinessService.checkStatus();
      if (mounted) {
        setState(() {
          _hasReadinessToday = status['data']?['has_submitted_today'] ?? false;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingReadiness = false);
    }
  }

  Future<void> _checkHygiene() async {
    setState(() => _isLoadingHygiene = true);
    try {
      _hasHygieneToday = await _hygieneService.checkTodayStatus();
      if (mounted) setState(() => _isLoadingHygiene = false);
    } catch (_) {
      if (mounted) setState(() => _isLoadingHygiene = false);
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      await prefs.remove(AppConstants.tokenKey);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => InkWell(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: SvgPicture.asset(
                'assets/images/logo.svg',
                width: 36,
                fit: BoxFit.contain,
                height: 36,
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userName, style: theme.textTheme.titleSmall),
            Text(
              companyName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: AppSpacing.borderRadiusSM,
                    ),
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      width: 48,
                      fit: BoxFit.contain,
                      height: 48,
                    ),
                  ),
                  AppSpacing.gapVerticalSM,
                  Text(
                    userName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    companyName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Beranda'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: const Text('Printer Thermal'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrinterSettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Bantuan'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: colorScheme.error),
              title: Text('Logout', style: TextStyle(color: colorScheme.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Konfirmasi'),
                    content: const Text('Apakah Anda yakin ingin keluar?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Ya'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) await _logout();
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Menu Operasional',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapVerticalXS,
            Text(
              'Kelola kebersihan toko, kesiapan diri, dan closing store.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapVerticalLG,
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMenuRow(
                  icon: Icons.checklist_rtl_outlined,
                  color: colorScheme.primary,
                  title: 'Kesiapan Diri',
                  subtitle: 'Isi form kesiapan diri (wajib tiap Jumat).',
                  trailing: _isLoadingReadiness
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: _hasReadinessToday
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: AppSpacing.borderRadiusMD,
                          ),
                          child: Text(
                            _hasReadinessToday ? 'Sudah' : 'Belum',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _hasReadinessToday ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReadinessPage()),
                    );
                    _checkReadiness();
                  },
                ),
                _buildMenuRow(
                  icon: Icons.cleaning_services_outlined,
                  color: colorScheme.primary,
                  title: 'Kebersihan Toko',
                  subtitle: 'Inspeksi kebersihan ruangan toko.',
                  trailing: _isLoadingHygiene
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: _hasHygieneToday
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: AppSpacing.borderRadiusMD,
                          ),
                          child: Text(
                            _hasHygieneToday ? 'Sudah' : 'Belum',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _hasHygieneToday ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HygienePage()),
                    );
                    _checkHygiene();
                  },
                ),
                _buildMenuRow(
                  icon: Icons.electrical_services_rounded,
                  color: colorScheme.primary,
                  title: 'Pemakaian Utility',
                  subtitle: 'Catat pemakaian listrik, air, gas, dll.',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UtilityUsageListPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 4,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusLG,
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Row(
            children: [
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusMD,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              AppSpacing.gapHorizontalMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.gapVerticalXS,
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (trailing == null)
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
