# PRD: Standardisasi Arsitektur Provider — Sagansa Mobile

**Versi:** 1.1
**Tanggal:** 2026-07-20
**Status:** Final
**Scope:** `mobiles/sagansa/lib/`

> **Catatan revisi (v1.1):** Data konkret dari audit kode aktual (jumlah file, daftar provider/service, status `PresenceProvider` yang sudah ada, service non-HTTP yang keliru dicantumkan) telah dikoreksi. Tabel migrasi disempurnakan agar tiap baris akurat terhadap isi kode hari ini.

---

## 1. Ringkasan Eksekutif

Project Sagansa Mobile saat ini memiliki **3 pola arsitektur yang bertumpuk**: `controllers/`, `providers/`, dan service HTTP yang sebagian besar masih memakai raw `http` sambil menduplikasi logic auth (token & header). Sementara itu `ApiClient` (singleton) sudah tersedia namun hanya dipakai oleh 2 dari ~26 service HTTP. PRD ini mendefinisikan **standar arsitektur tunggal** berbasis `provider` package yang konsisten, scalable, dan mudah dipelihara.

**Target:** Satu pola arsitektur yang diikuti seluruh developer, tanpa ambiguitas — Widget → Provider → Service → ApiClient.

---

## 2. Analisis Kondisi Saat Ini

### 2.1 Struktur Direktori (audit aktual)

```
lib/
├── controllers/          ← 4 file: Home, Presence, Leave, Asset (menerima BuildContext)
├── models/               ← 25 model classes
├── pages/                ← 75 halaman (mayoritas StatefulWidget)
├── providers/            ← 5 file: Auth, Printer, Theme, Presence, FuelServicePayment
├── services/             ← 33 file service HTTP + subfolder fake_gps_detection/
├── theme/                ← AppColors, AppTypography, AppSpacing, AppAnimations
├── utils/                ← Constants, format utilities
└── widgets/              ← 38 reusable UI components
```

### 2.2 Masalah yang Ditemukan

| # | Masalah | Dampak |
|---|---------|--------|
| 1 | **3 pola arsitektur bertumpuk** (controllers + providers + services mandiri) | Ambiguitas pattern, developer bingung harus pakai yang mana |
| 2 | **Service menduplikasi logic auth & raw `http` calls** | 16 service punya method token sendiri (`_getToken` / `getToken` static/instance); 24 service pakai raw `http.*` |
| 3 | **`ApiClient` (singleton) sudah ada tapi nyaris tak dipakai** | Hanya 2 service (`supplier_service`, `utility_usage_service`) yang memakainya; error handling, auth headers, logging jadi tidak konsisten |
| 4 | **Controllers menerima `BuildContext` via konstruktor** | Tidak testable, tight coupling dengan UI |
| 5 | **Provider hanya dipakai untuk 5 fitur** | Banyak state shared yang seharusnya bisa dipindah dari `setState` lokal ke Provider |
| 6 | **Duplikasi `http` package** | Hampir semua service HTTP pakai raw `http`, bertentangan dgn `ApiClient` yang sudah ada |

### 2.3 Contoh Duplikasi (real, dari kode)

```dart
// Pola yang diulang di 16 service, dengan 3 signature berbeda:
Future<String?> _getToken() async {              // varian instance private
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}
static Future<String?> getToken() async { ... }  // varian static (presence_service)
Future<String?> getToken() async { ... }         // varian instance public (auth_service)

// ApiClient sudah merangkum hal yang sama, tapi hanya 2 service yang memakainya:
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<Map<String, String>> _headers() async { /* inject Bearer token */ }
  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async { ... }
  Future<dynamic> post(String path, {dynamic body}) async { ... }
  Future<dynamic> put(String path, {dynamic body}) async { ... }
  Future<dynamic> delete(String path) async { ... }
  Future<dynamic> multipart(...) async { ... }
}
```

---

## 3. Arsitektur Target

### 3.1 Layer Diagram

