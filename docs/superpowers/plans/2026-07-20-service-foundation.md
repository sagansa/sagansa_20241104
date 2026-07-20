# Service Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eksekusi 4 workstream fondasi service layer (WS-04, WS-05, WS-08, WS-10) dari `PRD_CODEBASE_IMPROVEMENT.md`: type-safe `ApiClient` (generic), centralization endpoint ke class `Endpoints`, enum untuk status procurement/invoice, dan `AppLogger` release-aware.

**Architecture:** Empat komponen yang saling melengkapi: (1) `AppLogger` dulu sebagai fondasi (dipakai WS-10 dan WS-04), (2) `Endpoints` class terpusat (WS-08), (3) `ApiClient` generic typed-method (WS-04), (4) Enum status + migration magic number (WS-05). Setiap task lulus `flutter analyze` + `flutter test` sebelum lanjut.

**Tech Stack:** Flutter SDK, `provider ^6.1.2`, `http ^1.2.2`, `flutter_test`. Tidak ada dependency baru yang ditambahkan.

**Spec:** `PRD_CODEBASE_IMPROVEMENT.md` §4.4 (WS-04), §4.5 (WS-05), §4.8 (WS-08), §4.10 (WS-10).

**Direktori kerja:** `/Users/dityo/Codings/sagansa/mobiles/sagansa/` (semua path di bawah relatif ke sini).

---

## Aturan Umum

1. **Satu task = satu commit.** Pesan commit pakai conventional commits (`feat:`, `refactor:`, `chore:`).
2. **Test first (TDD).** Untuk enum & `AppLogger`: tulis test dulu yang merah, lalu implementasi.
3. **Backward compatible.** Method baru ditambahkan; method lama dianotasi `@Deprecated` tapi tidak dihapus di plan ini.
4. **Behavior tidak boleh berubah.** Setiap task diakhiri smoke test.
5. **Jangan sentuh service non-HTTP** (`thermal_printer_service`, `network_service`, `image_service`).

---

## File Structure

### Create (NEW)
- `lib/utils/app_logger.dart` — helper logging release-aware (Task 1-2)
- `lib/services/endpoints.dart` — class terpusat berisi semua endpoint path (Task 3)
- `lib/models/enums/procurement_item_status.dart` — enum + extension (Task 5)
- `lib/models/enums/invoice_status.dart` — enum + extension (Task 5)
- `test/utils/app_logger_test.dart`
- `test/services/endpoints_test.dart`
- `test/models/enums/procurement_item_status_test.dart`
- `test/models/enums/invoice_status_test.dart`
- `test/services/api_client_test.dart`

### Modify
- `lib/services/api_client.dart` — tambah typed generic methods, ganti logging ke `AppLogger` (Task 4, 6)
- `lib/models/procurement_model.dart` — pakai enum di helper (Task 7)
- `lib/pages/procurement_detail_page.dart`, `procurement_dashboard_page.dart`, `home_page.dart`, `create_invoice_page.dart`, `calendar_page.dart`, `daily_salary_list_page.dart` — replace magic number (Task 7)
- `lib/widgets/procurement_pipeline_card.dart`, `procurement_graph_view.dart` — replace magic number (Task 7)
- `lib/services/fake_gps_detection/services/audit_service.dart` — ganti `print()` ke `AppLogger` (Task 2)

---

## Task 1: Buat `AppLogger` Helper (TDD)

**Files:**
- Create: `lib/utils/app_logger.dart`
- Create: `test/utils/app_logger_test.dart`

**Goal:** Punya helper logging tunggal yang (a) no-op di release mode untuk level debug/info, (b) selalu log untuk warning/error (siap dikaitkan ke Crashlytics nanti), (c) ada method `redact` untuk sensor field sensitif.

- [ ] **Step 1: Tulis failing test**

Create `test/utils/app_logger_test.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/utils/app_logger.dart';

void main() {
  group('AppLogger.redact', () {
    test('redacts default sensitive keys', () {
      final input = {
        'name': 'sagansa',
        'token': 'abc.def.ghi',
        'password': 'rahasia',
        'access_token': 'xyz',
        'email': 'user@sagansa.id',
      };
      final redacted = AppLogger.redact(input);
      expect(redacted['name'], 'sagansa');           // tidak di-redact
      expect(redacted['token'], '***');
      expect(redacted['password'], '***');
      expect(redacted['access_token'], '***');
      expect(redacted['email'], 'user@sagansa.id');  // tidak di-redact
    });

    test('redacts case-insensitively', () {
      final input = {'Token': 'abc', 'PASSWORD': 'xyz'};
      final redacted = AppLogger.redact(input);
      expect(redacted['Token'], '***');
      expect(redacted['PASSWORD'], '***');
    });

    test('preserves non-sensitive keys', () {
      final input = {'id': 1, 'name': 'X', 'roles': ['admin']};
      final redacted = AppLogger.redact(input);
      expect(redacted, equals(input));
    });

    test('supports custom sensitive keys', () {
      final input = {'pin': '1234', 'cvv': '999'};
      final redacted = AppLogger.redact(input,
          sensitiveKeys: {'pin', 'cvv'});
      expect(redacted['pin'], '***');
      expect(redacted['cvv'], '***');
    });

    test('handles nested map shallowly (does NOT recurse)', () {
      final input = {
        'user': {'token': 'abc', 'name': 'X'}
      };
      final redacted = AppLogger.redact(input);
      // Behavior: redaction is shallow — nested 'token' tetap terlihat.
      // (Documented limitation; for deep redaction use jsonEncode + regex.)
      expect((redacted['user'] as Map)['token'], 'abc');
    });
  });

  group('AppLogger methods do not throw', () {
    test('debug executes without exception', () {
      // Tidak bisa assert output (karena kDebugMode true saat test),
      // tapi pastikan tidak throw.
      expect(() => AppLogger.debug('test message'), returnsNormally);
      expect(() => AppLogger.debug('test', error: Exception('e')), returnsNormally);
    });

    test('info executes without exception', () {
      expect(() => AppLogger.info('test'), returnsNormally);
    });

    test('warning executes without exception', () {
      expect(() => AppLogger.warning('test'), returnsNormally);
      expect(() => AppLogger.warning('test', error: Exception('e')), returnsNormally);
    });

    test('error executes without exception', () {
      expect(
        () => AppLogger.error('test', error: Exception('e'), stack: StackTrace.current),
        returnsNormally,
      );
    });
  });
}
```

- [ ] **Step 2: Jalankan test — harus FAIL**

Run: `flutter test test/utils/app_logger_test.dart`
Expected: FAIL `Target of URI doesn't exist: 'package:sagansa/utils/app_logger.dart'` atau `AppLogger not defined`.

- [ ] **Step 3: Implementasi `AppLogger`**

Create `lib/utils/app_logger.dart`:

