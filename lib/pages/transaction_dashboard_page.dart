import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/dashboard_scaffold.dart';
import 'closing_store_page.dart';
import 'delivery_page.dart';
import 'fuel_service_list_page.dart';
import 'procurement_workflow_page.dart';
import 'sales_order_employee_list_page.dart';
import 'supplier_list_page.dart';

class TransactionDashboardPage extends StatefulWidget {
  const TransactionDashboardPage({super.key});

  @override
  State<TransactionDashboardPage> createState() =>
      _TransactionDashboardPageState();
}

class _TransactionDashboardPageState extends State<TransactionDashboardPage> {
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
        if (mounted) {
          setState(() {
            isStorageStaff = userRoles.contains('storage-staff');
            isAdmin = userRoles.contains('admin') ||
                userRoles.contains('super_admin');
            isSupervisor = userRoles.contains('supervisor');
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      currentIndex: 3,
      title: 'Layanan Kasir & Penjualan',
      subtitle:
          'Kelola tutup shift laci kasir, pelacakan kurir, cetak stiker, dan invoice.',
      menuItems: [
        DashboardMenuItem(
          icon: Icons.point_of_sale_outlined,
          title: 'Penjualan',
          subtitle: 'Catat penjualan: online, employee, atau direct.',
          visible: isStorageStaff || isAdmin,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Pilih Tipe Penjualan'),
                contentPadding: AppSpacing.paddingMD,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Container(
                        padding: AppSpacing.paddingSM,
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.borderRadiusSM,
                        ),
                        child: const Icon(Icons.local_shipping_outlined,
                            color: AppColors.info),
                      ),
                      title: const Text('Penjualan by Online'),
                      subtitle: const Text('Pesanan via online shop (OS)'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const DeliveryPage(orderFor: '3'),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: AppSpacing.paddingSM,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.borderRadiusSM,
                        ),
                        child: const Icon(Icons.person_outline,
                            color: AppColors.success),
                      ),
                      title: const Text('Penjualan by Employee'),
                      subtitle: const Text('Penjualan oleh sales ke customer'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SalesOrderEmployeeListPage(),
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
                        child: const Icon(Icons.directions_run_outlined,
                            color: AppColors.warning),
                      ),
                      title: const Text('Penjualan by Direct'),
                      subtitle: const Text('Langsung outlet/toko'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const DeliveryPage(orderFor: '1'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        DashboardMenuItem(
          icon: Icons.timeline_outlined,
          title: 'Pembelian',
          subtitle: 'Lacak & proses alur lengkap: Request → Invoice → Payment Receipt.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ProcurementWorkflowPage()),
            );
          },
        ),
        DashboardMenuItem(
          icon: Icons.storefront_outlined,
          title: 'Tutup Shift Toko',
          subtitle: 'Catat laci kasir, setoran EDC & closing toko.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ClosingStorePage()),
            );
          },
        ),
        DashboardMenuItem(
          icon: Icons.local_gas_station_outlined,
          title: 'Bensin & Servis',
          subtitle: 'Catat pengeluaran bensin dan servis kendaraan.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const FuelServiceListPage()),
            );
          },
        ),
        DashboardMenuItem(
          icon: Icons.store_mall_directory_outlined,
          title: 'Supplier',
          subtitle: 'Kelola daftar supplier & rekening bank.',
          visible: isAdmin || isSupervisor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SupplierListPage()),
            );
          },
        ),
      ],
    );
  }
}
