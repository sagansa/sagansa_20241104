import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/app_colors.dart';
import '../widgets/modern_bottom_sheet.dart';
import '../theme/app_spacing.dart';
import '../utils/constants.dart';
import 'home_page.dart';
import 'delivery_page.dart';
import 'printer_settings_page.dart';
import 'procurement_dashboard_page.dart';
import 'invoice_dashboard_page.dart';
import 'payment_receipt_dashboard_page.dart';
import 'closing_store_page.dart';
import 'fuel_service_list_page.dart';
import 'supplier_list_page.dart';

class TransactionDashboardPage extends StatefulWidget {
  const TransactionDashboardPage({super.key});

  @override
  State<TransactionDashboardPage> createState() => _TransactionDashboardPageState();
}

class _TransactionDashboardPageState extends State<TransactionDashboardPage> {
  String userName = '';
  String companyName = 'SAGANSA';
  bool isStorageStaff = false;
  bool isAdmin = false;
  bool isSupervisor = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
          isAdmin = userRoles.contains('admin') || userRoles.contains('super_admin');
          isSupervisor = userRoles.contains('supervisor');
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
              'Layanan Kasir & Penjualan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapVerticalXS,
            Text(
              'Kelola tutup shift laci kasir, pelacakan kurir, cetak stiker, dan invoice.',
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
                  icon: Icons.storefront_outlined,
                  color: AppColors.primary,
                  title: 'Tutup Shift Toko',
                  subtitle: 'Catat laci kasir, setoran EDC & closing toko.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ClosingStorePage()),
                    );
                  },
                ),
                _buildMenuRow(
                  icon: Icons.local_gas_station_outlined,
                  color: AppColors.success,
                  title: 'Bensin & Servis',
                  subtitle: 'Catat pengeluaran bensin dan servis kendaraan.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FuelServiceListPage()),
                    );
                  },
                ),
                _buildMenuRow(
                  icon: Icons.receipt_outlined,
                  color: AppColors.success,
                  title: 'Request & Purchase',
                  subtitle: 'Kelola request belanja toko & approve item transfer.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProcurementDashboardPage()),
                    );
                  },
                ),
                _buildMenuRow(
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.primary,
                  title: 'Invoice Purchase',
                  subtitle: 'Lihat daftar invoice purchase & status pembayaran.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InvoiceDashboardPage()),
                    );
                  },
                ),
                _buildMenuRow(
                  icon: Icons.payments_outlined,
                  color: AppColors.success,
                  title: 'Payment Receipt',
                  subtitle: 'Riwayat pembayaran transfer invoice purchase.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentReceiptDashboardPage()),
                    );
                  },
                ),
                if (isStorageStaff) ...[
                  _buildMenuRow(
                    icon: Icons.local_shipping_outlined,
                    color: AppColors.info,
                    title: 'Pengiriman',
                    subtitle: 'Proses pengiriman pesanan online & direct.',
                    onTap: () {
                      ModernBottomSheet.show(
                        context: context,
                        title: 'Pilih Tipe Pengiriman',
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: Container(
                                padding: AppSpacing.paddingSM,
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.1),
                                  borderRadius: AppSpacing.borderRadiusSM,
                                ),
                                child: const Icon(Icons.local_shipping_outlined, color: AppColors.info),
                              ),
                              title: const Text('Pengiriman Online'),
                              subtitle: const Text('Kurir & logistik (OS)'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DeliveryPage(orderFor: '3'),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: Container(
                                padding: AppSpacing.paddingSM,
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: AppSpacing.borderRadiusSM,
                                ),
                                child: const Icon(Icons.directions_run_outlined, color: AppColors.warning),
                              ),
                              title: const Text('Pengiriman Direct'),
                              subtitle: const Text('Langsung outlet/toko'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DeliveryPage(orderFor: '1'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                if (isAdmin || isSupervisor) ...[
                  _buildMenuRow(
                    icon: Icons.store_mall_directory_outlined,
                    color: colorScheme.tertiary,
                    title: 'Supplier',
                    subtitle: 'Kelola daftar supplier & rekening bank.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SupplierListPage()),
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 3,
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
