# go_router Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrasi routing Sagansa Mobile dari 130 `Navigator.push` manual ke `go_router` dengan route tree terstruktur: deep linking-ready, auth redirect guard, dan `ShellRoute` untuk bottom navigation. Target: minimal 20 route utama ter-migrasi di sprint ini, sisanya gradual.

**Architecture:** `GoRouter` instance global dengan `redirect` callback berbasis `AuthProvider.isAuthenticated`. Bottom nav pakai `ShellRoute` agar state nav persist saat navigasi antar tab. Named route dipakai untuk deep link (`/procurement/123`).

**Tech Stack:** Flutter, `go_router: ^14.6.0` (atau latest stable), `provider ^6.1.2`, `flutter_test`.

**Spec:** `PRD_CODEBASE_IMPROVEMENT.md` §4.3 (WS-03).

**Direktori kerja:** `/Users/dityo/Codings/sagansa/mobiles/sagansa/` (semua path di bawah relatif ke sini).

---

## Aturan Umum

1. **Satu task = satu commit.** Pesan commit pakai `refactor(router): ...`.
2. **Gradual migration.** Selama migrasi, `Navigator.push` dan `context.go()` **bisa hidup berdampingan**. Jangan hapus `Navigator.push` yang belum ter-migrasi.
3. **Test first.** Tiap route penting harus punya widget test yang verifikasi: route → render page yang benar.
4. **Behavior preserve.** Setelah migrasi, alur login → home → navigasi harus sama persis dengan sebelumnya.
5. **Jangan configure deep link native** (Android Manifest / iOS Associated Domains) di sprint ini — itu task terpisah yang butuh domain verification. Sprint ini hanya siapkan URL scheme di sisi Flutter.

---

## File Structure

### Create (NEW)
- `lib/router/app_router.dart` — `GoRouter` instance + `GoRoute` tree
- `lib/router/route_names.dart` — konstanta nama route (untuk `goNamed`/`pushNamed`)
- `lib/widgets/main_shell.dart` — shell yang bungkus bottom nav + body
- `test/router/app_router_test.dart` — test redirect logic
- `test/widgets/main_shell_test.dart` — test bottom nav interaksi

### Modify
- `pubspec.yaml` — tambah `go_router`
- `lib/main.dart` — ganti `MaterialApp` → `MaterialApp.router`
- `lib/widgets/modern_bottom_nav.dart` — pakai `context.go()` bukan `Navigator.pushReplacement`
- Bertahap: 50+ file page (lihat "Migration Queue" §Route Tree)

---

## Route Tree (Target)

```
/login                                  → LoginPage
/                                       → redirect ke /home atau /login

ShellRoute (MainShell with bottom nav):
  /home                                 → HomePage              [tab 0]
  /hrd                                  → HRDDashboardPage      [tab 1]
  /stock                                → StockDashboardPage    [tab 2]
  /transaction                          → TransactionDashboardPage [tab 3]
  /operational                          → OperationalDashboardPage [tab 4]

Nested routes (di luar shell):
  /profile                              → ProfilePage
  /printer-settings                     → PrinterSettingsPage
  /loan                                 → LoanPage
  /salary                               → SalaryPage
  /leave                                → LeavePage
  /leave/new                            → LeaveFormPage
  /hygiene                              → HygienePage
  /readiness                            → ReadinessPage

Procurement:
  /procurement                          → ProcurementDashboardPage (atau workflow)
  /procurement/:id                      → ProcurementDetailPage
  /procurement/new                      → CreateProcurementPage
  /procurement/invoices/:id             → InvoiceDetailPage

Asset:
  /assets                               → AssetListPage
  /assets/from-product                  → AssetFromProductPage

Closing store:
  /closing-store                        → ClosingStorePage

Storage:
  /storage-stocks                       → StorageStockListPage

Fuel:
  /fuel-service/new                     → FuelServiceFormPage

Production:
  /production/new                       → ProductionFormPage
```

> **Catatan:** Daftar di atas bukan exhaustive. Bila ada page yang tidak ada route-nya, fallback ke `Navigator.push` lama (tidak masalah).

---

## Task 0: Snapshot & Dry Run Check

**Files:** —

- [ ] **Step 1: Catat baseline jumlah Navigator.push**

Run: `grep -rc "Navigator.push" lib/ | awk -F: '{sum+=$2} END {print sum}'`
Expected: ~130. Catat angkanya.

- [ ] **Step 2: Catat daftar page yang dipakai di Navigator.push**

Run:
```bash
grep -rhE "MaterialPageRoute.*=>.*const [A-Z][a-zA-Z]+\(" lib/ | grep -oE "const [A-Z][a-zA-Z]+\(" | sort -u
```
Expected: ~30 unique page class. Catat untuk "Migration Queue".