```dart
import 'dart:developer' as developer;

/// Helper logging terpusat yang release-aware.
///
/// - Level `debug` & `info`: no-op di release build (`kReleaseMode`).
/// - Level `warning` & `error`: selalu log (siap di-foward ke Crashlytics /
///   Sentry saat setup di masa depan).
///
/// **Penggunaan:**
/// ```dart
/// AppLogger.debug('User logged in: $userId');
/// AppLogger.error('Failed to fetch', error: e, stack: stack);
/// AppLogger.debug('Response: ${AppLogger.redact(json)}');
/// ```
class AppLogger {
  AppLogger._();

  /// Sensitive keys yang di-redact secara default oleh [redact].
  static const Set<String> defaultSensitiveKeys = {
    'token',
    'access_token',
    'password',
    'pin',
    'secret',
    'api_key',
    'apikey',
    'authorization',
  };

  /// Log level debug. No-op di release build.
  static void debug(String message, {Object? error, StackTrace? stack}) {
    if (kReleaseMode) return;
    if (error != null) {
      developer.log(message, error: error, stackTrace: stack, name: 'sagansa.debug');
    } else {
      developer.log(message, name: 'sagansa.debug');
    }
  }

  /// Log level info. No-op di release build.
  static void info(String message) {
    if (kReleaseMode) return;
    developer.log(message, name: 'sagansa.info');
  }

  /// Log level warning. Selalu aktif (juga di release).
  static void warning(String message, {Object? error}) {
    developer.log(
      message,
      error: error,
      name: 'sagansa.warning',
      level: 900,
    );
  }

  /// Log level error. Selalu aktif (juga di release).
  /// Wajib menyertakan [error] & [stack] untuk debugging yang baik.
  static void error(String message, {Object? error, StackTrace? stack}) {
    developer.log(
      message,
      error: error,
      stackTrace: stack,
      name: 'sagansa.error',
      level: 1000,
    );
  }

  /// Redact nilai key sensitif dari [data] sebelum di-log.
  ///
  /// Redaction bersifat **shallow** (hanya level pertama). Bila [data] punya
  /// nested map, field sensitif di dalamnya tidak akan ter-redact. Untuk
  /// redaction recursive, encode ke JSON lalu gunakan regex.
  ///
  /// [sensitiveKeys] case-insensitive (di-lowercase saat match).
  static Map<String, dynamic> redact(
    Map<String, dynamic> data, {
    Set<String> sensitiveKeys = defaultSensitiveKeys,
  }) {
    final lowered = sensitiveKeys.map((k) => k.toLowerCase()).toSet();
    return data.map((key, value) {
      if (lowered.contains(key.toLowerCase())) {
        return MapEntry(key, '***');
      }
      return MapEntry(key, value);
    });
  }

  /// Preview string dengan batas panjang — untuk log response body tanpa bocor.
  static String preview(String text, {int maxLength = 200}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}... (${text.length} bytes total)';
  }
}
```

**Catatan:** import `kReleaseMode` butuh `package:flutter/foundation.dart`. Tambahkan di atas file:

```dart
import 'package:flutter/foundation.dart' show kReleaseMode;
```

- [ ] **Step 4: Jalankan test — harus PASS**

Run: `flutter test test/utils/app_logger_test.dart`
Expected: `+10` atau `All tests passed!`

- [ ] **Step 5: Verifikasi analyze bersih**

Run: `flutter analyze lib/utils/app_logger.dart test/utils/app_logger_test.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/utils/app_logger.dart test/utils/app_logger_test.dart
git commit -m "feat(logger): add AppLogger release-aware helper

Centralized logging with redact() for sensitive fields and preview()
for truncating long output. debug/info no-op in release; warning/error
always logged (Crashlytics-ready)."
```

---

## Task 2: Ganti `print()` di `audit_service.dart` ke `AppLogger`

**Files:**
- Modify: `lib/services/fake_gps_detection/services/audit_service.dart`

**Goal:** Hapus 5 `print()` statements yang bocor di release build, ganti dengan `AppLogger`.

- [ ] **Step 1: Lihat semua print() saat ini**

Run: `grep -n "print(" lib/services/fake_gps_detection/services/audit_service.dart`
Expected: 5 baris (line 54, 58, 165, 182, 203).

- [ ] **Step 2: Tambah import `AppLogger`**

Edit `lib/services/fake_gps_detection/services/audit_service.dart`. Di bagian import (atas file), tambahkan:

```dart
import '../../utils/app_logger.dart';
```

(adjust path relatif tergantung struktur folder — `audit_service.dart` ada di `lib/services/fake_gps_detection/services/`, jadi naik 2 level ke `lib/utils/`).

- [ ] **Step 3: Ganti print() satu per satu**

Ganti:

```dart
print('Detection logged: ${log.id} - Valid: ${result.isValid}');
```

dengan:

```dart
AppLogger.debug('Detection logged: ${log.id} - Valid: ${result.isValid}');
```

Ganti:

```dart
print('Failed to log detection: $e');
```

dengan:

```dart
AppLogger.warning('Failed to log detection', error: e);
```

Ganti (line 165):

```dart
print('Failed to cleanup old logs: $e');
```

dengan:

```dart
AppLogger.warning('Failed to cleanup old logs', error: e);
```

Ganti (line 182):

```dart
print('Failed to sync logs: $e');
```

dengan:

```dart
AppLogger.warning('Failed to sync logs', error: e);
```

Ganti (line 203):

```dart
print('Synced ${logIds.length} detection logs to server');
```

dengan:

```dart
AppLogger.info('Synced ${logIds.length} detection logs to server');
```

- [ ] **Step 4: Verifikasi tidak ada print() tersisa**

Run: `grep -n "print(" lib/services/fake_gps_detection/services/audit_service.dart`
Expected: no output (zero matches).

- [ ] **Step 5: Jalankan test existing yang menyentuh file ini**

Run: `flutter test test/services/fake_gps_detection/audit_service_test.dart`
Expected: lulus (tidak ada regression).

- [ ] **Step 6: Commit**

```bash
git add lib/services/fake_gps_detection/services/audit_service.dart
git commit -m "refactor(audit_service): replace print() with AppLogger

5 print() statements were leaking to release build. Now debug/info
no-op in release; warnings always logged."
```

---

## Task 3: Buat Class `Endpoints` Terpusat

**Files:**
- Create: `lib/services/endpoints.dart`
- Create: `test/services/endpoints_test.dart`

**Goal:** Centralisasi 85+ endpoint string yang tersebar di 26 service ke satu class. Dipakai oleh Task 4 (ApiClient tidak hardcode path).

- [ ] **Step 1: Buat `Endpoints` class dengan semua endpoint dari audit**

Create `lib/services/endpoints.dart`:

```dart
/// Semua endpoint API Sagansa, terpusat di satu tempat.
///
/// **Penggunaan:**
/// ```dart
/// final data = await _api.get(Endpoints.procurementRequests);
/// final detail = await _api.get(Endpoints.procurementRequestDetail(id));
/// ```
///
/// Konvensi:
/// - Static const untuk path tetap.
/// - Static method untuk path dengan parameter (mengembalikan String).
/// - Naming: camelCase, grouped by domain via komentar.
class Endpoints {
  Endpoints._();

  // === Auth ===
  static const String login = 'login';
  static const String logout = 'logout';
  static const String profile = 'profile';

