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
import 'profile_page.dart';
import 'admin_profile_list_page.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/app_version_text.dart';
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
import 'sales_dashboard_page.dart';
import '../services/leave_service.dart';
import 'asset_dashboard_page.dart';
import '../services/asset_service.dart';
import '../services/hygiene_service.dart';
import 'hygiene_page.dart';
import 'hygiene_list_page.dart';
import '../services/readiness_service.dart';
import 'readiness_page.dart';
import 'readiness_list_page.dart';
import 'closing_store_page.dart';
import '../services/user_service.dart';
import '../services/sales_dashboard_service.dart';
import '../models/sales_dashboard_model.dart';
import '../services/inventory_anomaly_service.dart';
import '../utils/format_utils.dart';


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
  int _readinessCount = 0;
  int _hygieneCount = 0;
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

  // Sales dashboard + inventory anomaly (home grid cards).
  final SalesDashboardService _salesDashboardService = SalesDashboardService();
  final InventoryAnomalyService _inventoryAnomalyService = InventoryAnomalyService();

  bool isAdmin = false;
  List<Map<String, dynamic>> adminStockMonitorings = [];
  bool isLoadingAdminStockMonitoring = false;
  String latestStockDate = '';
  List<dynamic> _todayPresences = [];
  bool _isLoadingTodayPresences = false;
  int _totalEmployees = 0;
  int _lateCount = 0;
  int _onTimeCount = 0;
  int? _yesterdayOmzet;
  bool _isLoadingYesterdayOmzet = false;
  int? _anomalyMismatchCount;
  int _anomalyMatchCount = 0;
  bool _isLoadingAnomaly = false;

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
      final hasAdminRole = userRoles.contains('admin') || userRoles.contains('super_admin');

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

      if (hasAdminRole || hasStorageStaffRole) {
        await _fetchAdminStockMonitoring();
        await _loadTodayPresences();
        await _loadYesterdayOmzet();
        await _loadAnomalySummary();
      }

      if (hasAdminRole) {
        try {
          final readiness = await _readinessService.getHistory();
          final hygiene = await _hygieneService.getHistory();
          if (mounted) {
            setState(() {
              _readinessCount = readiness.length;
              _hygieneCount = hygiene.length;
            });
          }
        } catch (e) {
          developer.log('Error loading admin lists', error: e);
        }
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
      int reported = status['reported_stores'] ?? 0;
      final total = status['total_stores'] ?? 0;

      // Fallback: bila endpoint today-status belum menghitung laporan yang
      // baru dibuat (masih 0), hitung ulang dari daftar laporan hari ini.
      if (reported == 0 && total > 0) {
        try {
          reported = await _storageStockService.countReportedStoresToday();
        } catch (e) {
          developer.log('Error recounting reported stores', error: e);
        }
      }

      if (mounted) {
        setState(() {
          _reportedStores = reported;
          _totalStores = total;
          _hasReportedStorageToday = reported > 0;
        });
      }
    } catch (e) {
      developer.log('Error checking storage status', error: e);
    }
  }

  Future<void> _loadTodayPresences() async {
    if (!mounted) return;
    setState(() => _isLoadingTodayPresences = true);

    // Panggil terpisah agar kegagalan satu endpoint (mis. /users 500) tidak
    // menjatuhkan endpoint lain (mis. presensi tetap bisa dimuat).
    List<dynamic> presences = [];
    int totalEmployees = 0;

    try {
      final result = await PresenceService.getAllTodayPresences();
      presences = result.presences;
      final summary = result.summary;
      if (mounted) {
        setState(() {
          _lateCount = (summary?['late_count'] as num?)?.toInt() ?? 0;
          _onTimeCount = (summary?['on_time_count'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (e) {
      developer.log('Error loading today presences', error: e);
    }

    try {
      final users = await UserService().getUsers(role: 'staff');
      totalEmployees = users.length;
    } catch (e) {
      developer.log('Error loading users count', error: e);
    }

    if (mounted) {
      setState(() {
        _todayPresences = presences;
        _totalEmployees = totalEmployees;
        _isLoadingTodayPresences = false;
      });
    }
  }

  Future<void> _loadYesterdayOmzet() async {
    setState(() => _isLoadingYesterdayOmzet = true);
    try {
      final summary = await _salesDashboardService.getSummary(SalesPeriode.yesterday);
      if (!mounted) return;
      setState(() {
        _yesterdayOmzet = summary.omzet;
        _isLoadingYesterdayOmzet = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _yesterdayOmzet = null;
        _isLoadingYesterdayOmzet = false;
      });
      developer.log('Error loading yesterday omzet: $e');
    }
  }

  Future<void> _loadAnomalySummary() async {
    setState(() => _isLoadingAnomaly = true);
    try {
      final response = await _inventoryAnomalyService.getComparison();
      if (!mounted) return;
      setState(() {
        _anomalyMismatchCount = response.summary.mismatchCount;
        _anomalyMatchCount = response.summary.matchCount;
        _isLoadingAnomaly = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _anomalyMismatchCount = null;
        _isLoadingAnomaly = false;
      });
      developer.log('Error loading anomaly summary: $e');
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
              leading: const Icon(Icons.person_outline),
              title: const Text('Profil Saya'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
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
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: const Text('Kelola Profil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminProfileListPage()),
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
            const AppVersionText(),
          ],
        ),
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
                          _buildPresenceSection(),
                          _buildDashboardGrid(),
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
            // 1. Presensi
            _buildCompactCard(
              icon: Icons.fingerprint,
              iconColor: AppColors.success,
              value: _isLoadingTodayPresences
                  ? '...'
                  : '${_todayPresences.length}/$_totalEmployees',
              label: 'Presensi',
              badge: _lateCount > 0 ? '$_lateCount telat' : null,
              badgeColor: colorScheme.error,
              onTap: _showTodayPresencesSheet,
            ),
            // 2. Omzet Kemarin
            _buildCompactCard(
              icon: Icons.bar_chart,
              iconColor: AppColors.primary,
              value: _isLoadingYesterdayOmzet
                  ? '...'
                  : (_yesterdayOmzet == null
                      ? '-'
                      : FormatUtils.formatCurrencyCompact(_yesterdayOmzet!)),
              label: 'Omzet Kemarin',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SalesDashboardPage(),
                ),
              ),
            ),
            // 3. Selisih Stok
            _buildCompactCard(
              icon: Icons.compare_arrows,
              iconColor: colorScheme.error,
              value: _isLoadingAnomaly
                  ? '...'
                  : (_anomalyMismatchCount == null
                      ? '-'
                      : '$_anomalyMismatchCount'),
              label: 'Selisih Stok',
              badge: _anomalyMatchCount > 0 ? '$_anomalyMatchCount cocok' : null,
              badgeColor: AppColors.success,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InventoryAnomalyPage(),
                ),
              ),
            ),
            // 4. Invoice Unpaid
            _buildCompactCard(
              icon: Icons.receipt_outlined,
              iconColor: colorScheme.tertiary,
              value: isLoadingProcurement ? '...' : '$unpaidTransferInvoicesCount',
              label: 'Invoice Unpaid',
            ),
            // 5. Laporan Stok
            _buildCompactCard(
              icon: Icons.inventory_2_outlined,
              iconColor: AppColors.primary,
              value: '$_reportedStores/$_totalStores',
              label: 'Laporan Stok',
            ),
            // 6. Aset Jatuh Tempo
            _buildCompactCard(
              icon: Icons.notification_important_outlined,
              iconColor: colorScheme.error,
              value: _isLoadingAsset ? '...' : '$_assetDueTodayCount',
              label: 'Aset Jatuh Tempo',
            ),
          ],
        ),
        AppSpacing.gapVerticalLG,

        // Storage stock feed (tetap)
        _buildStorageStocksSection(),
      ],
    );
  }

  Widget _buildCompactCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    String? badge,
    Color? badgeColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final card = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.paddingSM,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Row atas: icon kiri + badge kanan (opsional)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: AppSpacing.borderRadiusSM,
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                if (badge != null)
                  Text(
                    badge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeColor ?? colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
            // Value tengah
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            // Label bawah
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMD,
        child: card,
      );
    }
    return card;
  }

  bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  /// Mengembalikan true bila [rawTime] (format HH:mm atau HH:mm:ss) lebih dari
  /// [threshold] (format HH:mm). Bila waktu tidak valid, anggap tidak telat.
  bool _isLateTime(String? rawTime, String threshold) {
    if (rawTime == null || rawTime.isEmpty) return false;
    final t = rawTime.split(':');
    final lim = threshold.split(':');
    if (t.length < 2 || lim.length < 2) return false;
    final th = int.tryParse(t[0]) ?? 0;
    final tm = int.tryParse(t[1]) ?? 0;
    final lh = int.tryParse(lim[0]) ?? 0;
    final lm = int.tryParse(lim[1]) ?? 0;
    final cur = th * 60 + tm;
    final limit = lh * 60 + lm;
    return cur > limit;
  }

  void _showTodayPresencesSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final presences = _todayPresences;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Presensi Hari Ini',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${presences.length} karyawan telah presensi',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 16),
                Expanded(
                  child: _isLoadingTodayPresences
                      ? const Center(child: CircularProgressIndicator())
                      : presences.isEmpty
                          ? Center(
                              child: Text(
                                'Belum ada presensi hari ini.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: AppSpacing.paddingMD,
                              itemCount: presences.length,
                              itemBuilder: (context, idx) {
                                final presence =
                                    presences[idx] as Map<String, dynamic>;

                                // ── Nama (robust terhadap berbagai struktur) ──
                                final userName = presence['user'] is Map
                                    ? (presence['user']['name'] ??
                                        presence['user']['full_name'])
                                    : (presence['employee'] is Map
                                        ? (presence['employee']['name'] ??
                                            presence['employee']
                                                ['full_name'])
                                        : (presence['created_by'] is Map
                                            ? (presence['created_by']['name'] ??
                                                presence['created_by']
                                                    ['full_name'])
                                            : presence['user_name'] ?? presence['name']));
                                final name = (userName?.toString().isNotEmpty ==
                                        true)
                                    ? userName.toString()
                                    : '-';

                                // ── Store: prioritas nickname ──
                                final storeMap = presence['store'] is Map
                                    ? presence['store'] as Map
                                    : null;
                                final store = storeMap != null
                                    ? (storeMap['nickname']?.toString().isNotEmpty ==
                                                true
                                            ? storeMap['nickname']
                                            : storeMap['name'])
                                        ?.toString()
                                    : null;
                                final storeText =
                                    (store?.isNotEmpty == true) ? store! : '-';

                                final clockInRaw =
                                    presence['clock_in']?.toString();
                                final clockOutRaw =
                                    presence['clock_out']?.toString();

                                // ── Status telat masuk ──
                                bool inLate;
                                if (presence['is_late'] != null) {
                                  inLate = _toBool(presence['is_late']);
                                } else if (presence['late'] != null) {
                                  inLate = _toBool(presence['late']);
                                } else {
                                  inLate = _isLateTime(clockInRaw, '09:00');
                                }

                                // ── Status telat keluar (pulang) ──
                                bool outLate;
                                if (presence['is_late_out'] != null) {
                                  outLate = _toBool(presence['is_late_out']);
                                } else if (presence['out_late'] != null) {
                                  outLate = _toBool(presence['out_late']);
                                } else {
                                  outLate = _isLateTime(clockOutRaw, '17:00');
                                }

                                final inColor = inLate
                                    ? colorScheme.error
                                    : AppColors.success;
                                final outColor = outLate
                                    ? AppColors.success
                                    : colorScheme.error;

                                return Card(
                                  margin: const EdgeInsets.only(
                                      bottom: AppSpacing.sm),
                                  child: Padding(
                                    padding: AppSpacing.paddingMD,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: colorScheme.primary
                                              .withValues(alpha: 0.1),
                                          child: Icon(Icons.person,
                                              size: 20,
                                              color: colorScheme
                                                  .onSurfaceVariant),
                                        ),
                                        AppSpacing.gapHorizontalMD,
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                storeText,
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (clockInRaw != null)
                                              Text(
                                                'In: $clockInRaw',
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: inColor,
                                                ),
                                              ),
                                            if (clockOutRaw != null)
                                              Text(
                                                'Out: $clockOutRaw',
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: outColor,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            );
          },
        );
      },
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
