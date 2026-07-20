# Home Page Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pecah God Widget `lib/pages/home_page.dart` (1.985 LOC, 37 `setState`, 30+ state field, 20 service inline) menjadi `HomeDashboardProvider` yang ter-test + 6 card widget reusable. Target akhir: `home_page.dart` ≤ 500 LOC, 0 `setState`, 0 inline service.

**Architecture:** Tiga layer: (1) `HomeDashboardProvider` (ChangeNotifier) memegang semua state summary + menjalankan loading paralel; (2) Card widget `StatelessWidget` yang subscribe via `context.select` (fine-grained rebuild); (3) `HomePage` jadi shell ringkas yang inject provider + susun card. Mengikuti pola yang sudah ada di `FuelServicePaymentProvider`.

**Tech Stack:** Flutter, `provider ^6.1.2`, `flutter_test`, `mocktail ^1.0.4` (untuk mock service). Tidak ada dependency baru selain mocktail (dev-only).

**Spec:** `PRD_CODEBASE_IMPROVEMENT.md` §4.2 (WS-02).

**Direktori kerja:** `/Users/dityo/Codings/sagansa/mobiles/sagansa/` (semua path di bawah relatif ke sini).

---

## Aturan Umum

1. **Satu task = satu commit.** Pesan commit pakai `refactor(home): ...`.
2. **Test first (TDD).** Provider wajib punya test sebelum dipakai.
3. **Behavior tidak boleh berubah.** Tiap task diakhiri smoke test visual.
4. **Backward compatible:** AppBar, bottom nav, navigasi ke sub-page TIDAK diubah di plan ini. Hanya body HomePage yang dipecah.
5. **Card di-extract satu per satu**, dengan smoke test di antaranya. **Jangan refactor semua card sekaligus** — risiko regression tinggi.
6. **Jangan hapus method `_buildXxx` di `home_page.dart` sampai card penggantinya merge & ter-verifikasi.** Strafing replacement.

---

## File Structure

### Create (NEW)
- `lib/providers/home_dashboard_provider.dart` — ChangeNotifier memegang summary state + service references
- `lib/widgets/home/home_presence_summary_card.dart`
- `lib/widgets/home/home_procurement_summary_card.dart`
- `lib/widgets/home/home_asset_summary_card.dart`
- `lib/widgets/home/home_hygiene_readiness_card.dart`
- `lib/widgets/home/home_sales_anomaly_card.dart`
- `lib/widgets/home/home_admin_overview_card.dart`
- `lib/widgets/home/home_skeleton_loader.dart`
- `test/providers/home_dashboard_provider_test.dart`
- `test/widgets/home/home_presence_summary_card_test.dart` (dan 5 lainnya)

### Modify
- `lib/pages/home_page.dart` — rewrite total (StatefulWidget → StatelessWidget shell)
- `lib/main.dart` — register `HomeDashboardProvider` di MultiProvider (atau page-scoped; lihat Task 6)

### Dependency
- `pubspec.yaml` — tambah `mocktail: ^1.0.4` di `dev_dependencies`

---

## State Decomposition (target)

| Saat ini (HomePageState field) | Pindah ke | Dimiliki oleh |
|---|---|---|
| `userName`, `companyName` | `AuthProvider` (sudah ada `loadUserInfo`) | global |
| `isAdmin`, `isStorageStaff` | `AuthProvider` (tambah getter `roles`) | global |
| `todayPresence`, `previousPresences`, `yesterdayPresence` | `HomePresenceState` | `HomeDashboardProvider` |
| `_hasActiveLeave` | `AuthProvider.checkActiveLeave` (sudah ada) | global |
| `hasLoanData`, `pendingLeavesCount`, `hasLeavesThisMonth`, `salaryPaymentStatus` | `HomeLeaveSalaryState` | `HomeDashboardProvider` |
| `pendingProcurementsCount`, `approvedProcurementsCount`, `invoiceDraftCount`, `invoiceDoneCount`, `unpaidInvoicesCount`, `unpaidTransferInvoicesCount`, `isLoadingProcurement` | `HomeProcurementState` | `HomeDashboardProvider` |
| `_hasReportedStorageToday`, `_reportedStores`, `_totalStores` | `HomeStorageState` | `HomeDashboardProvider` |
| `_hasReportedHygieneToday`, `_hygieneCount` | `HomeHygieneState` | `HomeDashboardProvider` |
| `_hasReportedReadinessToday`, `_readinessCount` | `HomeReadinessState` | `HomeDashboardProvider` |
| `_assetDueTodayCount`, `_isLoadingAsset` | `HomeAssetState` | `HomeDashboardProvider` |
| `_todayPresences`, `_totalEmployees`, `_lateCount`, `_onTimeCount`, `_isLoadingTodayPresences` | `HomeAdminPresenceState` | `HomeDashboardProvider` |
| `_yesterdayOmzet`, `_isLoadingYesterdayOmzet` | `HomeSalesState` | `HomeDashboardProvider` |
| `_anomalyMismatchCount`, `_anomalyMatchCount`, `_isLoadingAnomaly` | `HomeAnomalyState` | `HomeDashboardProvider` |
| `pendingOnlineOrderCount`, `pendingDirectOrderCount`, `isLoadingOrders` | `HomeOrdersState` | `HomeDashboardProvider` |
| `adminStockMonitorings`, `isLoadingAdminStockMonitoring`, `latestStockDate` | `HomeAdminStockState` | `HomeDashboardProvider` |

---

## Task 0: Tambah `mocktail` Dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Tambah `mocktail` ke dev_dependencies**