  // === Admin ===
  static const String adminProfile = 'admin/profile';
  static String adminProfileDetail(int id) => 'admin/profile/$id';
  static const String adminLeaves = 'admin/leaves';

  // === Users & Roles ===
  static const String users = 'users';

  // === Presence ===
  static const String userPresence = 'user-presence';
  static const String presencesToday = 'presences/today';
  static const String presencesMonthly = 'presences/monthly';
  static const String presencesHistory = 'presences/history';
  static const String checkIn = 'check-in';
  static const String checkOut = 'check-out';

  // === Leaves ===
  static const String leaves = 'leaves';

  // === Salaries ===
  static const String salaries = 'salaries';
  static String salaryDetail(int id) => 'salaries/$id';
  static const String salaryEmployees = 'salaries/employees';

  // === Daily Salaries ===
  static const String dailySalaries = 'daily-salaries';
  static const String dailySalariesEmployees = 'daily-salaries/employees';
  static const String dailySalariesBulkUpdateStatus =
      'daily-salaries/bulk-update-status';

  // === Stores ===
  static const String stores = 'stores';
  static const String shiftStores = 'shift-stores';

  // === Calendar ===
  static const String calendar = 'calendar';

  // === Location & Device Tokens ===
  static const String locationPing = 'location';
  static const String deviceTokens = 'device-tokens';

  // === Storage Stocks ===
  static const String storageStocksTodayStatus = 'storage-stocks/today-status';
  static const String storageStocksMonitoring = 'storage-stocks/monitoring';
  static const String storageStocksProducts = 'storage-stocks/products';
  static String storageStockDetail(int id) => 'storage-stocks/$id';
  static const String storageStockCreate = 'storage-stocks';

  // === Transfer Stocks ===
  static String transferStockDetail(int id) => 'transfer-stocks/$id';
  static const String transferStockProducts = 'transfer-stocks/products';
  static const String transferStockCreate = 'transfer-stocks';

  // === Closing Stores ===
  static const String closingStores = 'closing-stores';
  static String closingStoreDetail(int id) => 'closing-stores/$id';
  static const String closingStoresActiveDraft = 'closing-stores/active-draft';
  static const String closingStoresSave = 'closing-stores/save';
  static const String closingStoresUnpaidTransactions =
      'closing-stores/unpaid-transactions';
  static const String closingStoresVehicles = 'closing-stores/vehicles';
  static const String closingStoresSuppliers = 'closing-stores/suppliers';
  static const String closingStoresFuelServices = 'closing-stores/fuel-services';
  static const String closingStoresFuelServicesForPayment =
      'closing-stores/fuel-services-for-payment';
  static const String closingStoresFuelServicesUsers =
      'closing-stores/fuel-services/users';

  // === Procurement ===
  static const String procurementProducts = 'procurement/products';
  static const String procurementRequests = 'procurement/requests';
  static String procurementRequestDetail(int id) => 'procurement/requests/$id';
  static String procurementRequestActionPost() => 'procurement/requests';
  static String procurementRequestSave(int id) => 'procurement/requests/$id';
  static const String procurementDetailRequests = 'procurement/detail-requests';
  static String procurementApproveItem(int itemId) =>
      'procurement/requests/items/$itemId/approve';
  static String procurementRejectItem(int itemId) =>
      'procurement/requests/items/$itemId/reject';
  static const String procurementInvoices = 'procurement/invoices';
  static String procurementInvoiceDetail(int id) => 'procurement/invoices/$id';
  static const String procurementPaymentReceipts =
      'procurement/payment-receipts';
  static String procurementPaymentReceiptDetail(int id) =>
      'procurement/payment-receipts/$id';

  // === Recipes & Productions ===
  static const String recipes = 'recipes';
  static String recipeDetail(int id) => 'recipes/$id';
  static String recipesByProduct(int productId) => 'recipes/by-product/$productId';
  static const String productions = 'productions';

  // === Sales Orders (general) ===
  static const String salesOrderSearch = 'sales-orders/search';
  static const String salesOrderReadyToShip = 'sales-orders/ready-to-ship';
  static const String salesOrderMarkPrinted =
      'sales-orders/payment-proofs/printed';
  static const String salesOrderDeliveryUpdate = 'sales-orders/delivery-update';
  static const String salesOrderUpdatePaymentStatus =
      'sales-orders/update-payment-status';
  static const String salesOrderUpdateItems = 'sales-orders/update-items';

  // === Sales Orders Online (admin) ===
  static const String onlineShopProviders = 'sales-orders/online-shop-providers';
  static const String deliveryServices = 'sales-orders/delivery-services';
  static const String onlineProducts = 'sales-orders/online-products';
  static const String createSalesOrderOnline = 'sales-orders/online';

  // === Sales Orders Employee ===
  static const String salesOrderEmployee = 'sales-orders/employee';
  static String salesOrderEmployeeDetail(int id) => 'sales-orders/employee/$id';
  static const String salesOrderEmployeeSupportingData =
      'sales-orders/employee/supporting-data';

  // === Sales Dashboard ===
  static const String salesDashboard = 'sales-dashboard';

  // === Inventory Anomalies ===
  static const String compareInventoryAnomaly = 'inventory-anomalies/compare';

  // === Hygiene ===
  static const String hygiene = 'hygiene';
  static const String hygieneRooms = 'hygiene/rooms';
  static const String hygieneTodayStatus = 'hygiene/today-status';
  static const String hygieneOfRooms = 'hygiene/of-rooms';
  static String hygieneRoomUpdate(int id) => 'hygiene/of-rooms/$id';

  // === Readiness ===
  // (readiness endpoint sama dengan hygiene pattern — konfirmasi via service)

  // === Assets ===
  static const String assetCategories = 'asset-categories';
  static const String assets = 'assets';
  static String assetDetail(int id) => 'assets/$id';
  static const String assetDashboard = 'assets/dashboard';
  static const String assetCurrentStore = 'assets/current-store';
  static const String assetFromProduct = 'assets/from-product';
  static const String assetProducts = 'asset-products';
  static const String assetIssues = 'asset-issues';
  static String assetIssueDetail(int id) => 'asset-issues/$id';

  // === Suppliers ===
  static const String suppliers = 'suppliers';
  static String supplierDetail(int id) => 'suppliers/$id';

  // === Utility Usages ===
  static const String utilities = 'utilities';
  static const String utilityUsages = 'utility-usages';
  static String utilityUsageDetail(int id) => 'utility-usages/$id';

  // === Regional (address) ===
  static const String provinces = 'provinces';
  static const String cities = 'cities';
  static const String districts = 'districts';
  static const String subdistricts = 'subdistricts';
  static const String postalCodes = 'postal-codes';

  // === Banks ===
  static const String banks = 'banks';

  // === App version ===
  static const String appVersion = 'app-version';
}
```

- [ ] **Step 2: Tulis test ringkas**

Create `test/services/endpoints_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/services/endpoints.dart';

