import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/home_dashboard_provider.dart';
import '../services/notification_service.dart';
import '../services/version_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/home/cards/home_anomaly_card.dart';
import '../widgets/home/cards/home_asset_card.dart';
import '../widgets/home/cards/home_asset_due_card.dart';
import '../widgets/home/cards/home_closing_store_card.dart';
import '../widgets/home/cards/home_delivery_card.dart';
import '../widgets/home/cards/home_invoice_unpaid_card.dart';
import '../widgets/home/cards/home_leave_card.dart';
import '../widgets/home/cards/home_loan_card.dart';
import '../widgets/home/cards/home_presence_summary_card.dart';
import '../widgets/home/cards/home_salary_slip_card.dart';
import '../widgets/home/cards/home_shopping_card.dart';
import '../widgets/home/cards/home_specific_gravity_card.dart';
import '../widgets/home/cards/home_stock_report_card.dart';
import '../widgets/home/cards/home_stock_warehouse_card.dart';
import '../widgets/home/cards/home_yesterday_omzet_card.dart';
import '../widgets/home/home_drawer.dart';
import '../widgets/home/sections/home_presence_section.dart';
import '../widgets/home/sections/home_storage_stocks_section.dart';
import '../widgets/home/sections/today_presences_sheet.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/theme_toggle_button.dart';
import 'hrd_dashboard_page.dart';
import 'notification_list_page.dart';
import 'presence_page.dart';
import 'stock_dashboard_page.dart';
import 'transaction_dashboard_page.dart';


class HomePage extends StatefulWidget {
  final bool? initialIsAdmin;
  const HomePage({super.key, this.initialIsAdmin});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  bool isLoading = false;
  final int _selectedIndex = 0;

  /// Jumlah notifikasi belum dibaca (badge bell).
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initData();
    _refreshUnreadCount();