Edit `pubspec.yaml`, di section `dev_dependencies:` tambahkan:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  flutter_launcher_icons: ^0.14.4
  flutter_native_splash: ^2.4.0
  mocktail: ^1.0.4
```

- [ ] **Step 2: Jalankan `pub get`**

Run: `flutter pub get`
Expected: `Got dependencies!` tanpa conflict.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(deps): add mocktail for unit testing providers"
```

---

## Task 1: Buat `HomeDashboardProvider` Skeleton (TDD)

**Files:**
- Create: `lib/providers/home_dashboard_provider.dart`
- Create: `test/providers/home_dashboard_provider_test.dart`

**Goal:** Provider ter-definisi dengan grouped state, constructor injection (testable), dan method `loadAll` yang kosong dulu (akan diisi di Task 2-4). Test memastikan instance bisa di-create & `notifyListeners` dipanggil.

- [ ] **Step 1: Tulis failing test skeleton**

Create `test/providers/home_dashboard_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sagansa/providers/home_dashboard_provider.dart';
import 'package:sagansa/services/procurement_service.dart';
import 'package:sagansa/services/asset_service.dart';
import 'package:sagansa/services/sales_dashboard_service.dart';
import 'package:sagansa/services/inventory_anomaly_service.dart';
import 'package:sagansa/services/leave_service.dart';
import 'package:sagansa/services/salary_service.dart';
import 'package:sagansa/services/storage_stock_service.dart';
import 'package:sagansa/services/hygiene_service.dart';
import 'package:sagansa/services/readiness_service.dart';
import 'package:sagansa/services/presence_service.dart';
import 'package:sagansa/services/user_service.dart';

class _MockProcurement extends Mock implements ProcurementService {}
class _MockAsset extends Mock implements AssetService {}
class _MockSales extends Mock implements SalesDashboardService {}
class _MockAnomaly extends Mock implements InventoryAnomalyService {}
class _MockLeave extends Mock implements LeaveService {}
class _MockSalary extends Mock implements SalaryService {}
class _MockStorage extends Mock implements StorageStockService {}
class _MockHygiene extends Mock implements HygieneService {}
class _MockReadiness extends Mock implements ReadinessService {}
class _MockPresence extends Mock implements PresenceService {}
class _MockUser extends Mock implements UserService {}

void main() {
  late HomeDashboardProvider provider;
  late _MockProcurement mockProcurement;
  // ... declare other mocks

  setUp(() {
    mockProcurement = _MockProcurement();
    // ... init other mocks
    provider = HomeDashboardProvider(
      procurementService: mockProcurement,
      // ... pass other mocks
    );
  });

  test('initial state is empty/idle', () {
    expect(provider.isLoading, false);
    expect(provider.error, isNull);
    expect(provider.procurement.pendingCount, 0);
    expect(provider.asset.dueTodayCount, 0);
  });

  test('notifyListeners called on state change', () {
    var notifiedCount = 0;
    provider.addListener(() => notifiedCount++);

    provider.markLoading();
    expect(notifiedCount, 1);
  });
}
```

- [ ] **Step 2: Jalankan test — harus FAIL**

Run: `flutter test test/providers/home_dashboard_provider_test.dart`
Expected: FAIL karena `HomeDashboardProvider` belum ada.

- [ ] **Step 3: Implementasi skeleton provider**

Create `lib/providers/home_dashboard_provider.dart`:

```dart
import 'package:flutter/foundation.dart';
import '../services/procurement_service.dart';
import '../services/asset_service.dart';
import '../services/sales_dashboard_service.dart';
import '../services/inventory_anomaly_service.dart';
import '../services/leave_service.dart';
import '../services/salary_service.dart';
import '../services/storage_stock_service.dart';
import '../services/hygiene_service.dart';
import '../services/readiness_service.dart';
import '../services/presence_service.dart';
import '../services/user_service.dart';

// === State value objects (immutable per-group) ===

@immutable
class HomeProcurementState {
  final int pendingCount;
  final int approvedCount;
  final int invoiceDraftCount;
  final int invoiceDoneCount;
  final int unpaidInvoicesCount;
  final int unpaidTransferInvoicesCount;
  final bool isLoading;

  const HomeProcurementState({
    this.pendingCount = 0,
    this.approvedCount = 0,
    this.invoiceDraftCount = 0,
    this.invoiceDoneCount = 0,
    this.unpaidInvoicesCount = 0,
    this.unpaidTransferInvoicesCount = 0,
    this.isLoading = false,
  });

  HomeProcurementState copyWith({
    int? pendingCount,
    int? approvedCount,
    int? invoiceDraftCount,
    int? invoiceDoneCount,
    int? unpaidInvoicesCount,
    int? unpaidTransferInvoicesCount,
    bool? isLoading,
  }) =>
      HomeProcurementState(
        pendingCount: pendingCount ?? this.pendingCount,
        approvedCount: approvedCount ?? this.approvedCount,
        invoiceDraftCount: invoiceDraftCount ?? this.invoiceDraftCount,
        invoiceDoneCount: invoiceDoneCount ?? this.invoiceDoneCount,
        unpaidInvoicesCount: unpaidInvoicesCount ?? this.unpaidInvoicesCount,
        unpaidTransferInvoicesCount:
            unpaidTransferInvoicesCount ?? this.unpaidTransferInvoicesCount,
        isLoading: isLoading ?? this.isLoading,
      );
}

@immutable
class HomeAssetState {
  final int dueTodayCount;
  final bool isLoading;
  const HomeAssetState({this.dueTodayCount = 0, this.isLoading = false});
  HomeAssetState copyWith({int? dueTodayCount, bool? isLoading}) =>
      HomeAssetState(
        dueTodayCount: dueTodayCount ?? this.dueTodayCount,
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
/// Panggil [loadAll] sekali saat page init; [refreshSection] untuk partial.
class HomeDashboardProvider extends ChangeNotifier {
  final ProcurementService _procurementService;
  final AssetService _assetService;
  final SalesDashboardService _salesDashboardService;
  final InventoryAnomalyService _anomalyService;
  final LeaveService _leaveService;
  final SalaryService _salaryService;
  final StorageStockService _storageService;
  final HygieneService _hygieneService;
  final ReadinessService _readinessService;
  final PresenceService _presenceService;
  final UserService _userService;

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
    required LeaveService leaveService,
    required SalaryService salaryService,
    required StorageStockService storageService,
    required HygieneService hygieneService,
    required ReadinessService readinessService,
    required PresenceService presenceService,
    required UserService userService,
  })  : _procurementService = procurementService,
        _assetService = assetService,
        _salesDashboardService = salesDashboardService,
        _anomalyService = anomalyService,
        _leaveService = leaveService,
        _salaryService = salaryService,
        _storageService = storageService,
        _hygieneService = hygieneService,
        _readinessService = readinessService,
        _presenceService = presenceService,
        _userService = userService;

  // Getters
  HomeProcurementState get procurement => _procurement;
  HomeAssetState get asset => _asset;
  HomeSalesState get sales => _sales;
  HomeAnomalyState get anomaly => _anomaly;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Mark loading (untuk test stub). LoadAll akan diisi di task berikutnya.
  @visibleForTesting
  void markLoading() {
    _isLoading = true;
    notifyListeners();
  }

  /// Load semua section (parallel). TODO di Task 2-4.
  Future<void> loadAll({required bool isAdmin, required bool isStorageStaff}) async {
    // TODO: implement in Task 2-4
  }

  /// Refresh salah satu section saja (untuk pull-to-refresh per-card).
  Future<void> refreshProcurement() async {
    // TODO
  }
}
```

