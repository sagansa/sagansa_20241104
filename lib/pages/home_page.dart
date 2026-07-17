import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import '../models/presence_model.dart';
import 'presence_page.dart';
import '../widgets/modern_bottom_nav.dart';
import 'hrd_dashboard_page.dart';
import 'stock_dashboard_page.dart';
import 'transaction_dashboard_page.dart';
import 'printer_settings_page.dart';
import '../widgets/theme_toggle_button.dart';
import '../controllers/home_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import '../services/presence_service.dart';
import '../services/version_service.dart';
import '../services/salary_service.dart';
import '../services/procurement_service.dart';
import '../models/procurement_model.dart';
import '../services/storage_stock_service.dart';
import 'storage_stock_list_page.dart';
import 'inventory_anomaly_page.dart';
import '../services/leave_service.dart';
import 'asset_dashboard_page.dart';
import '../services/asset_service.dart';
import '../services/hygiene_service.dart';
import 'hygiene_page.dart';
import '../services/readiness_service.dart';
import 'readiness_page.dart';
import 'closing_store_page.dart';


class HomePage extends StatefulWidget {
  final bool? initialIsAdmin;
  const HomePage({super.key, this.initialIsAdmin});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late HomeController _controller;
  String userName = '';
  String companyName = 'SAGANSA';
  PresenceModel? todayPresence;
  List<PresenceModel> previousPresences = [];
  final int initialDisplayCount = 7;
  bool isLoading = false;
  final int _selectedIndex = 0;
  bool _hasActiveLeave = false;
  bool isUserDataLoaded = false;
  PresenceModel? yesterdayPresence;
  bool isStorageStaff = false;
  int pendingOnlineOrderCount = 0;
  int pendingDirectOrderCount = 0;
  bool isLoadingOrders = false;
  bool hasLoanData = false;
  int pendingProcurementsCount = 0;
  bool _hasReportedStorageToday = false;
  int _reportedStores = 0;
  int _totalStores = 0;
  final StorageStockService _storageStockService = StorageStockService();
  bool _hasReportedHygieneToday = false;
  final HygieneService _hygieneService = HygieneService();
  bool _hasReportedReadinessToday = false;
  final ReadinessService _readinessService = ReadinessService();
  int approvedProcurementsCount = 0;
  int invoiceDraftCount = 0;
  int invoiceDoneCount = 0;
  int unpaidInvoicesCount = 0;
  int unpaidTransferInvoicesCount = 0;
  bool isLoadingProcurement = false;
  int pendingLeavesCount = 0;
  bool hasLeavesThisMonth = false;
  String salaryPaymentStatus = 'Belum Ada';
  bool isLoadingLeaveAndSalary = false;

  // Asset management summary.
  final AssetService _assetService = AssetService();
  int _assetDueTodayCount = 0;
  bool _isLoadingAsset = false;

  bool isAdmin = false;
  List<Map<String, dynamic>> adminStockMonitorings = [];
  bool isLoadingAdminStockMonitoring = false;
  String latestStockDate = '';
  List<dynamic> _todayPresences = [];
  bool _isLoadingTodayPresences = false;

