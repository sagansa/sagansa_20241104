# Provider Architecture Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrasi codebase `mobiles/sagansa/` ke arsitektur tunggal Widget → Provider → Service → ApiClient: hapus duplikasi `_getToken`/raw `http` di 21 service, hapus direktori `controllers/` dengan memindahkan logic-nya ke Provider, dan refactor pages agar memakai Provider.

**Architecture:** Empat phase berurutan — (1) konsolidasi service ke `ApiClient`, (2) perluas/buat Provider untuk menampung logic controller, (3) hapus `controllers/`, (4) refactor pages. Setiap phase menghasilkan kode yang dapat di-build dan dapat di-test secara independen. `ApiClient` yang sudah ada (singleton, get/getRaw/post/put/delete/multipart dengan auto-inject token, error handling, logging) menjadi satu-satunya jalur HTTP.

**Tech Stack:** Flutter, `provider ^6.1.2`, `http ^1.2.2`, `flutter_lints ^6.0.0`, `flutter_test` SDK. Test dengan `flutter test`; lint dengan `flutter analyze`.

**Spec:** `PRD_PROVIDER_STANDARD.md` (v1.1, Final).

**Direktori kerja:** `/Users/dityo/Codings/sagansa/mobiles/sagansa/` (semua path di bawah relatif ke sini).

---

## Aturan Umum (berlaku untuk semua task)

1. **Jangan lanjut ke task berikutnya sebelum `flutter analyze` bersih (0 error) dan `flutter test` lulus.**
2. **Satu task = satu commit.** Pesan commit pakai conventional commits (`refactor(service): migrate X to ApiClient`, `feat(provider): add X`, `refactor(page): use XProvider`, `chore: remove controllers/`).
3. **DRY:** setiap service yang dipindahkan ke `ApiClient` harus menghapus method `_getToken()`/`getToken()`/`_headers()` dan import `shared_preferences` (jika hanya dipakai untuk token) dari file tersebut.
4. **Error handling:** Service tetap melempar `Exception` (ApiClient sudah merangkum pesan dari backend). Provider menerjemahkan `Exception` ke `_errorMessage` via `_parseError`. Widget membaca `provider.errorMessage`.
5. **Test first:** untuk Provider baru dan refactor provider, tulis test dulu yang merah, lalu implementasi, lalu hijau. Untuk service migration, test dijalankan untuk memastikan tidak ada regresi (lihat "Strategi Testing Service" di bawah).
6. **Jangan menyentuh** service non-HTTP yang tercantum di PRD Section 5 Phase 1d (`thermal_printer_service`, `network_service`, `image_service`, `asset_check_reminder_service`, `location_tracking_service`).

### Strategi Testing Service Migration

Service yang dimigrasi TIDAK punya test file saat ini. Karena `ApiClient` memakai `package:http` langsung (tidak di-inject), kita TIDAK menulis unit test per-service dengan mock `http`. Pendekatan:

- **Regression test otomatis:** sebelum migrasi service `X`, jalankan `flutter analyze lib/services/X_service.dart` dan catat warning/lint yang ada. Setelah migrasi, pastikan jumlah warning TIDAK naik (idealnya turun karena import `shared_preferences` hilang).
- **Smoke test build:** `flutter analyze` global dan `flutter test` (semua test eksisting) harus tetap hijau.
- **Verifikasi manual:** untuk service yang dipakai halaman interaktif (presence, sales order, dll), lakukan smoke test di emulator setelah Phase 1 selesai untuk memastikan fitur masih jalan.

Jika di masa depan ingin unit test per-service, refactoring `ApiClient` agar `http.Client` di-inject adalah PR terpisah (di luar scope plan ini).

---

## File Structure

File yang akan dimodifikasi/dibuat, dikelompokkan per fase:

### Phase 1 (Service → ApiClient)
- **Modify (21 file service):** `lib/services/{procurement,sales_dashboard,presence,auth,leave,salary,store,image_upload,sales_order,sales_order_employee,production,recipe,hygiene,readiness,asset,asset_check,asset_issue,storage_stock,transfer_stock,closing_store,inventory_anomaly}_service.dart`
- **Tidak diubah (2 file):** `lib/services/supplier_service.dart`, `lib/services/utility_usage_service.dart` (sudah pakai `ApiClient`)

### Phase 2 (Provider)
- **Create:** `lib/providers/procurement_provider.dart`, `lib/providers/sales_dashboard_provider.dart`, `lib/providers/leave_provider.dart`, `lib/providers/asset_provider.dart`
- **Modify:** `lib/providers/presence_provider.dart` (perluas untuk menyerap logic `presence_controller.dart`)
- **Modify:** `lib/providers/auth_provider.dart` (tambah method `loadHomeData()` untuk menyerap `home_controller.dart`)
- **Create (test):** `test/providers/{procurement,sales_dashboard,leave,asset,presence,auth}_provider_test.dart`

### Phase 3 (Hapus controllers/)
- **Delete:** `lib/controllers/home_controller.dart`, `lib/controllers/presence_controller.dart`, `lib/controllers/leave_controller.dart`, `lib/controllers/asset_controller.dart`
- **Delete:** `lib/controllers/` (folder kosong setelah 4 file dihapus)
- **Modify:** semua file yang mengimpor `*Controller` — refactor ke Provider (ditangani di Phase 4)

### Phase 4 (Page refactor)
- **Modify:** pages yang memakai controller: home page, presence page, leave page, asset page, asset_*, dan pages lain yang memakai `setState` untuk state shared lintas-widget.
- Lihat "Page Refactor Matrix" di Task 4.0 untuk daftar lengkap.

---

## PHASE 1: Konsolidasi Service ke ApiClient

> **Tujuan:** Semua service HTTP memakai `ApiClient`. Hapus `_getToken`/`getToken`/`_headers`/import `shared_preferences` (jika khusus token) di setiap service.

### Task 1.0: Tambah helper command & baseline

**Files:**
- Tidak ada perubahan kode. Hanya setup baseline.

- [ ] **Step 1: Catat baseline test & analyze**

Run:
```bash
cd /Users/dityo/Codings/sagansa/mobiles/sagansa
flutter analyze 2>&1 | tail -5
flutter test 2>&1 | tail -10
```

Expected: catat jumlah issue analyze (mis. "X issues") dan hasil test (mis. "All tests passed!"). Ini baseline untuk verifikasi tiap task tidak menambah masalah.

- [ ] **Step 2: Commit baseline kosong (optional, lewati jika tidak perlu)**

Lewati — baseline hanya catatan.

---

### Task 1.1: Migrate `procurement_service.dart` ke ApiClient

**Files:**
- Modify: `lib/services/procurement_service.dart` (seluruh file, 589 baris)

`ProcurementService` adalah service terbesar dan paling representatif — dipakai sebagai template untuk service lain. Setelah ini selesai, pola yang sama diulang untuk service lain (Task 1.3+).

- [ ] **Step 1: Ganti import**

```dart
// Hapus:
import 'package:shared_preferences/shared_preferences.dart';
// Hapus:
import 'package:http/http.dart' as http;
// Tambah:
import 'api_client.dart';
```

Pertahankan import `dart:convert` (tidak dipakai setelah migrasi sebenarnya — verifikasi dengan analyze), `dart:io` (untuk `File`), `image_upload_service.dart`, `procurement_model.dart`, `constants.dart` (untuk `ApiConstants` — masih dipakai? HAPUS jika tidak lagi karena `ApiClient` yang urus baseUrl. **Verifikasi** bahwa tidak ada lagi pemakaian `ApiConstants.baseUrl` di file ini sebelum hapus importnya).

> **Catatan penting tentang `ApiConstants`:** `ApiClient` memakai `ApiConstants.baseUrl` secara internal (lihat `api_client.dart:29`). Jadi service tidak perlu lagi membangun URL sendiri.

- [ ] **Step 2: Tambah field `ApiClient` dan hapus `_getToken`**

Ganti:
```dart
class ProcurementService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  // ... methods
}
```

Dengan:
```dart
class ProcurementService {
  final ApiClient _api = ApiClient();

  // ... methods
}
```

- [ ] **Step 3: Migrate method GET sederhana (`getProducts`)**

Ganti method `getProducts` dengan:
```dart
Future<List<ProcurementProduct>> getProducts() async {
  final data = await _api.get('procurement/products');
  final List productsJson = (data as List?) ?? [];
  return productsJson.map((j) => ProcurementProduct.fromJson(j as Map<String, dynamic>)).toList();
}
```

> **Catatan:** `ApiClient._handleResponse` sudah otomatis mengembalikan `json['data']` ketika `json['success'] == true`. Jadi `data` di sini sudah berupa list produk.