- [ ] **Step 4: Jalankan test — harus PASS**

Run: `flutter test test/providers/home_dashboard_provider_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/providers/home_dashboard_provider.dart test/providers/home_dashboard_provider_test.dart
git commit -m "feat(provider): add HomeDashboardProvider skeleton

Constructor-injected services (mockable). Grouped state value objects
(HomeProcurementState, HomeAssetState, etc). loadAll() to be implemented
in follow-up tasks."
```

---

## Task 2: Implementasi `loadProcurement` di Provider (TDD)

**Files:**
- Modify: `lib/providers/home_dashboard_provider.dart`
- Modify: `test/providers/home_dashboard_provider_test.dart`

**Goal:** Pindahkan logic `_loadProcurementCounts` dari `home_page.dart:287-336` ke provider, dengan service di-mock di test.

- [ ] **Step 1: Tambah test untuk `_loadProcurement`**

Append ke `test/providers/home_dashboard_provider_test.dart`:

```dart
import 'package:sagansa/models/procurement_model.dart';

void main() {
  // ... existing setUp

  group('loadProcurement', () {
    test('populates pending & approved counts from getProcurementSummary', () async {
      // Arrange: mock summary dengan 2 pending + 1 approved
      final summary = {
        'requests': [
          RequestPurchase(
            id: 1,
            detailRequests: [
              RequestPurchaseItem(id: 11, status: '1', paymentTypeId: 1),
              RequestPurchaseItem(id: 12, status: '1', paymentTypeId: 1),
              RequestPurchaseItem(id: 13, status: '4', paymentTypeId: 1),
            ],
          ),
        ],
        'invoice_draft': 2,
        'invoice_done': 5,
        'invoice_unpaid': 3,
      };
      when(() => mockProcurement.getProcurementSummary())
          .thenAnswer((_) async => summary);
      when(() => mockProcurement.getInvoices(
              paymentStatus: '1', perPage: 100))
          .thenAnswer((_) async => InvoiceListResult(items: [
                Invoice(id: 1, paymentTypeId: 1),
                Invoice(id: 2, paymentTypeId: 2),
                Invoice(id: 3, paymentTypeId: 1),
              ]));

      // Act
      await provider.loadProcurement();

      // Assert
      expect(provider.procurement.pendingCount, 2);
      expect(provider.procurement.approvedCount, 1);
      expect(provider.procurement.invoiceDraftCount, 2);
      expect(provider.procurement.invoiceDoneCount, 5);
      expect(provider.procurement.unpaidInvoicesCount, 3);
      expect(provider.procurement.unpaidTransferInvoicesCount, 2);
      expect(provider.procurement.isLoading, false);
    });

    test('handles service error gracefully (state stays default)', () async {
      when(() => mockProcurement.getProcurementSummary())
          .thenThrow(Exception('network'));

      await provider.loadProcurement();

      expect(provider.procurement.pendingCount, 0);
      expect(provider.procurement.isLoading, false);
    });
  });
}
```

> **Catatan:** signature `RequestPurchase`, `RequestPurchaseItem`, `Invoice`, `InvoiceListResult` harus disesuaikan dengan definisi aktual di `lib/models/procurement_model.dart`. Bila constructor berbeda, adjust mock di Step 1.

- [ ] **Step 2: Jalankan test — harus FAIL**

Run: `flutter test test/providers/home_dashboard_provider_test.dart`
Expected: FAIL karena `loadProcurement` belum ada.

- [ ] **Step 3: Implementasi `loadProcurement` di provider**