  @override
  void initState() {
    super.initState();
    _controller = HomeController(context);
    if (widget.initialIsAdmin != null) {
      isAdmin = widget.initialIsAdmin!;
    }
    _initData();

    // Check for app updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionService().checkForUpdate(context);
    });
  }

  Future<void> _initData() async {
    setState(() {
      isLoading = true;
    });

    try {
      developer.log('Loading user data from SharedPreferences');
      // Load user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      if (userString == null) {
        throw Exception('User data not found');
      }

      final userData = json.decode(userString);
      developer.log('User data loaded: ${userData['name']}');
      final userRoles = List<String>.from(userData['roles'] ?? []);
      final hasStorageStaffRole = userRoles.contains('storage-staff');
      final hasAdminRole = userRoles.contains('admin') || userRoles.contains('super_admin') || userRoles.contains('supervisor');

      // Load presence data
      developer.log('Loading presence data');
      final presenceData = await _controller.loadPresenceData();
      developer.log('Presence data loaded: ${json.encode(presenceData)}');

      final todayData = presenceData['data']?['today'];
      final previousData = presenceData['data']?['previous'] as List? ?? [];

      // Fetch loan data
      bool hasLoan = false;
      try {
        final salaryHistory = await SalaryService().getSalaryHistory();
        hasLoan = salaryHistory.any((item) => item['has_loan'] == true);
      } catch (e) {
        developer.log('Error checking loans in HomePage: $e');
      }

      developer.log('Today presence: $todayData');
      developer.log('Previous presences: $previousData');

      if (mounted) {
        setState(() {
          userName = userData['name'] ?? '';
          companyName = userData['company']?['name'] ?? 'SAGANSA';
          isStorageStaff = hasStorageStaffRole;
          isAdmin = hasAdminRole;
          hasLoanData = hasLoan;
          try {
            todayPresence =
                todayData != null ? PresenceModel.fromJson(todayData) : null;
            yesterdayPresence = previousData.isNotEmpty
                ? PresenceModel.fromJson(previousData[0])
                : null;
            previousPresences = previousData
                .map((item) {
                  try {
                    return PresenceModel.fromJson(item);
                  } catch (e) {
                    developer.log('Error parsing presence item', error: e);
                    return null;
                  }
                })
                .whereType<PresenceModel>()
                .toList();
          } catch (e) {
            developer.log('Error processing presence data', error: e);
            todayPresence = null;
            yesterdayPresence = null;
            previousPresences = [];
          }
          isUserDataLoaded = true;
        });
      }

      // Check active leave
      developer.log('Checking active leave');
      final hasActiveLeave = await _controller.checkActiveLeave();
      if (mounted) {
        setState(() {
          _hasActiveLeave = hasActiveLeave;
        });
      }
      developer.log('Active leave status: $_hasActiveLeave');

      if (hasStorageStaffRole) {
        await _loadPendingOrdersCount();
      }

      await Future.wait([
        _loadProcurementCounts(),
        _loadDashboardStats(),
      ]);

      await _checkStorageStatus();

      await Future.wait([
        _checkReadinessStatus(),
        _checkHygieneStatus(),
      ]);

      // Ringkasan aset untuk SEMUA user (backend memfilter ke aset miliknya).
      await _loadAssetSummary();

      if (hasAdminRole) {
        await _fetchAdminStockMonitoring();
        await _loadTodayPresences();
      }
    } catch (e) {
      developer.log('Error in _initData',
          error: e, stackTrace: StackTrace.current);
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

  Future<void> _loadProcurementCounts() async {
    if (!mounted) return;
    setState(() => isLoadingProcurement = true);
    try {
      final summary = await ProcurementService().getProcurementSummary();
      final List<RequestPurchase> requests = summary['requests'] ?? [];
      int pending = 0;
      int approved = 0;
      for (final req in requests) {
        for (final item in req.detailRequests) {
          if (item.status == '1') {
            pending++;
          } else if (item.status == '4') {
            approved++;
          }
        }
      }

      // Fetch unpaid transfer invoices count
      int unpaidTransferCount = 0;
      try {
        final invoiceResult = await ProcurementService().getInvoices(
          paymentStatus: '1',
          perPage: 100,
        );
        unpaidTransferCount = invoiceResult.items
            .where((inv) => inv.paymentTypeId == 1)
            .length;
      } catch (e) {
        developer.log('Error loading unpaid transfer invoices', error: e);
      }

      if (mounted) {
        setState(() {
          pendingProcurementsCount = pending;
          approvedProcurementsCount = approved;
          invoiceDraftCount = summary['invoice_draft'] ?? 0;
          invoiceDoneCount = summary['invoice_done'] ?? 0;
          unpaidInvoicesCount = summary['invoice_unpaid'] ?? 0;
          unpaidTransferInvoicesCount = unpaidTransferCount;
        });
      }
    } catch (e) {
      developer.log('Error loading procurement counts', error: e);
    } finally {
      if (mounted) {
        setState(() => isLoadingProcurement = false);
      }
    }
  }

  Future<void> _checkStorageStatus() async {
    try {
      final status = await _storageStockService.checkTodayStatus();
      if (mounted) {
        setState(() {
          _reportedStores = status['reported_stores'] ?? 0;
          _totalStores = status['total_stores'] ?? 0;
          _hasReportedStorageToday = _reportedStores > 0;
        });
      }
    } catch (e) {
      developer.log('Error checking storage status', error: e);
    }
  }

  Future<void> _loadTodayPresences() async {
    if (!mounted) return;
    setState(() => _isLoadingTodayPresences = true);
    try {
      final presences = await PresenceService.getAllTodayPresences();
      if (mounted) {
        setState(() {
          _todayPresences = presences;
          _isLoadingTodayPresences = false;
        });
      }
    } catch (e) {
      developer.log('Error loading today presences', error: e);
      if (mounted) {
        setState(() => _isLoadingTodayPresences = false);
      }
    }
  }

  Future<void> _checkReadinessStatus() async {
    try {
      final status = await _readinessService.checkStatus();
      if (mounted) {
        setState(() {
          _hasReportedReadinessToday = status['data']?['has_submitted_today'] ?? false;
        });
      }
    } catch (e) {
      developer.log('Error checking readiness status', error: e);
    }
  }

  Future<void> _checkHygieneStatus() async {
    try {
      final status = await _hygieneService.checkTodayStatus();
      if (mounted) {
        setState(() {
          _hasReportedHygieneToday = status;
        });
      }
    } catch (e) {
      developer.log('Error checking hygiene status', error: e);
    }
  }

  /// Ambil ringkasan dashboard aset (due_today) untuk badge menu.
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
    } catch (e) {
      developer.log('Error loading asset summary', error: e);
      if (mounted) setState(() => _isLoadingAsset = false);
    }
  }

  Future<void> _loadDashboardStats() async {
    if (!mounted) return;
    setState(() => isLoadingLeaveAndSalary = true);
    try {
      // 1. Load Leaves Pending count
      final leaves = await LeaveService().getLeaves();
      final now = DateTime.now();
      final currentMonthLeaves = leaves.where((l) => 
        l.createdAt.year == now.year && l.createdAt.month == now.month).toList();
      
      final pendingLeaves = currentMonthLeaves.where((l) => l.statusText.toLowerCase() == 'pending').length;
      final hasLeaves = currentMonthLeaves.isNotEmpty;

      // 2. Load Salary Payment status
      final salaries = await SalaryService().getSalaryHistory();
      String salStatus = 'Belum Ada';
      if (salaries.isNotEmpty) {
        final recent = salaries.first;
        final status = recent['status']?.toString().toLowerCase();
        if (status == 'paid') {
          salStatus = 'Gaji Lunas';
        } else if (status == 'processing') {
          salStatus = 'Proses Gaji';
        } else {
          salStatus = 'Belum Lunas';
        }
      }

      if (mounted) {
        setState(() {
          pendingLeavesCount = pendingLeaves;
          hasLeavesThisMonth = hasLeaves;
          salaryPaymentStatus = salStatus;
        });
      }
    } catch (e) {
      developer.log('Error loading leave & salary stats', error: e);
    } finally {
      if (mounted) {
        setState(() => isLoadingLeaveAndSalary = false);
      }
    }
  }

  Future<void> _loadPendingOrdersCount() async {
    if (!isStorageStaff) return;
    setState(() => isLoadingOrders = true);
    try {
      // 1. Fetch Online Orders (for = '3')
      final onlineResult = await PresenceService.getSalesOrders(
        deliveryStatus: 2,
        page: 1,
        perPage: 1,
        orderFor: '3',
      );
      if (onlineResult['success'] == true) {
        final Map<String, dynamic> meta = onlineResult['meta'] ?? {};
        if (mounted) {
          setState(() {
            pendingOnlineOrderCount = meta['total'] ?? 0;
          });
        }
      }

      // 2. Fetch Direct Orders (for = '1')
      final directResult = await PresenceService.getSalesOrders(
        deliveryStatus: 2,
        page: 1,
        perPage: 1,
        orderFor: '1',
      );
      if (directResult['success'] == true) {
        final Map<String, dynamic> meta = directResult['meta'] ?? {};
        if (mounted) {
          setState(() {
            pendingDirectOrderCount = meta['total'] ?? 0;
          });
        }
      }
    } catch (e) {
      developer.log('Error loading pending orders count', error: e);
    } finally {
      if (mounted) {
        setState(() => isLoadingOrders = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    await _initData();
  }

  Future<void> _loadPresenceData() async {
    setState(() => isLoading = true);
    try {
      final response = await _controller.loadPresenceData();
      developer.log('Raw API response in HomePage: ${json.encode(response)}',
          name: 'HomePage');

      if (mounted) {
        setState(() {
          if (response['data']?['today'] != null) {
            todayPresence = PresenceModel.fromJson(response['data']['today']);
            developer.log(
                'Today presence set: ${json.encode(response['data']['today'])}',
                name: 'HomePage');
          } else {
            todayPresence = null;
          }

          final previousData = response['data']?['previous'] as List? ?? [];
          previousPresences =
              previousData.map((item) => PresenceModel.fromJson(item)).toList();
          yesterdayPresence =
              previousPresences.isNotEmpty ? previousPresences[0] : null;
        });
      }
    } catch (e) {
      developer.log('Error in _loadPresenceData: $e',
          error: e, name: 'HomePage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _controller.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }


  Future<void> _navigateToPresencePage() async {
    // Langsung navigasi ke PresencePage
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresencePage(
          isCheckIn: todayPresence == null,
        ),
      ),
    );

    // Refresh data jika ada perubahan
    if (result == true) {
      await _loadPresenceData();
      setState(() {});
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

  Widget _buildPresenceCard(PresenceModel presence) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final checkInDateTime = _controller.splitDateTime(presence.checkIn);
    final checkOutDateTime = presence.checkOut != null
        ? _controller.splitDateTime(presence.checkOut!)
        : null;

    return Card(
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          children: [
            Text(
              presence.store,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              presence.shiftStore,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVerticalMD,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check In',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.gapVerticalSM,
                      _buildStatusBadge(
                        presence.getStatusColor(presence.checkInStatus),
                        presence.getStatusText(presence.checkInStatus),
                      ),
                      AppSpacing.gapVerticalSM,
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
                          AppSpacing.gapHorizontalXS,
                          Text(
                            checkInDateTime['date']!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: colorScheme.onSurfaceVariant),
                          AppSpacing.gapHorizontalXS,
                          Text(
                            checkInDateTime['time']!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 80,
                  color: colorScheme.outlineVariant.withValues(alpha:0.5),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Check Out',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.gapVerticalSM,
                      if (presence.checkOut != null) ...[
                        _buildStatusBadge(
                          presence.getStatusColor(presence.checkOutStatus),
                          presence.getStatusText(presence.checkOutStatus),
                        ),
                        AppSpacing.gapVerticalSM,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              checkOutDateTime!['date']!,
                              style: theme.textTheme.bodySmall,
                            ),
                            AppSpacing.gapHorizontalXS,
                            Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              checkOutDateTime['time']!,
                              style: theme.textTheme.bodySmall,
                            ),
                            AppSpacing.gapHorizontalXS,
                            Icon(Icons.access_time, size: 14, color: colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ] else ...[
                        _buildStatusBadge(
                          AppColors.warning,
                          'Belum',
                        ),
                        AppSpacing.gapVerticalSM,
                        Text(
                          'Belum Absen Pulang',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
            if (presence.checkOut == null) ...[
              AppSpacing.gapVerticalMD,
              ElevatedButton.icon(
                onPressed: _navigateToPresencePage,
                icon: Icon(Icons.logout, color: AppColors.onError),
                label: const Text(
                  'CLOCK OUT / ABSEN KELUAR',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.onError,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Color color, String text) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: AppSpacing.borderRadiusSM,
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPresenceSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (todayPresence != null) {
      if (todayPresence!.checkOut != null) {
        // Bila hari ini sudah clock out maka tidak menampilkan apapun.
        return const SizedBox.shrink();
      }
      return _buildPresenceCard(todayPresence!);
    }

    return Card(
      child: Container(
        padding: AppSpacing.paddingXL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fingerprint_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            AppSpacing.gapVerticalMD,
            Text(
              'Belum ada presensi untuk hari ini',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapVerticalSM,
            Text(
              'Silakan lakukan presensi masuk terlebih dahulu.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            AppSpacing.gapVerticalLG,
            ElevatedButton.icon(
              onPressed: _navigateToPresencePage,
              icon: Icon(Icons.login, color: AppColors.onSuccess),
              label: const Text(
                'CLOCK IN / ABSEN MASUK',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.onSuccess,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
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
        actions: [
          const ThemeToggleButton(),
          AppSpacing.gapHorizontalSM,
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
                      color: colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Beranda'),
              onTap: () => Navigator.pop(context),
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
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                          _buildPresenceSection(),
                          _buildDashboardGrid(),
                        ],
                      ),
          ),
        ),
      ),

      bottomNavigationBar: ModernBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        presences: [
          ...previousPresences,
          if (todayPresence != null) todayPresence!
        ],
      ),
    );
  }



  Widget _buildCompactDashboardCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMD,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:             AppSpacing.paddingXS,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusSM,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            AppSpacing.gapVerticalXS,
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.gapVerticalXS,
                    Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        height: 1.15,
                      ),
                    ),
                    AppSpacing.gapVerticalXS,
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDashboardGrid() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              _buildCompactDashboardCard(
                icon: _hasReportedStorageToday ? Icons.check_circle : Icons.warning_amber_rounded,
                iconColor: _hasReportedStorageToday ? AppColors.success : Theme.of(context).colorScheme.error,
                title: 'Stok Gudang',
                value: '$_reportedStores/$_totalStores',
                subtitle: _totalStores > 0
                    ? (_reportedStores == _totalStores ? 'Semua sudah laporan' : '$_reportedStores store sudah laporan')
                    : 'Belum ada laporan',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StorageStockListPage()),
                  ).then((_) {
                    _checkStorageStatus();
                  });
                },
              ),
              _buildCompactDashboardCard(
                icon: Icons.local_shipping_outlined,
                iconColor: colorScheme.primary,
                title: 'Pengiriman',
                value: '${pendingOnlineOrderCount + pendingDirectOrderCount} Total',
                subtitle: 'OS: $pendingOnlineOrderCount | Dir: $pendingDirectOrderCount',
              ),
            ],
            // Manajemen Aset: tampilkan untuk SEMUA user. Backend otomatis
            // memfilter agar user hanya melihat aset di mana dia PIC/creator
            // (admin melihat semua).
            _buildCompactDashboardCard(
              icon: Icons.inventory_2_outlined,
                iconColor: AppColors.warning,
              title: 'Manajemen Aset',
              value: _isLoadingAsset
                  ? 'Loading...'
                  : (_assetDueTodayCount > 0
                      ? '$_assetDueTodayCount Jatuh Tempo'
                      : 'Aman'),
              subtitle: 'Aset yang ditugaskan ke Anda',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AssetDashboardPage()),
                ).then((_) {
                  _loadAssetSummary();
                });
              },
            ),
            _buildCompactDashboardCard(
              icon: Icons.cleaning_services_outlined,
                iconColor: colorScheme.primary,
              title: 'Kebersihan',
              value: _hasReportedHygieneToday ? 'Selesai' : 'Isi Form!',
              subtitle: _hasReportedHygieneToday ? 'Sudah Laporan' : 'Belum Laporan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HygienePage()),
                ).then((_) {
                  _checkHygieneStatus();
                });
              },
            ),
            _buildCompactDashboardCard(
              icon: Icons.checklist_rtl_outlined,
              iconColor: colorScheme.primary,
              title: 'Kesiapan Diri',
              value: _hasReportedReadinessToday ? 'Selesai' : 'Isi Form!',
              subtitle: _hasReportedReadinessToday ? 'Sudah Laporan' : 'Belum Laporan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReadinessPage()),
                ).then((_) {
                  _checkReadinessStatus();
                });
              },
            ),
            _buildCompactDashboardCard(
              icon: Icons.store_outlined,
              iconColor: AppColors.warning,
              title: 'Closing Store',
              value: 'Buka',
              subtitle: 'Laporan penutupan toko',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClosingStorePage()),
                );
              },
            ),
            _buildCompactDashboardCard(
              icon: Icons.wallet_outlined,
                iconColor: AppColors.info,
              title: 'Slip Gaji',
              value: isLoadingLeaveAndSalary ? 'Loading...' : salaryPaymentStatus,
              subtitle: 'Gaji & Slip',
            ),
            _buildCompactDashboardCard(
              icon: Icons.receipt_long_outlined,
              iconColor: AppColors.warning,
              title: 'Cuti',
              value: isLoadingLeaveAndSalary
                  ? 'Loading...'
                  : (!hasLeavesThisMonth 
                      ? 'Kosong' 
                      : (pendingLeavesCount > 0 ? '$pendingLeavesCount Pending' : 'Disetujui')),
              subtitle: 'Cuti & Izin',
            ),
            if (hasLoanData)
              _buildCompactDashboardCard(
                icon: Icons.payments_outlined,
                iconColor: Theme.of(context).colorScheme.error,
                title: 'Kasbon',
                value: 'Kasbon Staf',
                subtitle: 'Pinjaman',
              ),
            _buildCompactDashboardCard(
              icon: Icons.shopping_cart_outlined,
                iconColor: colorScheme.tertiary,
              title: 'Belanja',
              value: isLoadingProcurement
                  ? 'Loading...'
                  : (unpaidInvoicesCount > 0 ? '$unpaidInvoicesCount Blm Lunas' : 'Invoice Lunas'),
              subtitle: 'Draft: $invoiceDraftCount | Done: $invoiceDoneCount',
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // ADMIN DASHBOARD & STOCK MONITORING FEED METHODS
  // ==========================================

  Future<void> _fetchAdminStockMonitoring() async {
    if (!mounted) return;
    setState(() => isLoadingAdminStockMonitoring = true);
    try {
      final data = await _storageStockService.getStockMonitoring();
      if (mounted) {
        setState(() {
          adminStockMonitorings = data;
          if (data.isNotEmpty) {
            latestStockDate = data.first['last_stock_date'] ?? '';
          } else {
            latestStockDate = '';
          }
        });
      }
    } catch (e) {
      developer.log('Error fetching admin stock monitoring', error: e);
    } finally {
      if (mounted) {
        setState(() => isLoadingAdminStockMonitoring = false);
      }
    }
  }

  Widget _buildAdminDashboard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Header
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
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _onRefresh,
              tooltip: 'Segarkan Halaman',
            ),
          ],
        ),
        AppSpacing.gapVerticalMD,

        // 2x2 Grid of KPIs
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                icon: Icons.receipt_long_outlined,
                iconColor: AppColors.warning,
                title: 'Pengajuan Cuti',
                value: isLoadingLeaveAndSalary ? '...' : '$pendingLeavesCount',
                subtitle: 'Menunggu Persetujuan',
              ),
            ),
            AppSpacing.gapHorizontalSM,
            Expanded(
              child: _buildKpiCard(
                icon: Icons.receipt_outlined,
                iconColor: colorScheme.tertiary,
                title: 'Invoice Belum Dibayar',
                value: isLoadingProcurement ? '...' : '$unpaidTransferInvoicesCount',
                subtitle: 'Metode Transfer',
              ),
            ),
          ],
        ),
        AppSpacing.gapVerticalSM,
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                icon: Icons.inventory_2_outlined,
                iconColor: AppColors.primary,
                title: 'Laporan Stok',
                value: '$_reportedStores/$_totalStores',
                subtitle: 'Toko Sudah Melapor',
              ),
            ),
            AppSpacing.gapHorizontalSM,
            Expanded(
              child: _buildKpiCard(
                icon: Icons.notification_important_outlined,
                iconColor: colorScheme.error,
                title: 'Jatuh Tempo Aset',
                value: _isLoadingAsset ? '...' : '$_assetDueTodayCount',
                subtitle: 'Aset Harus Diperiksa',
              ),
            ),
          ],
        ),
        AppSpacing.gapVerticalLG,

        // Presensi Hari Ini
        _buildTodayPresencesSection(),
        AppSpacing.gapVerticalLG,

        // Perbandingan Penjualan vs Stok (admin & super_admin)
        _buildInventoryAnomalySection(),

        AppSpacing.gapVerticalLG,

        // Laporan Storage Stock Feed
        _buildStorageStocksSection(),
      ],
    );
  }

  Widget _buildInventoryAnomalySection() {
    if (!isAdmin) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const InventoryAnomalyPage(),
            ),
          );
        },
        borderRadius: AppSpacing.borderRadiusMD,
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Row(
            children: [
              Container(
                padding: AppSpacing.paddingXS,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSM,
                ),
                child: const Icon(Icons.compare_arrows,
                    color: AppColors.primary, size: 24),
              ),
              AppSpacing.gapHorizontalMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perbandingan Penjualan vs Stok',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Deteksi anomali & susut (SO vs stok gudang)',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: AppSpacing.paddingXS,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusSM,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            AppSpacing.gapVerticalMD,
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            AppSpacing.gapVerticalXS,
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayPresencesSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Presensi Hari Ini',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isLoadingTodayPresences)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
          ],
        ),
        AppSpacing.gapVerticalSM,
        if (_todayPresences.isEmpty && !_isLoadingTodayPresences)
          Card(
            child: Padding(
              padding: AppSpacing.paddingMD,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
                  AppSpacing.gapHorizontalSM,
                  Text(
                    'Belum ada presensi hari ini.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_todayPresences.take(10).map((presence) {
            final name = presence['user']?['name'] ?? '-';
            final store = presence['store']?['name'] ?? '-';
            final clockIn = presence['clock_in'] ?? '-';
            final clockOut = presence['clock_out'];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: AppSpacing.paddingMD,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.person, size: 20, color: colorScheme.onSurfaceVariant),
                    ),
                    AppSpacing.gapHorizontalMD,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            store,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'In: $clockIn',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (clockOut != null)
                          Text(
                            'Out: $clockOut',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          })),
      ],
    );
  }

  Widget _buildStorageStocksSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter to only get low stock items for homepage alert display
    final lowStockItems = adminStockMonitorings.where((item) {
      final double calculatedTotal = double.tryParse(item['calculated_total_stock']?.toString() ?? '0') ?? 0.0;
      final double qtyLow = double.tryParse(item['quantity_low']?.toString() ?? '0') ?? 0.0;
      return calculatedTotal < qtyLow;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peringatan Stok Kritis (Low Stock)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (latestStockDate.isNotEmpty) ...[
                    AppSpacing.gapVerticalXS,
                    Text(
                      'Pembaruan Terakhir: $latestStockDate',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _fetchAdminStockMonitoring,
              tooltip: 'Segarkan Monitoring',
            ),
          ],
        ),
        AppSpacing.gapVerticalSM,
        isLoadingAdminStockMonitoring
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ),
              )
            : lowStockItems.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: AppColors.success, size: 24),
                          AppSpacing.gapHorizontalMD,
                          Expanded(
                            child: Text(
                              'Semua stok gudang dalam kondisi aman.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: lowStockItems.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = lowStockItems[index];
                        final name = item['name'] ?? '';
                        final double calculatedTotal = double.tryParse(item['calculated_total_stock']?.toString() ?? '0') ?? 0.0;
                        final double qtyLow = double.tryParse(item['quantity_low']?.toString() ?? '0') ?? 0.0;
                        final unit = item['unit_nickname'] ?? '';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          leading: Container(
                            padding: AppSpacing.paddingXS,
                            decoration: BoxDecoration(
                              color: colorScheme.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 20),
                          ),
                          title: Text(
                            name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Batas Min: ${qtyLow.toStringAsFixed(0)} $unit',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${calculatedTotal.toStringAsFixed(0)} $unit',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.error,
                                ),
                              ),
                              Text(
                                'Low Stock',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }
}