```
┌─────────────────────────────────────────────────────┐
│                    WIDGET LAYER                      │
│  StatefulWidget / StatelessWidget                   │
│  - Render UI only                                   │
│  - Consume Provider via context.watch / Consumer    │
│  - Delegate actions to Provider                     │
└──────────────────────┬──────────────────────────────┘
                       │ reads / watches
┌──────────────────────▼──────────────────────────────┐
│                  PROVIDER LAYER                      │
│  ChangeNotifier subclasses                          │
│  - Holds UI state (loading, error, data)            │
│  - Calls Service methods                            │
│  - Calls notifyListeners() on state change          │
│  - NO API calls directly                            │
└──────────────────────┬──────────────────────────────┘
                       │ calls
┌──────────────────────▼──────────────────────────────┐
│                  SERVICE LAYER                       │
│  Stateless classes (no ChangeNotifier)               │
│  - Business logic & API calls                       │
│  - Uses ApiClient for ALL HTTP requests             │
│  - Maps JSON → Model                                │
│  - Returns typed Model objects                      │
│  - Throws exceptions on error                       │
└──────────────────────┬──────────────────────────────┘
                       │ uses
┌──────────────────────▼──────────────────────────────┐
│                  API CLIENT LAYER                    │
│  ApiClient (singleton)                              │
│  - HTTP GET/POST/PUT/DELETE/Multipart               │
│  - Auth headers (auto-inject token)                 │
│  - Response parsing & error handling                │
│  - Logging                                         │
└─────────────────────────────────────────────────────┘
```

### 3.2 Yang Dihapus

| Direktori | Status | Alasan |
|-----------|--------|--------|
| `controllers/` | **HAPUS** | Fungsi pindah ke Provider. Controller + BuildContext = tidak testable |
| Duplikasi `_getToken()` di services | **HAPUS** | Gunakan `ApiClient` |
| Raw `http.get/post` di services | **HAPUS** | Gunakan `ApiClient.get/post` |

---

## 4. Convention & Standard

### 4.1 File Naming

| Tipe | Format | Contoh |
|------|--------|--------|
| Provider | `*_provider.dart` | `procurement_provider.dart` |
| Service | `*_service.dart` | `procurement_service.dart` |
| Model | `*_model.dart` | `procurement_model.dart` |
| API Client | `api_client.dart` | — |

### 4.2 Directory Structure (Target)

```
lib/
├── main.dart
├── models/
│   ├── procurement_model.dart
│   ├── sales_dashboard_model.dart
│   └── ...
├── providers/
│   ├── theme_provider.dart              (global — MultiProvider)
│   ├── printer_provider.dart            (global — MultiProvider)
│   ├── auth_provider.dart               (global — MultiProvider)
│   ├── fuel_service_payment_provider.dart (global — MultiProvider)
│   ├── presence_provider.dart           (perlu audit: page-level vs global)
│   ├── procurement_provider.dart        (page-level)
│   ├── sales_dashboard_provider.dart    (page-level)
│   └── ...
├── services/
│   ├── api_client.dart             (singleton)
│   ├── procurement_service.dart    (uses ApiClient)
│   ├── sales_dashboard_service.dart (uses ApiClient)
│   └── ...
├── theme/
├── utils/
└── widgets/
```

**`controllers/` dihapus.** Semua logic yang ada di controllers dipindah ke Provider atau Service.

### 4.3 Provider Patterns

#### A. Global Provider (MultiProvider)

Untuk state yang dipakai **di seluruh aplikasi**:

```dart
// main.dart — kondisi aktual hari ini (4 provider global)
MultiProvider(
  providers: [
    ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider),
    ChangeNotifierProvider<PrinterProvider>.value(value: _printerProvider),
    ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
    ChangeNotifierProvider<FuelServicePaymentProvider>.value(
        value: _fuelServicePaymentProvider),
  ],
  child: ...
)
```

**Saat ini sudah benar.** Tidak ada perubahan untuk provider global yang sudah ada. Provider feature baru yang hanya dibutuhkan di satu halaman tetap dibuat page-level (lihat Section B).

#### B. Page-Level Provider

Untuk state yang **hanya dipakai di 1 halaman/fitur**:

```dart
// procurement_page.dart
class ProcurementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProcurementProvider(),
      child: const _ProcurementView(),
    );
  }
}

class _ProcurementView extends StatelessWidget {
  const _ProcurementView();

  @override
  Widget build(BuildContext context) {
    // Pakai context.watch / Consumer di sini
  }
}
```

**Provider di-create di widget tree, bukan di `main()`.**

#### C. Provider Template