Edit `lib/providers/home_dashboard_provider.dart`. Tambahkan method di dalam class:

```dart
  /// Load procurement summary (pending/approved counts + invoice stats).
  /// Throws tidak — error di-swallow & state tetap default.
  Future<void> loadProcurement() async {
    _procurement = _procurement.copyWith(isLoading: true);
    notifyListeners();

    try {
      final summary = await _procurementService.getProcurementSummary();
      final List<RequestPurchase> requests =
          summary['requests'] as List<RequestPurchase>? ?? [];

      int pending = 0;
      int approved = 0;
      for (final req in requests) {
        for (final item in req.detailRequests) {
          if (item.statusEnum.isPending) {
            pending++;
          } else if (item.statusEnum.isPartiallyApproved) {
            approved++;
          }
        }
      }

      int unpaidTransferCount = 0;
      try {
        final invoiceResult = await _procurementService.getInvoices(
          paymentStatus: '1',
          perPage: 100,
        );
        unpaidTransferCount = invoiceResult.items
            .where((inv) => inv.paymentTypeId == 1)
            .length;
      } catch (_) {
        // Soft fail: unpaidTransferCount stays 0.
      }

      _procurement = _procurement.copyWith(
        pendingCount: pending,
        approvedCount: approved,
        invoiceDraftCount: (summary['invoice_draft'] as num?)?.toInt() ?? 0,
        invoiceDoneCount: (summary['invoice_done'] as num?)?.toInt() ?? 0,
        unpaidInvoicesCount: (summary['invoice_unpaid'] as num?)?.toInt() ?? 0,
        unpaidTransferInvoicesCount: unpaidTransferCount,
        isLoading: false,
      );
    } catch (_) {
      _procurement = _procurement.copyWith(isLoading: false);
    } finally {
      notifyListeners();
    }
  }
```

> Tambah import di atas:
> ```dart
> import '../models/enums/procurement_item_status.dart';
> ```

- [ ] **Step 4: Jalankan test — harus PASS**

Run: `flutter test test/providers/home_dashboard_provider_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/providers/home_dashboard_provider.dart test/providers/home_dashboard_provider_test.dart
git commit -m "feat(provider): implement loadProcurement with mocktail tests

Migrated from home_page.dart _loadProcurementCounts (lines 287-336).
Service exceptions are swallowed; state defaults preserved."
```

---

## Task 3: Implementasi `loadAsset`, `loadSales`, `loadAnomaly` (Paralel Pattern)

**Files:**
- Modify: `lib/providers/home_dashboard_provider.dart`
- Modify: `test/providers/home_dashboard_provider_test.dart`

**Goal:** Tambah 3 method load dengan pattern sama dengan Task 2. Mereka independen dan bisa dijalankan paralel di `loadAll`.

- [ ] **Step 1: Tambah 3 test group**

Append ke test file:

```dart
group('loadAsset', () {
  test('populates dueTodayCount', () async {
    when(() => mockAsset.getDashboardSummary())
        .thenAnswer((_) async => {'due_today': 3});
    await provider.loadAsset();
    expect(provider.asset.dueTodayCount, 3);
    expect(provider.asset.isLoading, false);
  });

  test('swallows error, state stays default', () async {
    when(() => mockAsset.getDashboardSummary()).thenThrow(Exception());
    await provider.loadAsset();
    expect(provider.asset.dueTodayCount, 0);
  });
});

group('loadSales', () {
  test('populates yesterdayOmzet', () async {
    when(() => mockSales.getSummary(any()))
        .thenAnswer((_) async => SalesSummary(omzet: 1500000));
    await provider.loadSales();
    expect(provider.sales.yesterdayOmzet, 1500000);
  });
});

group('loadAnomaly', () {
  test('populates mismatch & match counts', () async {
    when(() => mockAnomaly.getComparison()).thenAnswer((_) async =>
        AnomalyComparisonResponse(
          summary: AnomalySummary(mismatchCount: 2, matchCount: 10),
        ));
    await provider.loadAnomaly();
    expect(provider.anomaly.mismatchCount, 2);
    expect(provider.anomaly.matchCount, 10);
  });
});
```

> **Catatan:** nama class & method (`SalesSummary`, `AnomalyComparisonResponse`, `SalesPeriode`) harus diverifikasi dari file service aktual (`lib/services/sales_dashboard_service.dart`, `lib/services/inventory_anomaly_service.dart`). Bila berbeda, adjust.

- [ ] **Step 2: Jalankan test — harus FAIL**