    // Check for app updates. Data loading is started after authentication in
    // _initData; starting it here as well caused duplicate unauthenticated
    // requests during app startup.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionService().checkForUpdate(context);
    });
  }

  /// Ambil jumlah notifikasi belum dibaca untuk badge bell (polling manual).
  Future<void> _refreshUnreadCount() async {
    try {
      final count = await NotificationService.instance.getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      // Abaikan kegagalan (mis. token expired); badge cukup tidak tampil.
    }
  }

  /// Buka halaman notifikasi, lalu refresh badge saat kembali.
  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationListPage()),
    );
    if (mounted) _refreshUnreadCount();
  }

  Future<void> _initData() async {
    // Ambil provider sekali di awal sebelum await apa pun untuk menghindari
    // penggunaan BuildContext secara asynchronous.
    final homeProvider = context.read<HomeDashboardProvider>();
    final authProvider = context.read<AuthProvider>();
    setState(() {
      isLoading = true;
    });

    try {
      // Load user info (userName/companyName) + roles via AuthProvider.
      await authProvider.loadUserInfo();
      if (!mounted) return;
      final isStorageStaffRole = authProvider.isStorageStaff;
      final hasAdminRole = widget.initialIsAdmin ?? authProvider.isAdmin;

      // Load dashboard data only after the auth token/user context is ready.
      // This prevents two concurrent waves of requests (including
      // storage-stocks/today-status) during startup.
      await homeProvider.loadAll();
      if (!mounted) return;

      // Load presence data via provider (today + previous + active leave flag).
      await homeProvider.loadPresence();
      if (!mounted) return;

      if (isStorageStaffRole) {
        await homeProvider.loadOrders();
        if (!mounted) return;
      }

      await homeProvider.loadLeaveSalary();
      if (!mounted) return;

      if (hasAdminRole || isStorageStaffRole) {
        await homeProvider.loadAdminStock();
        if (!mounted) return;
        await homeProvider.loadAdminPresence();
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('User data not found')) {
          _logout();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _initData();
  }

  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.logout();
    if (!mounted) return;
    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage.isNotEmpty
              ? authProvider.errorMessage
              : 'Gagal melakukan logout'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }


  Future<void> _navigateToPresencePage() async {
    final homeProvider = context.read<HomeDashboardProvider>();
    // Langsung navigasi ke PresencePage
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresencePage(
          isCheckIn: homeProvider.presence.todayPresence == null,
        ),
      ),
    );

    // Refresh data jika ada perubahan
    if (result == true) {
      await homeProvider.loadPresence();
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        // Sudah di home, tidak perlu navigasi
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HRDDashboardPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StockDashboardPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TransactionDashboardPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Read user info & roles from AuthProvider (single source of truth).
    final userName =
        context.select<AuthProvider, String>((a) => a.userName);
    final companyName =
        context.select<AuthProvider, String>((a) => a.companyName);
    final isAdmin = widget.initialIsAdmin ??
        context.select<AuthProvider, bool>((a) => a.isAdmin);
    final isStorageStaff =
        context.select<AuthProvider, bool>((a) => a.isStorageStaff);
    final hasLoanData = context.select<HomeDashboardProvider, bool>(
        (p) => p.leaveSalary.hasLoanData);
    final isUserDataLoaded = context.select<HomeDashboardProvider, bool>(
        (p) => p.presence.isUserDataLoaded);

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
        actions: [
          badges.Badge(
            showBadge: _unreadCount > 0,
            position: badges.BadgePosition.topEnd(top: 2, end: 2),
            badgeContent: Text(
              _unreadCount > 99 ? '99+' : '$_unreadCount',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            badgeStyle: const badges.BadgeStyle(
              padding: EdgeInsets.all(5),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications),
              tooltip: 'Notifikasi',
              onPressed: _openNotifications,
            ),
          ),
          const ThemeToggleButton(),
          AppSpacing.gapHorizontalSM,
        ],
      ),
      drawer: HomeDrawer(
        userName: userName,
        companyName: companyName,
        isAdmin: isAdmin,
        onLogout: _logout,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          key: const Key('homeRefresh'),
          onRefresh: _onRefresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: AppSpacing.paddingMD,
                    child: !isUserDataLoaded
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 100),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : isAdmin
                    ? _buildAdminDashboard()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          HomePresenceSection(
                              onNavigateToPresence: _navigateToPresencePage),
                          _buildDashboardGrid(
                            isStorageStaff: isStorageStaff,
                            hasLoanData: hasLoanData,
                          ),
                        ],
                      ),
                  ),
                ),
              );
            },
          ),
        ),
      ),

      bottomNavigationBar: ModernBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        presences: () {
          final p = context.read<HomeDashboardProvider>().presence;
          return [...p.previousPresences, if (p.todayPresence != null) p.todayPresence!];
        }(),
      ),
    );
  }




  Widget _buildDashboardGrid({
    required bool isStorageStaff,
    required bool hasLoanData,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.gapVerticalMD,
        Text(
          'Menu Dashboard',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.gapVerticalSM,
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 140,
            childAspectRatio: 1.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          children: [
            if (isStorageStaff) ...[
              const HomeStockWarehouseCard(),
              const HomeDeliveryCard(),
              const HomeSpecificGravityCard(),
            ],
            // Manajemen Aset: tampilkan untuk SEMUA user. Backend otomatis
            // memfilter agar user hanya melihat aset di mana dia PIC/creator
            // (admin melihat semua).
            const HomeAssetCard(),
            const HomeClosingStoreCard(),
            const HomeSalarySlipCard(),
            const HomeLeaveCard(),
            if (hasLoanData)
              const HomeLoanCard(),
            const HomeShoppingCard(),
          ],
        ),
      ],
    );
  }


  Widget _buildAdminDashboard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome header (tetap)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Admin',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Ringkasan operasional harian toko',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        AppSpacing.gapVerticalMD,

        // 3-column grid: 6 cards
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.0,
          children: [
            // 1. Presensi (provider-driven)
            HomePresenceSummaryCard(
                onTap: () => showTodayPresencesSheet(context)),
            // 2. Omzet Kemarin (provider-driven)
            const HomeYesterdayOmzetCard(),
            // 3. Selisih Stok (provider-driven)
            const HomeAnomalyCard(),
            // 4. Invoice Unpaid (provider-driven)
            const HomeInvoiceUnpaidCard(),
            // 5. Laporan Stok (provider-driven)
            const HomeStockReportCard(),
            // 6. Aset Jatuh Tempo (provider-driven)
            const HomeAssetDueCard(),
          ],
        ),
        AppSpacing.gapVerticalLG,

        // Storage stock feed (tetap)
        const HomeStorageStocksSection(),
      ],
    );
  }

}