- [ ] **Step 3: Catat semua tempat `Navigator.pushReplacement` dipakai**

Run:
```bash
grep -rn "Navigator.pushReplacement\|Navigator.pushReplacementNamed" lib/
```
Expected: mayoritas di `modern_bottom_nav.dart`. Itu akan diganti di Task 5.

---

## Task 1: Tambah Dependency `go_router`

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Cek latest stable go_router**

Run: `flutter pub add go_router --dry-run`
Expected: menampilkan versi yang akan ditambah (mis. `go_router: ^14.6.0`).

- [ ] **Step 2: Tambah dependency**

Edit `pubspec.yaml`. Tambah ke `dependencies:`:

```yaml
dependencies:
  # ... existing
  go_router: ^14.6.0
```

Atau jalankan langsung:

Run: `flutter pub add go_router`
Expected: `Got dependencies!` dan `pubspec.lock` ter-update.

- [ ] **Step 3: Verifikasi import bekerja**

Buat file sementara untuk cek:

Run: `echo "import 'package:go_router/go_router.dart'; void main() {}" > /tmp/test_go_router.dart && dart analyze /tmp/test_go_router.dart`
Expected: no error (hanya "unused import" warning, itu OK).

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(deps): add go_router for declarative routing"
```

---

## Task 2: Buat `RouteNames` Konstanta

**Files:**
- Create: `lib/router/route_names.dart`

**Goal:** Centralisasi nama route & path agar konsisten, hindari typo.

- [ ] **Step 1: Buat file konstanta**

Create `lib/router/route_names.dart`:

```dart
/// Nama route terpusat untuk `go_router`.
///
/// **Penggunaan:**
/// ```dart
/// context.go(RoutePaths.home);
/// context.goNamed(RouteNames.home);
/// context.go('${RoutePaths.procurementDetail}/$id');
/// ```
abstract class RouteNames {
  static const String login = 'login';
  static const String home = 'home';
  static const String hrd = 'hrd';
  static const String stock = 'stock';
  static const String transaction = 'transaction';
  static const String operational = 'operational';
  static const String profile = 'profile';
  static const String printerSettings = 'printer-settings';
  static const String loan = 'loan';
  static const String salary = 'salary';
  static const String leave = 'leave';
  static const String leaveNew = 'leave-new';
  static const String hygiene = 'hygiene';
  static const String readiness = 'readiness';
  static const String procurement = 'procurement';
  static const String procurementDetail = 'procurement-detail';
  static const String procurementNew = 'procurement-new';
  static const String invoiceDetail = 'invoice-detail';
  static const String assets = 'assets';
  static const String assetFromProduct = 'asset-from-product';
  static const String closingStore = 'closing-store';
  static const String storageStocks = 'storage-stocks';
  static const String fuelServiceNew = 'fuel-service-new';
  static const String productionNew = 'production-new';
}

abstract class RoutePaths {
  static const String login = '/login';
  static const String home = '/home';
  static const String hrd = '/hrd';
  static const String stock = '/stock';
  static const String transaction = '/transaction';
  static const String operational = '/operational';
  static const String profile = '/profile';
  static const String printerSettings = '/printer-settings';
  static const String loan = '/loan';
  static const String salary = '/salary';
  static const String leave = '/leave';
  static const String leaveNew = '/leave/new';
  static const String hygiene = '/hygiene';
  static const String readiness = '/readiness';
  static const String procurement = '/procurement';
  // Pattern untuk route dengan parameter pakai :param.
  static const String procurementDetail = '/procurement/:id';
  static const String procurementNew = '/procurement/new';
  static const String invoiceDetail = '/procurement/invoices/:id';
  static const String assets = '/assets';
  static const String assetFromProduct = '/assets/from-product';
  static const String closingStore = '/closing-store';
  static const String storageStocks = '/storage-stocks';
  static const String fuelServiceNew = '/fuel-service/new';
  static const String productionNew = '/production/new';
}
```

- [ ] **Step 2: Verifikasi analyze**

Run: `flutter analyze lib/router/route_names.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/router/route_names.dart
git commit -m "feat(router): add RouteNames & RoutePaths constants"
```

---

## Task 3: Buat `MainShell` Widget (ShellRoute wrapper)

**Files:**
- Create: `lib/widgets/main_shell.dart`
- Create: `test/widgets/main_shell_test.dart`

**Goal:** Shell yang merender `ModernBottomNav` + body child. Ini akan dipakai `ShellRoute` agar bottom nav persist saat berpindah tab.

- [ ] **Step 1: Tulis widget test**

Create `test/widgets/main_shell_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sagansa/widgets/main_shell.dart';