- [ ] **Step 4: Migrate GET dengan query params (`getRequests`, `getRequestsPaged`, `getDetailRequests`, `getInvoices`, `getPaymentReceipts`)**

Contoh: `getRequests`:
```dart
Future<List<RequestPurchase>> getRequests({int page = 1, int perPage = 1000}) async {
  final data = await _api.get('procurement/requests', queryParams: {
    'page': page.toString(),
    'per_page': perPage.toString(),
  });
  final List requestsJson = (data as List?) ?? [];
  return requestsJson.map((j) => RequestPurchase.fromJson(j as Map<String, dynamic>)).toList();
}
```

Contoh: `getRequestsPaged` (perlu `pagination` meta — pakai `getRaw`):
```dart
Future<Map<String, dynamic>> getRequestsPaged({int page = 1, int perPage = 20}) async {
  final body = await _api.getRaw('procurement/requests', queryParams: {
    'page': page.toString(),
    'per_page': perPage.toString(),
  });
  if (body['success'] == true) {
    final List data = body['data'] ?? [];
    final meta = body['pagination'] ?? {};
    final hasMore = (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1);
    return {
      'data': data.map((e) => RequestPurchase.fromJson(e as Map<String, dynamic>)).toList(),
      'has_more': hasMore,
    };
  }
  throw Exception(body['message'] ?? 'Failed to load procurement requests');
}
```

Pola yang sama untuk `getInvoices` dan `getPaymentReceipts` (keduanya membaca `body['meta']` → tetap pakai `getRaw` karena `_handleResponse` hanya kembalikan `data`):
```dart
Future<PaginatedResult<InvoicePurchase>> getInvoices({
  String? orderStatus, String? paymentStatus, int? storeId,
  int page = 1, int perPage = 10,
}) async {
  final params = <String, String>{
    'page': page.toString(),
    'per_page': perPage.toString(),
  };
  if (orderStatus != null) params['order_status'] = orderStatus;
  if (paymentStatus != null) params['payment_status'] = paymentStatus;
  if (storeId != null) params['store_id'] = storeId.toString();

  final body = await _api.getRaw('procurement/invoices', queryParams: params);
  final List invoicesJson = body['data'] ?? [];
  final meta = body['meta'] as Map<String, dynamic>? ?? {};
  return PaginatedResult(
    items: invoicesJson.map((j) => InvoicePurchase.fromJson(j as Map<String, dynamic>)).toList(),
    currentPage: meta['current_page'] ?? 1,
    lastPage: meta['last_page'] ?? 1,
    perPage: meta['per_page'] ?? perPage,
    total: meta['total'] ?? 0,
  );
}
```

> **Penting:** bedakan kapan pakai `get` vs `getRaw`:
> - `get` → response berhasil dengan `success: true`, Anda butuh hanya `data` (list atau objek).
> - `getRaw` → Anda butuh field di luar `data` (mis. `pagination`, `meta`, `has_more`).

- [ ] **Step 5: Migrate GET detail (`getRequestDetail`, `getInvoiceDetail`, `getPaymentReceiptDetail`)**

Contoh `getRequestDetail`:
```dart
Future<RequestPurchase> getRequestDetail(int id) async {
  final data = await _api.get('procurement/requests/$id');
  return RequestPurchase.fromJson(data as Map<String, dynamic>);
}
```

- [ ] **Step 6: Migrate GET dengan logic agregasi (`getProcurementSummary`)**

`getProcurementSummary` membaca `body['meta']['invoice_counts']` → pakai `getRaw`:
```dart
Future<Map<String, dynamic>> getProcurementSummary() async {
  final body = await _api.getRaw('procurement/requests');
  final List requestsJson = body['data'] ?? [];
  final Map<String, dynamic> meta = (body['meta'] as Map<String, dynamic>?) ?? {};
  final Map<String, dynamic> invoiceCounts =
      (meta['invoice_counts'] as Map<String, dynamic>?) ?? {'draft': 0, 'done': 0, 'unpaid': 0};
  return {
    'requests': requestsJson.map((j) => RequestPurchase.fromJson(j as Map<String, dynamic>)).toList(),
    'invoice_draft': invoiceCounts['draft'] ?? 0,
    'invoice_done': invoiceCounts['done'] ?? 0,
    'invoice_unpaid': invoiceCounts['unpaid'] ?? 0,
  };
}
```

- [ ] **Step 7: Migrate POST sederhana (`createRequest`, `approveItem`, `rejectItem`, `cancelItem`, `receiveInvoice`)**

Contoh `createRequest`:
```dart
Future<bool> createRequest(int storeId, List<Map<String, dynamic>> items) async {
  await _api.post('procurement/requests', body: {
    'store_id': storeId,
    'items': items,
  });
  return true; // ApiClient melempar Exception jika gagal
}
```

Contoh `approveItem`:
```dart
Future<bool> approveItem(int itemId) async {
  await _api.post('procurement/requests/items/$itemId/approve');
  return true;
}
```

Pola yang sama untuk `rejectItem`, `cancelItem`, `receiveInvoice`.

> **Catatan return type:** method ini sebelumnya mengembalikan `true` saat sukses dan melempar Exception saat gagal. Pertahankan contract ini — `ApiClient.post` otomatis melempar Exception jika non-2xx, jadi cukup `return true` setelah pemanggilan sukses.

- [ ] **Step 8: Migrate POST yang mengembalikan data (`createInvoice`, `createInvoiceStandalone`, `getPaymentReceiptQris`)**

Contoh `createInvoice`:
```dart
Future<int> createInvoice(int requestId, {
  required int supplierId,
  required List<Map<String, dynamic>> items,
  List<int>? requestIds,
}) async {
  final body = <String, dynamic>{
    'supplier_id': supplierId,
    'items': items,
  };
  if (requestIds != null && requestIds.isNotEmpty) body['request_ids'] = requestIds;

  final data = await _api.post('procurement/requests/$requestId/create-invoice', body: body);
  // Backend mengembalikan {invoice_id: N} di luar data envelope — pakai getRaw? Tidak:
  // _handleResponse mengembalikan json['data'] kalau success==true. Tapi field invoice_id
  // mungkin di root body, bukan di data. Verifikasi respons backend.
  // Asumsi aman: invoice_id ada di dalam data. Jika tidak, ganti ke getRaw.
  return (data as Map<String, dynamic>)['invoice_id'] ?? 0;
}
```

> **Peringatan:** jika respons backend `{"success": true, "invoice_id": 5}` (invoice_id di root), maka `ApiClient._handleResponse` akan kembalikan `json['data']` yang mungkin `null`. Dalam kasus itu, ganti pemanggilan ke `_api.getRaw(...)` dan baca `body['invoice_id']`. **Engineer WAJIB memverifikasi** dengan smoke test sebelum lanjut.

`createInvoiceStandalone` mengembalikan `data['data']['id']` → setelah migrasi `data` sudah = `json['data']` jadi:
```dart
Future<int> createInvoiceStandalone({
  required int supplierId, required int storeId, required int paymentTypeId,
  required String date, required List<Map<String, dynamic>> items,
  int? taxes, int? discounts, String? notes,
}) async {
  final body = <String, dynamic>{
    'supplier_id': supplierId, 'store_id': storeId, 'payment_type_id': paymentTypeId,
    'date': date, 'items': items,
  };
  if (taxes != null) body['taxes'] = taxes;
  if (discounts != null) body['discounts'] = discounts;
  if (notes != null) body['notes'] = notes;

  final data = await _api.post('procurement/invoices', body: body);
  return (data as Map<String, dynamic>)['id'] ?? 0;
}
```

- [ ] **Step 9: Migrate PUT (`updateInvoice`)**

```dart
Future<InvoicePurchase> updateInvoice(int invoiceId, {
  int? supplierId, int? paymentTypeId, int? taxes, int? discounts,
  String? notes, List<Map<String, dynamic>>? items,
}) async {
  final body = <String, dynamic>{};
  if (supplierId != null) body['supplier_id'] = supplierId;
  if (paymentTypeId != null) body['payment_type_id'] = paymentTypeId;
  if (taxes != null) body['taxes'] = taxes;
  if (discounts != null) body['discounts'] = discounts;
  if (notes != null) body['notes'] = notes;
  if (items != null) body['items'] = items;

  final data = await _api.put('procurement/invoices/$invoiceId', body: body);
  return InvoicePurchase.fromJson(data as Map<String, dynamic>);
}
```

- [ ] **Step 10: Migrate multipart (`createPaymentReceipt`, `createFuelServicePaymentReceipt`)**