void main() {
  group('Endpoints static const', () {
    test('auth endpoints', () {
      expect(Endpoints.login, 'login');
      expect(Endpoints.logout, 'logout');
      expect(Endpoints.profile, 'profile');
    });

    test('procurement base paths', () {
      expect(Endpoints.procurementProducts, 'procurement/products');
      expect(Endpoints.procurementRequests, 'procurement/requests');
      expect(Endpoints.procurementInvoices, 'procurement/invoices');
    });
  });

  group('Endpoints param methods', () {
    test('procurementRequestDetail injects id', () {
      expect(Endpoints.procurementRequestDetail(42), 'procurement/requests/42');
    });

    test('procurementApproveItem injects itemId', () {
      expect(
        Endpoints.procurementApproveItem(7),
        'procurement/requests/items/7/approve',
      );
    });

    test('procurementRejectItem injects itemId', () {
      expect(
        Endpoints.procurementRejectItem(7),
        'procurement/requests/items/7/reject',
      );
    });

    test('assetDetail injects id', () {
      expect(Endpoints.assetDetail(99), 'assets/99');
    });

    test('supplierDetail injects id', () {
      expect(Endpoints.supplierDetail(3), 'suppliers/3');
    });
  });

  group('Endpoints completeness', () {
    test('all values are non-empty', () {
      // Sanity: pastikan tidak ada const yang kelupaan.
      const values = [
        Endpoints.login,
        Endpoints.profile,
        Endpoints.procurementProducts,
        Endpoints.assets,
        Endpoints.suppliers,
      ];
      for (final v in values) {
        expect(v.isNotEmpty, true);
      }
    });
  });
}
```

- [ ] **Step 3: Jalankan test — harus PASS**

Run: `flutter test test/services/endpoints_test.dart`
Expected: `All tests passed!`

- [ ] **Step 4: Verifikasi compile**

Run: `flutter analyze lib/services/endpoints.dart`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/services/endpoints.dart test/services/endpoints_test.dart
git commit -m "feat(services): add centralized Endpoints class

Consolidates 85+ endpoint string literals scattered across 26 services.
Methods for parameterized paths (e.g. Endpoints.procurementRequestDetail(id)).
Will replace hardcoded strings in services (follow-up migration task)."
```

---

## Task 4: Type-Safe `ApiClient` Generic Methods + Logging Cleanup

**Files:**
- Modify: `lib/services/api_client.dart`
- Create: `test/services/api_client_test.dart`

**Goal:** Tambah method generic `getList<T>`, `getObject<T>`, `postObject<T>` tanpa menghapus method lama (backward-compat). Ganti `debugPrint(response.body)` ke `AppLogger` dengan preview & redaction.

- [ ] **Step 1: Audit pemakaian method ApiClient saat ini**

Run:
```bash
grep -rEn "ApiClient\(\)\.(get|post|put|delete|getRaw|postRaw|multipart)" lib/services/ | wc -l
```
Expected: angka pemakaian (untuk memastikan method lama tidak bisa dihapus).

- [ ] **Step 2: Tambah unit test untuk method generic baru (TDD)**

Create `test/services/api_client_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Product {
  final int id;
  final String name;
  _Product(this.id, this.name);

  factory _Product.fromJson(Map<String, dynamic> j) =>
      _Product(j['id'] as int, j['name'] as String);
}

void main() {
  // Karena ApiClient pakai package:http global, kita override via
  // `http.Client` hanya bila ApiClient refactor untuk inject client.
  // Untuk plan ini, ApiClient masih pakai top-level http.get/post —
  // test ini fokus kontrak signature, bukan HTTP real.

  group('ApiClient generic methods exist', () {
    final client = ApiClient();

    test('getList<T> method exists with correct signature', () {
      // Verifikasi method terdaftar (signature check).
      expect(client.getList<_Product>, isA<Function>());
    });

    test('getObject<T> method exists', () {
      expect(client.getObject<_Product>, isA<Function>());
    });

    test('postObject<T> method exists', () {
      expect(client.postObject<_Product>, isA<Function>());
    });
  });
}
```

> **Catatan:** Unit test penuh (dengan mock HTTP) butuh ApiClient refactor untuk menerima `http.Client` via constructor injection — itu adalah workstream terpisah. Di sini kita hanya memastikan method generic **terdefinisi & callable**.

- [ ] **Step 3: Jalankan test — harus FAIL**

Run: `flutter test test/services/api_client_test.dart`
Expected: FAIL karena method `getList` belum ada.

- [ ] **Step 4: Edit `api_client.dart` — tambah import & method generic**

Edit `lib/services/api_client.dart`. Tambah import di atas:

```dart
import '../utils/app_logger.dart';
```

Lalu tambahkan method-method generic **di dalam class `ApiClient`** (setelah method `delete`, sebelum `multipart`):

```dart
  // === Type-safe generic variants (preferred for new code) ===
  //
  // Method lama (get/post/put/delete) return `dynamic` dan rentan bug type.
  // Method generic ini langsung mengembalikan List<T> atau T hasil decode.

  /// GET yang langsung return `List<T>`.
  ///
  /// Memanggil [get] lalu decode setiap elemen via [fromJson].
  Future<List<T>> getList<T>(
    String path, {
    required T Function(Map<String, dynamic> json) fromJson,
    Map<String, String>? queryParams,
  }) async {
    final data = await get(path, queryParams: queryParams);
    final list = data is List ? data : const <dynamic>[];
    return list
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// GET yang return single object `T`.
  Future<T> getObject<T>(
    String path, {
    required T Function(Map<String, dynamic> json) fromJson,
    Map<String, String>? queryParams,
  }) async {
    final data = await get(path, queryParams: queryParams);
    return fromJson(data as Map<String, dynamic>);
  }

  /// POST yang return single object `T`.
  Future<T> postObject<T>(
    String path, {
    required T Function(Map<String, dynamic> json) fromJson,
    dynamic body,
  }) async {
    final data = await post(path, body: body);
    return fromJson(data as Map<String, dynamic>);
  }

  /// PUT yang return single object `T`.
  Future<T> putObject<T>(
    String path, {
    required T Function(Map<String, dynamic> json) fromJson,
    dynamic body,
  }) async {
    final data = await put(path, body: body);
    return fromJson(data as Map<String, dynamic>);
  }
```

- [ ] **Step 5: Anotasi method lama dengan `@Deprecated`**

Masih di `lib/services/api_client.dart`, beri anotasi `@Deprecated` di atas method `get`, `post`, `put`, `delete`. Contoh untuk `get`:

```dart
  /// Sends a GET request to the specified endpoint path.
  @Deprecated('Use typed variant getList<T> or getObject<T> for type safety. '
      'Will be removed after full migration (see PRD_CODEBASE_IMPROVEMENT WS-04).')
  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    // ... isi tetap
  }
```

Lakukan sama untuk `post`, `put`, `delete`. **Jangan beri `@Deprecated` pada `getRaw`, `postRaw`, `multipart`** karena belum punya pengganti generic.

- [ ] **Step 6: Ganti logging di `_handleResponse` & method-method**

Di `_handleResponse` (sekitar line 156), ganti:

```dart
debugPrint('ApiClient Response (${response.statusCode}): ${response.body}');
```