```dart
import 'package:flutter/foundation.dart';
import '../services/my_service.dart';
import '../models/my_model.dart';

enum MyFeatureState { idle, loading, success, error }

class MyFeatureProvider extends ChangeNotifier {
  final MyService _service = MyService();

  // State
  MyFeatureState _state = MyFeatureState.idle;
  List<MyModel> _items = [];
  String? _errorMessage;

  // Getters
  MyFeatureState get state => _state;
  List<MyModel> get items => _items;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == MyFeatureState.loading;
  bool get hasError => _state == MyFeatureState.error;

  // Actions
  Future<void> loadData() async {
    _state = MyFeatureState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _service.getItems();
      _state = MyFeatureState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state = MyFeatureState.error;
    }

    notifyListeners();
  }

  void reset() {
    _state = MyFeatureState.idle;
    _items = [];
    _errorMessage = null;
    notifyListeners();
  }
}
```

### 4.4 Service Template

**Semua service WAJIB pakai `ApiClient`, tidak boleh raw `http`.**

```dart
import '../models/my_model.dart';
import 'api_client.dart';

class MyService {
  final ApiClient _api = ApiClient();

  // GET list
  Future<List<MyModel>> getItems() async {
    final json = await _api.get('items');
    return (json as List).map((e) => MyModel.fromJson(e)).toList();
  }

  // GET detail
  Future<MyModel> getItem(String id) async {
    final json = await _api.get('items/$id');
    return MyModel.fromJson(json);
  }

  // POST create
  Future<MyModel> createItem(Map<String, dynamic> data) async {
    final json = await _api.post('items', body: data);
    return MyModel.fromJson(json);
  }

  // PUT update
  Future<MyModel> updateItem(String id, Map<String, dynamic> data) async {
    final json = await _api.put('items/$id', body: data);
    return MyModel.fromJson(json);
  }

  // DELETE
  Future<void> deleteItem(String id) async {
    await _api.delete('items/$id');
  }
}
```

### 4.5 Widget Conventions

#### Membaca Provider

```dart
// ✅ BENAR — Read once (tidak rebuild)
final provider = context.read<MyProvider>();

// ✅ BENAR — Watch (rebuild saat berubah)
final state = context.watch<MyProvider>().state;

// ✅ BENAR — Consumer untuk rebuild partial
Consumer<MyProvider>(
  builder: (context, provider, _) {
    return Text(provider.items.length.toString());
  },
)

// ❌ SALAH — Provider.of dengan listen: false di build()
final provider = Provider.of<MyProvider>(context, listen: false);
```

#### Memanggil Action

```dart
// ✅ BENAR — dari event handler
onPressed: () => context.read<MyProvider>().loadData(),

// ✅ BENAR — dari initState
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<MyProvider>().loadData();
  });
}

// ❌ SALAH — dari build()
Widget build(BuildContext context) {
  context.read<MyProvider>().loadData(); // ← jangan di build!
}
```

### 4.6 Error Handling Standard

#### Di Provider

```dart
Future<void> loadData() async {
  _state = MyFeatureState.loading;
  _errorMessage = null;
  notifyListeners();

  try {
    _items = await _service.getItems();
    _state = MyFeatureState.success;
  } catch (e) {
    _errorMessage = _parseError(e);
    _state = MyFeatureState.error;
  }

  notifyListeners();
}

String _parseError(dynamic e) {
  if (e is Exception) {
    return e.toString().replaceFirst('Exception: ', '');
  }
  return 'Terjadi kesalahan yang tidak diketahui';
}
```

#### Di Widget

```dart
Widget build(BuildContext context) {
  final provider = context.watch<MyProvider>();

  if (provider.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (provider.hasError) {
    return ErrorWidget(
      message: provider.errorMessage ?? 'Gagal memuat data',
      onRetry: () => context.read<MyProvider>().loadData(),
    );
  }

  return _buildContent(provider.items);
}
```

### 4.7 Provider Registration Priority

| Prioritas | Provider | Scope | Registrasi |
|-----------|----------|-------|------------|
| 1 | `ThemeProvider` | Global | `main.dart` MultiProvider |
| 2 | `PrinterProvider` | Global | `main.dart` MultiProvider |
| 3 | `AuthProvider` | Global | `main.dart` MultiProvider |
| 4 | `FuelServicePaymentProvider` | Global | `main.dart` MultiProvider |
| 5 | `PresenceProvider` & feature providers lain | Page-level | `ChangeNotifierProvider` di page widget |

