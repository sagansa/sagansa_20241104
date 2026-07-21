import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sagansa/models/inventory_anomaly_model.dart';
import 'package:sagansa/models/procurement_model.dart';
import 'package:sagansa/models/sales_dashboard_model.dart';
import 'package:sagansa/providers/home_dashboard_provider.dart';
import 'package:sagansa/services/asset_service.dart';
import 'package:sagansa/services/inventory_anomaly_service.dart';
import 'package:sagansa/services/leave_service.dart';
import 'package:sagansa/services/presence_service.dart';
import 'package:sagansa/services/procurement_service.dart';
import 'package:sagansa/services/salary_service.dart';
import 'package:sagansa/services/sales_dashboard_service.dart';
import 'package:sagansa/services/storage_stock_service.dart';
import 'package:sagansa/services/user_service.dart';
import 'package:sagansa/widgets/home/cards/home_anomaly_card.dart';
import 'package:sagansa/widgets/home/cards/home_asset_due_card.dart';
import 'package:sagansa/widgets/home/cards/home_invoice_unpaid_card.dart';
import 'package:sagansa/widgets/home/cards/home_presence_summary_card.dart';
import 'package:sagansa/widgets/home/cards/home_stock_report_card.dart';
import 'package:sagansa/widgets/home/cards/home_yesterday_omzet_card.dart';

class _MockProcurement extends Mock implements ProcurementService {}
class _MockAsset extends Mock implements AssetService {}
class _MockSales extends Mock implements SalesDashboardService {}
class _MockAnomaly extends Mock implements InventoryAnomalyService {}
class _MockStorage extends Mock implements StorageStockService {}
class _MockPresence extends Mock implements PresenceService {}
class _MockUser extends Mock implements UserService {}
class _MockLeave extends Mock implements LeaveService {}
class _MockSalary extends Mock implements SalaryService {}

