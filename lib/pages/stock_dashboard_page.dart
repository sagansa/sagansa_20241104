import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/constants.dart';
import '../services/storage_stock_service.dart';
import '../services/asset_service.dart';
import 'home_page.dart';
import 'storage_stock_list_page.dart';
import 'transfer_stock_list_page.dart';
import 'asset_dashboard_page.dart';
import 'printer_settings_page.dart';

class StockDashboardPage extends StatefulWidget {
  const StockDashboardPage({super.key});

  @override
  State<StockDashboardPage> createState() => _StockDashboardPageState();
}

class _StockDashboardPageState extends State<StockDashboardPage> {
  String userName = '';
  String companyName = 'SAGANSA';
  bool isStorageStaff = false;
  bool _hasReportedToday = false;
  int _reportedStores = 0;
  int _totalStores = 0;
  final StorageStockService _storageStockService = StorageStockService();
  final AssetService _assetService = AssetService();
  int _assetDueTodayCount = 0;
  bool _isLoadingAsset = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkStatus();
    _loadAssetSummary();
  }

  Future<void> _checkStatus() async {
    final status = await _storageStockService.checkTodayStatus();
    if (mounted) {
      setState(() {
        _reportedStores = status['reported_stores'] ?? 0;
        _totalStores = status['total_stores'] ?? 0;
        _hasReportedToday = _reportedStores > 0;
      });
    }
  }

  /// Ringkasan aset jatuh tempo hari ini untuk badge menu Manajemen Aset.
  /// Ditampilkan untuk semua user (backend memfilter ke aset yang
  /// ditugaskan/aksesibel ke user login).
  Future<void> _loadAssetSummary() async {
    if (!mounted) return;
    setState(() => _isLoadingAsset = true);
    try {
      final summary = await _assetService.getDashboardSummary();
      if (mounted) {
        setState(() {
          _assetDueTodayCount = (summary['due_today'] ?? 0) as int;
          _isLoadingAsset = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAsset = false);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = json.decode(userString);
        final userRoles = List<String>.from(userData['roles'] ?? []);
        setState(() {
          userName = userData['name'] ?? '';
          companyName = userData['company']?['name'] ?? 'SAGANSA';
          isStorageStaff = userRoles.contains('storage-staff');
        });
      }
    } catch (e) {
      // Ignore
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
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
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
            Text(
              userName,
              style: theme.textTheme.titleSmall,
            ),
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
                // TODO: Implementasi halaman bantuan
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

                if (confirmed == true) {
                  await _logout();
                }
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
              'Manajemen Inventaris & Stok',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapVerticalXS,
            Text(
              'Monitor stok produk, kelola gudang, dan lakukan stock opname.',
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
                  icon: Icons.inventory_outlined,
                  color: AppColors.info,
                  title: 'Stok Gudang',
                  subtitle: 'Input sisa stok bahan baku saat ini di gudang.',
                      trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: _hasReportedToday ? AppColors.success.withValues(alpha: 0.1) : colorScheme.error.withValues(alpha: 0.1),
                                borderRadius: AppSpacing.borderRadiusMD,
                              ),
                              child: Text(
                                '$_reportedStores/$_totalStores',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _hasReportedToday ? AppColors.success : colorScheme.error,
                                ),
                              ),
                            ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StorageStockListPage()),
                    );
                    _checkStatus();
                  },
                ),
                _buildMenuRow(
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.warning,
                  title: 'Manajemen Aset',
                  subtitle: 'Pemeriksaan aset berkala & issue tracking.',
                  trailing: _isLoadingAsset
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : (_assetDueTodayCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.borderRadiusMD,
                              ),
                              child: Text(
                                '$_assetDueTodayCount Jatuh Tempo',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: AppSpacing.borderRadiusMD,
                              ),
                              child: Text(
                                'Aman',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            )),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AssetDashboardPage()),
                    );
                    _loadAssetSummary();
                  },
                ),
                _buildMenuRow(
                  icon: Icons.warehouse_outlined,
                  color: AppColors.secondary,
                  title: 'Transfer Stok Gudang',
                  subtitle: 'Ajukan atau verifikasi mutasi stok antar-outlet.',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TransferStockListPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 2,
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