```dart
Future<PaymentReceipt> createPaymentReceipt({
  required List<int> invoiceIds,
  required int transferAmount,
  int? totalAmount,
  String? notes,
  File? image,
}) async {
  final fields = <String, String>{
    'transfer_amount': transferAmount.toString(),
  };
  for (var id in invoiceIds) {
    // Catatan: ApiClient.multipart belum mendukung array field[].
    // Lihat "Blocking Issue A" di bawah. Jika field['invoice_ids[]'] di-override
    // di map, hanya nilai terakhir yang dikirim. Backend mungkin mengharapkan
    // field berulang. Solusi sementara: kirim sebagai JSON string.
    // Engineer: verifikasi backend dapat terima 'invoice_ids' sebagai JSON.
  }
  // ... (lihat Blocking Issue A)
}
```

> **Blocking Issue A — Array field di multipart:**
> `ApiClient.multipart` menerima `Map<String, String> fields`, yang tidak mendukung multiple values untuk key yang sama (`invoice_ids[]`). Backend Laravel biasanya menerima `invoice_ids[]=1&invoice_ids[]=2`.
>
> **Solusi yang direkomendasikan (tambah ke Task 1.1.A):** Perluas `ApiClient.multipart` untuk menerima `Map<String, List<String>>` atau field khusus array. Lihat Task 1.1.A di bawah.
>
> **Jika tidak diperluas:** ubah `ProcurementService.createPaymentReceipt` untuk kirim `invoice_ids` sebagai JSON string dan pastikan backend mendukungnya (koordinasi dengan backend). Pilihan ini lebih cepat tapi melanggar konsistensi REST.

- [ ] **Step 11: Verifikasi build & analyze**

Run:
```bash
flutter analyze lib/services/procurement_service.dart 2>&1 | tail -20
```

Expected: 0 error. Warning boleh, tapi jumlahnya ≤ baseline.

Run smoke (jika ada page yang pakai procurement):
```bash
flutter test test/widgets/procurement_entity_card_test.dart 2>&1 | tail -10
```

Expected: PASS.

- [ ] **Step 12: Commit**

```bash
git add lib/services/procurement_service.dart
git commit -m "refactor(service): migrate procurement_service to ApiClient"
```

---

### Task 1.1.A: Perluas `ApiClient.multipart` untuk dukung array field

**Files:**
- Modify: `lib/services/api_client.dart` (method `multipart`, baris 100-125)

Task ini **wajib sebelum** Step 10 Task 1.1 bisa dianggap selesai. Jika engineer memilih solusi "JSON string" di Task 1.1 Step 10, skip task ini — tapi dokumentasikan di commit message.

- [ ] **Step 1: Tulis test untuk `ApiClient.multipart` dengan array field**

Create: `test/services/api_client_multipart_test.dart`

> **Catatan:** `ApiClient` saat ini memakai `http` secara langsung (tidak di-inject), sehingga sulung di-unit-test. Test di sini bersifat **integration smoke** menggunakan `http.MockClient` dari `package:http/testing.dart` — namun karena `ApiClient` memakai `http.get`/`http.post` global (bukan instance yang di-inject), MockClient tidak bisa di-attach tanpa refactor lebih dalam.
>
> **Karena itu, pendekatan tdd-test untuk ApiClient multipart tidak feasible tanpa refactor dependency injection.** Lakukan verifikasi manual berikut sebagai pengganti unit test:

- [ ] **Step 2: Implementasi perluasan signature**

Ganti method `multipart` di `api_client.dart`:
```dart
/// Sends a multipart request (e.g. for uploads).
///
/// [fields] mendukung nilai string tunggal. Untuk field array (mis. `ids[]`),
/// gunakan [arrayFields] yang akan dikirim sebagai multiple entries dengan
/// key yang sama.
Future<dynamic> multipart({
  required String method,
  required String path,
  Map<String, String> fields = const {},
  Map<String, List<String>> arrayFields = const {},
  List<http.MultipartFile>? files,
}) async {
  final token = await _getToken();
  final uri = Uri.parse('${ApiConstants.baseUrl}/$path');
  debugPrint('ApiClient Multipart $method: $uri');

  final request = http.MultipartRequest(method, uri);
  request.headers.addAll({
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  });

  request.fields.addAll(fields);
  arrayFields.forEach((key, values) {
    for (final v in values) {
      request.fields.putIfAbsent(key, () => v);
      // Catatan: putIfAbsent hanya set pertama. Untuk multiple values,
      // MultipartRequest.fields adalah Map, tidak mendukung duplikat key
      // secara native. Lihat Step 3 untuk workaround.
    }
  });
  if (files != null) request.files.addAll(files);

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);
  return _handleResponse(response);
}
```

- [ ] **Step 3: Verifikasi multiple values untuk key sama**

`http.MultipartRequest.fields` adalah `Map<String,String>` — tidak mendukung multiple values dengan key sama. Untuk Laravel `ids[]=1&ids[]=2`, sebenarnya body multipart harus memiliki dua part bernama `ids[]`.

> **Solusi definitif:** gunakan `request.fields` untuk scalar, dan untuk array, tambahkan manual via `request.fields[key] = value` hanya bekerja untuk 1 value. Untuk multiple, kita perlu akses ke internal `MultipartRequest` — yang publik adalah `fields`. **Ada cara lain:** `MultipartFile` constructor tidak untuk field string.
>
> **Workaround resmi:** Kirim array sebagai JSON string field (`ids` = `"[1,2,3]"`), dan backend Laravel membaca via `$request->input('ids')` setelah `json_decode`. Ini paling clean.
>
> **Implementasi final:** hapus `arrayFields` parameter, gunakan konvensi JSON string:
> - Di service: `fields['invoice_ids'] = jsonEncode(invoiceIds);`
> - Backend wajib parsing JSON string.
> - **Engineer WAJIB koordinasi dengan backend sebelum pilihan ini.**
>
> Jika backend TIDAK mendukung JSON string, kita harus pakai `dio` atau package lain. Itu scope PR terpisah.

- [ ] **Step 4: Tambah dokumentasi inline di ApiClient**

Tambah komentar di atas method `multipart`:
```dart
/// Catatan: [fields] adalah Map<String,String>. Untuk field array Laravel
/// (`key[]=v1&key[]=v2`), kirim sebagai JSON string: `fields['key'] = jsonEncode([v1,v2])`.
/// Backend harus parsing via json_decode($request->input('key')). Lihat
/// ProcurementService.createPaymentReceipt untuk contoh.
```

- [ ] **Step 5: Update Task 1.1 Step 10 (`createPaymentReceipt`) pakai JSON string**

```dart
Future<PaymentReceipt> createPaymentReceipt({
  required List<int> invoiceIds,
  required int transferAmount,
  int? totalAmount,
  String? notes,
  File? image,
}) async {
  final fields = <String, String>{
    'invoice_ids': jsonEncode(invoiceIds),  // JSON string, backend json_decode
    'transfer_amount': transferAmount.toString(),
  };
  if (totalAmount != null) fields['total_amount'] = totalAmount.toString();
  if (notes != null) fields['notes'] = notes;
  if (image != null) {
    final path = await ImageUploadService.upload(image, directory: 'images/PaymentReceipt');
    if (path == null) throw Exception('Gagal upload gambar ke img service.');
    fields['image'] = path;
  }

  final data = await _api.multipart(method: 'POST', path: 'procurement/payment-receipts', fields: fields);
  return PaymentReceipt.fromJson(data as Map<String, dynamic>);
}
```

Lakukan sama untuk `createFuelServicePaymentReceipt` (`fuel_service_ids`).

- [ ] **Step 6: Koordinasi backend & smoke test**

Sebelum commit, **engineer wajib** koordinasi dengan backend untuk memastikan endpoint `POST /procurement/payment-receipts` dan `POST /procurement/fuel-service-payment-receipts` menerima `invoice_ids`/`fuel_service_ids` sebagai JSON string. Jika backend sudah handle via `$request->input('invoice_ids')` dengan auto-cast array di Laravel, JSON string akan otomatis ter-parse. Jika tidak, backend perlu update.

- [ ] **Step 7: Commit**

```bash
git add lib/services/api_client.dart lib/services/procurement_service.dart
git commit -m "refactor(api-client): document array field convention; migrate procurement multipart"
```

---

### Task 1.2: Helper migration pattern (referensi cepat)

> Tidak ada langkah. Ini adalah **ringkasan pola** yang dipakai berulang di Task 1.3+. Engineer bisa kembali ke sini kapan saja.

**Pola A — GET list (response `{success, data:[...]}`):**
```dart
Future<List<Model>> getItems() async {
  final data = await _api.get('items');
  return ((data as List?) ?? [])
      .map((j) => Model.fromJson(j as Map<String, dynamic>))
      .toList();
}
```