dengan:

```dart
AppLogger.debug('ApiClient Response (${response.statusCode}): '
    '${AppLogger.preview(response.body)}');
```

Di tiap method (`get`, `post`, `put`, `delete`), ganti:

```dart
debugPrint('ApiClient GET: $uri');
```

dengan:

```dart
AppLogger.debug('ApiClient GET: $uri');
```

(Ganti `GET` dengan `POST`/`PUT`/`DELETE`/`Multipart` sesuai method.)

Di atas file, hapus import `package:flutter/foundation.dart` **bila** `debugPrint` tidak lagi dipakai. Verifikasi:

Run: `grep -n "debugPrint" lib/services/api_client.dart`
Expected: 0 matches (semua sudah jadi `AppLogger.debug`).

Bila masih ada `debugPrint` lain (misal di `multipart`), ganti juga.

- [ ] **Step 7: Jalankan test baru**

Run: `flutter test test/services/api_client_test.dart`
Expected: `All tests passed!`

- [ ] **Step 8: Verifikasi analyze — pasti banyak warning `@Deprecated`**

Run: `flutter analyze lib/services/api_client.dart`
Expected: 0 error. (Warning `deprecated_member_use` di tempat lain adalah indikasi migrasi yang belum selesai — itu OK untuk plan ini.)

- [ ] **Step 9: Verifikasi semua test existing masih lulus**

Run: `flutter test`
Expected: semua lulus (mungkin ada warning di output, bukan failure).

- [ ] **Step 10: Commit**

```bash
git add lib/services/api_client.dart test/services/api_client_test.dart
git commit -m "feat(api_client): add type-safe generic methods + AppLogger

- getList<T>, getObject<T>, postObject<T>, putObject<T> with fromJson callback
- Deprecate dynamic get/post/put/delete (will migrate callers gradually)
- Replace debugPrint(response.body) with AppLogger.debug + preview()
  to avoid leaking PII in logs"
```

---

## Task 5: Buat Enum `ProcurementItemStatus` & `InvoiceStatus` (TDD)

**Files:**
- Create: `lib/models/enums/procurement_item_status.dart`
- Create: `lib/models/enums/invoice_status.dart`
- Create: `test/models/enums/procurement_item_status_test.dart`
- Create: `test/models/enums/invoice_status_test.dart`

**Goal:** Hilangkan 27 magic-number `status == 'X'` dengan enum terpusat.

**Mapping (dari audit §2.3.E):**
- Procurement item: `'1'`=Pending, `'2'`=Done, `'3'`=Rejected, `'4'`=Partially Approved.

**Invoice mapping (perlu konfirmasi dari backend):** sementara pakai yang umum di Laravel invoice modules: `'1'`=Draft, `'2'`=Done/Sent, `'3'`=Void. **Verify dari backend sebelum implement.**

- [ ] **Step 1: Tulis failing test untuk `ProcurementItemStatus`**

Create `test/models/enums/procurement_item_status_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/models/enums/procurement_item_status.dart';

void main() {
  group('ProcurementItemStatus.fromApi', () {
    test('maps known codes', () {
      expect(ProcurementItemStatus.fromApi('1'),
          ProcurementItemStatus.pending);
      expect(ProcurementItemStatus.fromApi('2'), ProcurementItemStatus.done);
      expect(ProcurementItemStatus.fromApi('3'), ProcurementItemStatus.rejected);
      expect(ProcurementItemStatus.fromApi('4'),
          ProcurementItemStatus.partiallyApproved);
    });

    test('null → unknown', () {
      expect(ProcurementItemStatus.fromApi(null),
          ProcurementItemStatus.unknown);
    });

    test('unknown code → unknown', () {
      expect(ProcurementItemStatus.fromApi('99'),
          ProcurementItemStatus.unknown);
      expect(ProcurementItemStatus.fromApi(''),
          ProcurementItemStatus.unknown);
    });
  });

  group('ProcurementItemStatus.toApi', () {
    test('inverse of fromApi', () {
      for (final status in ProcurementItemStatus.values) {
        if (status == ProcurementItemStatus.unknown) continue;
        final code = status.toApi();
        expect(ProcurementItemStatus.fromApi(code), status);
      }
    });
  });

  group('ProcurementItemStatus predicates', () {
    test('isPending', () {
      expect(ProcurementItemStatus.pending.isPending, true);
      expect(ProcurementItemStatus.done.isPending, false);
    });

    test('isApproved (done OR partiallyApproved)', () {
      expect(ProcurementItemStatus.done.isApproved, true);
      expect(ProcurementItemStatus.partiallyApproved.isApproved, true);
      expect(ProcurementItemStatus.pending.isApproved, false);
      expect(ProcurementItemStatus.rejected.isApproved, false);
    });

    test('isRejected', () {
      expect(ProcurementItemStatus.rejected.isRejected, true);
      expect(ProcurementItemStatus.done.isRejected, false);
    });
  });

  group('ProcurementItemStatus.displayLabel', () {
    test('human-readable Indonesian labels', () {
      expect(ProcurementItemStatus.pending.displayLabel, 'Pending Approval');
      expect(ProcurementItemStatus.done.displayLabel, 'Done');
      expect(ProcurementItemStatus.rejected.displayLabel, 'Rejected');
      expect(ProcurementItemStatus.partiallyApproved.displayLabel,
          'Partially Approved');
      expect(ProcurementItemStatus.unknown.displayLabel, 'Unknown');
    });
  });
}
```

- [ ] **Step 2: Jalankan test — harus FAIL**

Run: `flutter test test/models/enums/procurement_item_status_test.dart`
Expected: FAIL karena file `procurement_item_status.dart` belum ada.

- [ ] **Step 3: Implementasi enum**

Create `lib/models/enums/procurement_item_status.dart`:

```dart
/// Status item permintaan procurement (RequestPurchaseItem.status).
///
/// Mapping ke kode string yang dikirim backend:
/// - `'1'` → [pending]
/// - `'2'` → [done]
/// - `'3'` → [rejected]
/// - `'4'` → [partiallyApproved]
///
/// Source of truth untuk mapping ini: `lib/models/procurement_model.dart:264-267`
/// (`statusText` getter) dan `lib/pages/home_page.dart:297-303`.
enum ProcurementItemStatus {
  pending,
  done,
  rejected,
  partiallyApproved,
  unknown;

  /// Decode dari kode string backend. Null / tidak dikenal → [unknown].
  static ProcurementItemStatus fromApi(String? code) {
    return switch (code) {
      '1' => ProcurementItemStatus.pending,
      '2' => ProcurementItemStatus.done,
      '3' => ProcurementItemStatus.rejected,
      '4' => ProcurementItemStatus.partiallyApproved,
      _ => ProcurementItemStatus.unknown,
    };
  }

  /// Encode ke kode string untuk request body. [unknown] → `'0'`.
  String toApi() {
    return switch (this) {
      ProcurementItemStatus.pending => '1',
      ProcurementItemStatus.done => '2',
      ProcurementItemStatus.rejected => '3',
      ProcurementItemStatus.partiallyApproved => '4',
      ProcurementItemStatus.unknown => '0',
    };
  }

  /// Label Indonesia untuk display.
  String get displayLabel {
    return switch (this) {
      ProcurementItemStatus.pending => 'Pending Approval',
      ProcurementItemStatus.done => 'Done',
      ProcurementItemStatus.rejected => 'Rejected',
      ProcurementItemStatus.partiallyApproved => 'Partially Approved',
      ProcurementItemStatus.unknown => 'Unknown',
    };
  }

  /// Predikat siap pakai — mengganti `status == '1'` dst.
  bool get isPending => this == ProcurementItemStatus.pending;
  bool get isDone => this == ProcurementItemStatus.done;
  bool get isRejected => this == ProcurementItemStatus.rejected;
  bool get isPartiallyApproved => this == ProcurementItemStatus.partiallyApproved;
  bool get isApproved => isDone || isPartiallyApproved;
  bool get isUnknown => this == ProcurementItemStatus.unknown;
}
```