**Aturan:** Jangan registrasi provider di `main.dart` kecuali memang dibutuhkan di **seluruh aplikasi**. `PresenceProvider` saat ini TIDAK terdaftar di `main.dart` — jika ternyata dibutuhkan lintas halaman, promosikan ke global setelah migrasi.

---

## 5. Migrasi Plan

> **Catatan akurasi:** Tabel berikut disusun dari audit kode aktual per 2026-07-20. Service non-HTTP yang sebelumnya keliru dimasukkan (`thermal_printer_service`, `network_service`, `image_service`, `asset_check_reminder_service`, `location_tracking_service`) dikeluarkan — mereka tidak memanggil backend REST dan tidak perlu `ApiClient`.

### Phase 1: Konsolidasi ApiClient (Minggu 1)

**Goal:** Semua service HTTP pakai `ApiClient`, hapus duplikasi logic token/header.

#### 1a. Sudah pakai `ApiClient` (tidak perlu diubah — 2 service)

| Service | Catatan |
|---------|---------|
| `supplier_service.dart` | Sudah pakai `ApiClient` ✓ |
| `utility_usage_service.dart` | Sudah pakai `ApiClient` ✓ |

#### 1b. Service HTTP yang perlu migrasi ke `ApiClient` (prioritas tinggi — 21 service)

| Service | Status Saat Ini | Action |
|---------|----------------|--------|
| `procurement_service.dart` | `_getToken()` + raw `http` | Migrate ke `ApiClient` |
| `sales_dashboard_service.dart` | `_getToken()` + `_headers()` + raw `http` | Migrate ke `ApiClient` |
| `presence_service.dart` | `static getToken()` + raw `http` (13 pemakaian) | Migrate ke `ApiClient` |
| `auth_service.dart` | `getToken()` (instance public) + raw `http` | Migrate ke `ApiClient` |
| `leave_service.dart` | inline `SharedPreferences.getString('token')` + raw `http` | Migrate ke `ApiClient` |
| `salary_service.dart` | inline `SharedPreferences.getString('token')` + raw `http` | Migrate ke `ApiClient` |
| `store_service.dart` | `_getToken()` + raw `http` | Migrate ke `ApiClient` |
| `image_upload_service.dart` | `_getToken()` + raw `http` | Migrate ke `ApiClient` |
| `sales_order_service.dart` | `_getToken()` + raw `http` | Migrate ke `ApiClient` |
| `sales_order_employee_service.dart` | `_getToken()` + raw `http` | Migrate ke `ApiClient` |
| `production_service.dart` | `_getToken()` + raw `http` | Migrate ke `ApiClient` |
| `recipe_service.dart` | `_getToken()` + raw `http` | Migrate ke `ApiClient` |
| `hygiene_service.dart` | `_getToken()` + raw `http` | Migrate ke `ApiClient` |
| `readiness_service.dart` | raw `http` | Migrate ke `ApiClient` |
| `asset_service.dart` | `_getToken()` + raw `http` | Migrate ke `ApiClient` |
| `asset_check_service.dart` | `_getToken()` + raw `http` | Migrate ke `ApiClient` |
| `asset_issue_service.dart` | `_getToken()` + raw `http` | Migrate ke `ApiClient` |
| `storage_stock_service.dart` | `_getToken()` + raw `http` | Migrate ke `ApiClient` |
| `transfer_stock_service.dart` | `_getToken()` + raw `http` | Migrate ke `ApiClient` |
| `closing_store_service.dart` | `_getToken()` + raw `http` | Migrate ke `ApiClient` |
| `inventory_anomaly_service.dart` | `_getToken()` + raw `http` | Migrate ke `ApiClient` |

#### 1c. Service HTTP yang masih perlu ditinjau (mungkin perlu migrasi, verifikasi pakai API internal)

| Service | Status | Action |
|---------|--------|--------|
| `user_service.dart` | raw `http` (6 pemakaian), tidak ada `_getToken` | Audit apakah endpoint butuh auth; jika ya → `ApiClient` |
| `version_service.dart` | raw `http` (1 pemakaian), endpoint publik `appVersion` | Kemungkinan **tidak** perlu auth — validasi, bisa dibiarkan raw atau pakai `ApiClient` tanpa token |
| `location_service.dart` | raw `http` (2 pemakaian), tidak ada token-method | Audit apakah endpoint internal; jika ya → `ApiClient` |
| `calendar_service.dart` | tidak ada `http.*` maupun token | Verifikasi: jika hanya helper tanggal → **bukan** service HTTP, keluarkan dari scope |
| `fake_gps_detection/services/*.dart` | perlu audit per file | Audit per sub-service; migrasi hanya yang memanggil backend |