void main() {
  testWidgets('MainShell renders child + bottom nav', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(
          location: '/home',
          child: const Scaffold(body: Text('Home Body')),
        ),
      ),
    );

    expect(find.text('Home Body'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('tab 0 (home) is selected when location is /home',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(
          location: '/home',
          child: const SizedBox(),
        ),
      ),
    );

    final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar));
    expect(bottomNav.currentIndex, 0);
  });

  testWidgets('tab 2 (stock) is selected when location is /stock',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(
          location: '/stock',
          child: const SizedBox(),
        ),
      ),
    );

    final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar));
    expect(bottomNav.currentIndex, 2);
  });
}
```

- [ ] **Step 2: Jalankan test — harus FAIL**

Run: `flutter test test/widgets/main_shell_test.dart`
Expected: FAIL karena `MainShell` belum ada.

- [ ] **Step 3: Implementasi `MainShell`**

Create `lib/widgets/main_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/route_names.dart';
import 'modern_bottom_nav.dart';

/// Shell yang membungkus body page + bottom navigation bar.
///
/// Dipakai oleh `ShellRoute` di `app_router.dart` agar bottom nav persist
/// saat navigasi antar tab (Home, HRD, Stock, Transaction, Operational).
class MainShell extends StatelessWidget {
  /// URL location saat ini (untuk menentukan tab aktif).
  final String location;

  /// Body page yang dirender di atas bottom nav.
  final Widget child;

  const MainShell({
    super.key,
    required this.location,
    required this.child,
  });

  int _indexFromLocation(String loc) {
    if (loc.startsWith(RoutePaths.home)) return 0;
    if (loc.startsWith(RoutePaths.hrd)) return 1;
    if (loc.startsWith(RoutePaths.stock)) return 2;
    if (loc.startsWith(RoutePaths.transaction)) return 3;
    if (loc.startsWith(RoutePaths.operational)) return 4;
    return 0;
  }

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RoutePaths.home);
        break;
      case 1:
        context.go(RoutePaths.hrd);
        break;
      case 2:
        context.go(RoutePaths.stock);
        break;
      case 3:
        context.go(RoutePaths.transaction);
        break;
      case 4:
        context.go(RoutePaths.operational);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _indexFromLocation(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: ModernBottomNav(
        currentIndex: currentIndex,
        onTap: (i) => _onTabTapped(context, i),
      ),
    );
  }
}
```

- [ ] **Step 4: Update `ModernBottomNav` — buat tap handler fleksibel**

`ModernBottomNav` saat ini langsung memanggil `Navigator.pushReplacement` di internal. Ubah jadi murni presentation (delegate onTap ke parent). Edit `lib/widgets/modern_bottom_nav.dart`:

Hapus method `_handleNavigation` (line 21-56), hapus semua import page yang tidak lagi diperlukan:

```dart
import 'package:flutter/material.dart';
import '../models/presence_model.dart';

class ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<PresenceModel>? presences;

  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.presences,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurfaceVariant;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      selectedIconTheme: IconThemeData(color: selectedColor, size: 26),
      unselectedIconTheme: IconThemeData(color: unselectedColor, size: 24),
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.badge_outlined), activeIcon: Icon(Icons.badge), label: 'HRD'),
        BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Stock'),
        BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Transaction'),
        BottomNavigationBarItem(
            icon: Icon(Icons.engineering_outlined),
            activeIcon: Icon(Icons.engineering),
            label: 'Ops'),
      ],
      onTap: (index) => onTap(index),
    );
  }
}
```

> **Catatan:** field `presences` mungkin sudah tidak terpakai — cek dulu. Bila tidak ada pemanggil, hapus.

- [ ] **Step 5: Jalankan test — harus PASS**

Run: `flutter test test/widgets/main_shell_test.dart`
Expected: `All tests passed!`.

- [ ] **Step 6: Cek apakah ModernBottomNav dipakai di tempat lain**

Run: `grep -rn "ModernBottomNav" lib/`
Expected: muncul di `main_shell.dart` + beberapa page yang pakai langsung (home_page, dll). Page yang pakai langsung akan di-update di task migrasi.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/main_shell.dart lib/widgets/modern_bottom_nav.dart test/widgets/main_shell_test.dart
git commit -m "feat(router): add MainShell + decouple ModernBottomNav navigation

MainShell wraps body + bottom nav for use in ShellRoute. ModernBottomNav
no longer hardcodes Navigator.pushReplacement; navigation delegated to
parent via onTap callback."
```

---