**Pola B — GET list dengan pagination meta (response punya `meta`/`pagination`):**
```dart
Future<PaginatedResult<Model>> getItems({int page = 1, int perPage = 10}) async {
  final body = await _api.getRaw('items', queryParams: {
    'page': page.toString(), 'per_page': perPage.toString(),
  });
  final List items = body['data'] ?? [];
  final meta = (body['meta'] as Map<String, dynamic>?) ?? {};
  return PaginatedResult(
    items: items.map((j) => Model.fromJson(j as Map<String, dynamic>)).toList(),
    currentPage: meta['current_page'] ?? 1,
    lastPage: meta['last_page'] ?? 1,
    perPage: meta['per_page'] ?? perPage,
    total: meta['total'] ?? 0,
  );
}
```

**Pola C — GET detail (`{success, data:{...}}`):**
```dart
Future<Model> getItem(int id) async {
  final data = await _api.get('items/$id');
  return Model.fromJson(data as Map<String, dynamic>);
}
```

**Pola D — POST create (return Model):**
```dart
Future<Model> createItem(Map<String, dynamic> payload) async {
  final data = await _api.post('items', body: payload);
  return Model.fromJson(data as Map<String, dynamic>);
}
```

**Pola E — POST action (return bool):**
```dart
Future<bool> approveItem(int id) async {
  await _api.post('items/$id/approve');
  return true;
}
```

**Pola F — PUT update:**
```dart
Future<Model> updateItem(int id, Map<String, dynamic> payload) async {
  final data = await _api.put('items/$id', body: payload);
  return Model.fromJson(data as Map<String, dynamic>);
}
```

**Pola G — DELETE:**
```dart
Future<void> deleteItem(int id) async {
  await _api.delete('items/$id');
}
```

**Pola H — Multipart dengan image upload:**
```dart
Future<Model> uploadItem(File image, {String? name}) async {
  final fields = <String, String>{};
  if (name != null) fields['name'] = name;

  // Upload gambar via img service terlebih dahulu (existing pattern)
  final path = await ImageUploadService.upload(image, directory: 'images/Item');
  if (path == null) throw Exception('Gagal upload gambar.');
  fields['image'] = path;

  final data = await _api.multipart(method: 'POST', path: 'items', fields: fields);
  return Model.fromJson(data as Map<String, dynamic>);
}
```

---

### Task 1.3: Migrate `sales_dashboard_service.dart`

**Files:**
- Modify: `lib/services/sales_dashboard_service.dart`

- [ ] **Step 1: Baca file dan identifikasi method-methodnya**

Run: `cat lib/services/sales_dashboard_service.dart`

Identifikasi: setiap method punya pola `_getToken()` + `_headers()` + raw `http`. Catat endpoint dan return type tiap method.

- [ ] **Step 2: Terapkan Pola A-G (lihat Task 1.2) untuk setiap method**

Hapus `_getToken`, `_headers`, import `shared_preferences`, import `http`. Tambah `final ApiClient _api = ApiClient();`. Migrasi setiap method sesuai pola yang cocok.

- [ ] **Step 3: Verifikasi**

```bash
flutter analyze lib/services/sales_dashboard_service.dart 2>&1 | tail -10
```

Expected: 0 error.

- [ ] **Step 4: Commit**

```bash
git add lib/services/sales_dashboard_service.dart
git commit -m "refactor(service): migrate sales_dashboard_service to ApiClient"
```

---

### Task 1.4: Migrate `presence_service.dart`

**Files:**
- Modify: `lib/services/presence_service.dart`

> **Catatan khusus:** `presence_service.dart` memakai `static getToken()` (static method) yang dipanggil di ≥13 tempat di file yang sama. Selain itu service ini dipakai oleh `PresenceController` (yang akan dihapus di Phase 3) dan `PresenceProvider`. Setelah migrasi, pastikan tidak ada static method `getToken` tersisa.

- [ ] **Step 1: Hapus `static getToken()` dan ganti pemanggilannya**

Karena `ApiClient` sudah handle token internal, semua pemanggilan `PresenceService.getToken()` di dalam file ini dihapus. Method-method yang memakai token langsung diubah ke `_api.get/post/...`.

- [ ] **Step 2: Ubah class jadi instance-based dengan `ApiClient` field**

```dart
class PresenceService {
  final ApiClient _api = ApiClient();
  // ...
}
```

> **Peringatan:** jika ada caller di luar file yang memanggil `PresenceService.getToken()` secara static, itu akan break. Cari dulu:
> ```bash
> grep -rn "PresenceService.getToken" lib/
> ```
> Jika ada, hapus pemanggilan itu (caller lain harus ambil token via `ApiClient` atau langsung dari `SharedPreferences` di tempat yang spesifik membutuhkan).

- [ ] **Step 3: Migrasi semua method sesuai pola (Task 1.2)**

- [ ] **Step 4: Verifikasi tidak ada lagi static getToken**

```bash
grep -n "static.*getToken\|PresenceService.getToken" lib/services/presence_service.dart lib/
```

Expected: 0 hasil di `lib/services/presence_service.dart`. Untuk hasil di luar, perlu refactor terpisah (catat sebagai TODO di commit message jika ada).

- [ ] **Step 5: Verifikasi analyze & commit**

```bash
flutter analyze lib/services/presence_service.dart 2>&1 | tail -10
git add lib/services/presence_service.dart
git commit -m "refactor(service): migrate presence_service to ApiClient; remove static getToken"
```

---

### Task 1.5: Migrate `auth_service.dart`

**Files:**
- Modify: `lib/services/auth_service.dart`

> **Catatan khusus:** `auth_service.dart` mungkin punya method `login` yang TIDAK memakai token (karena belum login). Verifikasi: apakah `_handleResponse` ApiClient OK dengan request tanpa token? Ya — `_headers()` mengecek `if (token != null)`, jadi header Authorization dilewati jika tidak ada token. Login/register dapat pakai `ApiClient` tanpa masalah.

- [ ] **Step 1: Identifikasi method login/register/refresh/logout**

```bash
cat lib/services/auth_service.dart
```

- [ ] **Step 2: Migrasi sesuai pola. Untuk method yang menyimpan token ke SharedPreferences (`login`, `register`), pertahankan logic penyimpanan token — itu masih valid.**

Contoh `login`:
```dart
Future<Map<String, dynamic>> login(String email, String password) async {
  final data = await _api.post('auth/login', body: {
    'email': email, 'password': password,
  });
  // Simpan token
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(AppConstants.tokenKey, data['token']);
  return data;
}
```

> **Penting:** method login kemungkinan masih butuh akses `SharedPreferences` untuk **menyimpan** token (bukan membaca). Import `shared_preferences` tetap dipertahankan di `auth_service.dart`. Yang dihapus hanya `_getToken()` (method baca token).

- [ ] **Step 3: Verifikasi & commit**

```bash
flutter analyze lib/services/auth_service.dart 2>&1 | tail -10
git add lib/services/auth_service.dart
git commit -m "refactor(service): migrate auth_service to ApiClient (write token still via SharedPreferences)"
```

---

### Task 1.6: Migrate batch sederhana (leave, salary, store, hygiene)

**Files (4 services, masing-masing satu commit):**
- Modify: `lib/services/leave_service.dart`
- Modify: `lib/services/salary_service.dart`
- Modify: `lib/services/store_service.dart`
- Modify: `lib/services/hygiene_service.dart`

Service-service ini mengikuti pola seragam: inline `SharedPreferences.getInstance().getString('token')` + raw `http`. Migrasi langsung.

- [ ] **Step 1: Untuk setiap service, jalankan loop berikut (1 commit per service):**

Untuk `leave_service.dart`:
1. Baca file. Identifikasi method.
2. Hapus inline token-read. Tambah `final ApiClient _api = ApiClient();`.
3. Hapus import `http`, `shared_preferences` (jika hanya untuk baca token).
4. Migrasi setiap method sesuai pola (Task 1.2).
5. `flutter analyze lib/services/leave_service.dart` → 0 error.
6. `git add lib/services/leave_service.dart && git commit -m "refactor(service): migrate leave_service to ApiClient"`.

- [ ] **Step 2: Ulangi Step 1 untuk `salary_service.dart`**

Commit: `refactor(service): migrate salary_service to ApiClient`

- [ ] **Step 3: Ulangi Step 1 untuk `store_service.dart`**

Commit: `refactor(service): migrate store_service to ApiClient`

- [ ] **Step 4: Ulangi Step 1 untuk `hygiene_service.dart`**

Commit: `refactor(service): migrate hygiene_service to ApiClient`

---

### Task 1.7: Migrate batch image & upload services

**Files:**
- Modify: `lib/services/image_upload_service.dart`
- Modify: `lib/services/sales_order_service.dart`
- Modify: `lib/services/sales_order_employee_service.dart`

- [ ] **Step 1: `image_upload_service.dart`**

Baca file. Ini upload gambar ke img service (bukan backend utama). Verifikasi apakah base URL sama dengan `ApiConstants.baseUrl` atau berbeda (`IMG_SERVICE_URL`).