- [ ] **Step 4: Jalankan test — harus PASS**

Run: `flutter test test/models/enums/procurement_item_status_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Tulis failing test untuk `InvoiceStatus`**

> **PRASYARAT:** Sebelum implement, periksa mapping invoice yang sebenarnya dari backend (POST `procurement/invoices` response). Mapping di bawah adalah asumsi; bila berbeda, update test & enum sebelum commit.

Create `test/models/enums/invoice_status_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/models/enums/invoice_status.dart';

void main() {
  group('InvoiceStatus.fromApi', () {
    test('maps known codes', () {
      expect(InvoiceStatus.fromApi('1'), InvoiceStatus.draft);
      expect(InvoiceStatus.fromApi('2'), InvoiceStatus.done);
      expect(InvoiceStatus.fromApi('3'), InvoiceStatus.void_);
    });

    test('null/unknown → unknown', () {
      expect(InvoiceStatus.fromApi(null), InvoiceStatus.unknown);
      expect(InvoiceStatus.fromApi('99'), InvoiceStatus.unknown);
    });
  });

  group('InvoiceStatus predicates', () {
    test('isDraft', () {
      expect(InvoiceStatus.draft.isDraft, true);
      expect(InvoiceStatus.done.isDraft, false);
    });

    test('isDone', () {
      expect(InvoiceStatus.done.isDone, true);
      expect(InvoiceStatus.draft.isDone, false);
    });
  });

  group('InvoiceStatus.toApi', () {
    test('inverse of fromApi', () {
      for (final s in InvoiceStatus.values) {
        if (s == InvoiceStatus.unknown) continue;
        expect(InvoiceStatus.fromApi(s.toApi()), s);
      }
    });
  });
}
```

- [ ] **Step 6: Jalankan test — harus FAIL**

Run: `flutter test test/models/enums/invoice_status_test.dart`
Expected: FAIL.

- [ ] **Step 7: Implementasi `InvoiceStatus`**

Create `lib/models/enums/invoice_status.dart`:

```dart
/// Status invoice procurement.
///
/// Mapping (perlu dikonfirmasi dari backend):
/// - `'1'` → [draft]
/// - `'2'` → [done]
/// - `'3'` → [void_]
///
/// TODO(verifikasi): cross-check dengan controller `ProcurementInvoiceController`
/// di backend sebelum diandalkan.
enum InvoiceStatus {
  draft,
  done,
  void_,
  unknown;

  static InvoiceStatus fromApi(String? code) {
    return switch (code) {
      '1' => InvoiceStatus.draft,
      '2' => InvoiceStatus.done,
      '3' => InvoiceStatus.void_,
      _ => InvoiceStatus.unknown,
    };
  }

  String toApi() {
    return switch (this) {
      InvoiceStatus.draft => '1',
      InvoiceStatus.done => '2',
      InvoiceStatus.void_ => '3',
      InvoiceStatus.unknown => '0',
    };
  }

  String get displayLabel => switch (this) {
        InvoiceStatus.draft => 'Draft',
        InvoiceStatus.done => 'Done',
        InvoiceStatus.void_ => 'Void',
        InvoiceStatus.unknown => 'Unknown',
      };

  bool get isDraft => this == InvoiceStatus.draft;
  bool get isDone => this == InvoiceStatus.done;
  bool get isVoid => this == InvoiceStatus.void_;
  bool get isUnknown => this == InvoiceStatus.unknown;
}
```

- [ ] **Step 8: Jalankan semua enum test**

Run: `flutter test test/models/enums/`
Expected: `All tests passed!`

- [ ] **Step 9: Verifikasi analyze**

Run: `flutter analyze lib/models/enums/`
Expected: `No issues found!`

- [ ] **Step 10: Commit**

```bash
git add lib/models/enums/ test/models/enums/
git commit -m "feat(models): add ProcurementItemStatus & InvoiceStatus enums

Replaces 27 magic-number status == 'X' patterns with self-documenting
enum + predicates (isPending, isApproved, isRejected). Migration of
call sites in next task."
```

---

## Task 6: Migrasi `procurement_model.dart` Pakai Enum

**Files:**
- Modify: `lib/models/procurement_model.dart:264-267`

**Goal:** Helper `statusText` di model pakai enum, menghilangkan 4 magic number.

- [ ] **Step 1: Lihat implementasi `statusText` saat ini**

Run: `sed -n '260,275p' lib/models/procurement_model.dart`
Expected: melihat blok dengan `if (detailRequests.any((item) => item.status == '1')) ...` dst.

- [ ] **Step 2: Tambah extension di `procurement_model.dart`**

Edit `lib/models/procurement_model.dart`. Tambah import di atas:

```dart
import 'enums/procurement_item_status.dart';
```

Lalu tambahkan extension di akhir file (atau setelah class `RequestPurchaseItem`):

```dart
/// Extension untuk mapping `RequestPurchaseItem.status` (String) ke enum.
extension RequestPurchaseItemStatusX on RequestPurchaseItem {
  /// Status sebagai enum ter-type-safe.
  ProcurementItemStatus get statusEnum =>
      ProcurementItemStatus.fromApi(status);
}
```

- [ ] **Step 3: Refactor `statusText` di `RequestPurchase` (induk)**

Ganti blok:

```dart
  String get statusText {
    if (detailRequests.any((item) => item.status == '1')) return 'Pending Approval';
    if (detailRequests.every((item) => item.status == '3')) return 'Rejected';
    if (detailRequests.any((item) => item.status == '4')) return 'Partially Approved';
    if (detailRequests.every((item) => item.status == '2')) return 'Done';
    return 'Unknown';
  }
```

dengan:

```dart
  String get statusText {
    if (detailRequests.isEmpty) return 'Unknown';
    if (detailRequests.any((i) => i.statusEnum.isPending)) {
      return ProcurementItemStatus.pending.displayLabel;
    }
    if (detailRequests.every((i) => i.statusEnum.isRejected)) {
      return ProcurementItemStatus.rejected.displayLabel;
    }
    if (detailRequests.any((i) => i.statusEnum.isPartiallyApproved)) {
      return ProcurementItemStatus.partiallyApproved.displayLabel;
    }
    if (detailRequests.every((i) => i.statusEnum.isDone)) {
      return ProcurementItemStatus.done.displayLabel;
    }
    return 'Unknown';
  }