## Task 4: Buat `app_router.dart` dengan Auth Redirect

**Files:**
- Create: `lib/router/app_router.dart`
- Create: `test/router/app_router_test.dart`

**Goal:** Definisikan `GoRouter` instance dengan semua route utama + redirect logic.

- [ ] **Step 1: Tulis test untuk redirect logic**

Create `test/router/app_router_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sagansa/providers/auth_provider.dart';
import 'package:sagansa/router/app_router.dart';

class _FakeAuth extends AuthProvider {
  _FakeAuth({required this.authenticated});
  final bool authenticated;

  @override
  bool get isAuthenticated => authenticated;
}

void main() {
  group('appRouter redirect', () {
    testWidgets('unauthenticated user hitting /home → redirect to /login',
        (tester) async {
      final router = buildRouter(_FakeAuth(authenticated: false));

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path,
          '/login');
    });

    testWidgets('authenticated user hitting /login → redirect to /home',
        (tester) async {
      final router = buildRouter(_FakeAuth(authenticated: true));

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path,
          '/home');
    });
  });
}
```

- [ ] **Step 2: Jalankan test — harus FAIL**

Run: `flutter test test/router/app_router_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementasi `app_router.dart`**

Create `lib/router/app_router.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/hrd_dashboard_page.dart';
import '../pages/stock_dashboard_page.dart';
import '../pages/transaction_dashboard_page.dart';
import '../pages/operational_dashboard_page.dart';
import '../pages/profile_page.dart';
import '../pages/printer_settings_page.dart';
import '../pages/loan_page.dart';
import '../pages/salary_page.dart';
import '../pages/leave_page.dart';
import '../pages/leave_form_page.dart';
import '../pages/hygiene_page.dart';
import '../pages/readiness_page.dart';
import '../pages/procurement_dashboard_page.dart';
import '../pages/procurement_detail_page.dart';
import '../pages/create_procurement_page.dart';
import '../pages/invoice_detail_page.dart';
import '../pages/asset_list_page.dart';
import '../pages/asset_from_product_page.dart';
import '../pages/closing_store_page.dart';
import '../pages/storage_stock_list_page.dart';
import '../pages/fuel_service_form_page.dart';
import '../pages/production_form_page.dart';
import '../providers/auth_provider.dart';
import '../widgets/main_shell.dart';
import 'route_names.dart';