> **Jika img service punya base URL berbeda:** `ApiClient` saat ini hardcoded ke `ApiConstants.baseUrl`. `image_upload_service.dart` TIDAK bisa pakai `ApiClient` untuk upload ke img service. **Solusi:** biarkan `image_upload_service.dart` pakai raw `http` (di luar scope migrasi — tambah catatan ke PRD bahwa img service adalah endpoint terpisah).
>
> **Jika ternyata via backend utama:** migrasi pakai Pola H (multipart).

Verifikasi:
```bash
grep -n "baseUrl\|IMG_SERVICE_URL\|Uri.parse" lib/services/image_upload_service.dart | head -10
```

- [ ] **Step 2: Commit berdasarkan temuan Step 1**

Jika tidak dimigrasi (endpoint berbeda):
```bash
git commit --allow-empty -m "docs(service): image_upload_service uses separate img service endpoint; out of ApiClient scope"
```

Jika dimigrasi:
```bash
git add lib/services/image_upload_service.dart
git commit -m "refactor(service): migrate image_upload_service to ApiClient"
```

- [ ] **Step 3: Migrate `sales_order_service.dart` sesuai pola**

```bash
flutter analyze lib/services/sales_order_service.dart 2>&1 | tail -10
git add lib/services/sales_order_service.dart
git commit -m "refactor(service): migrate sales_order_service to ApiClient"
```

- [ ] **Step 4: Migrate `sales_order_employee_service.dart` sesuai pola**

```bash
flutter analyze lib/services/sales_order_employee_service.dart 2>&1 | tail -10
git add lib/services/sales_order_employee_service.dart
git commit -m "refactor(service): migrate sales_order_employee_service to ApiClient"
```

---

### Task 1.8: Migrate batch production cluster

**Files:**
- Modify: `lib/services/production_service.dart`
- Modify: `lib/services/recipe_service.dart`
- Modify: `lib/services/readiness_service.dart`

- [ ] **Step 1: Untuk setiap service, ikuti pola Task 1.6 (1 commit per service)**

1. `production_service.dart` → commit `refactor(service): migrate production_service to ApiClient`
2. `recipe_service.dart` → commit `refactor(service): migrate recipe_service to ApiClient`
3. `readiness_service.dart` → commit `refactor(service): migrate readiness_service to ApiClient`

Setelah masing-masing, jalankan `flutter analyze lib/services/X_service.dart 2>&1 | tail -10` (expected 0 error).

---

### Task 1.9: Migrate batch asset cluster

**Files:**
- Modify: `lib/services/asset_service.dart`
- Modify: `lib/services/asset_check_service.dart`
- Modify: `lib/services/asset_issue_service.dart`

- [ ] **Step 1: Untuk setiap service, ikuti pola Task 1.6 (1 commit per service)**

1. `asset_service.dart` → commit `refactor(service): migrate asset_service to ApiClient`
2. `asset_check_service.dart` → commit `refactor(service): migrate asset_check_service to ApiClient`
3. `asset_issue_service.dart` → commit `refactor(service): migrate asset_issue_service to ApiClient`

---

### Task 1.10: Migrate batch stock & ops cluster

**Files:**
- Modify: `lib/services/storage_stock_service.dart`
- Modify: `lib/services/transfer_stock_service.dart`
- Modify: `lib/services/closing_store_service.dart`
- Modify: `lib/services/inventory_anomaly_service.dart`

- [ ] **Step 1: Untuk setiap service, ikuti pola Task 1.6 (1 commit per service)**

1. `storage_stock_service.dart` → `refactor(service): migrate storage_stock_service to ApiClient`
2. `transfer_stock_service.dart` → `refactor(service): migrate transfer_stock_service to ApiClient`
3. `closing_store_service.dart` → `refactor(service): migrate closing_store_service to ApiClient`
4. `inventory_anomaly_service.dart` → `refactor(service): migrate inventory_anomaly_service to ApiClient`

---

### Task 1.11: Audit Phase 1c (service yang perlu tinjauan)

**Files (evaluasi, mungkin tidak diubah):**
- Audit: `lib/services/user_service.dart`
- Audit: `lib/services/version_service.dart`
- Audit: `lib/services/location_service.dart`
- Audit: `lib/services/calendar_service.dart`
- Audit: `lib/services/fake_gps_detection/services/*.dart`

- [ ] **Step 1: Audit `user_service.dart`**

```bash
grep -nE "http\.|_getToken|getToken|SharedPreferences|Authorization" lib/services/user_service.dart
```

Identifikasi endpoint yang dipanggil. Jika endpoint butuh auth → migrate pakai `ApiClient`. Jika publik → biarkan raw `http` tapi tambahkan komentar `// Public endpoint, no auth needed` dan dokumentasikan di PRD.

- [ ] **Step 2: Audit `version_service.dart`**

```bash
head -40 lib/services/version_service.dart
grep -n "ApiConstants\|baseUrl\|Authorization" lib/services/version_service.dart
```

Endpoint `ApiConstants.appVersion` kemungkinan publik. Jika ya → tambahkan komentar dan dokumentasikan. Tidak perlu migrasi.

- [ ] **Step 3: Audit `location_service.dart` dan `calendar_service.dart`**

Lakukan grep yang sama. Keputusan: migrate / biarkan / keluarkan dari scope. Catat di commit.

- [ ] **Step 4: Audit `fake_gps_detection/services/*.dart`**

```bash
ls lib/services/fake_gps_detection/services/
for f in lib/services/fake_gps_detection/services/*.dart; do
  echo "=== $f ==="
  grep -cE "http\.|_getToken|SharedPreferences" "$f"
done
```

Untuk setiap sub-service yang memanggil backend, migrate. Untuk yang tidak, dokumentasikan.

- [ ] **Step 5: Commit hasil audit**

```bash
git add -A
git commit -m "chore(service): audit Phase 1c services; document endpoint auth requirements"
```

---

### Task 1.12: Verifikasi akhir Phase 1

**Files:** tidak ada perubahan.

- [ ] **Step 1: Grep verifikasi sukses metric**

Run:
```bash
echo "=== _getToken/getToken di services ==="
grep -rE "_getToken|getToken" lib/services/ | grep -v "api_client.dart" | wc -l
echo "=== raw http di services ==="
grep -lE "http\.(get|post|put|delete)" lib/services/*.dart | grep -v "api_client.dart"
echo "=== import shared_preferences di services ==="
grep -l "shared_preferences" lib/services/*.dart
```

Expected:
- `_getToken/getToken`: 0 (di luar `api_client.dart`)
- Raw `http.*` di `lib/services/*.dart`: hanya file yang didokumentasikan di Phase 1c/1d (mis. `version_service.dart` jika endpoint publik)
- `shared_preferences` di service: hanya `auth_service.dart` (untuk write token saat login)

- [ ] **Step 2: Full analyze & test**

```bash
flutter analyze 2>&1 | tail -10
flutter test 2>&1 | tail -10
```

Expected: analyze ≤ baseline issues, test All passed.

- [ ] **Step 3: Smoke test manual di emulator (critical path)**

Jalankan app, lakukan login, buka halaman procurement, presence, sales dashboard. Verifikasi fitur dasar masih jalan.

- [ ] **Step 4: Tag commit Phase 1 selesai**

```bash
git tag phase1-service-consolidation
```

---

## PHASE 2: Provider (sebelum hapus controllers)

> **Tujuan:** siapkan Provider yang akan menampung logic controller sebelum `controllers/` dihapus. Setelah Phase 2 selesai, Provider siap dipakai page (Phase 4), dan controller dapat dihapus (Phase 3).

### Task 2.0: Provider baseline test

**Files:** tidak ada perubahan.

- [ ] **Step 1: Catat baseline test provider yang ada**

```bash
flutter test test/providers/ 2>&1 | tail -10
```

---

### Task 2.1: Perluas `PresenceProvider` untuk menampung `PresenceController` logic

**Files:**
- Modify: `lib/providers/presence_provider.dart` (saat ini 56 baris, minimalis)
- Modify: `lib/controllers/presence_controller.dart` (baca referensi, jangan hapus dulu)
- Test: `test/providers/presence_provider_test.dart`

> **Sumber logic:** baca `lib/controllers/presence_controller.dart` (140 baris). Method yang perlu dipindahkan: `loadInitialData`, `getCurrentLocation`, `validateStoreLocation`, `submitPresence`. **Navigation dan snackbar TIDAK dipindah ke Provider** — itu tetap di widget.

- [ ] **Step 1: Tulis failing test untuk `PresenceProvider`**