#### 1d. Service **bukan HTTP** (di luar scope Phase 1 — jangan sentuh)

| Service | Fungsi sebenarnya |
|---------|-------------------|
| `thermal_printer_service.dart` | Render & cetak PDF/stiker via `printing` + `pdf` |
| `network_service.dart` | Cek konektivitas jaringan |
| `image_service.dart` | Resize/generate gambar, bukan HTTP |
| `asset_check_reminder_service.dart` | Handle FCM `asset_check_due`, notifikasi lokal |
| `location_tracking_service.dart` | Background service FCM/lokasi, bukan REST |

### Phase 2: Hapus Controllers (Minggu 2)

**Goal:** Pindah logic dari `controllers/` ke Provider atau Service. Semua controller saat ini menerima `BuildContext` via konstruktor (anti-pattern).

| Controller | Fungsi saat ini | Tujuan |
|------------|-----------------|--------|
| `home_controller.dart` | `loadUserInfo()`, `loadPresenceData()`, `checkActiveLeave()`, `logout()` + navigasi via `context` | Distribusikan ke `AuthProvider` (user info, logout) + `PresenceProvider` (presence data) |
| `presence_controller.dart` | `loadInitialData()`, `getCurrentLocation()`, `validateStoreLocation()`, `submitPresence()` + navigasi/snackbar via `context` | Pindah ke `PresenceProvider` (sudah ada — **perlu diperluas**) |
| `leave_controller.dart` | Logic leave + `ScaffoldMessenger.of(context)` | Pindah ke `LeaveProvider` (new) |
| `asset_controller.dart` | Logic asset (menyimpan `context` walau belum dipakai) | Pindah ke `AssetProvider` (new) |

> **Inkonsistensi v1.0 dikoreksi:** `PresenceProvider` **sudah ada** (`lib/providers/presence_provider.dart`, 56 baris) — saat ini minimalis (hanya `setTodayPresence` + `fetchPresences`). Yang dibutuhkan adalah **memperluas** untuk menyerap logic dari `presence_controller.dart`, bukan membuat baru.

### Phase 3: Buat/Perluas Provider (Minggu 2-3)

| Provider | Status | Scope | Service |
|----------|--------|-------|---------|
| `PresenceProvider` | **Sudah ada — perlu diperluas** | Tentukan global vs page-level setelah audit | `PresenceService` |
| `ProcurementProvider` | Belum ada (new) | Page-level | `ProcurementService` |
| `SalesDashboardProvider` | Belum ada (new) | Page-level | `SalesDashboardService` |
| `LeaveProvider` | Belum ada (new) | Page-level | `LeaveService` |
| `AssetProvider` | Belum ada (new) | Page-level | `AssetService` |

### Phase 4: Refactor Pages (Minggu 3-4)

Untuk setiap halaman yang masih memakai controller atau `setState` untuk state shared:
1. Buat/perluas Provider jika belum ada
2. Pindah state shared dari `_StatefulWidget` ke Provider
3. Ganti `notifyListeners()` di Provider, **pertahankan `setState()` untuk state UI lokal sederhana**
4. Pindahkan navigation/snackbar ke widget layer (bawa keluar dari controller)
5. Test fungsi yang sama

> **Prioritas halaman:** halaman yang saat ini memakai `*Controller` adalah kandidat migrasi pertama (home, presence, leave, asset).

---

## 6. Checklist Kode Baru

Sebelum merge kode baru, pastikan:

- [ ] Service HTTP menggunakan `ApiClient`, bukan raw `http`
- [ ] Tidak ada `_getToken()` / `getToken()` duplikasi di service
- [ ] State shared menggunakan Provider, bukan state lokal
- [ ] State page-local tetap pakai `setState()` (ini benar)
- [ ] Provider mengikuti template di Section 4.3C
- [ ] Error handling mengikuti convention di Section 4.6
- [ ] Widget mengikuti conventions di Section 4.5
- [ ] Tidak ada `BuildContext` di service atau model
- [ ] File naming mengikuti Section 4.1

---

## 7. Anti-Patterns (JANGAN LAKUKAN)

### 7.1 API Call Langsung dari Widget