Run: `flutter test test/providers/home_dashboard_provider_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementasi 3 method**

Tambah ke `lib/providers/home_dashboard_provider.dart`:

```dart
  Future<void> loadAsset() async {
    _asset = _asset.copyWith(isLoading: true);
    notifyListeners();
    try {
      final summary = await _assetService.getDashboardSummary();
      _asset = _asset.copyWith(
        dueTodayCount: (summary['due_today'] ?? 0) as int,
        isLoading: false,
      );
    } catch (_) {
      _asset = _asset.copyWith(isLoading: false);
    } finally {
      notifyListeners();
    }
  }

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
```

> Tambah import `SalesPeriode` dari `sales_dashboard_model.dart` di atas file.

- [ ] **Step 4: Jalankan test — harus PASS**

Run: `flutter test test/providers/home_dashboard_provider_test.dart`
Expected: `All tests passed!`.

- [ ] **Step 5: Implementasi `loadAll` (menjalankan 4 secara paralel)**

Edit method `loadAll` di provider:

```dart
  Future<void> loadAll({required bool isAdmin, required bool isStorageStaff}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadProcurement(),
        loadAsset(),
        loadSales(),
        loadAnomaly(),
        // TODO di task lanjutan: loadPresence, loadLeave, loadHygiene, dst.
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
```

- [ ] **Step 6: Update test `loadAll`**

Tambah test:

```dart
group('loadAll', () {
  test('runs all 4 loaders in parallel', () async {
    when(() => mockProcurement.getProcurementSummary())
        .thenAnswer((_) async => {'requests': <RequestPurchase>[]});
    when(() => mockProcurement.getInvoices(paymentStatus: '1', perPage: 100))
        .thenAnswer((_) async => InvoiceListResult(items: []));
    when(() => mockAsset.getDashboardSummary())
        .thenAnswer((_) async => {'due_today': 0});
    when(() => mockSales.getSummary(any()))
        .thenAnswer((_) async => SalesSummary(omzet: 0));
    when(() => mockAnomaly.getComparison()).thenAnswer((_) async =>
        AnomalyComparisonResponse(
          summary: AnomalySummary(mismatchCount: 0, matchCount: 0)));

    await provider.loadAll(isAdmin: false, isStorageStaff: false);

    expect(provider.isLoading, false);
    expect(provider.error, isNull);
  });
});
```

- [ ] **Step 7: Commit**

```bash
git add lib/providers/home_dashboard_provider.dart test/providers/home_dashboard_provider_test.dart
git commit -m "feat(provider): implement loadAsset/loadSales/loadAnomaly + loadAll"
```

---

## Task 4: Buat Card Widget Pertama — `HomeProcurementSummaryCard` (TDD)

**Files:**
- Create: `lib/widgets/home/home_procurement_summary_card.dart`
- Create: `test/widgets/home/home_procurement_summary_card_test.dart`

**Goal:** Card pertama yang membaca `HomeDashboardProvider.procurement` via `context.select`. Pattern ini akan jadi template untuk card lainnya.

- [ ] **Step 1: Tulis widget test**

Create `test/widgets/home/home_procurement_summary_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sagansa/providers/home_dashboard_provider.dart';
import 'package:sagansa/widgets/home/home_procurement_summary_card.dart';

class _FakeHomeDashboardProvider extends HomeDashboardProvider {
  _FakeHomeDashboardProvider({
    required super.procurementService,
    required super.assetService,
    required super.salesDashboardService,
    required super.anomalyService,
    required super.leaveService,
    required super.salaryService,
    required super.storageService,
    required super.hygieneService,
    required super.readinessService,
    required super.presenceService,
    required super.userService,
  });

  // Override real services dengan noop (tidak dipanggil di test ini).
}

void main() {
  testWidgets('shows pending & approved counts from provider',
      (tester) async {
    // Setup: provider dengan procurement state pre-loaded.
    final provider = _FakeHomeDashboardProvider(
      procurementService: _NoopProcurement(),
      // ...
    );
    // Set state manually untuk test (test-only):
    provider.setProcurementForTest(const HomeProcurementState(
      pendingCount: 5,
      approvedCount: 3,
      invoiceDraftCount: 2,
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: provider,
          child: const Scaffold(body: HomeProcurementSummaryCard()),
        ),
      ),
    );

    expect(find.text('5'), findsWidgets);
    expect(find.text('3'), findsWidgets);
  });
}
```

> **Catatan:** untuk membuat state pre-loaded di test, tambahkan method `@visibleForTesting setProcurementForTest(...)` di provider. Implementasinya di Step 3.

- [ ] **Step 2: Jalankan test — harus FAIL**

Run: `flutter test test/widgets/home/home_procurement_summary_card_test.dart`
Expected: FAIL.

- [ ] **Step 3: Tambah test helper di provider**

Edit `lib/providers/home_dashboard_provider.dart`. Tambahkan method:

```dart
  /// Test-only setter untuk pre-populate state.
  @visibleForTesting
  void setProcurementForTest(HomeProcurementState state) {
    _procurement = state;
    notifyListeners();
  }
```

- [ ] **Step 4: Implementasi card widget**

Create `lib/widgets/home/home_procurement_summary_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_dashboard_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Card ringkasan procurement di Home.
///
/// Subscribe ke [HomeDashboardProvider.procurement] via `context.select`
/// agar hanya rebuild saat state procurement berubah.
class HomeProcurementSummaryCard extends StatelessWidget {
  const HomeProcurementSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Fine-grained: hanya rebuild saat procurement state berubah.
    final procurement = context.select<HomeDashboardProvider,
        HomeProcurementState>((p) => p.procurement);

    if (procurement.isLoading) {
      return const _ProcurementSkeleton();
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.shopping_cart, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
                Text('Procurement',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                      label: 'Pending', value: procurement.pendingCount),
                ),
                Expanded(
                  child: _Stat(
                      label: 'Approved',
                      value: procurement.approvedCount),
                ),
                Expanded(
                  child: _Stat(
                      label: 'Invoice Draft',
                      value: procurement.invoiceDraftCount),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                      label: 'Invoice Done',
                      value: procurement.invoiceDoneCount),
                ),
                Expanded(
                  child: _Stat(
                      label: 'Unpaid',
                      value: procurement.unpaidInvoicesCount),
                ),
                Expanded(
                  child: _Stat(
                      label: 'Unpaid Transfer',
                      value: procurement.unpaidTransferInvoicesCount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ProcurementSkeleton extends StatelessWidget {
  const _ProcurementSkeleton();
  @override
  Widget build(BuildContext context) {
    // TODO: gunakan SkeletonLoading yang sudah ada di lib/widgets/.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(children: const [Text('Loading...')]),
      ),
    );
  }
}
```

- [ ] **Step 5: Jalankan test — harus PASS**

Run: `flutter test test/widgets/home/home_procurement_summary_card_test.dart`
Expected: `All tests passed!`.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/home/home_procurement_summary_card.dart lib/providers/home_dashboard_provider.dart test/widgets/home/home_procurement_summary_card_test.dart
git commit -m "feat(home): add HomeProcurementSummaryCard with context.select

First card extracted from home_page.dart. Uses fine-grained rebuild
via context.select on HomeProcurementState. Includes skeleton loader."
```