Create: `test/providers/presence_provider_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/providers/presence_provider.dart';

void main() {
  group('PresenceProvider', () {
    test('initial state idle, no presence, no error', () {
      final p = PresenceProvider();
      expect(p.state, PresenceState.idle);
      expect(p.todayPresence, isNull);
      expect(p.stores, isEmpty);
      expect(p.shiftStores, isEmpty);
      expect(p.errorMessage, isNull);
      expect(p.isLoading, isFalse);
      expect(p.hasError, isFalse);
    });

    test('reset mengembalikan ke idle dan clear data', () {
      final p = PresenceProvider();
      // paksa state seolah-olah error
      // (tidak bisa set private field langsung; skip jika tidak ada setter)
      p.reset();
      expect(p.state, PresenceState.idle);
      expect(p.errorMessage, isNull);
    });

    // Catatan: test loadInitialData/submitPresence butuh mock service.
    // Karena PresenceService pakai ApiClient yang tidak di-inject, skip
    // integration test di sini. Tambahan: refactor service untuk DI
    // adalah PR terpisah.
  });
}
```

- [ ] **Step 2: Run test, verifikasi merah**

```bash
flutter test test/providers/presence_provider_test.dart 2>&1 | tail -20
```

Expected: FAIL dengan error `PresenceState not defined` atau `method reset not found` — karena provider belum diubah.

- [ ] **Step 3: Perluas `PresenceProvider`**

Ganti isi `lib/providers/presence_provider.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/store_model.dart';
import '../models/shift_store_model.dart';
import '../services/presence_service.dart';

enum PresenceState { idle, loading, success, error }

class PresenceProvider extends ChangeNotifier {
  final PresenceService _service = PresenceService();

  // State
  PresenceState _state = PresenceState.idle;
  List<Store> _stores = [];
  List<ShiftStore> _shiftStores = [];
  dynamic _todayPresence; // disesuaikan dengan tipe sebenarnya
  String? _errorMessage;
  Position? _currentLocation;

  // Getters
  PresenceState get state => _state;
  List<Store> get stores => _stores;
  List<ShiftStore> get shiftStores => _shiftStores;
  dynamic get todayPresence => _todayPresence;
  String? get errorMessage => _errorMessage;
  Position? get currentLocation => _currentLocation;
  bool get isLoading => _state == PresenceState.loading;
  bool get hasError => _state == PresenceState.error;

  // Actions — dipindahkan dari PresenceController (tanpa BuildContext)
  Future<void> loadInitialData() async {
    _state = PresenceState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _service.loadInitialData();
      // result: {stores: [...], shiftStores: [...]} — sesuaikan dengan signature service
      // Jika service tidak punya loadInitialData, panggil getStores + getShiftStores
      _stores = result['stores'] as List<Store>;
      _shiftStores = result['shiftStores'] as List<ShiftStore>;
      _state = PresenceState.success;
    } catch (e) {
      _errorMessage = _parseError(e);
      _state = PresenceState.error;
    }
    notifyListeners();
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi tidak aktif.');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak.');
      }
      _currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseError(e);
      _state = PresenceState.error;
      notifyListeners();
    }
  }

  Future<bool> submitPresence({
    required int storeId,
    required int shiftStoreId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    _state = PresenceState.loading;
    notifyListeners();
    try {
      await _service.submitPresence(
        storeId: storeId,
        shiftStoreId: shiftStoreId,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );
      _state = PresenceState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _state = PresenceState.error;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _state = PresenceState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring('Exception: '.length) : s;
  }
}
```

> **Catatan penting:** signature service `_service.loadInitialData()`, `_service.submitPresence(...)` diasumsikan. **Engineer WAJIB menyesuaikan** dengan method aktual di `lib/services/presence_service.dart` setelah Phase 1 selesai. Jika service tidak punya method `loadInitialData`, pecah jadi `_service.getStores()` + `_service.getShiftStores()`.

- [ ] **Step 4: Run test, verifikasi hijau**

```bash
flutter test test/providers/presence_provider_test.dart 2>&1 | tail -10
```

Expected: PASS.

- [ ] **Step 5: Analyze**

```bash
flutter analyze lib/providers/presence_provider.dart 2>&1 | tail -10
```

Expected: 0 error.

- [ ] **Step 6: Commit**

```bash
git add lib/providers/presence_provider.dart test/providers/presence_provider_test.dart
git commit -m "feat(provider): expand PresenceProvider to absorb PresenceController logic"
```

---

### Task 2.2: Tambah `loadHomeData` ke `AuthProvider` (untuk `HomeController`)

**Files:**
- Modify: `lib/providers/auth_provider.dart`
- Test: `test/providers/auth_provider_test.dart` (create jika belum ada)
- Reference: baca `lib/controllers/home_controller.dart` (87 baris)

`HomeController.loadUserInfo()` membaca dari SharedPreferences (`loginDataKey`), `loadPresenceData()` memanggil PresenceService, `checkActiveLeave()` memanggil LeaveService. Logic ini pindah ke `AuthProvider`.

- [ ] **Step 1: Baca `home_controller.dart` & `auth_provider.dart`**

```bash
cat lib/controllers/home_controller.dart
cat lib/providers/auth_provider.dart
```

- [ ] **Step 2: Tulis failing test**

Create atau extend: `test/providers/auth_provider_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sagansa/providers/auth_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'login_data': '{"data":{"user":{"name":"Budi","company":{"name":"SAGANSA"}}}}',
    });
  });

  group('AuthProvider home data', () {
    test('loadUserInfo mengisi userName dan companyName dari SharedPreferences', () async {
      final p = AuthProvider();
      await p.loadUserInfo();
      expect(p.userName, 'Budi');
      expect(p.companyName, 'SAGANSA');
    });

    test('userName default string kosong jika login_data tidak ada', () async {
      SharedPreferences.setMockInitialValues({});
      final p = AuthProvider();
      await p.loadUserInfo();
      expect(p.userName, '');
    });
  });
}
```

- [ ] **Step 3: Run test, verifikasi merah**

```bash
flutter test test/providers/auth_provider_test.dart 2>&1 | tail -20
```

Expected: FAIL (`loadUserInfo` not found atau field tidak ada).

- [ ] **Step 4: Implementasi di `AuthProvider`**

Tambah ke `lib/providers/auth_provider.dart`:
```dart
Map<String, String>? _cachedUserInfo;

String get userName => _cachedUserInfo?['userName'] ?? '';
String get companyName => _cachedUserInfo?['companyName'] ?? 'SAGANSA';

Future<void> loadUserInfo() async {
  if (_cachedUserInfo != null) return;
  final prefs = await SharedPreferences.getInstance();
  final loginDataString = prefs.getString(AppConstants.loginDataKey);
  if (loginDataString != null) {
    final loginData = json.decode(loginDataString);
    final userData = loginData['data']?['user'] ?? {};
    _cachedUserInfo = {
      'userName': userData['name'] ?? '',
      'companyName': userData['company']?['name'] ?? 'SAGANSA',
    };
    notifyListeners();
  }
}
```

> Tambahkan import: `dart:convert`, `shared_preferences`, `constants.dart` jika belum ada. Sesuaikan struktur JSON dengan aktual `login_data` (baca `home_controller.dart` baris 17-30 untuk konfirmasi struktur).

- [ ] **Step 5: Run test, verifikasi hijau, analyze, commit**

```bash
flutter test test/providers/auth_provider_test.dart 2>&1 | tail -10
flutter analyze lib/providers/auth_provider.dart 2>&1 | tail -5
git add lib/providers/auth_provider.dart test/providers/auth_provider_test.dart
git commit -m "feat(provider): add loadUserInfo to AuthProvider for HomeController absorption"
```

---

### Task 2.3: Buat `LeaveProvider` (untuk `LeaveController`)

**Files:**
- Create: `lib/providers/leave_provider.dart`
- Test: `test/providers/leave_provider_test.dart`
- Reference: `lib/controllers/leave_controller.dart` (78 baris)

- [ ] **Step 1: Baca `leave_controller.dart` & `leave_service.dart`**

Identifikasi method dan state yang dikelola controller.

- [ ] **Step 2: Tulis failing test**

Create: `test/providers/leave_provider_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/providers/leave_provider.dart';

void main() {
  group('LeaveProvider', () {
    test('initial state idle', () {
      final p = LeaveProvider();
      expect(p.state, LeaveState.idle);
      expect(p.leaves, isEmpty);
      expect(p.errorMessage, isNull);
      expect(p.isLoading, isFalse);
    });

    test('reset clears state', () {
      final p = LeaveProvider();
      p.reset();
      expect(p.state, LeaveState.idle);
      expect(p.errorMessage, isNull);
    });
  });
}
```

- [ ] **Step 3: Run, verifikasi merah**

- [ ] **Step 4: Implementasi `LeaveProvider`**