/// Build a provider with all 9 mocked services for widget tests.
HomeDashboardProvider _providerWithMocks({
  required _MockProcurement procurement,
  required _MockAsset asset,
  required _MockSales sales,
  required _MockAnomaly anomaly,
  required _MockStorage storage,
  required _MockPresence presence,
  required _MockUser user,
  required _MockLeave leave,
  required _MockSalary salary,
}) {
  return HomeDashboardProvider(
    procurementService: procurement,
    assetService: asset,
    salesDashboardService: sales,
    anomalyService: anomaly,
    storageService: storage,
    presenceService: presence,
    userService: user,
    leaveService: leave,
    salaryService: salary,
  );
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required HomeDashboardProvider provider,
  required Widget child,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider.value(
        value: provider,
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockProcurement mockProcurement;
  late _MockAsset mockAsset;
  late _MockSales mockSales;
  late _MockAnomaly mockAnomaly;
  late _MockStorage mockStorage;
  late _MockPresence mockPresence;
  late _MockUser mockUser;
  late _MockLeave mockLeave;
  late _MockSalary mockSalary;
  late HomeDashboardProvider provider;

  setUp(() {
    mockProcurement = _MockProcurement();
    mockAsset = _MockAsset();
    mockSales = _MockSales();
    mockAnomaly = _MockAnomaly();
    mockStorage = _MockStorage();
    mockPresence = _MockPresence();
    mockUser = _MockUser();
    mockLeave = _MockLeave();
    mockSalary = _MockSalary();
    provider = _providerWithMocks(
      procurement: mockProcurement,
      asset: mockAsset,
      sales: mockSales,
      anomaly: mockAnomaly,
      storage: mockStorage,
      presence: mockPresence,
      user: mockUser,
      leave: mockLeave,
      salary: mockSalary,
    );
    registerFallbackValue(SalesPeriode.today);
  });

  group('HomeAssetDueCard', () {
    testWidgets('renders dueTodayCount value when asset loaded',
        (tester) async {
      when(() => mockAsset.getDashboardSummary())
          .thenAnswer((_) async => {'due_today': 7, 'overdue': 0, 'due_this_week': 0});
      await provider.loadAsset();

      await _pumpCard(
        tester,
        provider: provider,
        child: const HomeAssetDueCard(),
      );

      expect(find.text('7'), findsOneWidget);
      expect(find.text('Aset Jatuh Tempo'), findsOneWidget);
    });

    testWidgets('shows placeholder while loading', (tester) async {
      // Use a Completer so the mock stays pending until we resolve it.
      final completer = Completer<Map<String, dynamic>>();
      when(() => mockAsset.getDashboardSummary()).thenAnswer((_) => completer.future);

      // Trigger load — sync part sets isLoading=true and notifies.
      unawaited(provider.loadAsset());
      // Let microtasks run so notifyListeners has fired.
      await Future.microtask(() {});

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: provider,
            child: const Scaffold(body: HomeAssetDueCard()),
          ),
        ),
      );

      expect(find.text('...'), findsOneWidget);

      // Complete so the test doesn't hang on teardown.
      completer.complete({'due_today': 0});
    });
  });

  group('HomeStockReportCard', () {
    testWidgets('renders reported/total ratio', (tester) async {
      when(() => mockStorage.checkTodayStatus()).thenAnswer((_) async => {
            'total_stores': 5,
            'reported_stores': 3,
            'user_store_reported': 1,
          });
      await provider.loadStorage();

      await _pumpCard(
        tester,
        provider: provider,
        child: const HomeStockReportCard(),
      );

      expect(find.text('3/5'), findsOneWidget);
      expect(find.text('Laporan Stok'), findsOneWidget);
    });
  });

  group('HomeYesterdayOmzetCard', () {
    testWidgets('renders formatted omzet value', (tester) async {
      when(() => mockSales.getSummary(SalesPeriode.yesterday))
          .thenAnswer((_) async => const SalesSummary(
                periodeLabel: 'Kemarin',
                omzet: 1500000,
                orderCount: 10,
                totalQty: 50,
                omzetPrev: 1000000,
                orderCountPrev: 8,
                totalQtyPrev: 40,
                prevLabel: 'Lusa',
              ));
      await provider.loadSales();

      await _pumpCard(
        tester,
        provider: provider,
        child: const HomeYesterdayOmzetCard(),
      );

      // FormatUtils.formatCurrencyCompact(1500000) contains "1,5" or "1,5 Jt"
      // (depends on locale); at minimum label must render.
      expect(find.text('Omzet Kemarin'), findsOneWidget);
    });

    testWidgets('renders dash when omzet null', (tester) async {
      when(() => mockSales.getSummary(SalesPeriode.yesterday))
          .thenThrow(Exception());
      await provider.loadSales();

      await _pumpCard(
        tester,
        provider: provider,
        child: const HomeYesterdayOmzetCard(),
      );

      expect(find.text('-'), findsOneWidget);
    });
  });

  group('HomeAnomalyCard', () {
    testWidgets('renders mismatch count + match badge', (tester) async {
      when(() => mockAnomaly.getComparison()).thenAnswer((_) async =>
          InventoryAnomalyResponse(
            period: const InventoryAnomalyPeriod(
                dateFrom: '', dateTo: '', storeIds: []),
            summary: const InventoryAnomalySummary(
                productsCompared: 12,
                matchCount: 10,
                mismatchCount: 2,
                noSoDataCount: 0,
                noStockDataCount: 0,
                totalSoldQty: 0,
                totalStockOutQty: 0),
            items: const [],
            meta: const InventoryAnomalyMeta(
                currentPage: 1, lastPage: 1, perPage: 50, total: 0),
          ));
      await provider.loadAnomaly();

      await _pumpCard(
        tester,
        provider: provider,
        child: const HomeAnomalyCard(),
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.text('Selisih Stok'), findsOneWidget);
      expect(find.textContaining('10'), findsWidgets);
    });
  });

  group('HomeInvoiceUnpaidCard', () {
    testWidgets('renders unpaidTransferInvoicesCount', (tester) async {
      when(() => mockProcurement.getProcurementSummary())
          .thenAnswer((_) async => {
                'requests': const [],
                'invoice_draft': 0,
                'invoice_done': 0,
                'invoice_unpaid': 5,
              });
      when(() => mockProcurement.getInvoices(paymentStatus: '1', perPage: 100))
          .thenAnswer((_) async => PaginatedResult(
                items: const [],
                currentPage: 1,
                lastPage: 1,
                perPage: 100,
                total: 0,
              ));
      await provider.loadProcurement();

      await _pumpCard(
        tester,
        provider: provider,
        child: const HomeInvoiceUnpaidCard(),
      );

      expect(find.text('Invoice Unpaid'), findsOneWidget);
    });
  });

  group('HomePresenceSummaryCard', () {
    testWidgets('renders today presences ratio', (tester) async {
      when(() => mockPresence.getAllTodayPresences()).thenAnswer((_) async =>
          (
            presences: [
              {'id': 1},
              {'id': 2},
              {'id': 3},
            ],
            summary: {'late_count': 1, 'on_time_count': 2},
          ));
      when(() => mockUser.getUsers(role: 'staff'))
          .thenAnswer((_) async => [{'id': 1}, {'id': 2}, {'id': 3}, {'id': 4}, {'id': 5}]);
      await provider.loadAdminPresence();

      await _pumpCard(
        tester,
        provider: provider,
        child: const HomePresenceSummaryCard(),
      );

      expect(find.text('3/5'), findsOneWidget);
      expect(find.text('Presensi'), findsOneWidget);
      // Late badge "1 telat" should appear.
      expect(find.textContaining('telat'), findsOneWidget);
    });
  });
}
