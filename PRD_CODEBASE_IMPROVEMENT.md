# PRD: Codebase Improvement Master Plan — Sagansa Mobile

**Versi:** 1.0
**Tanggal:** 2026-07-20
**Status:** Final
**Scope:** `mobiles/sagansa/lib/`, `test/`, tooling (`pubspec.yaml`, `analysis_options.yaml`)

> **Konteks:** PRD ini adalah **master plan** yang mengonsolidasikan 14 area improvement hasil audit kode. Setiap area dirumuskan sebagai workstream yang dapat dijalankan independen, namun tetap terurut berdasarkan dependensi & dampak. PRD ini melengkapi (tidak menggantikan) `PRD_PROVIDER_STANDARD.md` — bila kedua dokumen bertentangan dalam detail teknis, `PRD_PROVIDER_STANDARD` lebih spesifik untuk arsitektur provider.

---

## Daftar Isi

1. [Ringkasan Eksekutif](#1-ringkasan-eksekutif)
2. [Analisis Kondisi Saat Ini](#2-analisis-kondisi-saat-ini)
3. [Arsitektur Target](#3-arsitektur-target)
4. [Workstream Detail (14 Area)](#4-workstream-detail-14-area)
5. [Roadmap Eksekusi](#5-roadmap-eksekusi)
6. [Anti-Patterns](#6-anti-patterns-jangan-lakukan)
7. [Success Metrics](#7-success-metrics)
8. [Risk Register](#8-risk-register)
9. [Glossary](#9-glossary)

---

## 1. Ringkasan Eksekutif

Sagansa Mobile adalah aplikasi Flutter dewasa: **208 file Dart, ~58.000 LOC, 75 halaman, 33 service, 25 model, 38 widget**. Kode sudah berfungsi dan dirilis (v1.2.8+15), namun pertumbuhan cepat menumpulkan beberapa "code smell" klasik:

- **`home_page.dart` adalah God Widget** — 1.985 LOC, 37 `setState`, 20 service di-inject, 30+ state field. Halaman lain juga gemuk: `delivery_page.dart` 3.937 LOC, `closing_store_page.dart` 1.518 LOC.
- **713 `setState`** tersebar di 75 halaman, sebagian besar menduplikasi logic yang seharusnya naik ke Provider.
- **Routing manual** — 130 `Navigator.push` hardcoded, hanya 2 route terdaftar di `MaterialApp.routes`. Tidak ada deep linking, back-stack testing menyulitkan.
- **`ApiClient` return `dynamic`** — type safety hilang; tiap service melakukan `data is List ? data : []` manual.
- **27 magic number status** (`status == '1'`, `'4'`, dst.) bertebaran di business logic.
- **Test coverage sangat tipis** — 13 file test, mayoritas widget procurement. **Zero service test** (kecuali `audit_service`).
- **72 `debugPrint` + 42 `developer.log`** — beberapa mem-print token & response body mentah (risk PII/keamanan).
- **`analysis_options.yaml`** sangat longgar — hanya pakai `flutter_lints` default.

**Target:** Selama **3 bulan (12 minggu)**, eksekusi 14 workstream untuk mencapai:

1. **Maintainability** — `home_page.dart` ≤ 500 LOC, state via Provider, ~50% reduksi `setState`.
2. **Type safety** — `ApiClient` generic, model dengan `freezed`/`json_serializable`.
3. **Testability** — minimal 60% coverage pada service + util pure-logic.
4. **Routing modern** — `go_router`, deep linking-ready.
5. **DX & quality gate** — `analysis_options` ketat, zero `print`, lint passing di CI.

**Prinsip eksekusi:**
- **Incremental & reversible** — tiap workstream berdiri sendiri, bisa di-merge terpisah.
- **Tidak ada "big bang rewrite"** — fitur baru jalan terus selama migrasi.
- **Test first** — workstream refactor diawali penambahan test karakteristik (characterization test) pada behavior yang akan diganggu.

---

## 2. Analisis Kondisi Saat Ini

### 2.1 Audit Konkret (per 2026-07-20)

| Metrik | Nilai | Ambang Sehat | Status |
|---|---|---|---|
| Total file `lib/*.dart` | 208 | — | — |
| Total LOC | 58.233 | — | — |
| Halaman (`lib/pages/`) | 75 | — | — |
| Service (`lib/services/*.dart`) | 33 | — | — |
| Model (`lib/models/*.dart`) | 25 | — | — |
| Widget reusable | 38 | — | — |
| Provider | 7 | — | — |
| File test | 13 | — | 🟡 kurang |
| Service test | 1 (`audit_service`) | 33 | 🔴 kritis |
| File > 500 LOC | 31 | < 20 | 🔴 |
| File > 300 LOC | 71 | < 50 | 🔴 |
| `setState` total | 713 | < 400 | 🟡 |
| `Navigator.push` hardcoded | 130 | 0 (semua via router) | 🔴 |
| Route terdaftar di `MaterialApp` | 2 | semua | 🔴 |
| Magic number `status == 'X'` | 27 | 0 | 🔴 |
| `debugPrint` + `developer.log` | 72 + 42 = 114 | < 30 (release-aware) | 🟡 |
| `print()` statements | 5 | 0 | 🟡 |
| Service pakai `ApiClient` | 26 / 33 | 33 | 🟡 |
| Model dengan `toJson` | ~15 / 25 | 25 | 🟡 |
| Endpoint string unik di service | 85 | — | — |
| TODO/FIXME marker | 2 | < 10 | 🟢 |

### 2.2 Top 10 File Terbesar (LOC)

| # | File | LOC | Catatan |
|---|---|---|---|
| 1 | `pages/delivery_page.dart` | 3.937 | Perlu dipecah per sub-tab |
| 2 | `pages/home_page.dart` | 1.985 | God Widget — prioritas #1 |
| 3 | `pages/closing_store_page.dart` | 1.518 | Multi-step form, bisa di-extract |
| 4 | `pages/supplier_form_page.dart` | 989 | Form panjang |
| 5 | `pages/sales_dashboard_page.dart` | 985 | Bisa pecah jadi card-card |
| 6 | `pages/utility_usage_form_page.dart` | 950 | — |
| 7 | `pages/create_payment_receipt_page.dart` | 913 | — |
| 8 | `pages/invoice_detail_page.dart` | 861 | — |
| 9 | `pages/create_sales_order_online_page.dart` | 832 | — |
| 10 | `pages/procurement_workflow_page.dart` | 794 | — |

### 2.3 Duplikasi & Anti-Pattern Utama

#### A. Duplikasi `ErrorWidget.builder` di `main.dart`
```dart
// lib/main.dart baris 150-157 — di-set 2x identik:
ErrorWidget.builder = (FlutterErrorDetails details) {
  return CustomErrorWidget(errorDetails: details);
};
ErrorWidget.builder = (FlutterErrorDetails details) {  // duplikat!
  return CustomErrorWidget(errorDetails: details);
};
```

#### B. `home_page.dart` menduplikasi logic `AuthProvider`
```dart
// auth_provider.dart:213 — loadUserInfo()
Future<void> loadUserInfo() async { ... }
// auth_provider.dart:232 — checkActiveLeave()
Future<void> checkActiveLeave() async { ... }

// home_page.dart juga punya logic yang sama di _initData()
// State di 2 tempat → bug saat sinkronisasi.
```

#### C. Service inline di dalam Widget
```dart
// Anti-pattern yang diulang di 64 page:
class SomePageState extends State<SomePage> {
  final SomeService _service = SomeService();   // dibuat per-instance
  // ...
}
```
Seharusnya via Provider (`ChangeNotifierProvider.value`) atau `get_it` untuk service stateless.

#### D. `ApiClient` kehilangan type
```dart
// api_client.dart:28 — return dynamic, kehilangan informasi tipe
Future<dynamic> get(String path, {Map<String, String>? queryParams}) async { ... }

// Setiap service menebak tipe manual:
final data = await _api.get('procurement/products');
final List<dynamic> productsJson = data is List ? data : [];  // fragile
return productsJson.map((e) => ProcurementProduct.fromJson(e)).toList();
```

#### E. Magic number status
```dart
// home_page.dart:297-303
for (final item in req.detailRequests) {
  if (item.status == '1') pending++;        // apa artinya '1'?
  else if (item.status == '4') approved++;  // apa artinya '4'?
}
// Padahal sudah ada AppConstants.leaveStatusPending=1 dst. untuk leave,
// tapi procurement belum punya enum setara.
```

#### F. Routing manual
```dart
// Di 130 tempat berbeda, pattern ini diulang:
Navigator.push(context, MaterialPageRoute(
  builder: (context) => const SomePage(),
));
// Tidak ada named route, tidak ada deep link, tidak bisa di-test secara terisolasi.
```

#### G. `closingStoreUrl` string matching yang rapuh
```dart
// constants.dart:115-133 — fragile:
if (baseUrl.contains('127.0.0.1:8001')) { ... }
else if (baseUrl.contains('localhost:8001')) { ... }
else if (baseUrl.contains('192.168.')) { ... }
else {
  if (host.startsWith('api.')) host = 'www.${host.substring(4)}';
}
```

---

## 3. Arsitektur Target

### 3.1 Layer Diagram (Target)

```
┌──────────────────────────────────────────────────────────┐
│                    ROUTING LAYER (NEW)                    │
│  go_router (GoRoute tree)                               │
│  - URL-based navigation & deep linking                  │
│  - ShellRoute untuk bottom nav                          │
│  - Redirect guard untuk auth                            │
└────────────────────────┬─────────────────────────────────┘
                         │ instantiates
┌────────────────────────▼─────────────────────────────────┐
│                    WIDGET LAYER                          │
│  StatelessWidget (preferred) / StatefulWidget           │
│  - Render UI only                                       │
│  - Consume Provider via context.watch / Consumer        │
│  - Page ≤ 500 LOC (split if exceeded)                   │
│  - NO business logic, NO API calls                      │
└────────────────────────┬─────────────────────────────────┘
                         │ watches / reads
┌────────────────────────▼─────────────────────────────────┐
│                  PROVIDER LAYER                          │
│  ChangeNotifier subclasses                              │
│  - Holds UI state (loading, error, data)                │
│  - Calls Service methods                                │
│  - notifyListeners() on state change                    │
│  - Global (MultiProvider) or Page-scoped                │
└────────────────────────┬─────────────────────────────────┘
                         │ calls
┌────────────────────────▼─────────────────────────────────┐
│                  SERVICE LAYER                           │
│  Stateless classes (no ChangeNotifier)                  │
│  - Business logic & API calls                           │
│  - Uses ApiClient (typed, generic)                      │
│  - Returns typed models, NOT Map<String, dynamic>       │
│  - Injectable (via Provider or get_it)                  │
└────────────────────────┬─────────────────────────────────┘
                         │ HTTP / multipart
┌────────────────────────▼─────────────────────────────────┐
│                  API CLIENT (TYPED)                      │
│  ApiClient singleton (generic)                          │
│  - Future<T> get<T>(path, {fromJson})                   │
│  - Inject Bearer token, handle 401, retry, etc.         │
│  - Redacted logging (no PII / token in body)            │
└────────────────────────┬─────────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────┐
│                    MODEL LAYER                           │
│  freezed + json_serializable (generated)                │
│  - Immutable, copyWith, equality, hashCode              │
│  - fromJson / toJson auto-generated                     │
└──────────────────────────────────────────────────────────┘
```

### 3.2 Yang Ditambahkan

| Komponen | Sebelum | Sesudah |
|---|---|---|
| Router | `Navigator.push` (130 tempat) | `go_router` dengan `GoRoute` tree |
| State di HomePage | 30+ field `setState` | `HomeDashboardProvider` |
| ApiClient return | `dynamic` | Generic `<T>` + `fromJson` |
| Model | Manual `fromJson`, sebagian tanpa `toJson` | `freezed` + `json_serializable` |
| Status | Magic string `'1'`, `'4'` | Enum dengan `fromApi` / `toApi` |
| Endpoint | Hardcoded string di service | Centralized `Endpoint` class |
| Logging | `debugPrint` + `developer.log` di 114 tempat | `AppLogger` (release-aware, redacted) |
| Lint | `flutter_lints` default | Custom rules + `dart fix` baseline |
| Test | 13 file | Target ≥ 60% coverage service + util |

### 3.3 Yang Dihapus

- Duplikasi `ErrorWidget.builder` di `main.dart`.
- Duplikasi `loadUserInfo` / `checkActiveLeave` antara `AuthProvider` & `HomePage`.
- Endpoint const di `ApiConstants` yang sudah tidak terpakai (konsolidasi ke satu sumber).
- `print()` statements (5 tempat) — ganti dengan `AppLogger`.

---

## 4. Workstream Detail (14 Area)

Setiap workstream berisi: **masalah → solusi → acceptance criteria → file terdampak → estimasi effort**.

### 4.1 [WS-01] Hapus Duplikasi `main.dart` & Quick Lint Wins

**Masalah:**
- `ErrorWidget.builder` di-set 2x identik di `main.dart:150-157`.
- `analysis_options.yaml` hanya pakai `flutter_lints` default; banyak rule bagus dimatikan.

**Solusi:**
1. Hapus duplikasi `ErrorWidget.builder`.
2. Update `analysis_options.yaml` dengan rule ketat (lihat §4.12 untuk detail).
3. Jalankan `dart fix --apply` untuk auto-clean baseline.
4. Tambahkan `// ignore_for_file:` hanya bila terdapat justifikasi tertulis.

**Acceptance Criteria:**
- [ ] Hanya ada **1** assignment `ErrorWidget.builder` di `main.dart`.
- [ ] `flutter analyze` menghasilkan **0 warning** & **0 info** (hanya error yang absah).
- [ ] `dart fix --apply` telah dijalankan; diff review-able.

**File terdampak:**
- `lib/main.dart`
- `analysis_options.yaml`

**Effort:** ½ hari

---

### 4.2 [WS-02] Refactor `home_page.dart` — God Widget Decomposition

**Masalah:**
`home_page.dart` (1.985 LOC) menanggung terlalu banyak tanggung jawab:
- 30+ state field (`pendingProcurementsCount`, `invoiceDraftCount`, `_hasReportedStorageToday`, dst.)
- 37 `setState`
- 20 service instance di-create
- Logic presence, leave, procurement, asset, hygiene, readiness, sales dashboard, anomaly, omzet — semua jadi satu.
- Duplikasi dengan `AuthProvider.loadUserInfo` & `checkActiveLeave`.

**Solusi:**

#### A. Buat `HomeDashboardProvider`
```dart
// lib/providers/home_dashboard_provider.dart
class HomeDashboardProvider extends ChangeNotifier {
  final ProcurementService _procurementService;
  final AssetService _assetService;
  final SalesDashboardService _salesDashboardService;
  final InventoryAnomalyService _anomalyService;
  final LeaveService _leaveService;
  // ... etc

  // Grouped state
  HomePresenceState presence = HomePresenceState.initial();
  HomeProcurementState procurement = HomeProcurementState.initial();
  HomeAssetState asset = HomeAssetState.initial();
  // ...
  bool isLoading = false;
  String? error;

  HomeDashboardProvider(this._procurementService, this._assetService, /* ... */);

  Future<void> loadAll({required UserRoles roles}) async {
    isLoading = true; error = null; notifyListeners();
    try {
      final results = await Future.wait([
        _loadPresence(roles),
        _loadProcurementSummary(),
        _loadAssetSummary(),
        // ...
      ]);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  Future<void> refreshSection(HomeSection section) async { /* partial refresh */ }
}
```

#### B. Pecah UI jadi Card Widget

```
lib/widgets/home/
├── home_presence_summary_card.dart
├── home_procurement_summary_card.dart
├── home_asset_summary_card.dart
├── home_hygiene_readiness_card.dart
├── home_sales_anomaly_card.dart
└── home_admin_overview_card.dart
```

Tiap card adalah `StatelessWidget` yang `context.watch<HomeDashboardProvider>()` dan hanya rebuild saat state-nya sendiri berubah (gunakan `Selector` untuk fine-grained).

#### C. `HomePage` jadi Shell Sederhana

```dart
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.initialIsAdmin});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeDashboardProvider(/* injected services */)
        ..loadAll(roles: context.read<AuthProvider>().roles),
      child: Scaffold(
        appBar: const HomeAppBar(),
        body: const _HomeBody(),
        bottomNavigationBar: const ModernBottomNav(currentIndex: 0),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<HomeDashboardProvider, bool>((p) => p.isLoading);
    if (isLoading) return const HomeSkeletonLoader();
    return ListView(
      children: const [
        HomePresenceSummaryCard(),
        HomeProcurementSummaryCard(),
        HomeAssetSummaryCard(),
        // ...
      ],
    );
  }
}
```

**Acceptance Criteria:**
- [ ] `home_page.dart` ≤ 500 LOC (target ideal: 200-300).
- [ ] Tidak ada lagi field `Service()` di dalam `HomePage` / `HomePageState`.
- [ ] Tidak ada lagi `setState` di `home_page.dart` (semua via Provider).
- [ ] `HomeDashboardProvider` punya unit test untuk `loadAll` (mock service).
- [ ] `loadUserInfo` & `checkActiveLeave` hanya ada di `AuthProvider`.
- [ ] Performance: frame time rebuild saat refresh 1 section ≤ 16ms ( Selector bekerja).

**File terdampak:**
- `lib/pages/home_page.dart` (rewrite total)
- `lib/providers/home_dashboard_provider.dart` (NEW)
- `lib/widgets/home/*.dart` (NEW, 6-8 file)
- `lib/main.dart` (registrasi provider)
- `test/providers/home_dashboard_provider_test.dart` (NEW)

**Effort:** 3-4 hari (1 developer), atau 2 hari dengan brainstorm + TDD.

---

### 4.3 [WS-03] Migrasi Routing ke `go_router`

**Masalah:**
- 130 `Navigator.push` hardcoded dengan `MaterialPageRoute(builder:)`.
- Hanya 2 route terdaftar (`/login`, `/home`).
- Tidak ada deep linking, tidak ada redirect guard berbasis auth state.
- Back-stack testing menyulitkan.

**Solusi:**

#### A. Tambah `go_router` dependency
```yaml
# pubspec.yaml
dependencies:
  go_router: ^14.0.0
```

#### B. Definisikan route tree
```dart
// lib/router/app_router.dart
final goRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    final isOnLogin = state.matchedLocation == '/login';
    if (!isAuthenticated && !isOnLogin) return '/login';
    if (isAuthenticated && isOnLogin) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomePage()),
        GoRoute(path: '/hrd', builder: (_, __) => const HRDDashboardPage()),
        GoRoute(path: '/stock', builder: (_, __) => const StockDashboardPage()),
        GoRoute(path: '/transaction', builder: (_, __) => const TransactionDashboardPage()),
        GoRoute(path: '/operational', builder: (_, __) => const OperationalDashboardPage()),
        // nested:
        GoRoute(
          path: '/procurement/:id',
          builder: (_, state) => ProcurementDetailPage(id: int.parse(state.pathParameters['id']!)),
        ),
        // dst.
      ],
    ),
  ],
);
```

#### C. Ganti `Navigator.push` bertahap
- Konversi per-feature (mis. semua route procurement dulu, lalu sales, dst.).
- `ModernBottomNav._handleNavigation` ganti `Navigator.pushReplacement` → `context.go('/...')`.
- Pertahankan `Navigator.push` sementara untuk page yang belum ter-migrasi (kompatibel).

**Acceptance Criteria:**
- [ ] `go_router: ^14.x` ada di `pubspec.yaml`.
- [ ] Minimal **10 route utama** ter-migrasi (login, home, 5 dashboard utama, detail page penting).
- [ ] Auth redirect guard berfungsi (logout → `/login`, login sukses → `/home`).
- [ ] Deep linking manual via `adb shell am start -W -a android.intent.action.VIEW -d "sagansa://procurement/123"` bekerja (after URI scheme config).
- [ ] Bottom nav pakai `context.go()`.

**File terdampak:**
- `pubspec.yaml`
- `lib/router/app_router.dart` (NEW)
- `lib/main.dart` (ganti `MaterialApp` → `MaterialApp.router`)
- `lib/widgets/modern_bottom_nav.dart` (ganti navigasi)
- 50+ file page (per-stage migration)

**Effort:** 1-2 minggu (gradual migration, bisa paralel dengan fitur lain).

---

### 4.4 [WS-04] Type-Safe `ApiClient` (Generic)

**Masalah:**
`ApiClient.get/post/put/delete` return `Future<dynamic>`, sehingga setiap caller menebak tipe secara manual (`data is List ? data : []`). Rawan runtime error & tidak ada autocomplete.

**Solusi:**

Tambahkan method generic tanpa menghapus method lama (backward-compatible):

```dart
class ApiClient {
  // ... method lama (deprecated, tandai dengan @Deprecated)

  /// GET yang langsung return List<T> hasil decode.
  Future<List<T>> getList<T>(
    String path, {
    required T Function(Map<String, dynamic> json) fromJson,
    Map<String, String>? queryParams,
  }) async {
    final data = await get(path, queryParams: queryParams);
    final list = data is List ? data : <dynamic>[];
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET yang return single object T.
  Future<T> getObject<T>(
    String path, {
    required T Function(Map<String, dynamic> json) fromJson,
    Map<String, String>? queryParams,
  }) async {
    final data = await get(path, queryParams: queryParams);
    return fromJson(data as Map<String, dynamic>);
  }

  /// POST yang return single object T (response umumnya { data: {...} }).
  Future<T> postObject<T>(
    String path, {
    required T Function(Map<String, dynamic> json) fromJson,
    dynamic body,
  }) async {
    final data = await post(path, body: body);
    return fromJson(data as Map<String, dynamic>);
  }

  // Pattern sama untuk put / delete.
}
```

**Migrasi service bertahap:**
```dart
// Sebelum:
Future<List<ProcurementProduct>> getProducts() async {
  final data = await _api.get('procurement/products');
  final List<dynamic> productsJson = data is List ? data : [];
  return productsJson.map((e) => ProcurementProduct.fromJson(e)).toList();
}

// Sesudah:
Future<List<ProcurementProduct>> getProducts() =>
  _api.getList('procurement/products', fromJson: ProcurementProduct.fromJson);
```

**Acceptance Criteria:**
- [ ] Method `getList<T>`, `getObject<T>`, `postObject<T>` tersedia.
- [ ] Method lama dianotasi `@Deprecated('Use typed variant getList/getObject/postObject')`.
- [ ] Minimal **10 service** sudah migrasi ke method generic (sebagai proof of pattern).
- [ ] Tidak ada lagi pattern `data is List ? data : []` di service yang sudah migrasi.

**File terdampak:**
- `lib/services/api_client.dart`
- 26 service file yang pakai `ApiClient` (bertahap)

**Effort:** 1 hari (implement core) + ongoing saat refactor service.

---

### 4.5 [WS-05] Enum untuk Status (Procurement & Lainnya)

**Masalah:**
27 magic number `status == 'X'` bertebaran, terutama di `home_page.dart`, `procurement_*`, `sales_order_*`. Tidak ada dokumentasi makna angka di kode.

**Solusi:**

Buat enum terpusat + extension method:

```dart
// lib/models/enums/procurement_item_status.dart
enum ProcurementItemStatus {
  pending,      // '1'
  partiallyApproved,
  approved,     // '4'
  rejected,
  unknown;

  static ProcurementItemStatus fromApi(String? code) {
    return switch (code) {
      '1' => ProcurementItemStatus.pending,
      '4' => ProcurementItemStatus.approved,
      // ... map lengkap berdasarkan dokumentasi backend
      _ => ProcurementItemStatus.unknown,
    };
  }

  String toApi() => switch (this) {
    ProcurementItemStatus.pending => '1',
    ProcurementItemStatus.approved => '4',
    // ...
    _ => '0',
  };

  bool get isPending => this == ProcurementItemStatus.pending;
  bool get isApproved => this == ProcurementItemStatus.approved;
}

// Extension di model:
extension ProcurementItemStatusX on RequestPurchaseItem {
  ProcurementItemStatus get statusEnum => ProcurementItemStatus.fromApi(status);
}
```

**Cakupan enum yang harus dibuat:**
| Enum | Lokasi saat ini | Jumlah magic number |
|---|---|---|
| `ProcurementItemStatus` | `home_page`, `procurement_*` | ~8 |
| `InvoiceStatus` | `home_page`, `invoice_*` | ~5 |
| `PaymentReceiptStatus` | `payment_receipt_*` | ~4 |
| `SalesOrderStatus` | `sales_order_*` | ~5 |
| `AssetCheckStatus` | `asset_*` | ~3 |

(Sudah ada `LeaveStatus` sebagai pattern via `AppConstants.leaveStatus*`; konsolidasikan juga ke enum.)

**Acceptance Criteria:**
- [ ] 5 enum di atas dibuat di `lib/models/enums/`.
- [ ] Setiap enum punya `fromApi` / `toApi` + unit test.
- [ ] **0** magic number `status == 'X'` tersisa di `lib/` (verifiable via grep).
- [ ] Behavior aplikasi tidak berubah (characterization test passing).

**File terdampak:**
- `lib/models/enums/*.dart` (NEW, 5 file)
- `lib/models/procurement_model.dart`, `invoice_*`, dll (tambah extension)
- `lib/pages/home_page.dart`, `lib/pages/procurement_*.dart`, dll
- `lib/utils/constants.dart` (konsolidasi)
- `test/models/enums/*_test.dart` (NEW)

**Effort:** 2 hari.

---

### 4.6 [WS-06] Service Injection Pattern (Hapus `Service()` di Widget)

**Masalah:**
64 dari 75 page membuat instance service inline (`final _service = SomeService();`) — tiap rebuild widget menyimpan reference, susah di-mock untuk test, tidak konsisten dengan layer arsitektur.

**Solusi:**

Pilih **satu** dari dua pendekatan (decided in brainstorm):

**Opsi A — Provider-based** (sesuai `PRD_PROVIDER_STANDARD`):
```dart
// Daftarkan service sebagai singleton provider
MultiProvider(providers: [
  Provider<ProcurementService>(create: (_) => ProcurementService()),
  Provider<AssetService>(create: (_) => AssetService()),
  // ...
])

// Di page:
final procService = context.read<ProcurementService>();
```

**Opsi B — `get_it` service locator** (lebih ringan untuk service stateless):
```dart
// lib/services/service_locator.dart
final getIt = GetIt.instance;
void setupServices() {
  getIt.registerLazySingleton(() => ProcurementService());
  getIt.registerLazySingleton(() => AssetService());
  // ...
}

// Di page:
final procService = getIt<ProcurementService>();
```

> **Rekomendasi:** Opsi A (konsisten dengan Provider yang sudah dipakai). Tapi `get_it` lebih cocok bila ingin benar-benar memisahkan service dari widget tree.

**Acceptance Criteria:**
- [ ] Decided approach terdokumentasi di ADR (Architecture Decision Record).
- [ ] Tidak ada lagi `final _xService = XService()` sebagai field non-final di `State` class.
- [ ] Minimal 10 page sudah pakai injection pattern.
- [ ] Paling tidak satu service bisa di-mock di unit test.

**File terdampak:**
- `lib/main.dart` (registrasi)
- 64 file page (bertahap)

**Effort:** ongoing (1-2 page per sprint).

---

### 4.7 [WS-07] Type-Safe Models dengan `freezed` + `json_serializable`

**Masalah:**
- 10 dari 25 model tidak punya `toJson` (lihat audit §2.1).
- Model manual → boilerplate `==`/`hashCode`/`copyWith` biasanya tidak ada atau salah.
- Maintenance tinggi saat field berubah.

**Solusi:**

#### A. Tambah dependency
```yaml
# pubspec.yaml
dependencies:
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

dev_dependencies:
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  build_runner: ^2.4.13
```

#### B. Konversi model bertahap (prioritas: model yang sering berubah / dipakai cross-page)

```dart
// lib/models/procurement_product.dart (sebelum: 80 LOC manual)
@freezed
class ProcurementProduct with _$ProcurementProduct {
  const factory ProcurementProduct({
    required int id,
    required String name,
    @JsonKey(name: 'unit_price') required int unitPrice,
    // ...
  }) = _ProcurementProduct;

  factory ProcurementProduct.fromJson(Map<String, dynamic> json) =>
      _$ProcurementProductFromJson(json);
}
```

#### C. Generate & test
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Migration order:**
1. Model yang paling sering diubah (procurement, sales_order).
2. Model yang punya nested complex (presence, asset).
3. Sisanya.

**Acceptance Criteria:**
- [ ] `freezed`, `json_serializable`, `build_runner` ada di `pubspec.yaml`.
- [ ] Minimal **10 model** ter-migrasi.
- [ ] Semua model punya `==`, `hashCode`, `copyWith`, `toJson`, `fromJson` (auto-generated).
- [ ] `*.g.dart`, `*.freezed.dart` di-exclude dari analyzer (sudah, tapi pastikan).
- [ ] Build runner sukses tanpa warning.

**File terdampak:**
- `pubspec.yaml`
- 25 file di `lib/models/`
- `analysis_options.yaml` (sudah exclude)

**Effort:** 3-4 hari (full migration). Bisa paralel per-domain.

---

### 4.8 [WS-08] Endpoint Centralization

**Masalah:**
- `constants.dart` definisikan ~50 const `ApiConstants.xxx` (full URL dengan baseUrl).
- Tapi service malah hardcode path relatif (`_api.get('procurement/requests')`).
- 85 endpoint string unik tersebar di 26 service.
- Dua sumber kebenaran → inkonsistensi saat endpoint berubah.

**Solusi:**

Pilih **satu** pendekatan:

**Opsi A — Endpoint class terpusat (rekomendasi):**
```dart
// lib/services/endpoints.dart
class Endpoints {
  // Auth
  static const login = 'login';
  static const logout = 'logout';

  // Procurement
  static const procurementProducts = 'procurement/products';
  static const procurementRequests = 'procurement/requests';
  static String procurementRequestDetail(int id) => 'procurement/requests/$id';
  static String procurementApproveItem(int id) => 'procurement/requests/items/$id/approve';
  // ...
}

// Pakai:
final data = await _api.get(Endpoints.procurementRequests);
final detail = await _api.get(Endpoints.procurementRequestDetail(id));
```

**Opsi B — Pertahankan const URL di `ApiConstants`, hapus hardcode di service.**

> **Rekomendasi:** Opsi A — path relatif lebih sesuai dengan design `ApiClient` yang sudah prepend `baseUrl`.

**Acceptance Criteria:**
- [ ] `lib/services/endpoints.dart` dibuat dengan **semua** 85 endpoint.
- [ ] Tidak ada lagi literal string path di `lib/services/*.dart` (kecuali yang di-generate dari method).
- [ ] Hapus const URL di `ApiConstants` yang sudah tidak terpakai.
- [ ] Update `PRD_PROVIDER_STANDARD` untuk referensi.

**File terdampak:**
- `lib/services/endpoints.dart` (NEW)
- 26 file service
- `lib/utils/constants.dart`

**Effort:** 1 hari.

---

### 4.9 [WS-09] Test Coverage: Service & Util

**Masalah:**
- 13 file test total; hanya 1 service test (`audit_service`).
- 0 test untuk util pure-logic (`format_utils`, `image_utils`, `text_formatters`).
- 0 test untuk `home_page.dart` (paling kompleks & rawan bug).
- Tidak ada CI gate untuk coverage.

**Solusi:**

#### A. Util pure-logic (prioritas tertinggi, ROI tinggi)
```dart
// test/utils/format_utils_test.dart
void main() {
  group('FormatUtils.currency', () {
    test('formats positive number correctly', () {
      expect(FormatUtils.currency(1500000), contains('1.500.000'));
    });
    test('handles zero', () { ... });
    test('handles negative', () { ... });
  });
}
```

#### B. Service test dengan HTTP mock
```yaml
# pubspec.yaml dev_dependencies
mocktail: ^1.0.4
http_mock_adapter: ^0.6.1
```

```dart
// test/services/procurement_service_test.dart
class MockApiClient extends Mock implements ApiClient {}
void main() {
  late MockApiClient mockApi;
  late ProcurementService service;

  setUp(() {
    mockApi = MockApiClient();
    service = ProcurementService.test(apiClient: mockApi);
  });

  test('getProducts returns parsed list on success', () async {
    when(() => mockApi.get('procurement/products'))
        .thenAnswer((_) async => [/* raw json */]);
    final result = await service.getProducts();
    expect(result, hasLength(2));
    expect(result.first.name, 'Beras 5kg');
  });

  test('getProducts throws on empty response', () async { ... });
}
```

> Catatan: service harus mendukung dependency injection di constructor (tambah `@visibleForTesting` parameter).

#### C. Widget test ringkas untuk HomePage
```dart
// test/pages/home_page_test.dart
testWidgets('shows presence card for staff role', (tester) async {
  final authProvider = AuthProvider.mocked(roles: ['staff']);
  await tester.pumpWidget(MaterialApp(
    home: ChangeNotifierProvider.value(
      value: authProvider,
      child: const HomePage(),
    ),
  ));
  expect(find.byType(HomePresenceSummaryCard), findsOneWidget);
});
```

**Coverage target:**
| Area | Target | Prioritas |
|---|---|---|
| `lib/utils/*.dart` | 80% | 1 |
| `lib/services/*.dart` (10 service prioritas) | 60% | 2 |
| `lib/providers/*.dart` | 70% | 2 |
| `lib/widgets/procurement_*` (lanjut yang ada) | 70% | 3 |
| `lib/pages/home_page.dart` | 50% (widget test ringkas) | 3 |

**Acceptance Criteria:**
- [ ] `mocktail`, `http_mock_adapter` di dev_dependencies.
- [ ] Service punya constructor test-friendly (`@visibleForTesting ApiClient? apiClient`).
- [ ] Coverage util ≥ 80%, service ≥ 60% (yang prioritas).
- [ ] Script `./scripts/run_tests.sh` menghasilkan coverage report (LCOV).
- [ ] CI gate (bila ada): coverage tidak boleh turun > 5% di PR.

**File terdampak:**
- `pubspec.yaml`
- 26 service file (tambah constructor test-friendly)
- `test/utils/*_test.dart` (NEW, ~7 file)
- `test/services/*_test.dart` (NEW, ~10 file)
- `test/providers/home_dashboard_provider_test.dart` (NEW)

**Effort:** 1-2 minggu (ongoing per sprint).

---

### 4.10 [WS-10] `AppLogger` — Logging Release-Aware

**Masalah:**
- 72 `debugPrint` + 42 `developer.log` tersebar.
- `ApiClient._handleResponse` (line 156) mem-print `response.body` mentah — bisa berisi PII/token.
- 5 `print()` yang pasti bocor di release build.
- Tidak ada level filter, tidak ada redaction.

**Solusi:**

#### A. Buat `AppLogger` helper
```dart
// lib/utils/app_logger.dart
import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message, {Object? error, StackTrace? stack}) {
    if (!kDebugMode) return;
    // Bisa ditambah Sentry / Crashlytics backend di sini nanti.
    if (error != null) {
      developer.log(message, error: error, stackTrace: stack);
    } else {
      debugPrint(message);
    }
  }

  static void info(String message) {
    if (!kDebugMode) return;
    debugPrint('[INFO] $message');
  }

  static void warning(String message, {Object? error}) {
    debugPrint('[WARN] $message');
    // Always log warnings, even in release (to Crashlytics bila setup)
  }

  static void error(String message, {Object? error, StackTrace? stack}) {
    developer.log(message, error: error, stackTrace: stack, level: 1000);
    // Always log errors (send to Crashlytics / Sentry in production)
  }

  /// Redact sensitive keys dari map sebelum log.
  static Map<String, dynamic> redact(Map<String, dynamic> data,
      {Set<String> sensitiveKeys = const {'token', 'password', 'access_token', 'pin'}}) {
    return data.map((k, v) => MapEntry(k, sensitiveKeys.contains(k.toLowerCase()) ? '***' : v));
  }
}
```

#### B. Ganti semua `debugPrint`/`print`/`developer.log`

```bash
# Quick audit:
grep -rn "debugPrint\|developer.log\|^\s*print(" lib/
# Ganti dengan AppLogger.xxx secara bertahap.
```

#### C. ApiClient: jangan log body mentah
```dart
// Sebelum (api_client.dart:156):
debugPrint('ApiClient Response (${response.statusCode}): ${response.body}');

// Sesudah:
final preview = response.body.length > 200
    ? '${response.body.substring(0, 200)}... (${response.body.length} bytes)'
    : response.body;
AppLogger.debug('ApiClient Response ${response.statusCode}: $preview');
```

**Acceptance Criteria:**
- [ ] `lib/utils/app_logger.dart` dibuat dengan API jelas.
- [ ] **0** `print()` di `lib/` (grep harus 0).
- [ ] `debugPrint` ≤ 30 (sisanya via `AppLogger`).
- [ ] `ApiClient` tidak lagi print `response.body` mentah (hanya preview, redacted).
- [ ] Logging otomatis no-op di release mode (kecuali warning/error).

**File terdampak:**
- `lib/utils/app_logger.dart` (NEW)
- `lib/services/api_client.dart`
- 50+ file yang punya `debugPrint`/`developer.log`

**Effort:** 1-2 hari.

---

### 4.11 [WS-11] Fix `closingStoreUrl` Logic

**Masalah:**
`constants.dart:115-133` pakai string matching rapuh:
```dart
if (baseUrl.contains('127.0.0.1:8001')) { ... }
else if (baseUrl.contains('localhost:8001')) { ... }
else if (baseUrl.contains('192.168.')) { ... }
else { if (host.startsWith('api.')) host = 'www.${host.substring(4)}'; }
```

Sulit dibaca, rawan typo, behavior edge case tidak jelas.

**Solusi:**

Gunakan `Uri.parse` + map environment eksplisit:

```dart
// lib/utils/constants.dart
static String get closingStoreUrl {
  final apiUri = Uri.parse(baseUrl);
  final adminUri = apiUri.replace(
    host: _resolveAdminHost(apiUri.host),
    port: _resolveAdminPort(apiUri),
    path: '/admin/transaction/closings/panel/closing-stores',
  );
  return adminUri.toString();
}

static String _resolveAdminHost(String apiHost) {
  if (apiHost.startsWith('api.')) return 'www.${apiHost.substring(4)}';
  return apiHost;  // localhost / 192.168.x.x tidak diubah
}

static int _resolveAdminPort(Uri apiUri) {
  // Admin web jalan di port 8000 untuk lokal dev.
  if (apiUri.host == '127.0.0.1' || apiUri.host == 'localhost') return 8000;
  if (apiUri.host.startsWith('192.168.')) return 8000;
  return apiUri.port == 80 || apiUri.port == 443 ? apiUri.port : 443;
}
```

**Acceptance Criteria:**
- [ ] Tidak ada lagi `.contains('127.0.0.1')` / `.contains('192.168.')` di `constants.dart`.
- [ ] Unit test untuk 4 skenario: production (api.sagansa.id), localhost, 192.168.x.x, edge case.
- [ ] URL yang dihasilkan sama dengan sebelumnya (regression-safe).

**File terdampak:**
- `lib/utils/constants.dart`
- `test/utils/closing_store_url_test.dart` (NEW)

**Effort:** ½ hari.

---

### 4.12 [WS-12] Tighten `analysis_options.yaml`

**Masalah:**
Hanya pakai `flutter_lints` default. Banyak rule bagus dimatikan.

**Solusi:**

Update `analysis_options.yaml`:

```yaml
analyzer:
  exclude:
    - build/**
    - .dart_tool/**
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    # Treat warning & info as error (fail CI):
    deprecated_member_use: warning
    missing_required_param: error
    missing_return: error
    todo: ignore
    import_of_legacy_library_into_null_safe: error

include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Style
    prefer_single_quotes: true
    prefer_const_constructors: true
    prefer_const_constructors_in_immutables: true
    prefer_const_declarations: true
    prefer_const_literals_to_create_immutables: true
    prefer_final_fields: true
    prefer_final_locals: true
    require_trailing_commas: true
    # Robustness
    avoid_print: true
    avoid_dynamic_calls: true
    avoid_type_to_string: true
    always_declare_return_types: true
    type_annotate_public_apis: true
    # Documentation
    public_member_api_docs: false  # terlalu noisy untuk project internal
    lines_longer_than_80_chars: false  # Flutter tree sering panjang
    # Imports
    always_use_package_imports: false
    prefer_relative_imports: true
    directives_ordering: true
    # Flutter-specific
    use_key_in_widget_constructors: true
    sized_box_for_whitespace: true
    use_build_context_synchronously: true
```

**Acceptance Criteria:**
- [ ] `analysis_options.yaml` update sesuai di atas.
- [ ] `flutter analyze` setelah `dart fix --apply` → 0 issues.
- [ ] `strict-casts`, `strict-inference` aktif.

**File terdampak:**
- `analysis_options.yaml`
- Banyak file (auto-fixed)

**Effort:** ½ hari + ongoing review.

---

### 4.13 [WS-13] Developer Documentation (`DEVELOPMENT.md`)

**Masalah:**
- `README.md` masih template default Flutter ("A new Flutter project").
- Tidak ada setup instruction, env vars (`API_URL`, `FALLBACK_API_URL`), cara build APK/IPA, troubleshooting.
- Info tersembunyi di `build_ipa_unsigned.sh`, `constants.dart`, `docs/app-store-*`.

**Solusi:**

Buat struktur dokumentasi:

```
README.md                           ← overview + link ke setup
docs/
├── DEVELOPMENT.md                  ← setup dev environment
├── ARCHITECTURE.md                 ← arsitektur (refer PRD ini & PROVIDER_STANDARD)
├── BUILD_RELEASE.md                ← build APK/IPA, signing, upload
├── ENVIRONMENT.md                  ← env vars & konfigurasi
└── CONTRIBUTING.md                 ← commit convention, PR process
```

**Isi minimum `DEVELOPMENT.md`:**
- Prasyarat (Flutter version, Dart SDK, Android SDK, Xcode).
- Setup: `flutter pub get`, `dart run build_runner build` (after WS-07).
- Environment: `--dart-define=API_URL=...`.
- Run: `flutter run --flavor dev --dart-define=API_URL=http://localhost:8001`.
- Test: `flutter test --coverage`.
- Code generation: `dart run build_runner watch -d`.

**Acceptance Criteria:**
- [ ] `README.md` punya overview project asli (bukan template).
- [ ] `docs/DEVELOPMENT.md` punya instruksi setup lengkap.
- [ ] `docs/ENVIRONMENT.md` mendokumentasikan semua `--dart-define`.
- [ ] `docs/BUILD_RELEASE.md` mengonsolidasikan info dari `build_ipa_unsigned.sh`, `docs/app-store-*`, `docs/play-console-*`.

**File terdampak:**
- `README.md` (rewrite)
- `docs/DEVELOPMENT.md` (NEW)
- `docs/ENVIRONMENT.md` (NEW)
- `docs/BUILD_RELEASE.md` (NEW)
- `docs/CONTRIBUTING.md` (NEW)

**Effort:** 1 hari.

---

### 4.14 [WS-14] Dependency Audit & Pinning

**Masalah:**
- Beberapa komentar `pubspec.yaml` "Atau versi terbaru" menandakan versi tidak dipertimbangkan sengaja.
- Firebase: `firebase_core ^3.6.0` vs `firebase_messaging ^15.1.3` — cek kompatibilitas dengan deployment target iOS.
- Tidak ada Dependabot/Renovate untuk otomatisasi PR update.

**Solusi:**

#### A. Audit dependency
```bash
flutter pub outdated
flutter pub deps --no-dev
```

#### B. Tambah Renovate atau Dependabot config
```json
// .github/renovate.json (atau .github/dependabot.yml)
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended", "schedule:weekly"],
  "packageRules": [
    {
      "groupName": "flutter",
      "matchPackagePatterns": ["^flutter", "^sdk.flutter"]
    },
    {
      "groupName": "firebase",
      "matchPackagePatterns": ["^firebase"]
    }
  ]
}
```

#### C. Perbaiki komentar `pubspec.yaml`
Hapus komentar "Atau versi terbaru" — versi harus explicit & di-pin di `pubspec.lock`.

**Acceptance Criteria:**
- [ ] `flutter pub outdated` audit selesai; minor update dijalankan.
- [ ] Konflik dependency (jika ada) ter-dokumentasi.
- [ ] Renovate/Dependabot aktif (bila project di GitHub).
- [ ] Komentar "Atau versi terbaru" dihapus dari `pubspec.yaml`.

**File terdampak:**
- `pubspec.yaml`
- `.github/renovate.json` (NEW) atau `.github/dependabot.yml`

**Effort:** ½ hari.

---

## 5. Roadmap Eksekusi

### 5.1 Timeline 12 Minggu

```
Minggu 1-2:  FOUNDATION (Quick wins + cleanup)
             ├─ WS-01  Duplikasi main.dart + lint baseline
             ├─ WS-12  analysis_options ketat
             ├─ WS-11  Fix closingStoreUrl
             ├─ WS-14  Dependency audit
             └─ WS-13  DEVELOPMENT.md (minimal setup docs)

Minggu 3-4:  API LAYER (type safety foundation)
             ├─ WS-04  ApiClient generic
             ├─ WS-08  Endpoint centralization
             └─ WS-05  Enum status (mulai, minimal 3 enum)

Minggu 5-7:  ARCHITECTURE (refactor besar)
             ├─ WS-02  HomePage decomposition (PRIORITAS UTAMA)
             ├─ WS-06  Service injection pattern
             └─ WS-10  AppLogger

Minggu 8-9:  ROUTING & MODELS
             ├─ WS-03  go_router (gradual migration)
             ├─ WS-07  freezed + json_serializable (mulai 10 model)
             └─ WS-05  Enum status (lanjutan + cleanup)

Minggu 10-12: QUALITY (test & polish)
              ├─ WS-09  Test coverage (util + 10 service)
              ├─ WS-07  freezed (sisanya)
              └─ Final cleanup & retrospective
```

### 5.2 Urutan Berdasarkan Dampak × Effort

| Prioritas | Workstream | Dampak | Effort | Ratio |
|---|---|---|---|---|
| ★★★ | WS-02 HomePage refactor | Sangat Tinggi | Tinggi | Menentukan kelanjutan project |
| ★★★ | WS-04 ApiClient generic | Tinggi | Rendah | Foundation untuk semua service |
| ★★★ | WS-12 Lint ketat | Sedang | Rendah | Quality gate murah |
| ★★☆ | WS-03 go_router | Tinggi | Sedang | Deep linking + testability |
| ★★☆ | WS-05 Enum status | Sedang | Rendah | Bug prevention cepat |
| ★★☆ | WS-09 Test coverage | Tinggi | Tinggi | Confidence untuk refactor |
| ★★☆ | WS-10 AppLogger | Sedang | Rendah | Keamanan + debuggability |
| ★☆☆ | WS-08 Endpoint central | Sedang | Rendah | Konsistensi |
| ★☆☆ | WS-07 freezed models | Sedang | Sedang | Boilerplate eliminasi |
| ★☆☆ | WS-06 Service injection | Sedang | Ongoing | Testability |
| ☆☆☆ | WS-01 main.dart cleanup | Rendah | Sangat Rendah | Quick win |
| ☆☆☆ | WS-11 closingStoreUrl | Rendah | Sangat Rendah | Quick win |
| ☆☆☆ | WS-13 Dev docs | Sedang | Rendah | Onboarding |
| ☆☆☆ | WS-14 Dependency audit | Rendah | Sangat Rendah | Maintenance |

### 5.3 urutan Eksekusi yang Direkomendasikan (Quick Start)

Untuk mendapat momentum cepat tanpa mengganggu fitur:

```
Sprint 1 (1 minggu):
  WS-01 + WS-12 + WS-11 + WS-14    ← cepat, menang, motivasi tim

Sprint 2 (1 minggu):
  WS-04 + WS-08 + WS-10            ← foundation service layer

Sprint 3-4 (2 minggu):
  WS-02 (HomePage refactor)        ← THE big one, fokus penuh
  + WS-05 enum (bertahap)

Sprint 5+ :
  Sisanya gradual
```

### 5.4 Tracking Progress

Buat issue/epic per workstream. Setiap workstream punya:
- **PR draft** dengan checklist dari acceptance criteria.
- **Branch terpisah** (`refactor/ws-02-home-page`, dll).
- **Reviewer assignment** (minimal 1, idealnya 2 untuk WS-02, WS-03, WS-07).
- **Demo** di sprint review.

---

## 6. Anti-Patterns (JANGAN LAKUKAN)

### 6.1 Big Bang Refactor

```dart
// ❌ JANGAN: hapus semua setState di 75 page sekaligus dalam 1 PR
// ✅ LAKUKAN: pecah per-workstream, 1 PR per domain (procurement dulu, sales kemudian)
```

### 6.2 Refactor Tanpa Test Karakteristik

```dart
// ❌ JANGAN: langsung refactor home_page.dart tanpa test apapun
// ✅ LAKUKAN: tulis characterization test dulu (golden test UI minimal,
//             snapshot state) sebelum ubah logic
```

### 6.3 Migrasi Partial Tanpa Backward Compatibility

```dart
// ❌ JANGAN: hapus method ApiClient.get lama saat masih banyak yang pakai
// ✅ LAKUKAN: tambah method baru (generic), tandai lama @Deprecated,
//             migrasi bertahap, hapus yang lama setelah 0 usage
```

### 6.4 Magic String di New Code

```dart
// ❌ JANGAN:
if (status == '4') { ... }  // developer baru tidak tahu apa ini

// ✅ LAKUKAN:
if (statusEnum.isApproved) { ... }
```

### 6.5 `print()` di Production Code

```dart
// ❌ JANGAN:
print('debug: $userData');           // bocor di release
debugPrint(response.body);           // bisa berisi token/PII

// ✅ LAKUKAN:
AppLogger.debug('Loaded user data');
AppLogger.debug('Response preview: ${AppLogger.redact(json)}');
```

### 6.6 Service Locator yang Tidak Ter-test

```dart
// ❌ JANGAN: getIt.registerSingleton(() => Service()) tanpa cara override
// ✅ LAKUKAN: allow override for testing
getIt.registerLazySingleton<Service>(() => Impl());
// Di test:
getIt.unregister<Service>(); getIt.registerLazySingleton<Service>(() => MockService());
```

### 6.7 `setState` untuk State yang Dibagi Multiple Widget

```dart
// ❌ JANGAN: HomePage punya field `_pendingCount` yang dibaca 5 card anak
// ✅ LAKUKAN: naikkan ke Provider, card pakai context.select untuk performant rebuild
```

---

## 7. Success Metrics

### 7.1 KPI Kuantitatif (Target 3 Bulan)

| Metrik | Baseline (2026-07-20) | Target (Q4 2026) | Cara Ukur |
|---|---|---|---|
| File > 500 LOC | 31 | < 15 | `find lib -name "*.dart" -exec wc -l {} +` |
| File > 300 LOC | 71 | < 40 | sama |
| `home_page.dart` LOC | 1.985 | < 500 | `wc -l` |
| `setState` total | 713 | < 400 | `grep -rc setState` |
| `Navigator.push` | 130 | < 50 | `grep -rc Navigator.push` |
| Route terdaftar (`go_router`) | 2 | ≥ 20 | manual count |
| Magic number status | 27 | 0 | `grep -rE "status == '[0-9]'"` |
| `print()` statements | 5 | 0 | `grep -rn "print("` |
| `debugPrint` total | 72 | < 30 | `grep -rc debugPrint` |
| File test | 13 | ≥ 40 | `find test -name "*.dart"` |
| Service test | 1 | ≥ 10 | sama |
| Model dengan `toJson` | ~15 | 25 (100%) | grep |
| Service pakai `ApiClient` typed | 0 | ≥ 15 | grep `getList<T>\|getObject<T>` |
| `flutter analyze` issues | TBD | 0 | command output |
| Coverage `lib/utils/` | ~10% | ≥ 80% | `flutter test --coverage` |
| Coverage `lib/services/` (top 10) | ~5% | ≥ 60% | sama |

### 7.2 KPI Kualitatif

- **Developer onboarding time** baru: dari X hari → ≤ 2 hari (dengan `DEVELOPMENT.md`).
- **Bug regression rate**: turun (substraktif dengan test coverage).
- **Confidence refactor**: developer tidak takut ubah kode karena ada test + lint.
- **PR review time**: turun karena perubahan lebih terlokalisasi.

### 7.3 Health Check Script

Buat `scripts/codebase_health.sh` yang mengeluarkan semua metrik di atas, dijalankan tiap sprint:

```bash
#!/usr/bin/env bash
# scripts/codebase_health.sh
echo "=== Sagansa Codebase Health Report ==="
echo "Date: $(date)"
echo ""
echo "Total Dart files: $(find lib -name '*.dart' | wc -l)"
echo "Total LOC: $(find lib -name '*.dart' -exec cat {} + | wc -l)"
echo "Files > 500 LOC: $(find lib -name '*.dart' -exec wc -l {} + | awk '$1>500 && $2!="total"' | wc -l)"
echo "setState count: $(grep -rc 'setState' lib/ | awk -F: '{sum+=$2} END {print sum}')"
echo "Navigator.push count: $(grep -rc 'Navigator.push' lib/ | awk -F: '{sum+=$2} END {print sum}')"
echo "Magic number status: $(grep -rE "status == '[0-9]'" lib/ | wc -l)"
echo "print() statements: $(grep -rn '^\s*print(' lib/ | wc -l)"
echo "debugPrint count: $(grep -rc 'debugPrint' lib/ | awk -F: '{sum+=$2} END {print sum}')"
echo "Test files: $(find test -name '*.dart' | wc -l)"
echo ""
echo "=== Analyze ==="
flutter analyze 2>&1 | tail -5
```

Jalankan tiap akhir sprint, commit hasilnya ke `docs/health-reports/` untuk tracking temporal.

---

## 8. Risk Register

| ID | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| R1 | WS-02 (HomePage refactor) pecah fitur existing | Tinggi | Tinggi | Characterization test dulu; pecah PR per-card; regression manual test tiap merge |
| R2 | WS-03 (go_router) bermasalah dengan back navigation yang sudah ada | Sedang | Sedang | Migrasi per-fitur; pertahankan Navigator.push untuk yang belum; deep testing bottom nav |
| R3 | WS-07 (freezed) conflict dengan model manual existing | Sedang | Sedang | Migrasi model satu per satu; jangan campur freezed + manual di class yang sama |
| R4 | Performance regression dari Provider terlalu banyak notifyListeners() | Sedang | Sedang | Gunakan `Selector` / `context.select` (fine-grained); profile dengan DevTools |
| R5 | Tim tidak konsisten mengikuti standar baru | Tinggi | Sedang | CI gate `flutter analyze`; PR template dengan checklist; code review ketat di awal |
| R6 | Build runner melambat saat `freezed` model banyak | Rendah | Rendah | Exclude yang tidak perlu; pakai `watch -d` saat dev |
| R7 | `go_router` breaking change di versi major baru | Sedang | Rendah | Pin minor version; review changelog saat upgrade |
| R8 | Test HTTP mock tidak sinkron dengan API backend aktual | Sedang | Sedang | Contract test dengan backend; review saat API berubah |
| R9 | Refactor session terlalu panjang → conflict dengan feature work | Tinggi | Sedang | Branch short-lived; rebase rutin; koordinasi dengan roadmap fitur |
| R10 | `firebase_core ^3.6.0` vs `firebase_messaging ^15.1.3` incompatible dengan iOS deployment target | Rendah | Tinggi | Cek sebelum upgrade; uji build iOS tiap PR yang sentuh firebase |

---

## 9. Glossary

| Istilah | Definisi |
|---|---|
| **ADR** | Architecture Decision Record — dokumen ringkas yang mencatat keputusan arsitektur & rasionalnya |
| **Anti-pattern** | Pola kode yang terlihat solutif tetapi sebetulnya menimbulkan masalah |
| **`ApiClient`** | Singleton di `lib/services/api_client.dart` yang membungkus semua HTTP call ke backend |
| **`AppLogger`** | Helper logging yang release-aware (no-op di release) — diusulkan di WS-10 |
| **Characterization test** | Test yang men-dokumentasikan behavior kode **saat ini** (bahkan yang buggy) sebelum refactor, untuk memastikan refactor tidak mengubah output |
| **CI gate** | Ambang batas di CI yang menyebabkan build gagal (mis: coverage turun, lint error) |
| **`freezed`** | Package code generation untuk model Dart immutable, auto-generate `==`/`hashCode`/`copyWith` |
| **God Widget** | Widget yang terlalu besar & menanggung terlalu banyak tanggung jawab (contoh: `home_page.dart`) |
| **`go_router`** | Package routing de facto Flutter tim, mendukung deep linking, redirect, nested route |
| **Lint rule** | Aturan static analysis yang membatasi pola kode tertentu |
| **Magic number** | Literal angka/string di kode yang maknanya tidak self-documenting (contoh: `status == '4'`) |
| **Provider** | Package state management yang dipakai project ini (`ChangeNotifier` + `MultiProvider`) |
| **Selector** | Widget provider untuk rebuild hanya saat sebagian state berubah (fine-grained) |
| **Service locator** | Pattern dengan `get_it` untuk resolve dependency tanpa constructor injection |
| **Strict mode** | Konfigurasi analyzer `strict-casts`, `strict-inference`, `strict-raw-types` yang mempersempit lubang type |
| **Workstream (WS)** | Satu unit pekerjaan di PRD ini, dapat dieksekusi independen |

---

## 10. Appendix

### A. Referensi

- `PRD_PROVIDER_STANDARD.md` — Standar arsitektur provider yang lebih detail.
- `docs/UI_STANDARDS.md` — Standar UI/widget.
- `docs/app-store-*.md`, `docs/play-console-*.md` — Build & release.
- `pubspec.yaml`, `analysis_options.yaml` — Konfigurasi project.

### B. Audit Script untuk Health Check

Lihat §7.3 — buat `scripts/codebase_health.sh` di Sprint 1.

### C. PR Template yang Disarankan

```markdown
## Workstream: WS-XX — [Nama]

### Checklist
- [ ] Acceptance criteria terpenuhi (lihat PRD §4.X)
- [ ] `flutter analyze` → 0 issues
- [ ] `flutter test` → 0 failure
- [ ] Tidak ada `print()` baru ditambahkan
- [ ] Tidak ada magic number baru (`status == 'X'`)
- [ ] File yang diubah tidak melebihi 500 LOC (atau pecah)

### Test plan
- [ ] Manual smoke test fitur terdampak
- [ ] Regression test area terkait

### Health metric changes
- `setState` count: before=X → after=Y
- LOC of changed file: before=X → after=Y
```

---

**Akhir dokumen.**