---

## Task 5: Buat 5 Card Lainnya (Pattern Repetition)

**Files:**
- Create: `lib/widgets/home/home_asset_summary_card.dart`
- Create: `lib/widgets/home/home_sales_anomaly_card.dart`
- Create: `lib/widgets/home/home_presence_summary_card.dart`
- Create: `lib/widgets/home/home_hygiene_readiness_card.dart`
- Create: `lib/widgets/home/home_admin_overview_card.dart`
- Create: `lib/widgets/home/home_skeleton_loader.dart`
- 5 file test di `test/widgets/home/`

**Goal:** Selesaikan semua card dengan pattern yang sama dengan Task 4. Setiap card ≤ 150 LOC.

> Karena pattern identik dengan Task 4, di sini hanya berikan struktur & acceptance criteria. Implementasi detail mengikuti template `home_procurement_summary_card.dart`.

- [ ] **Step 1: Untuk tiap card, ikuti urutan ini**

Untuk **`home_asset_summary_card.dart`**:

1. Tulis widget test yang pre-load `provider.asset = HomeAssetState(dueTodayCount: 7)`.
2. Card menampilkan dueTodayCount dengan label "Aset Jatuh Tempo".
3. Tap card → navigasi ke `AssetDashboardPage()` (pertahankan Navigator.push untuk sekarang).
4. Run test, verify pass.
5. Commit: `feat(home): add HomeAssetSummaryCard`.

Untuk **`home_sales_anomaly_card.dart`**:

1. Test pre-load `sales = HomeSalesState(yesterdayOmzet: 1500000)` & `anomaly = HomeAnomalyState(mismatchCount: 2, matchCount: 10)`.
2. Card menampilkan omzet kemarin (format Rupiah) + anomaly mismatch count.
3. Commit: `feat(home): add HomeSalesAnomalyCard`.

Untuk **`home_presence_summary_card.dart`**:

1. **Catatan:** presence state belum ada di provider (Task 2-3 fokus procurement/asset/sales/anomaly). Tambahkan `HomePresenceState` ke provider dulu sebelum card ini.
2. Test pre-load state dengan `PresenceModel` mock.
3. Card menampilkan today presence + yesterday summary + tombol check-in/out.
4. Commit: `feat(provider): add HomePresenceState` lalu `feat(home): add HomePresenceSummaryCard`.

Untuk **`home_hygiene_readiness_card.dart`**:

1. Tambah `HomeHygieneState` & `HomeReadinessState` ke provider.
2. Card menampilkan status laporan hygiene + readiness hari ini.
3. Commit terpisah untuk state + card.

Untuk **`home_admin_overview_card.dart`**:

1. Card khusus admin: today presences (late/onTime), total employees, admin stock monitoring.
2. Hanya render saat `isAdmin == true` (baca dari AuthProvider).
3. Commit.

- [ ] **Step 2: Buat `home_skeleton_loader.dart`**

Create `lib/widgets/home/home_skeleton_loader.dart`:

```dart
import 'package:flutter/material.dart';
import '../skeleton_loading.dart';

/// Skeleton loader untuk seluruh body Home saat initial load.
class HomeSkeletonLoader extends StatelessWidget {
  const HomeSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: SkeletonLoading(height: 100),
      ),
    );
  }
}
```

(Adjust signature `SkeletonLoading` sesuai yang sudah ada di `lib/widgets/skeleton_loading.dart`.)

- [ ] **Step 3: Verify semua card test lulus**

Run: `flutter test test/widgets/home/`
Expected: `All tests passed!`.

- [ ] **Step 4: Commit skeleton loader & tiap card (boleh batch)**

```bash
git add lib/widgets/home/home_skeleton_loader.dart
git commit -m "feat(home): add HomeSkeletonLoader for initial loading state"
```

---

## Task 6: Rewrite `home_page.dart` jadi Shell Ringkas

**Files:**
- Modify: `lib/pages/home_page.dart` (rewrite besar)
- Modify: `lib/main.dart` (register `HomeDashboardProvider`)

**Goal:** Ganti StatefulWidget 1.985 LOC dengan StatelessWidget shell ~200-300 LOC.

- [ ] **Step 1: Snapshot home_page.dart sebelum rewrite (safety net)**

Run: `cp lib/pages/home_page.dart lib/pages/home_page.dart.bak` (lokal, tidak commit).

- [ ] **Step 2: Tambah AuthProvider getter `roles`**

Edit `lib/providers/auth_provider.dart`. Tambah getter:

```dart
  /// Roles user saat ini (untuk gating UI di HomePage).
  List<String> get roles {
    if (_userData == null) return const [];
    return List<String>.from(_userData!['roles'] ?? []);
  }

  bool get isAdmin => roles.any((r) => r == 'admin' || r == 'super_admin');
  bool get isStorageStaff => roles.contains('storage-staff');
```

- [ ] **Step 3: Register provider di `main.dart`**

Edit `lib/main.dart`. Di `_MyAppState`, tambahkan ke `MultiProvider`:

```dart
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider),
        ChangeNotifierProvider<PrinterProvider>.value(value: _printerProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<FuelServicePaymentProvider>.value(
            value: _fuelServicePaymentProvider),
        // NEW: Home dashboard provider (page-scoped lebih ideal,
        // tapi register global untuk simplicity — akan dipakai HomePage).
        ChangeNotifierProvider<HomeDashboardProvider>(
          create: (_) => HomeDashboardProvider(
            procurementService: ProcurementService(),
            assetService: AssetService(),
            salesDashboardService: SalesDashboardService(),
            anomalyService: InventoryAnomalyService(),
            leaveService: LeaveService(),
            salaryService: SalaryService(),
            storageService: StorageStockService(),
            hygieneService: HygieneService(),
            readinessService: ReadinessService(),
            presenceService: PresenceService(),
            userService: UserService(),
          ),
        ),
      ],
      // ...
```

Tambah import:

```dart
import 'providers/home_dashboard_provider.dart';
import 'services/procurement_service.dart';
import 'services/asset_service.dart';
import 'services/sales_dashboard_service.dart';
import 'services/inventory_anomaly_service.dart';
import 'services/leave_service.dart';
import 'services/salary_service.dart';
import 'services/storage_stock_service.dart';
import 'services/hygiene_service.dart';
import 'services/readiness_service.dart';
import 'services/presence_service.dart';
import 'services/user_service.dart';
```

- [ ] **Step 4: Tulis widget test untuk HomePage ringkas**

Create `test/pages/home_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sagansa/pages/home_page.dart';
import 'package:sagansa/providers/auth_provider.dart';
import 'package:sagansa/providers/home_dashboard_provider.dart';
import 'package:sagansa/services/procurement_service.dart';
// ... import semua service lain

void main() {
  late HomeDashboardProvider provider;

  setUp(() {
    provider = HomeDashboardProvider(
      procurementService: ProcurementService(),
      // ...
    );
  });

  testWidgets('HomePage renders HomeProcurementSummaryCard',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(
                value: _FakeAuthProvider()),
            ChangeNotifierProvider<HomeDashboardProvider>.value(
                value: provider),
          ],
          child: const HomePage(),
        ),
      ),
    );

    // Initial frame + load.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomeProcurementSummaryCard), findsOneWidget);
  });
}

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider() : super() {
    // set state via reflection atau test setter.
  }
}
```

- [ ] **Step 5: Rewrite `home_page.dart`**

Overwrite `lib/pages/home_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/home_dashboard_provider.dart';
import '../services/procurement_service.dart';
import '../services/asset_service.dart';
import '../services/sales_dashboard_service.dart';
import '../services/inventory_anomaly_service.dart';
import '../services/leave_service.dart';
import '../services/salary_service.dart';
import '../services/storage_stock_service.dart';
import '../services/hygiene_service.dart';
import '../services/readiness_service.dart';
import '../services/presence_service.dart';
import '../services/user_service.dart';
import '../services/version_service.dart';
import '../theme/app_colors.dart';
import '../widgets/home/home_skeleton_loader.dart';
import '../widgets/home/home_presence_summary_card.dart';
import '../widgets/home/home_procurement_summary_card.dart';
import '../widgets/home/home_asset_summary_card.dart';
import '../widgets/home/home_hygiene_readiness_card.dart';
import '../widgets/home/home_sales_anomaly_card.dart';
import '../widgets/home/home_admin_overview_card.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/app_version_text.dart';
import '../widgets/modern_bottom_nav.dart';

class HomePage extends StatefulWidget {
  final bool? initialIsAdmin;
  const HomePage({super.key, this.initialIsAdmin});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Trigger async load di frame berikutnya.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final home = context.read<HomeDashboardProvider>();
      home.loadAll(isAdmin: auth.isAdmin, isStorageStaff: auth.isStorageStaff);

      // Check for app updates (preserve behavior lama).
      VersionService().checkForUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<HomeDashboardProvider, bool>(
        (p) => p.isLoading);
    final isAdmin = widget.initialIsAdmin ??
        context.select<AuthProvider, bool>((a) => a.isAdmin);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sagansa'),
        actions: const [
          ThemeToggleButton(),
          AppVersionText(),
        ],
      ),
      body: isLoading
          ? const HomeSkeletonLoader()
          : RefreshIndicator(
              onRefresh: () => context.read<HomeDashboardProvider>().loadAll(
                    isAdmin: isAdmin,
                    isStorageStaff:
                        context.read<AuthProvider>().isStorageStaff,
                  ),
              child: ListView(
                children: [
                  const HomePresenceSummaryCard(),
                  const HomeProcurementSummaryCard(),
                  const HomeAssetSummaryCard(),
                  const HomeHygieneReadinessCard(),
                  const HomeSalesAnomalyCard(),
                  if (isAdmin) const HomeAdminOverviewCard(),
                ],
              ),
            ),
      bottomNavigationBar: const ModernBottomNav(currentIndex: 0),
    );
  }
}
```

- [ ] **Step 6: Jalankan semua test**

Run: `flutter test`
Expected: semua test lulus. Bila ada failure karena `VersionService().checkForUpdate(context)` di-init, mock atau skip di test.

- [ ] **Step 7: Smoke test mendalam di emulator**

Run: `flutter run`

Test manual komprehensif:
- [ ] Home page render tanpa crash.
- [ ] Skeleton loader tampil saat initial load (~1-3 detik).
- [ ] Card procurement muncul dengan angka benar (bandingkan dengan backup `home_page.dart.bak` di branch lama).
- [ ] Card asset, sales, anomaly muncul.
- [ ] Login sebagai admin → `HomeAdminOverviewCard` tampil.
- [ ] Login sebagai staff → admin card **tidak** tampil.
- [ ] Pull-to-refresh → semua card re-render.
- [ ] Bottom nav tetap fungsi (tap navigasi).
- [ ] Theme toggle berfungsi.