Ikuti template PRD Section 4.3C. Tambahkan method sesuai logic `LeaveController` (tanpa BuildContext — navigation/snackbar tetap di widget).

- [ ] **Step 5: Run test, analyze, commit**

```bash
git add lib/providers/leave_provider.dart test/providers/leave_provider_test.dart
git commit -m "feat(provider): add LeaveProvider"
```

---

### Task 2.4: Buat `AssetProvider` (untuk `AssetController`)

**Files:**
- Create: `lib/providers/asset_provider.dart`
- Test: `test/providers/asset_provider_test.dart`
- Reference: `lib/controllers/asset_controller.dart` (266 baris — paling besar)

- [ ] **Step 1: Baca `asset_controller.dart`**

```bash
cat lib/controllers/asset_controller.dart
```

Identifikasi semua method & state. Catat yang butuh context (Navigator, ScaffoldMessenger) — itu **tidak ikut** ke provider, tetap di widget.

- [ ] **Step 2: Tulis failing test (initial state + reset)**

Create: `test/providers/asset_provider_test.dart` — ikuti template Task 2.3 Step 2.

- [ ] **Step 3: Implementasi `AssetProvider`**

> **Catatan:** `asset_controller.dart` relatif besar (266 baris). Mungkin logic-nya perlu dipecah menjadi beberapa method di provider. Engineer pertimbangkan: apakah satu provider cukup, atau perlu beberapa provider (mis. `AssetListProvider`, `AssetFormProvider`). Default: satu provider dulu, pecah nanti jika terbukti terlalu besar saat dipakai.

- [ ] **Step 4: Run test, analyze, commit**

```bash
git add lib/providers/asset_provider.dart test/providers/asset_provider_test.dart
git commit -m "feat(provider): add AssetProvider"
```

---

### Task 2.5: Buat `ProcurementProvider`

**Files:**
- Create: `lib/providers/procurement_provider.dart`
- Test: `test/providers/procurement_provider_test.dart`

> Procurement belum punya controller — page langsung pakai `ProcurementService`. Buat provider untuk state management yang lebih rapi.

- [ ] **Step 1: Audit page procurement yang ada**

```bash
ls lib/pages/procurement_*.dart
grep -l "ProcurementService" lib/pages/*.dart
```

Identifikasi state yang saat ini dikelola via `setState` di page procurement (loading, list, error, pagination).

- [ ] **Step 2: Tulis failing test**

Create: `test/providers/procurement_provider_test.dart` — initial state + reset (template Task 2.3).

- [ ] **Step 3: Implementasi `ProcurementProvider`**

Method minimal:
- `loadProducts()`, `loadRequests({page, perPage})`, `loadInvoices({page, perPage})`
- `approveItem(id)`, `rejectItem(id)`, `cancelItem(id)`, `receiveInvoice(id)`
- State: `_products`, `_requests`, `_invoices`, `_state`, `_errorMessage`
- Pagination state untuk infinite scroll (`_currentPage`, `_hasMore`, `loadMore()`)

- [ ] **Step 4: Run, analyze, commit**

```bash
git add lib/providers/procurement_provider.dart test/providers/procurement_provider_test.dart
git commit -m "feat(provider): add ProcurementProvider"
```

---

### Task 2.6: Buat `SalesDashboardProvider`

**Files:**
- Create: `lib/providers/sales_dashboard_provider.dart`
- Test: `test/providers/sales_dashboard_provider_test.dart`

- [ ] **Step 1: Audit page sales dashboard & service**

```bash
ls lib/pages/sales_dashboard*.dart 2>/dev/null
grep -l "SalesDashboardService" lib/pages/*.dart
cat lib/services/sales_dashboard_service.dart
```

- [ ] **Step 2: Tulis failing test, implementasi, commit (template Task 2.5)**

Commit: `feat(provider): add SalesDashboardProvider`

---

## PHASE 3: Hapus `controllers/`

> **Prasyarat:** Phase 2 selesai (Provider sudah ada & ter-tested). Phase 4 (page refactor) dilakukan **bersamaan** dengan Phase 3 — setiap controller dihapus setelah page yang memakainya sudah direfactor ke Provider.

### Task 3.0: Inventory caller controller

**Files:** tidak ada perubahan.

- [ ] **Step 1: Cari semua pemanggil controller**

```bash
echo "=== HomeController ==="
grep -rln "HomeController" lib/
echo "=== PresenceController ==="
grep -rln "PresenceController" lib/
echo "=== LeaveController ==="
grep -rln "LeaveController" lib/
echo "=== AssetController ==="
grep -rln "AssetController" lib/
```

Catat semua file page yang memakai controller. Ini adalah target refactor di Phase 4.

---

### Task 3.1: Hapus `home_controller.dart` (setelah page direfactor)

> **Urutan eksekusi:** Task 4.1 (refactor home page) → Task 3.1 (hapus controller).

- [ ] **Step 1: Verifikasi tidak ada lagi import HomeController**

```bash
grep -rn "home_controller\|HomeController" lib/
```

Expected: hanya `lib/controllers/home_controller.dart` sendiri. Jika masih ada import di file lain → Task 4.1 belum selesai, kembali ke sana.

- [ ] **Step 2: Hapus file**

```bash
git rm lib/controllers/home_controller.dart
```

- [ ] **Step 3: Verifikasi analyze & test**

```bash
flutter analyze 2>&1 | tail -10
flutter test 2>&1 | tail -10
```

Expected: 0 error baru, test pass.

- [ ] **Step 4: Commit**

```bash
git commit -m "refactor(controllers): remove home_controller (logic moved to AuthProvider)"
```

---

### Task 3.2: Hapus `presence_controller.dart` (setelah Task 4.2)

- [ ] **Step 1: Verifikasi tidak ada import**

```bash
grep -rn "presence_controller\|PresenceController" lib/
```

Expected: hanya file controller sendiri.

- [ ] **Step 2: Hapus & commit**

```bash
git rm lib/controllers/presence_controller.dart
flutter analyze 2>&1 | tail -10
git commit -m "refactor(controllers): remove presence_controller (logic moved to PresenceProvider)"
```

---

### Task 3.3: Hapus `leave_controller.dart` (setelah Task 4.3)

```bash
grep -rn "leave_controller\|LeaveController" lib/  # verify 0 imports
git rm lib/controllers/leave_controller.dart
flutter analyze 2>&1 | tail -10
git commit -m "refactor(controllers): remove leave_controller (logic moved to LeaveProvider)"
```

---

### Task 3.4: Hapus `asset_controller.dart` (setelah Task 4.4)

```bash
grep -rn "asset_controller\|AssetController" lib/  # verify 0 imports
git rm lib/controllers/asset_controller.dart
flutter analyze 2>&1 | tail -10
git commit -m "refactor(controllers): remove asset_controller (logic moved to AssetProvider)"
```

---

### Task 3.5: Hapus folder `controllers/` jika kosong

- [ ] **Step 1: Verifikasi kosong**

```bash
ls lib/controllers/
```

Expected: kosong (tidak ada output).

- [ ] **Step 2: Hapus folder**

```bash
rmdir lib/controllers/ 2>/dev/null || echo "Folder tidak kosong — cek manual"
```

> Folder kosong tidak terlacak di git, jadi tidak perlu commit. Tapi pastikan `lib/controllers/` tidak ada di disk.

- [ ] **Step 3: Tag akhir Phase 3**

```bash
git tag phase3-controllers-removed
```

---

## PHASE 4: Page Refactor

> **Prasyarat:** Phase 2 selesai. Page refactor dan hapus controller berjalan bergantian per fitur.

### Task 4.0: Page Refactor Matrix

Daftar page yang perlu direfactor (urutan prioritas). Setiap baris = satu task refactor (4.x).

| Task | Page file | Controller lama | Provider baru | Prioritas |
|------|-----------|-----------------|---------------|-----------|
| 4.1 | `lib/pages/home_page.dart` (atau `dashboard_page.dart`) | `HomeController` | `AuthProvider` + `PresenceProvider` | Tinggi |
| 4.2 | `lib/pages/presence_page.dart` | `PresenceController` | `PresenceProvider` | Tinggi |
| 4.3 | `lib/pages/leave_page.dart` (atau `*_list_page.dart`) | `LeaveController` | `LeaveProvider` | Tinggi |
| 4.4 | `lib/pages/asset_*_page.dart` (multiple) | `AssetController` | `AssetProvider` | Tinggi |
| 4.5 | `lib/pages/procurement_*.dart` (multiple) | (langsung service) | `ProcurementProvider` | Sedang |
| 4.6 | `lib/pages/sales_dashboard*.dart` | (langsung service) | `SalesDashboardProvider` | Sedang |

> **Catatan:** nama file page aktual mungkin berbeda. Engineer WAJIB identifikasi via grep di awal tiap task.