/// Membangun `GoRouter` dengan auth redirect berbasis [AuthProvider].
///
/// Dipakai di `main.dart`:
/// ```dart
/// MaterialApp.router(routerConfig: buildRouter(authProvider))
/// ```
GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isOnLogin = state.matchedLocation == RoutePaths.login;

      if (!isAuthenticated && !isOnLogin) {
        return RoutePaths.login;
      }
      if (isAuthenticated && isOnLogin) {
        return RoutePaths.home;
      }
      return null;
    },
    routes: [
      // === Login (di luar shell) ===
      GoRoute(
        name: RouteNames.login,
        path: RoutePaths.login,
        builder: (_, __) => const LoginPage(),
      ),

      // === Main shell dengan bottom nav ===
      ShellRoute(
        builder: (_, __, child) => MainShell(
          location: GoRouterState.of(_).uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            name: RouteNames.home,
            path: RoutePaths.home,
            builder: (_, __) => const HomePage(),
          ),
          GoRoute(
            name: RouteNames.hrd,
            path: RoutePaths.hrd,
            builder: (_, __) => const HRDDashboardPage(),
          ),
          GoRoute(
            name: RouteNames.stock,
            path: RoutePaths.stock,
            builder: (_, __) => const StockDashboardPage(),
          ),
          GoRoute(
            name: RouteNames.transaction,
            path: RoutePaths.transaction,
            builder: (_, __) => const TransactionDashboardPage(),
          ),
          GoRoute(
            name: RouteNames.operational,
            path: RoutePaths.operational,
            builder: (_, __) => const OperationalDashboardPage(),
          ),
        ],
      ),

      // === Nested pages (di luar shell, full screen) ===
      GoRoute(
        name: RouteNames.profile,
        path: RoutePaths.profile,
        builder: (_, __) => const ProfilePage(),
      ),
      GoRoute(
        name: RouteNames.printerSettings,
        path: RoutePaths.printerSettings,
        builder: (_, __) => const PrinterSettingsPage(),
      ),
      GoRoute(
        name: RouteNames.loan,
        path: RoutePaths.loan,
        builder: (_, __) => const LoanPage(),
      ),
      GoRoute(
        name: RouteNames.salary,
        path: RoutePaths.salary,
        builder: (_, __) => const SalaryPage(),
      ),
      GoRoute(
        name: RouteNames.leave,
        path: RoutePaths.leave,
        builder: (_, __) => const LeavePage(),
      ),
      GoRoute(
        name: RouteNames.leaveNew,
        path: RoutePaths.leaveNew,
        builder: (_, __) => const LeaveFormPage(),
      ),
      GoRoute(
        name: RouteNames.hygiene,
        path: RoutePaths.hygiene,
        builder: (_, __) => const HygienePage(),
      ),
      GoRoute(
        name: RouteNames.readiness,
        path: RoutePaths.readiness,
        builder: (_, __) => const ReadinessPage(),
      ),

      // === Procurement ===
      GoRoute(
        name: RouteNames.procurement,
        path: RoutePaths.procurement,
        builder: (_, __) => const ProcurementDashboardPage(),
        routes: [
          GoRoute(
            name: RouteNames.procurementDetail,
            path: ':id',
            builder: (_, state) => ProcurementDetailPage(
              id: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            name: RouteNames.procurementNew,
            path: 'new',
            builder: (_, __) => const CreateProcurementPage(),
          ),
          GoRoute(
            name: RouteNames.invoiceDetail,
            path: 'invoices/:id',
            builder: (_, state) => InvoiceDetailPage(
              id: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),

      // === Assets ===
      GoRoute(
        name: RouteNames.assets,
        path: RoutePaths.assets,
        builder: (_, __) => const AssetListPage(),
        routes: [
          GoRoute(
            name: RouteNames.assetFromProduct,
            path: 'from-product',
            builder: (_, __) => const AssetFromProductPage(),
          ),
        ],
      ),

      // === Misc ===
      GoRoute(
        name: RouteNames.closingStore,
        path: RoutePaths.closingStore,
        builder: (_, __) => const ClosingStorePage(),
      ),
      GoRoute(
        name: RouteNames.storageStocks,
        path: RoutePaths.storageStocks,
        builder: (_, __) => const StorageStockListPage(),
      ),
      GoRoute(
        name: RouteNames.fuelServiceNew,
        path: RoutePaths.fuelServiceNew,
        builder: (_, __) => const FuelServiceFormPage(),
      ),
      GoRoute(
        name: RouteNames.productionNew,
        path: RoutePaths.productionNew,
        builder: (_, __) => const ProductionFormPage(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route tidak dikenal: ${state.uri}')),
    ),
  );
}
```

> **Catatan:** halaman detail dengan parameter (`ProcurementDetailPage(id: ...)`) mungkin perlu constructor baru yang menerima `id` — verify signature aktual page sebelum commit. Bila page pakai cara lain (mis. via service singleton), sesuaikan builder.

- [ ] **Step 4: Verifikasi compile**

Run: `flutter analyze lib/router/`
Expected: `No issues found!`. Bila ada error "page tidak punya constructor id", tandai dengan TODO & sementara pakai builder yang ignore param.

- [ ] **Step 5: Jalankan test redirect**

Run: `flutter test test/router/app_router_test.dart`
Expected: `All tests passed!`.

- [ ] **Step 6: Commit**

```bash
git add lib/router/app_router.dart test/router/app_router_test.dart
git commit -m "feat(router): add GoRouter with auth redirect + 20 routes

Routes: login, 5 main shell tabs, profile, printer, loan, salary,
leave (+new), hygiene, readiness, procurement (+detail/new/invoice),
assets (+from-product), closing-store, storage-stocks, fuel-service,
production. AuthProvider drives refreshListenable for auto-redirect
on login/logout."
```

---

## Task 5: Integrate `GoRouter` ke `main.dart`

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/providers/auth_provider.dart` (sudah `ChangeNotifier`, cukup verifikasi)

**Goal:** Ganti `MaterialApp` → `MaterialApp.router(routerConfig: buildRouter(...))`. Hapus `initialRoute` & `routes` lama.

- [ ] **Step 1: Edit `main.dart`**

Di `_MyAppState.build`, ganti `MaterialApp(...)` block:

**Sebelum:**
```dart
return AnnotatedRegion<SystemUiOverlayStyle>(
  value: overlayStyle,
  child: MaterialApp(
    restorationScopeId: 'sagansa',
    title: 'Sagansa',
    theme: themeData,
    darkTheme: ThemeProvider.darkTheme,
    themeMode: themeProvider.themeMode,
    initialRoute: widget.initialRoute,
    routes: {
      '/login': (context) => const LoginPage(),
      '/home': (context) => const HomePage(),
    },
    localizationsDelegates: const [...],
    supportedLocales: const [...],
    locale: const Locale('id'),
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: child!,
      );
    },
  ),
);
```

**Sesudah:**
```dart
return AnnotatedRegion<SystemUiOverlayStyle>(
  value: overlayStyle,
  child: MaterialApp.router(
    restorationScopeId: 'sagansa',
    title: 'Sagansa',
    theme: themeData,
    darkTheme: ThemeProvider.darkTheme,
    themeMode: themeProvider.themeMode,
    routerConfig: buildRouter(_authProvider),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      SfGlobalLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('id'),
      Locale('en'),
    ],
    locale: const Locale('id'),
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: child!,
      );
    },
  ),
);
```

Tambah import di atas `main.dart`:

```dart
import 'router/app_router.dart';
```

- [ ] **Step 2: Hapus logic `initialRoute` di `main()`**

Di fungsi `main()`, hapus blok pengecekan token + initialRoute (sekarang di-handle oleh router redirect):

**Sebelum:**
```dart
final prefs = await SharedPreferences.getInstance();
final String? token = prefs.getString('token');
final String initialRoute = (token != null && token.isNotEmpty) ? '/home' : '/login';
// ...
runApp(ErrorBoundaryWidget(child: MyApp(initialRoute: initialRoute)));
```

**Sesudah:**
```dart
runApp(const ErrorBoundaryWidget(child: MyApp()));
```

Hapus juga `final String initialRoute;` dari `MyApp` class — ganti jadi `const MyApp({super.key});`.

Hapus import `shared_preferences` di `main.dart` bila tidak lagi dipakai (verifikasi dengan grep).

- [ ] **Step 3: Verifikasi `AuthProvider` extends `ChangeNotifier`**

Run: `grep -n "class AuthProvider" lib/providers/auth_provider.dart`
Expected: `class AuthProvider with ChangeNotifier {` — sudah benar, `refreshListenable: authProvider` akan bekerja.

- [ ] **Step 4: Build & run di emulator**

Run: `flutter run`

**Expected behavior:**
- Cold start: langsung render `/login` atau `/home` tergantung token tersimpan.
- Login sukses → `AuthProvider.login()` call `notifyListeners()` → `refreshListenable` trigger router → auto-redirect ke `/home`.
- Logout → `AuthProvider.logout()` → auto-redirect ke `/login`.

- [ ] **Step 5: Smoke test komprehensif**

Di emulator:
- [ ] Login dengan kredensial valid → landasan di `/home`.
- [ ] Logout → redirect ke `/login`.
- [ ] Cold start dengan token tersimpan → langsung `/home`.
- [ ] Bottom nav tap → navigasi antar tab (Home/HRD/Stock/Transaction/Ops).
- [ ] Tap menu item yang navigasi ke detail page (mis. procurement detail) → render dengan benar.
- [ ] Back button → kembali ke page sebelumnya.

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart
git commit -m "refactor(main): switch MaterialApp to MaterialApp.router

GoRouter drives navigation. initialRoute removed (replaced by router
redirect). AuthProvider.refreshListenable ensures auto-redirect on
login/logout state change."
```

---

## Task 6: Migrasi Pemanggil `Navigator.push` Bertahap

**Files:**
- Modify: bertahap, lihat "Migration Queue" di bawah.

**Goal:** Ganti `Navigator.push(context, MaterialPageRoute(builder: ...))` ke `context.go()` / `context.push()`.

**Konversi:**
- `Navigator.pushReplacement` → `context.go()` (ganti halaman, no back).
- `Navigator.push` → `context.push()` (push ke stack, with back).
- `Navigator.pop` → `context.pop()`.

**Migration Queue (urut by prioritas & dampak):**

| Prioritas | File | Pattern |
|---|---|---|
| 1 | `lib/widgets/app_drawer.dart` (jika ada) | menu utama |
| 2 | `lib/pages/home_page.dart` | setelah Plan 3 selesai |
| 3 | `lib/pages/*_dashboard_page.dart` (5 file) | navigasi ke sub-page |
| 4 | `lib/pages/procurement_*.dart` | detail / new |
| 5 | `lib/pages/invoice_*.dart` | detail |
| 6 | `lib/pages/asset_*.dart` | detail / form |
| 7 | `lib/pages/closing_store_page.dart` | sub-page |
| 8 | `lib/pages/sales_*_page.dart` | sub-page |
| 9 | Sisanya | gradual |

- [ ] **Step 1: Migrasi satu file sebagai template**

Pilih file paling sederhana (mis. `lib/pages/leave_page.dart`). Untuk tiap `Navigator.push`:

**Sebelum:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const LeaveFormPage()),
);
```

**Sesudah:**
```dart
import 'package:go_router/go_router.dart';
import '../router/route_names.dart';

context.push(RoutePaths.leaveNew);
```

- [ ] **Step 2: Verifikasi leave_page.dart masih fungsi**

Run: `flutter run`
- Buka Leave page.
- Tap tombol "Ajukan Cuti" → harus navigasi ke LeaveFormPage.
- Back button → kembali ke Leave page.

- [ ] **Step 3: Commit per-file**

```bash
git add lib/pages/leave_page.dart
git commit -m "refactor(leave): migrate Navigator.push to go_router context.push"
```

- [ ] **Step 4: Ulangi untuk file berikutnya (1 commit per file)**

Untuk setiap file di Migration Queue:
1. Ganti semua `Navigator.push`/`pushReplacement` dengan `context.push`/`context.go`.
2. Tambah import `go_router` & `route_names`.
3. Build & quick smoke test.
4. Commit dengan pesan: `refactor(<domain>): migrate Navigator to go_router`.

- [ ] **Step 5: Verifikasi tidak ada Navigator.push tersisa di priority 1-7**

Run:
```bash
grep -rn "Navigator.push\|Navigator.pushReplacement" lib/pages/leave_*.dart lib/pages/procurement_*.dart lib/pages/invoice_*.dart lib/pages/asset_*.dart lib/pages/closing_store_page.dart lib/pages/home_page.dart lib/widgets/app_drawer.dart 2>/dev/null
```
Expected: mendekati 0 matches (atau 0 bila semua ter-migrasi).

- [ ] **Step 6: Catat jumlah Navigator.push akhir**

Run: `grep -rc "Navigator.push" lib/ | awk -F: '{sum+=$2} END {print sum}'`
Expected: turun dari baseline 130 ke sekitar 50-70 (target sprint ini: 20 route ter-migrasi).

---

## Task 7: Tambah Widget Test untuk Route Penting

**Files:**
- Create: `test/router/route_navigation_test.dart`

**Goal:** Test integrasi bahwa dari page A tap tombol X → landasan di page B.

- [ ] **Step 1: Tulis integration-style test**

Create `test/router/route_navigation_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sagansa/pages/home_page.dart';
import 'package:sagansa/pages/leave_page.dart';
import 'package:sagansa/pages/leave_form_page.dart';
import 'package:sagansa/providers/auth_provider.dart';
import 'package:sagansa/router/app_router.dart';

class _FakeAuth extends AuthProvider {
  _FakeAuth() : super() {
    // force authenticated via test setter.
    setAuthenticatedForTest(true);
  }
}

void main() {
  testWidgets('router renders HomePage when authenticated',
      (tester) async {
    final router = buildRouter(_FakeAuth());

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('can navigate from leave list to leave form via route',
      (tester) async {
    // Setup router dengan leave list sebagai entry.
    final router = buildRouter(_FakeAuth());
    router.go('/leave');

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(LeavePage), findsOneWidget);

    // Trigger navigation (simulasi tap button).
    router.push('/leave/new');
    await tester.pumpAndSettle();

    expect(find.byType(LeaveFormPage), findsOneWidget);
  });
}
```

- [ ] **Step 2: Tambah `setAuthenticatedForTest` di AuthProvider**

Edit `lib/providers/auth_provider.dart`. Tambah:

```dart
  @visibleForTesting
  void setAuthenticatedForTest(bool authenticated) {
    _token = authenticated ? 'test-token' : '';
    _userData = authenticated ? {'name': 'Test', 'roles': ['admin']} : null;
    notifyListeners();
  }
```

- [ ] **Step 3: Jalankan test — harus PASS**

Run: `flutter test test/router/route_navigation_test.dart`
Expected: `All tests passed!`.

- [ ] **Step 4: Commit**

```bash
git add test/router/route_navigation_test.dart lib/providers/auth_provider.dart
git commit -m "test(router): verify navigation between leave list & form

Added setAuthenticatedForTest helper for router integration tests."
```

---

## Task 8: Final Verification & Health Snapshot

**Files:**
- Create: `docs/health-reports/2026-07-20-sprint5-go-router-final.md`

- [ ] **Step 1: Jalankan health script**

Run: `./scripts/codebase_health.sh 2026-07-20-sprint5-go-router-final`

- [ ] **Step 2: Compare dengan baseline**

```bash
diff docs/health-reports/2026-07-20-baseline.md docs/health-reports/2026-07-20-sprint5-go-router-final.md
```

**Expected changes:**
- `Navigator.push` count: dari 130 → ~50-70 (target sprint ini).
- File test: naik ~3 (router + main_shell + navigation).
- LOC `lib/`: naik sedikit (`app_router.dart` + `route_names.dart` + `main_shell.dart`).

- [ ] **Step 3: Full analyze + test**

Run: `flutter analyze && flutter test`
Expected: 0 error, semua test lulus.

- [ ] **Step 4: Smoke test mendalam di emulator**

Run: `flutter run`

Test scenario:
- [ ] Cold start dengan token → langsung `/home`.
- [ ] Login → redirect `/home`.
- [ ] Logout → redirect `/login`.
- [ ] Bottom nav 5 tab semua bisa di-tap & switch.
- [ ] Navigation ke procurement detail dengan ID → render.
- [ ] Back button → kembali.
- [ ] Deep link via adb: `adb shell am start -W -a android.intent.action.VIEW -d "sagansa://procurement/1"` (bila URL scheme dikonfigurasi — skip bila belum, catat di docs).

- [ ] **Step 5: Commit health report**

```bash
git add docs/health-reports/2026-07-20-sprint5-go-router-final.md
git commit -m "docs(health): sprint 5 (go_router) final snapshot — Navigator.push 130→<70"
```

---

## Acceptance Criteria (dari PRD §4.3)

- [ ] `go_router: ^14.x` ada di `pubspec.yaml`.
- [ ] Minimal **10 route utama** ter-migrasi (target: 20).
- [ ] Auth redirect guard berfungsi (logout → `/login`, login sukses → `/home`).
- [ ] `MaterialApp.router` dipakai (bukan `MaterialApp` dengan `routes`).
- [ ] Bottom nav pakai `context.go()`.
- [ ] `test/router/app_router_test.dart` + `test/widgets/main_shell_test.dart` + `test/router/route_navigation_test.dart` lulus.
- [ ] `Navigator.push` count turun ≥ 50% dari baseline (130 → ≤ 70).

---

## Troubleshooting

### `ShellRoute` body tidak update saat navigasi

`ShellRoute` rebuild child saat location berubah. Pastikan `MainShell` menerima `location` yang re-evaluate. Bila `location` statis, bungkus dengan `Builder` dan pakai `GoRouterState.of(context).uri.path` di dalam builder.

### Page dengan parameter constructor tidak sederhana

Mis. `ProcurementDetailPage` butuh `id` + `storeId`. Bila terlalu kompleks, gunakan pattern "route as entry, fetch detail inside page":

```dart
GoRoute(
  path: '/procurement/:id',
  builder: (_, state) => ProcurementDetailPage(
    id: int.parse(state.pathParameters['id']!),
  ),
)
```

Dan di `ProcurementDetailPage`, fetch `storeId` via service di `initState` (bukan via constructor).

### Back button behavior aneh

`go_router` back menggunakan `context.pop()`. Pastikan tidak ada `WillPopScope` yang override. Bila perlu custom back, gunakan `PopScope` (Flutter 3.12+) dengan `canPop`.

### Redirect loop (infinite)

Terjadi bila: redirect dari `/login` ke `/home`, tapi user belum authenticated → redirect balik ke `/login`. Periksa logic:

```dart
if (!isAuthenticated && !isOnLogin) return '/login';   // belum auth + bukan di login → ke login
if (isAuthenticated && isOnLogin) return '/home';      // sudah auth + di login → ke home
return null;                                            // selain itu, no redirect
```

Pastikan kedua kondisi tidak konflik.

### Test `pumpAndSettle` timeout

Router redirect async bisa butuh beberapa frame. Pakai:

```dart
await tester.pump();
await tester.pump(const Duration(milliseconds: 100));
```

Alih-alih `pumpAndSettle()` yang bisa hang bila ada timer terus-menerus.

### `refreshListenable` tidak trigger redirect

Pastikan `AuthProvider.logout()` memanggil `notifyListeners()`:

```dart
Future<bool> logout() async {
  // ...
  notifyListeners();  // penting untuk trigger router redirect
  return true;
}
```

### ModernBottomNav `presences` field menyebabkan warning

Bila setelah hapus navigation logic field `presences` tidak terpakai, hapus juga. Atau biarkan dengan `// ignore: unused_field`.

---

## Out of Scope (untuk sprint ini)

- Konfigurasi deep link native (AndroidManifest intent-filter + iOS Associated Domains) — task terpisah yang butuh domain ownership.
- URL scheme custom (`sagansa://`) — butuh konfigurasi native.
- Web URL strategy (`PathUrlStrategy`) — bila build web target.
- Migrasi 130 Navigator.push sisanya — gradual, sprint berikutnya.
- Type-safe route via `go_router_builder` (codegen) — PR terpisah bila ingin compile-time route safety.
- Transisi animasi antar route (PageTransitionsTheme) — Sprint polish.