```dart
// ❌ JANGAN
class _MyPageState extends State<MyPage> {
  void _load() async {
    final response = await http.get(Uri.parse('...'));
    // ...
  }
}
```

### 7.2 Service Tanpa ApiClient

```dart
// ❌ JANGAN
class MyService {
  Future<String?> _getToken() async { ... }  // duplikasi!
  
  Future getData() async {
    final token = await _getToken();
    final response = await http.get(..., headers: {'Authorization': 'Bearer $token'});
    // ...
  }
}
```

### 7.3 Controller dengan BuildContext

```dart
// ❌ JANGAN
class MyController {
  final BuildContext context;  // tight coupling!
  
  MyController(this.context);
  
  void doSomething() {
    Navigator.push(context, MaterialPageRoute(...));
  }
}
```

### 7.4 Provider yang Memanggil API Langsung

```dart
// ❌ JANGAN
class MyProvider extends ChangeNotifier {
  Future<void> loadData() async {
    final response = await http.get(Uri.parse('...'));  // langsung HTTP!
    // ...
  }
}
```

### 7.5 State yang Dikelola di 2 Tempat

```dart
// ❌ JANGAN — state ada di widget DAN provider
class _MyPageState extends State<MyPage> {
  List<Item> _items = [];  // ← duplikasi!
  
  @override
  Widget build(BuildContext context) {
    final items = context.watch<MyProvider>().items;  // ← juga di provider
    // ...
  }
}
```

---

## 8. Kapan Pakai Apa

| Scenario | Solusi |
|----------|--------|
| State dipakai **seluruh aplikasi** (auth, theme) | Global Provider di `main.dart` |
| State dipakai **1 halaman/fitur** | Page-level Provider |
| State sederhana, tidak perlu share | `setState()` di StatefulWidget |
| **API call, business logic** | Service (pakai `ApiClient`) |
| **Transform data, validasi** | Service |
| **Navigation, show dialog** | Widget (langsung) |
| **Caching, auto-dispose** | (Future) Pertimbangkan Riverpod |

---

## 9. Evaluasi Provider vs Riverpod vs BLoC

### Untuk Project Ini (Sagansa)

| Kriteria | Provider | Riverpod | BLoC |
|----------|----------|----------|------|
| **Sudah terpakai** | Ya | Tidak | Tidak |
| **Learning curve** | Rendah | Sedang | Tinggi |
| **Boilerplate** | Rendah | Sedang | Tinggi |
| **Compile-time safety** | Tidak | Ya | Tidak |
| **Auto-dispose** | Tidak | Ya | Tidak |
| **Dependency injection** | Manual | Built-in | Manual |
| **Cocok untuk** | CRUD enterprise | Large-scale app | Event-driven app |

**Rekomendasi:** Provider sudah cukup untuk project ini. Migrasi ke Riverpod hanya perlu dipertimbangkan jika:
- Tim bertambah > 5 developer
- App memiliki > 50 screen
- Perlu caching otomatis dan auto-dispose

---

## 10. Success Metrics

| Metric | Target | Cara Ukur |
|--------|--------|-----------|
| Service HTTP yang pakai `ApiClient` | 100% | `grep -L ApiClient lib/services/*.dart` (di luar daftar 1d) → 0 |
| Duplikasi `_getToken()` / `getToken()` di service | 0 | `grep -rE "_getToken\|getToken" lib/services/` → hanya `api_client.dart` |
| Raw `http.*` di service HTTP | 0 (di luar `api_client.dart`) | `grep -lE "http\.(get\|post\|put\|delete\|MultipartRequest\|Request)" lib/services/*.dart` → hanya `api_client.dart` |
| Direktori `controllers/` | Dihapus | Folder `lib/controllers/` kosong/tidak ada |
| Konsistensi Provider | 100% page baru mengikuti template | Code review checklist |
| Error handling konsisten | 100% memakai `_parseError` pattern | Code review |

---

## 11. Glossary

| Istilah | Definisi |
|---------|----------|
| **Provider** | `package:provider` — ChangeNotifier-based state management |
| **ApiClient** | Singleton HTTP client yang handle auth, headers, error parsing |
| **Service** | Stateless class yang handle business logic & API calls |
| **Global Provider** | Provider yang didaftarkan di `main.dart` (auth, theme, printer) |
| **Page-level Provider** | Provider yang didaftarkan di page widget tree |
| **StatefulWidget + setState** | Pattern untuk state lokal sederhana di 1 widget |