- [ ] **Step 8: Hapus backup**

Run: `rm lib/pages/home_page.dart.bak`

- [ ] **Step 9: Verifikasi LOC & metrik**

Run:
```bash
wc -l lib/pages/home_page.dart
grep -c "setState" lib/pages/home_page.dart
grep -c "Service()" lib/pages/home_page.dart
```
Expected:
- `home_page.dart` LOC: < 200.
- `setState`: 0.
- `Service()` inline: 0 (semua via Provider).

- [ ] **Step 10: Commit (besar — pastikan reviewer aware)**

```bash
git add lib/pages/home_page.dart lib/main.dart lib/providers/auth_provider.dart test/pages/home_page_test.dart
git commit -m "refactor(home): rewrite home_page.dart as stateless shell

Was 1985 LOC StatefulWidget with 37 setState + 20 inline services.
Now ~150 LOC StatefulWidget shell that delegates to HomeDashboardProvider
and 6 card widgets. State centralized; cards use context.select for
fine-grained rebuild. All card behaviors verified via smoke test.

BREAKING CHANGE: home_page.dart no longer holds business state;
use HomeDashboardProvider via context.read/watch."
```

---

## Task 7: Final Verification & Health Snapshot

**Files:**
- Create: `docs/health-reports/2026-07-20-sprint3-home-refactor-final.md`

- [ ] **Step 1: Jalankan health script**

Run: `./scripts/codebase_health.sh 2026-07-20-sprint3-home-refactor-final`

- [ ] **Step 2: Compare dengan baseline**

Run:
```bash
diff docs/health-reports/2026-07-20-sprint1-baseline.md docs/health-reports/2026-07-20-sprint3-home-refactor-final.md
```

**Expected:**
- `home_page.dart` LOC: 1985 → < 200.
- `setState` count: 713 → ~676 (turun ~37, semua dari home).
- File test: naik ~10.
- Files > 500 LOC: turun 1 (home).

- [ ] **Step 3: Full analyze + test**

Run: `flutter analyze && flutter test --coverage`
Expected: 0 error, semua test lulus.

- [ ] **Step 4: Commit health report**

```bash
git add docs/health-reports/2026-07-20-sprint3-home-refactor-final.md
git commit -m "docs(health): sprint 3 (home refactor) final snapshot — home_page 1985→150 LOC"
```

---

## Acceptance Criteria (dari PRD §4.2)

- [ ] `home_page.dart` ≤ 500 LOC (target ideal: 200).
- [ ] **0** field `Service()` di dalam `HomePage` / `HomePageState`.
- [ ] **0** `setState` di `home_page.dart`.
- [ ] `HomeDashboardProvider` punya unit test untuk `loadAll` (≥ 5 test case).
- [ ] `loadUserInfo` & `checkActiveLeave` hanya ada di `AuthProvider` (tidak diduplikasi).
- [ ] Performance: rebuild 1 card saat state-nya berubah ≤ 16ms (verify dengan DevTools timeline saat pull-to-refresh).
- [ ] Smoke test manual lulus semua scenario di Task 6 Step 7.
- [ ] Card widget di `lib/widgets/home/` punya widget test masing-masing.

---

## Troubleshooting

### Card tidak rebuild saat provider `notifyListeners`

Pastikan pakai `context.select<HomeDashboardProvider, HomeDashboardX>((p) => p.x)`, **bukan** `context.watch` (yang rebuild pada setiap notify). Bila state object adalah class baru (bukan primitive), pastikan method `copyWith` menghasilkan instance berbeda (referensi).

### `VersionService().checkForUpdate(context)` error di test

Itu karena `VersionService` butuh package_info. Mock atau skip di test:

```dart
when(() => mockVersion.checkForUpdate(any())).thenReturn(null);
```

### Service constructor butuh parameter yang tidak ada di test

Lihat service definition. Bila `ProcurementService()` constructor no-arg, seharusnya langsung jalan. Bila butuh `ApiClient`, injection sudah otomatis karena singleton.

### Test widget memerlukan MultiProvider berlapis

Bungkus dengan `MultiProvider` di test, bukan satu-satu. Pastikan semua provider yang dibaca `HomePage` ter-registered di test (AuthProvider + HomeDashboardProvider).

### `context.select` gagal dengan "could not find ancestor"

Pastikan `HomePage` berada di bawah `MultiProvider` di widget tree. Bila provider diregister di `main.dart` MyApp, otomatis turun ke semua child.

### Performance rebuild tinggi (frame drop)

Profile dengan Flutter DevTools → Performance tab. Bila satu card rebuild ternyata memicu seluruh ListView rebuild, ganti `context.select` ke `Consumer<HomeDashboardProvider>` dengan `builder` yang wrap individual card.

---

## Out of Scope (untuk sprint ini)

- Migrasi presence/hygiene/readiness/storage state (Task 5 ringkas; bisa di-detail-kan di task lanjutan).
- Pull-to-refresh per-card (saat ini pull-to-refresh global saja).
- Error state UI per-card (saat ini error di-swallow & card kosong).
- Migrasi AppDrawer yang hilang dari home (kalau ada, restore di task terpisah).
- Refactor `delivery_page.dart` (3.937 LOC) — Sprint berikutnya, pattern sama.
- go_router integration (Plan 4).
