import 'package:flutter/foundation.dart';
import '../models/sales_dashboard_model.dart';
import '../services/asset_service.dart';
import '../services/inventory_anomaly_service.dart';
import '../services/procurement_service.dart';
import '../services/sales_dashboard_service.dart';

// === State value objects (immutable per-group) ===

@immutable
class HomeProcurementState {
  final int pendingCount;
  final int approvedCount;
  final int invoiceDraftCount;
  final int invoiceDoneCount;
  final int unpaidInvoicesCount;
  final bool isLoading;

  const HomeProcurementState({
    this.pendingCount = 0,
    this.approvedCount = 0,
    this.invoiceDraftCount = 0,
    this.invoiceDoneCount = 0,
    this.unpaidInvoicesCount = 0,
    this.isLoading = false,
  });

  HomeProcurementState copyWith({
    int? pendingCount,
    int? approvedCount,
    int? invoiceDraftCount,
    int? invoiceDoneCount,
    int? unpaidInvoicesCount,
    bool? isLoading,
  }) =>
      HomeProcurementState(
        pendingCount: pendingCount ?? this.pendingCount,
        approvedCount: approvedCount ?? this.approvedCount,
        invoiceDraftCount: invoiceDraftCount ?? this.invoiceDraftCount,
        invoiceDoneCount: invoiceDoneCount ?? this.invoiceDoneCount,
        unpaidInvoicesCount: unpaidInvoicesCount ?? this.unpaidInvoicesCount,
        isLoading: isLoading ?? this.isLoading,
      );
}

@immutable
class HomeAssetState {
  final int dueTodayCount;
  final int overdueCount;
  final int dueThisWeekCount;
  final bool isLoading;

  const HomeAssetState({
    this.dueTodayCount = 0,
    this.overdueCount = 0,
    this.dueThisWeekCount = 0,
    this.isLoading = false,
  });

  HomeAssetState copyWith({
    int? dueTodayCount,
    int? overdueCount,
    int? dueThisWeekCount,
    bool? isLoading,
  }) =>
      HomeAssetState(
        dueTodayCount: dueTodayCount ?? this.dueTodayCount,
        overdueCount: overdueCount ?? this.overdueCount,
        dueThisWeekCount: dueThisWeekCount ?? this.dueThisWeekCount,
        isLoading: isLoading ?? this.isLoading,
      );
}

@immutable
class HomeSalesState {
  final int? yesterdayOmzet;
  final bool isLoading;
  const HomeSalesState({this.yesterdayOmzet, this.isLoading = false});
  HomeSalesState copyWith({int? yesterdayOmzet, bool? isLoading}) =>
      HomeSalesState(
        yesterdayOmzet: yesterdayOmzet ?? this.yesterdayOmzet,
        isLoading: isLoading ?? this.isLoading,
      );
}

@immutable
class HomeAnomalyState {
  final int? mismatchCount;
  final int matchCount;
  final bool isLoading;
  const HomeAnomalyState(
      {this.mismatchCount, this.matchCount = 0, this.isLoading = false});
  HomeAnomalyState copyWith(
          {int? mismatchCount, int? matchCount, bool? isLoading}) =>
      HomeAnomalyState(
        mismatchCount: mismatchCount ?? this.mismatchCount,
        matchCount: matchCount ?? this.matchCount,
        isLoading: isLoading ?? this.isLoading,
      );
}

// === Provider ===

/// Memegang semua state summary dashboard Home.
///
/// Service di-inject via constructor untuk testability (mockable).
/// Panggil [loadAll] sekali saat page init.
class HomeDashboardProvider extends ChangeNotifier {
  final ProcurementService _procurementService;
  final AssetService _assetService;
  final SalesDashboardService _salesDashboardService;
  final InventoryAnomalyService _anomalyService;

  HomeProcurementState _procurement = const HomeProcurementState();
  HomeAssetState _asset = const HomeAssetState();
  HomeSalesState _sales = const HomeSalesState();
  HomeAnomalyState _anomaly = const HomeAnomalyState();

  bool _isLoading = false;
  String? _error;

  HomeDashboardProvider({
    required ProcurementService procurementService,
    required AssetService assetService,
    required SalesDashboardService salesDashboardService,
    required InventoryAnomalyService anomalyService,
  })  : _procurementService = procurementService,
        _assetService = assetService,
        _salesDashboardService = salesDashboardService,
        _anomalyService = anomalyService;

  // Getters
  HomeProcurementState get procurement => _procurement;
  HomeAssetState get asset => _asset;
  HomeSalesState get sales => _sales;
  HomeAnomalyState get anomaly => _anomaly;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load semua section (parallel).
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadProcurement(),
        loadAsset(),
        loadSales(),
        loadAnomaly(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load procurement summary.
  Future<void> loadProcurement() async {
    _procurement = _procurement.copyWith(isLoading: true);
    notifyListeners();

    try {
      final summary = await _procurementService.getProcurementSummary();
      final List requests = summary['requests'] as List? ?? [];

      int pending = 0;
      int approved = 0;
      for (final req in requests) {
        for (final item in (req as dynamic).detailRequests) {
          final status = (item as dynamic).status;
          if (status == '1') {
            pending++;
          } else if (status == '4' || status == '2') {
            approved++;
          }
        }
      }

      _procurement = _procurement.copyWith(
        pendingCount: pending,
        approvedCount: approved,
        invoiceDraftCount: (summary['invoice_draft'] as num?)?.toInt() ?? 0,
        invoiceDoneCount: (summary['invoice_done'] as num?)?.toInt() ?? 0,
        unpaidInvoicesCount: (summary['invoice_unpaid'] as num?)?.toInt() ?? 0,
        isLoading: false,
      );
    } catch (_) {
      _procurement = _procurement.copyWith(isLoading: false);
    } finally {
      notifyListeners();
    }
  }

  /// Load asset summary.
  Future<void> loadAsset() async {
    _asset = _asset.copyWith(isLoading: true);
    notifyListeners();
    try {
      final summary = await _assetService.getDashboardSummary();
      _asset = _asset.copyWith(
        dueTodayCount: (summary['due_today'] ?? 0) as int,
        overdueCount: (summary['overdue'] ?? 0) as int,
        dueThisWeekCount: (summary['due_this_week'] ?? 0) as int,
        isLoading: false,
      );
    } catch (_) {
      _asset = _asset.copyWith(isLoading: false);
    } finally {
      notifyListeners();
    }
  }

  /// Load sales summary.
  Future<void> loadSales() async {
    _sales = _sales.copyWith(isLoading: true);
    notifyListeners();
    try {
      final summary =
          await _salesDashboardService.getSummary(SalesPeriode.yesterday);
      _sales = _sales.copyWith(
        yesterdayOmzet: summary.omzet,
        isLoading: false,
      );
    } catch (_) {
      _sales = _sales.copyWith(yesterdayOmzet: null, isLoading: false);
    } finally {
      notifyListeners();
    }
  }

  /// Load anomaly summary.
  Future<void> loadAnomaly() async {
    _anomaly = _anomaly.copyWith(isLoading: true);
    notifyListeners();
    try {
      final response = await _anomalyService.getComparison();
      _anomaly = _anomaly.copyWith(
        mismatchCount: response.summary.mismatchCount,
        matchCount: response.summary.matchCount,
        isLoading: false,
      );
    } catch (_) {
      _anomaly = _anomaly.copyWith(mismatchCount: null, isLoading: false);
    } finally {
      notifyListeners();
    }
  }
}