```

- [ ] **Step 4: Verifikasi tidak ada magic number tersisa di model ini**

Run: `grep -n "status == " lib/models/procurement_model.dart`
Expected: 0 matches.

- [ ] **Step 5: Jalankan test procurement existing**

Run: `flutter test test/widgets/procurement_*.dart`
Expected: semua lulus (logic `statusText` harus menghasilkan output yang sama).

- [ ] **Step 6: Smoke test**

Run: `flutter run`
Buka halaman procurement list/dashboard, pastikan label status masih tampil ("Pending Approval", "Done", dll.) dengan benar.

- [ ] **Step 7: Commit**

```bash
git add lib/models/procurement_model.dart
git commit -m "refactor(procurement_model): use ProcurementItemStatus enum

statusText getter now uses enum predicates instead of status == '1'/'4'.
Adds RequestPurchaseItemStatusX extension for callers. Behavior unchanged."
```

---

## Task 7: Migrasi Magic Number di Pages & Widgets

**Files:**
- Modify: `lib/pages/procurement_detail_page.dart` (5 magic number)
- Modify: `lib/pages/procurement_dashboard_page.dart` (4)
- Modify: `lib/pages/home_page.dart` (2, di `_loadProcurementCounts`)
- Modify: `lib/pages/create_invoice_page.dart` (1)
- Modify: `lib/widgets/procurement_pipeline_card.dart` (2)
- Modify: `lib/widgets/procurement_graph_view.dart` (1)

> **Catatan:** `calendar_page.dart` & `daily_salary_list_page.dart` pakai pattern `status == 1 || status == '1'` yang merupakan status **lain** (cuti / salary), bukan procurement. Task ini **TIDAK** menyentuhnya — itu enum terpisah (buat di sprint mendatang).

- [ ] **Step 1: Audit semua lokasi yang akan diubah**

Run:
```bash
grep -rn "status == '[1-4]'" lib/pages/procurement_*.dart lib/pages/home_page.dart lib/pages/create_invoice_page.dart lib/widgets/procurement_*.dart
```
Expected: melihat ~15 baris. Catat tiap lokasi.

- [ ] **Step 2: Refactor `procurement_detail_page.dart`**

Edit file. Tambah import di atas:

```dart
import '../models/enums/procurement_item_status.dart';
```

Lalu cari & ganti tiap pattern. Contoh (line 139):

```dart
// Sebelum:
.where((item) => item.status == '4')

// Sesudah:
.where((item) => item.statusEnum.isApproved)
```

Contoh (line 192):

```dart
// Sebelum:
final hasApprovedItems = _request?.detailRequests.any((item) => item.status == '4') ?? false;

