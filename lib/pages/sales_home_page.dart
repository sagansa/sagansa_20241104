import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_spacing.dart';
import 'delivery_address_list_page.dart';
import 'sales_order_employee_list_page.dart';

/// Home khusus user sales-only.
///
/// Tanpa bottom navbar, tanpa drawer, tanpa section presence/clock-in.
/// Tab "Penjualan" ([SalesOrderEmployeeListPage]) hanya untuk sales aktif —
/// `sales + former-employee` diblokir dari penjualan dan hanya melihat
/// tab "Konsumen" ([DeliveryAddressListPage]).
class SalesHomePage extends StatefulWidget {
  const SalesHomePage({super.key});

  @override
  State<SalesHomePage> createState() => _SalesHomePageState();
}

class _SalesHomePageState extends State<SalesHomePage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _canSell = false;

  @override
  void initState() {
    super.initState();
    _loadCanSell();
    context.read<AuthProvider>().loadUserInfo();
  }

  Future<void> _loadCanSell() async {
    final canSell = await AuthService.canSell();
    if (!mounted) return;
    _tabController?.dispose();
    setState(() {
      _canSell = canSell;
      _tabController = TabController(length: canSell ? 2 : 1, vsync: this);
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.logout();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userName = context.select<AuthProvider, String>((a) => a.userName);
    final tabController = _tabController;

    if (tabController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName.isEmpty ? 'Sales' : userName,
              style: theme.textTheme.titleSmall,
            ),
            Text(
              _canSell ? 'Mode Penjualan' : 'Mode Konsumen',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          AppSpacing.gapHorizontalSM,
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: colorScheme.surface,
            child: TabBar(
              controller: tabController,
              indicatorColor: colorScheme.primary,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              tabs: _canSell
                  ? const [Tab(text: 'Penjualan'), Tab(text: 'Konsumen')]
                  : const [Tab(text: 'Konsumen')],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: _canSell
            ? const [
                SalesOrderEmployeeListPage(showAppBar: false),
                DeliveryAddressListPage(showAppBar: false),
              ]
            : const [
                DeliveryAddressListPage(showAppBar: false),
              ],
      ),
    );
  }
}