---

### Task 4.1: Refactor home page → pakai `AuthProvider.loadUserInfo`

**Files:**
- Modify: `lib/pages/home_page.dart` (atau nama aktual — verifikasi via grep)

- [ ] **Step 1: Identifikasi page aktual**

```bash
grep -rln "HomeController" lib/pages/
```

- [ ] **Step 2: Baca page & controller untuk mapping logic**

```bash
cat lib/pages/<home_page_aktual>.dart
cat lib/controllers/home_controller.dart
```

- [ ] **Step 3: Refactor — hapus `HomeController`, pakai `AuthProvider` + `PresenceProvider`**

Pola refactor:
1. Hapus import `HomeController` dan field `_controller`.
2. Hapus `_controller = HomeController(context)` di `initState`.
3. Ganti pemanggilan `_controller.loadUserInfo()` → `context.read<AuthProvider>().loadUserInfo()`.
4. Ganti baca state `_controller.userName` → `context.watch<AuthProvider>().userName`.
5. Untuk presence data & leave data → gunakan `PresenceProvider` (jika global) atau buat lokal di page.
6. Navigation/snackbar yang sebelumnya di controller → pindah ke widget event handler.

- [ ] **Step 4: Verifikasi analyze & manual smoke**

```bash
flutter analyze lib/pages/<home_page>.dart 2>&1 | tail -10
flutter test 2>&1 | tail -5
```

Jalankan app, buka home page, verifikasi user info muncul, presence/leave data ter-load.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/<home_page>.dart
git commit -m "refactor(page): home page uses AuthProvider instead of HomeController"
```

- [ ] **Step 6: Lanjut ke Task 3.1 (hapus home_controller)**

---

### Task 4.2: Refactor presence page → pakai `PresenceProvider`

**Files:**
- Modify: `lib/pages/presence_page.dart` (atau nama aktual)

- [ ] **Step 1: Identifikasi page aktual & baca controller**

```bash
grep -rln "PresenceController" lib/pages/
cat lib/controllers/presence_controller.dart
```

- [ ] **Step 2: Pilih registrasi provider**

Decision: apakah `PresenceProvider` page-level atau perlu jadi global?

Default: **page-level** (jika hanya presence_page yang pakai). Tambah ke widget tree:
```dart
class PresencePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PresenceProvider(),
      child: const _PresenceView(),
    );
  }
}
```

- [ ] **Step 3: Refactor page**

Hapus `PresenceController`. Pakai `context.read<PresenceProvider>()` untuk action, `context.watch<PresenceProvider>()` untuk state. Tambahkan loading/error UI sesuai PRD Section 4.6.

- [ ] **Step 4: Verifikasi & commit**

```bash
flutter analyze lib/pages/presence_page.dart 2>&1 | tail -10
git add lib/pages/presence_page.dart
git commit -m "refactor(page): presence page uses PresenceProvider instead of PresenceController"
```

- [ ] **Step 5: Lanjut ke Task 3.2 (hapus presence_controller)**

---

### Task 4.3: Refactor leave page → `LeaveProvider`

- [ ] **Step 1: Identifikasi page**

```bash
grep -rln "LeaveController" lib/pages/
```

- [ ] **Step 2: Refactor (template Task 4.2 Step 2-4)**

Pakai `LeaveProvider` (page-level). Commit: `refactor(page): leave page uses LeaveProvider`.

- [ ] **Step 3: Lanjut ke Task 3.3 (hapus leave_controller)**

---

### Task 4.4: Refactor asset pages → `AssetProvider`

**Files:** multiple asset pages.

- [ ] **Step 1: Identifikasi semua page yang pakai `AssetController`**

```bash
grep -rln "AssetController" lib/pages/
```

Kemungkinan multiple: `asset_list_page.dart`, `asset_form_page.dart`, `asset_detail_page.dart`, `asset_issue_page.dart`, dll.

- [ ] **Step 2: Untuk setiap page, refactor (template Task 4.2)**

> **Catatan:** jika multiple page share state asset, pertimbangkan promote `AssetProvider` ke global (di main.dart MultiProvider). Default tetap page-level dulu, promote jika terbukti perlu.

Satu commit per page.

- [ ] **Step 3: Lanjut ke Task 3.4 (hapus asset_controller)**

---

### Task 4.5: Refactor procurement pages → `ProcurementProvider`

**Files:** `lib/pages/procurement_*.dart` (multiple).

- [ ] **Step 1: Identifikasi**

```bash
grep -rln "ProcurementService" lib/pages/
```

- [ ] **Step 2: Refactor setiap page**

Ganti pemanggilan langsung `ProcurementService` dengan `ProcurementProvider` via `context.read/watch`. State loading/error pindah dari `setState` ke provider.

Satu commit per page (mis. `refactor(page): procurement list page uses ProcurementProvider`).

---

### Task 4.6: Refactor sales dashboard pages → `SalesDashboardProvider`

**Files:** `lib/pages/sales_dashboard*.dart`.

- [ ] **Step 1: Identifikasi & refactor (template Task 4.5)**

Satu commit per page.

---

## PHASE 5: Finalisasi & Verifikasi

### Task 5.1: Verifikasi semua success metrics PRD Section 10

- [ ] **Step 1: Grep verifikasi**

```bash
echo "=== Service HTTP pakai ApiClient ==="
grep -L "ApiClient" lib/services/*.dart 2>/dev/null
echo "(file tanpa ApiClient — harus hanya non-HTTP service dari Phase 1d)"

echo "=== Duplikasi _getToken/getToken di services ==="
grep -rE "_getToken|getToken" lib/services/ | grep -v api_client.dart
echo "(harus 0 hasil)"

echo "=== Raw http di service HTTP ==="
grep -lE "http\.(get|post|put|delete)" lib/services/*.dart | grep -v api_client.dart
echo "(harus hanya yang didokumentasikan di Phase 1c/1d)"

echo "=== controllers/ folder ==="
ls lib/controllers/ 2>/dev/null && echo "MASIH ADA" || echo "sudah dihapus ✓"
```

- [ ] **Step 2: Full analyze & test**

```bash
flutter analyze 2>&1 | tail -10
flutter test 2>&1 | tail -10
```

Expected: analyze tanpa error, all tests pass.

- [ ] **Step 3: Smoke test menyeluruh di emulator**

Critical path wajib diuji manual:
1. Login
2. Home page — user info, presence status, leave status
3. Presence page — submit presence
4. Procurement — list, create, approve/reject
5. Sales dashboard — load data
6. Asset — list, form, detail
7. Leave — list, apply

---

### Task 5.2: Update dokumentasi & commit final

- [ ] **Step 1: Update PRD status ke "Implemented"**

Modify: `PRD_PROVIDER_STANDARD.md` line 5:
```
**Status:** Implemented
```

- [ ] **Step 2: Commit**

```bash
git add PRD_PROVIDER_STANDARD.md
git commit -m "docs(prd): mark provider standardization as implemented"
git tag provider-architecture-migration-complete
```

---

## Lampiran A: Self-Review Checklist (jalankan setelah semua selesai)

Engineer jalankan checklist ini sebelum mengklaim selesai:

- [ ] Semua 21 service di Phase 1b sudah dimigrasi (lihat `git log --oneline | grep "migrate.*to ApiClient"`)
- [ ] `lib/controllers/` folder sudah tidak ada
- [ ] Tidak ada `_getToken`/`getToken` di `lib/services/` (kecuali `api_client.dart`)
- [ ] Tidak ada raw `http.get/post/put/delete` di `lib/services/*.dart` (kecuali yang didokumentasikan publik)
- [ ] `flutter analyze` 0 error
- [ ] `flutter test` semua hijau
- [ ] Smoke test manual semua critical path berhasil
- [ ] PRD ditandai `Implemented`

## Lampiran B: Out-of-Scope / Follow-up PR

Hal-hal yang **tidak** dicakup plan ini (catat sebagai PR terpisah jika dibutuhkan):

1. **Refactor `ApiClient` untuk dependency injection** — agar `http.Client` bisa di-mock untuk unit test service. Saat ini `ApiClient` pakai `http` global, sehingga unit test service tidak feasible tanpa refactor ini.
2. **Migrasi service non-HTTP** (`thermal_printer`, `network`, dll.) — di luar scope karena bukan REST API.
3. **Endpoint publik** (mis. `version_service`) — bisa tetap raw `http` atau pakai `ApiClient` dengan token null, keputusan ada di engineer saat Task 1.11.
4. **Migrasi ke Riverpod/BLoC** — PRD Section 9 menyimpulkan tetap di Provider; migrasi framework state management lain adalah keputusan strategis terpisah.
5. **Test coverage untuk service** — setelah PR dependency injection selesai, baru tulis unit test per-service dengan MockClient.