// Sesudah:
final hasApprovedItems = _request?.detailRequests.any((item) => item.statusEnum.isApproved) ?? false;
```

Contoh (line 310, gabungan `'1' || '4'`):

```dart
// Sebelum:
if (_isAdmin && (item.status == '1' || item.status == '4')) ...[
  if (item.status == '1') ...[

// Sesudah:
if (_isAdmin && item.statusEnum.isApproved || item.statusEnum.isPending) ...[
  if (item.statusEnum.isPending) ...[
```

> **Penting:** Untuk kondisi gabungan kompleks, baca konteks penuh sebelum ubah. Bila ragu, uji dengan print statement sebelum & sesudah untuk membandingkan.

- [ ] **Step 3: Refactor `procurement_dashboard_page.dart`**

Edit file. Tambah import. Lalu ganti pattern. Contoh (line 121):

```dart
// Sebelum:
return _requests.where((r) => r.detailRequests.any((item) => item.status == '1')).toList();

// Sesudah:
return _requests.where((r) => r.detailRequests.any((item) => item.statusEnum.isPending)).toList();
```

Line 123-124 (kombinasi any/every):

```dart
// Sebelum:
return _requests.where((r) => r.detailRequests.any((item) => item.status == '4') && 
                                      !r.detailRequests.any((item) => item.status == '1')).toList();

// Sesudah:
return _requests.where((r) => 
    r.detailRequests.any((item) => item.statusEnum.isPartiallyApproved) &&
    !r.detailRequests.any((item) => item.statusEnum.isPending)).toList();
```

Line 126:

```dart
// Sebelum:
return _requests.where((r) => r.detailRequests.isNotEmpty && r.detailRequests.every((item) => item.status == '2')).toList();

// Sesudah:
return _requests.where((r) => r.detailRequests.isNotEmpty && r.detailRequests.every((item) => item.statusEnum.isDone)).toList();
```

- [ ] **Step 4: Refactor `home_page.dart` (line 297-303)**

Edit `lib/pages/home_page.dart`. Tambah import:

```dart
import '../models/enums/procurement_item_status.dart';
```

Lalu ganti:

```dart
// Sebelum:
for (final item in req.detailRequests) {
  if (item.status == '1') {
    pending++;
  } else if (item.status == '4') {
    approved++;
  }
}

// Sesudah:
for (final item in req.detailRequests) {
  if (item.statusEnum.isPending) {
    pending++;
  } else if (item.statusEnum.isPartiallyApproved) {
    approved++;
  }
}
```

- [ ] **Step 5: Refactor `create_invoice_page.dart` (line 67)**

Edit file. Tambah import. Ganti:

```dart
// Sebelum:
.where((i) => i.status == '4' || i.status == '2')

// Sesudah:
.where((i) => i.statusEnum.isApproved)
```

(`'4' || '2'` = `partiallyApproved || done` = `isApproved`.)

- [ ] **Step 6: Refactor `lib/widgets/procurement_pipeline_card.dart`**

Edit file. Tambah import. Ganti:

```dart
// Sebelum:
if (request.detailRequests.every((i) => i.status == '3')) return 2; // Rejected
if (request.detailRequests.any((i) => i.status == '4' || i.status == '2')) return 1; // Approved

// Sesudah:
if (request.detailRequests.every((i) => i.statusEnum.isRejected)) return 2; // Rejected
if (request.detailRequests.any((i) => i.statusEnum.isApproved)) return 1; // Approved
```

- [ ] **Step 7: Refactor `lib/widgets/procurement_graph_view.dart` (line 325)**

Edit file. Tambah import. Ganti:

```dart
// Sebelum:
final approved = req.detailRequests.any((i) => i.status == '4');

// Sesudah:
final approved = req.detailRequests.any((i) => i.statusEnum.isPartiallyApproved);
```

> **Catatan:** Untuk `procurement_graph_view`, `'4'` adalah partiallyApproved (belum tentu `isApproved` yang mencakup done). **Baca konteks dulu** — bila di UI graph ini ingin show semua approved (termasuk done), pakai `isApproved`. Bila hanya partiallyApproved, pakai `isPartiallyApproved`. Verifikasi dengan test existing.

- [ ] **Step 8: Verifikasi tidak ada magic number procurement tersisa**

Run:
```bash
grep -rn "status == '[1-4]'" lib/pages/procurement_*.dart lib/pages/home_page.dart lib/pages/create_invoice_page.dart lib/widgets/procurement_*.dart lib/models/procurement_model.dart
```
Expected: 0 matches.

- [ ] **Step 9: Jalankan semua procurement test**

Run: `flutter test test/widgets/procurement_*.dart test/models/enums/`
Expected: semua lulus.

- [ ] **Step 10: Verifikasi global analyze & test**

Run: `flutter analyze && flutter test`
Expected: 0 error, semua test lulus.

- [ ] **Step 11: Smoke test manual**

Run: `flutter run`
Lakukan:
- Buka procurement dashboard — pastikan filter tab (Pending/Approved/Done) masih bekerja.
- Buka procurement detail — pastikan tombol approve/reject tampil di item yang tepat.
- Buka Home — pastikan badge count procurement sesuai.

- [ ] **Step 12: Commit (boleh pecah per-file bila reviewer minta)**

```bash
git add lib/pages/procurement_detail_page.dart lib/pages/procurement_dashboard_page.dart lib/pages/home_page.dart lib/pages/create_invoice_page.dart lib/widgets/procurement_pipeline_card.dart lib/widgets/procurement_graph_view.dart
git commit -m "refactor: replace 15 procurement magic-number statuses with enum

All 'status == \"1\"'/'2'/'3'/'4' patterns in procurement pages &
widgets now use item.statusEnum predicates. Behavior unchanged —
procurement dashboard filters, detail approvals, and home counts
verified via smoke test."
```

---

## Task 8: Final Verification & Snapshot

**Files:**
- Create: `docs/health-reports/2026-07-20-sprint2-foundation-final.md`

- [ ] **Step 1: Jalankan health script**

Run: `./scripts/codebase_health.sh 2026-07-20-sprint2-foundation-final`
Expected: report terbuat.

- [ ] **Step 2: Compare dengan baseline Sprint 1**

Run:
```bash
diff docs/health-reports/2026-07-20-sprint1-final.md docs/health-reports/2026-07-20-sprint2-foundation-final.md
```

**Expected changes:**
- `print()` count: dari 5 → **0** (audit_service sudah pakai AppLogger).
- `debugPrint` count: turun (~10-15 dari 72, ApiClient & audit_service).
- Magic number status: dari 27 → ~17 (10 procurement berhasil di-migrasi; sisanya calendar/salary/leave — di luar scope).
- File test: naik ~5 (AppLogger, Endpoints, ApiClient, 2 enum).
- LOC: naik sedikit (code baru + test).

- [ ] **Step 3: Full test + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 error analyze, semua test lulus.

- [ ] **Step 4: Commit final**

```bash
git add docs/health-reports/2026-07-20-sprint2-foundation-final.md
git commit -m "docs(health): sprint 2 (service foundation) final snapshot"
```

---

## Acceptance Criteria (dari PRD §4.4, §4.5, §4.8, §4.10)

### WS-10 — AppLogger
- [ ] `lib/utils/app_logger.dart` ada dengan API `debug`/`info`/`warning`/`error`/`redact`/`preview`.
- [ ] 10 unit test lulus.
- [ ] `print()` count di `lib/` = 0.
- [ ] `debugPrint` di `api_client.dart` diganti `AppLogger`.

### WS-08 — Endpoints
- [ ] `lib/services/endpoints.dart` ada, berisi 85+ endpoint.
- [ ] Test `endpoints_test.dart` lulus.
- [ ] (Catatan: migrasi service ke pakai `Endpoints.xxx` adalah **follow-up task di sprint berikutnya**, bukan scope plan ini.)

### WS-04 — ApiClient Generic
- [ ] Method `getList<T>`, `getObject<T>`, `postObject<T>`, `putObject<T>` tersedia.
- [ ] Method lama `get`/`post`/`put`/`delete` bertanda `@Deprecated`.
- [ ] Tidak ada lagi `debugPrint(response.body)` di ApiClient.

### WS-05 — Enum Status (Procurement)
- [ ] Enum `ProcurementItemStatus` & `InvoiceStatus` ada dengan `fromApi`/`toApi`/predikat.
- [ ] Extension `statusEnum` di `RequestPurchaseItem`.
- [ ] **0 magic number procurement** (`status == '[1-4]'`) di `lib/pages/procurement_*`, `lib/widgets/procurement_*`, `lib/models/procurement_model.dart`, `lib/pages/home_page.dart` (untuk blok procurement), `lib/pages/create_invoice_page.dart`.

### Sprint-level
- [ ] `docs/health-reports/2026-07-20-sprint2-foundation-final.md` ada.
- [ ] `flutter analyze` global → 0 error.
- [ ] `flutter test` → semua lulus.
- [ ] App build & jalan.

---

## Troubleshooting

### `procurement_graph_view.dart` logic berubah setelah ganti `'4'` → `isApproved`

`'4'` adalah partiallyApproved. Bila kode sebelumnya hanya cek `'4'`, mengganti ke `isApproved` (yang mencakup done) akan **mengubah behavior** — done item akan ikut terhitung. Selalu ganti `'4'` ke `isPartiallyApproved` BILA ingin preserve behavior exactly, atau `isApproved` bila memang ingin fix bug.

**Verify:** jalankan graph view dengan data procurement yang punya item done + partiallyApproved, bandingkan visual sebelum/sesudah.

### `@Deprecated` warning memenuhi output `flutter analyze`

Normal — akan muncul banyak warning `deprecated_member_use` di tempat yang masih pakai method lama. Itu indikator migrasi yang belum selesai. **Jangan di-suppress global**; biarkan sebagai signal yang mendorong migrasi bertahap.

Bila terlalu noisy, temporary tambah di `analysis_options.yaml`:
```yaml
errors:
  deprecated_member_use: info  # turunkan dari warning ke info
```

### Enum test fail karena mapping salah

Bila `InvoiceStatus` mapping di Task 5 salah (setelah konfirmasi backend berbeda), **update test & enum bersamaan**. Jangan abaikan failure — mapping enum adalah kontrak yang harus akurat.

### Service masih pakai hardcoded string padahal `Endpoints` sudah ada

Itu memang sengaja — migrasi 26 service ke `Endpoints.xxx` adalah **task terpisah** (di luar plan ini), agar PR review-able. Plan ini hanya deliver fondasi (class `Endpoints` + test). Migrasi bisa 1-2 service per PR.

---

## Out of Scope (untuk sprint ini)

- Migrasi 26 service ke pakai `Endpoints.xxx` — task ongoing, sprint mendatang.
- Migrasi caller service ke pakai `ApiClient.getList<T>` — task ongoing.
- Enum untuk status `Leave`, `Calendar`, `Salary`, `SalesOrder` — sprint mendatang.
- Enum untuk status `AssetCheck` — sprint mendatang.
- Refactor `ApiClient` untuk inject `http.Client` (untuk mock test penuh) — PR terpisah.
- Refactor HomePage — Plan 3 (WS-02).
- go_router — Plan 4 (WS-03).
