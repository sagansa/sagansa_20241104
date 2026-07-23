# PRD: Delivery Page Decomposition — Sagansa Mobile

**Versi:** 1.0
**Tanggal:** 2026-07-21
**Status:** Draft
**Scope:** `mobiles/sagansa/lib/pages/delivery_page.dart` (+ file pendukung baru di `lib/`)
**Spec induk:** `PRD_CODEBASE_IMPROVEMENT.md` §2.2 (delivery_page.dart = file terbesar #1)

---

## 1. Konteks & Masalah

`delivery_page.dart` saat ini **3.936 LOC** — God Widget terbesar di codebase (lebih besar dari `home_page.dart` sebelum di-refactor). File ini menanggung terlalu banyak tanggung jawab:

- **Daftar order** (online & direct) + paginasi infinite scroll + pencarian receipt + scan barcode.
- **Detail order** online (~1.080 LOC widget) & direct (~648 LOC widget) dengan UI berbeda total.
- **Form bukti pengiriman** (multi-upload foto, validasi status 3/6, nama penerima, catatan retur).
- **Stepper status pengiriman** (3 step direct / 4 step online).
- **PDF print** bukti pembayaran (A4, multi-page, package `pdf` + `printing`).
- **Thermal print** stiker resi (package `thermal_printer_service` + `PrinterProvider`).
- **Persistensi lokal** daftar stiker tercetak via `SharedPreferences`.
- **Admin actions** (edit payment status, edit produk — placeholder stub).
- **Barcode scanner** (`mobile_scanner`) — sudah kelas terpisah tapi masih di file yang sama.

### 1.1 Audit Konkret

| Metrik | Nilai |
|---|---|
| LOC | 3.936 |
| Method `_buildXxx` | 13 |
| Method async (`Future<void> _xxx`) | 16 |
| Field state lokal | ~25 (controllers, loading flags, data, role, print set) |
| Inline `PresenceService()` | ~8 call site (instance baru tiap call) |
| Inline `SharedPreferences.getInstance()` | 3 (admin role, printed stickers ×2) |
| Cabang `widget.orderFor == '1'/'3'` | ~20 lokasi (string-encoded mode) |
| Cabang `_isAdmin` | 5 lokasi (list filter, FAB, price visibility, payment edit, product edit) |
| Dep package berat | `pdf` + `printing` + `mobile_scanner` (tidak ada hubungan dengan rendering list) |

### 1.2 Anti-pattern Utama

**A. `colorScheme` & `textTheme` adalah getter di State** — memaksa semua `_buildXxx` jadi method instance, mustahil di-extract jadi `StatelessWidget` tanpa mengubah sumber theme.

**B. `String orderFor` (default `'3'`)** — string-encoded mode flag yang dipakai untuk gating ~20 tempat. Rentan typo (`'1'` vs `'3'`), tidak ada autocomplete, tidak self-documenting.

**C. Logic bisnis tercampur di widget state** — `_getDeliveryStatusText`, `_getPaymentStatusText`, `_getPaymentProofPrintStatusText`, `_formatPrice`, predikat `_isUnprintedPaymentProof` dll adalah pure function yang nyangkut di State class.

**D. Service instantiation inline** — `PresenceService()` di-bikin baru tiap call site (8×). Tidak bisa di-mock untuk test.

**E. SharedPreferences terurai di widget** — decode JSON `'user'` untuk admin role + serialize list `'printed_stickers'` manual.

**F. PDF & thermal print inline** — 200+ LOC logic PDF builder + 60 LOC thermal print nyangkut di widget yang seharusnya hanya menampilkan list.

---

## 2. Tujuan

Selama **4 sprint (8 minggu)**, pecah `delivery_page.dart` 3.936 LOC → ≤ **500 LOC** dengan arsitektur provider + widget per-section, mengikuti pola yang sudah terbukti di refactor `home_page.dart` (1945 → 402 LOC).

**Prinsip:**
- **Incremental & reversible** — tiap task berdiri sendiri, bisa di-merge terpisah, tidak ada "big bang rewrite".
- **Behavior tidak boleh berubah** — fitur jalan terus selama migrasi. Tiap task diakhiri smoke test.
- **Pattern reuse** — ikuti pola `HomeDashboardProvider` + per-card widget yang sudah ada.
- **TDD di layer baru** — provider & service wajib punya unit test sebelum dipakai.

---

## 3. Arsitektur Target

```
┌──────────────────────────────────────────────────────────┐
│  DeliveryPage (StatelessWidget shell, ≤300 LOC)          │
│  - AppBar (title brancing list/detail × online/direct)   │
│  - Body: list view OR detail view                        │
│  - FAB admin (online only)                               │
│  - ModernBottomNav                                       │
└────────────────────────┬─────────────────────────────────┘
                         │ watches
┌────────────────────────▼─────────────────────────────────┐
│  DeliveryProvider (ChangeNotifier)                       │
│  - State: orderList, selectedOrder, pagination, isLoading│
│  - Loaders: loadOrders, loadMore, searchOrder            │
│  - Actions: submitDelivery, markReadyToShip,             │
│             updatePaymentStatus                          │
└────────────────────────┬─────────────────────────────────┘
                         │ calls
┌────────────────────────▼─────────────────────────────────┐
│  PresenceService (existing, injected)                    │
│  + PaymentProofPdfService (NEW)                          │
│  + StickerPrintOrchestrator (NEW, wraps ThermalPrinter)  │
│  + DeliveryStatusRepository (NEW, SharedPreferences)     │
└──────────────────────────────────────────────────────────┘
```

### 3.1 File Structure Target

```
lib/
├── models/
│   ├── enums/
│   │   ├── order_mode.dart             (NEW: enum OrderMode { direct, online })
│   │   ├── delivery_status.dart        (NEW: enum + extensions)
│   │   └── payment_status.dart         (NEW: enum + extensions)
│   └── delivery/
│       └── printed_sticker.dart        (NEW: simple value object)
├── services/
│   ├── presence_service.dart           (existing)
│   ├── payment_proof_pdf_service.dart  (NEW: A4 PDF builder)
│   ├── sticker_print_orchestrator.dart (NEW: thermal print wrapper)
│   └── delivery_status_repository.dart (NEW: SharedPreferences repo)
├── providers/
│   └── delivery_provider.dart          (NEW: ChangeNotifier)
├── utils/
│   └── order_formatters.dart           (NEW: price/status text helpers)
├── widgets/
│   └── delivery/
│       ├── order_list_view.dart        (NEW: list + paginasi)
│       ├── order_list_card.dart        (NEW: 1 card di list)
│       ├── delivery_stepper.dart       (NEW: stepper 3/4 step)
│       ├── online_order_detail_view.dart   (NEW)
│       ├── direct_order_detail_view.dart   (NEW)
│       ├── photo_uploader.dart         (NEW: multi-upload, sudah ada prototype)
│       ├── sticker_print_button.dart   (NEW)
│       ├── admin_payment_status_field.dart (NEW)
│       └── barcode_scanner_page.dart   (NEW: pindah dari private class)
└── pages/
    └── delivery_page.dart              (rewrite: shell ringkas)
```

---

## 4. Workstream Detail

Tiap workstream: **masalah → solusi → acceptance criteria → file terdampak → effort**.

### 4.1 [WS-D1] Foundation — Enum & Pure Helpers

**Masalah:** String `orderFor` ('1'/'3') dan pure helpers (`_formatPrice`, status text/color) tersebar di State class.

**Solusi:**
```dart
// lib/models/enums/order_mode.dart
enum OrderMode {
  direct('1'),
  online('3');
  const OrderMode(this.code);
  final String code;
  static OrderMode fromCode(String? code) =>
      code == '1' ? OrderMode.direct : OrderMode.online;
}

// lib/models/enums/delivery_status.dart
enum DeliveryStatus {
  pending(1), readyToShip(4), delivered(3), returned(6), valid(2);
  // ... label, color, isTerminal, etc.
}

// lib/utils/order_formatters.dart
class OrderFormatters {
  static String formatPrice(dynamic value) { ... }
  static String deliveryStatusText(int code) { ... }
  static Color deliveryStatusColor(int code, ColorScheme cs) { ... }
  // payment_status, payment_proof_print_status, dst.
}
```

**Acceptance Criteria:**
- [ ] 3 enum + extensions dibuat di `lib/models/enums/`.
- [ ] `OrderFormatters` berisi semua pure helper (≥ 8 method).
- [ ] Unit test untuk enum `fromCode`/`toCode` + semua formatter.
- [ ] Behavior aplikasi tidak berubah.

**File:** `lib/models/enums/order_mode.dart`, `delivery_status.dart`, `payment_status.dart`, `lib/utils/order_formatters.dart`, `test/models/enums/*`, `test/utils/order_formatters_test.dart`.

**Effort:** 1 hari.

---

### 4.2 [WS-D2] Repository & Service Layer

**Masalah:** `SharedPreferences` (admin role, printed stickers) & service inline (`PresenceService()` 8×) menyulitkan testing dan melanggar layer arsitektur.

**Solusi:**

```dart
// lib/services/delivery_status_repository.dart
class DeliveryStatusRepository {
  Future<Set<int>> loadPrintedStickers() async { ... }
  Future<void> savePrintedSticker(int orderId) async { ... }
  Future<bool> loadIsAdmin() async { ... } // atau pakai AuthProvider.isAdmin
}

// lib/services/payment_proof_pdf_service.dart
class PaymentProofPdfService {
  final PresenceService _presence;
  Future<PrintResult> printProofs({
    required List<Map<String, dynamic>> orders,
    required OrderMode mode,
  }) async { ... } // pindahkan _printPaymentProofs + _downloadImageBytes
}

// lib/services/sticker_print_orchestrator.dart
class StickerPrintOrchestrator {
  final ThermalPrinterService _printer = ThermalPrinterService.instance;
  Future<bool> printSticker({
    required Map<String, dynamic> order,
    required PrinterProvider printerProvider,
  }) async { ... } // pindahkan _printSticker
}
```

**Acceptance Criteria:**
- [ ] 3 service/repo baru di `lib/services/`.
- [ ] `PresenceService` di-inject (tidak di-instantiate inline) ke `PaymentProofPdfService`.
- [ ] Unit test untuk `DeliveryStatusRepository` (mock SharedPreferences) & PDF service (mock `PresenceService` + `Printing`).
- [ ] `delivery_page.dart` tidak lagi langsung akses `SharedPreferences` untuk admin/sticker.

**File:** `lib/services/delivery_status_repository.dart`, `payment_proof_pdf_service.dart`, `sticker_print_orchestrator.dart`, `test/services/*`.

**Effort:** 2-3 hari.

---

### 4.3 [WS-D3] DeliveryProvider (State Migration)

**Masalah:** 25 state field lokal + 16 async method menumpuk di widget. Duplikasi dengan arsitektur home.

**Solusi:**

```dart
// lib/providers/delivery_provider.dart
@immutable
class DeliveryListState {
  final List<Map<String, dynamic>> orders;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  // copyWith...
}

@immutable
class DeliveryFormState {
  final Map<String, dynamic>? selectedOrder;
  final List<File> photoFiles;
  final int selectedStatus; // 3 delivered, 6 returned
  final String receiverName;
  final String notes;
  final bool isSubmitting;
  final bool isMarkingReady;
  // copyWith...
}

class DeliveryProvider extends ChangeNotifier {
  DeliveryProvider({
    required this.presenceService,
    required this.pdfService,
    required this.stickerOrchestrator,
    required this.statusRepository,
    required this.orderMode,
    required this.isAdmin,
  });

  DeliveryListState _list = ...;
  DeliveryFormState _form = ...;

  Future<void> loadInitialOrders() async { ... }
  Future<void> loadMoreOrders() async { ... }
  Future<void> searchOrder(String receiptNo) async { ... }
  Future<void> submitDelivery() async { ... }
  Future<void> markReadyToShip() async { ... }
  Future<void> updatePaymentStatus(int orderId, String status) async { ... }
  Future<void> printAllPendingPaymentProofs() async { ... }
  Future<void> printSticker(Map<String, dynamic> order) async { ... }

  // Form mutators
  void selectOrder(Map<String, dynamic> order) { ... }
  void clearSelection() { ... }
  void addPhoto(File file) { ... }
  void removePhotoAt(int index) { ... }
  void setReceiverName(String v) { ... }
  void setNotes(String v) { ... }
  void setStatus(int s) { ... }
}
```

**Acceptance Criteria:**
- [ ] `DeliveryProvider` dengan grouped state (list + form) + constructor injection.
- [ ] Register di `main.dart` `MultiProvider` (atau page-scoped).
- [ ] Unit test untuk `loadInitialOrders`, `loadMoreOrders`, `searchOrder`, `submitDelivery`, error handling (≥ 10 test case).
- [ ] `delivery_page.dart` tidak lagi punya state field bisnis (hanya UI shell flags).

**File:** `lib/providers/delivery_provider.dart`, `lib/main.dart`, `test/providers/delivery_provider_test.dart`.

**Effort:** 3-4 hari (TDD).

---

### 4.4 [WS-D4] Extract Widgets — List & Card

**Masalah:** `_buildOrderListView` (440 LOC) dan inline order card di dalamnya.

**Solusi:** Pecah jadi:
- `OrderListView` — Scaffold list + paginasi + search field (online) + scan button
- `OrderListCard` — 1 card di list, baca order map + provider via `context.select`

**Acceptance Criteria:**
- [ ] 2 widget baru di `lib/widgets/delivery/`.
- [ ] Masing-masing ≤ 200 LOC.
- [ ] Widget test untuk `OrderListCard` (rendering untuk online/direct/admin variation).
- [ ] `_buildOrderListView` dihapus dari `delivery_page.dart`.

**File:** `lib/widgets/delivery/order_list_view.dart`, `order_list_card.dart`, `test/widgets/delivery/order_list_card_test.dart`.

**Effort:** 2 hari.

---

### 4.5 [WS-D5] Extract Widgets — Stepper & Photo Uploader

**Masalah:** `_buildDeliveryStepper` (152 LOC, 3 vs 4 step branching) & `_buildPhotoUploader` (99 LOC, baru saja ditulis inline).

**Solusi:**
- `DeliveryStepper` — widget menerima `DeliveryStatus` + `OrderMode`, render step yang sesuai.
- `PhotoUploader` — widget menerima `List<File>` + callback `onAdd`/`onRemove`, sudah self-contained.

**Acceptance Criteria:**
- [ ] 2 widget baru, masing-masing ≤ 150 LOC.
- [ ] Stepper render benar untuk 6 skenario: pending/ready/delivered/returned × direct/online.
- [ ] Widget test untuk stepper & photo uploader.

**File:** `lib/widgets/delivery/delivery_stepper.dart`, `photo_uploader.dart`, `test/widgets/delivery/*`.

**Effort:** 1.5 hari.

---

### 4.6 [WS-D6] Extract Widgets — Detail Views (The Big One)

**Masalah:** `_buildOnlineOrderDetailView` (1.080 LOC) & `_buildOrderDetailView` (648 LOC dispatcher) — paling kompleks.

**Solusi:** Pecah jadi:
- `OnlineOrderDetailView` — section-section kecil (transaction card, recipient card, items list, photo, actions)
- `DirectOrderDetailView` — section equivalent untuk direct
- Sub-widget reusable: `OrderItemsList`, `DeliveryActions` (ready/submit/refund buttons), `AdminPaymentStatusField`, `StickerPrintButton`

**Acceptance Criteria:**
- [ ] 2 main detail widget + 4 sub-widget di `lib/widgets/delivery/`.
- [ ] Masing-masing main view ≤ 300 LOC, sub-widget ≤ 150 LOC.
- [ ] Widget test untuk kedua detail view (online + direct + admin gating).
- [ ] `_buildOnlineOrderDetailView` & `_buildOrderDetailView` dihapus.

**File:** `lib/widgets/delivery/online_order_detail_view.dart`, `direct_order_detail_view.dart`, `order_items_list.dart`, `delivery_actions.dart`, `admin_payment_status_field.dart`, `sticker_print_button.dart`, `test/widgets/delivery/*`.

**Effort:** 4-5 hari (paling berat).

---

### 4.7 [WS-D7] Extract Barcode Scanner Page

**Masalah:** `_BarcodeScannerPage` adalah private class di akhir file, sebenarnya self-contained tapi tidak reusable.

**Solusi:** Pindah ke file sendiri `lib/widgets/delivery/barcode_scanner_page.dart`, jadi public.

**Acceptance Criteria:**
- [ ] File baru `barcode_scanner_page.dart`.
- [ ] `_BarcodeScannerPage` dihapus dari `delivery_page.dart`.
- [ ] Widget test sederhana (render camera preview).

**File:** `lib/widgets/delivery/barcode_scanner_page.dart`, `test/widgets/delivery/barcode_scanner_page_test.dart`.

**Effort:** 0.5 hari.

---

### 4.8 [WS-D8] Final Shell Rewrite & Verification

**Masalah:** Setelah semua di-extract, `delivery_page.dart` harus jadi shell ringkas.

**Solusi:** Rewrite `delivery_page.dart` menjadi:
```dart
class DeliveryPage extends StatelessWidget {
  final OrderMode orderMode;
  const DeliveryPage({super.key, this.orderMode = OrderMode.online});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DeliveryProvider(
        presenceService: PresenceService(),
        pdfService: PaymentProofPdfService(PresenceService()),
        stickerOrchestrator: StickerPrintOrchestrator(),
        statusRepository: DeliveryStatusRepository(),
        orderMode: orderMode,
        isAdmin: context.read<AuthProvider>().isAdmin,
      )..loadInitialOrders(),
      child: const _DeliveryScaffold(),
    );
  }
}

class _DeliveryScaffold extends StatelessWidget {
  // AppBar + body (list/detail switch) + FAB + bottom nav
  // ≤ 200 LOC
}
```

**Acceptance Criteria:**
- [ ] `delivery_page.dart` ≤ 300 LOC.
- [ ] **0** state field bisnis di widget (hanya via Provider).
- [ ] **0** inline `PresenceService()` (via Provider injection).
- [ ] **0** inline `SharedPreferences` (via Repository).
- [ ] `flutter analyze` → 0 error/warning di file delivery.
- [ ] Full smoke test manual: list → search → detail online → upload photo → submit → print proof → print sticker → scan barcode → detail direct → retur.
- [ ] `setState` count ≤ 2 (hanya UI flags lokal).

**File:** `lib/pages/delivery_page.dart` (rewrite), `lib/main.dart` (register provider).

**Effort:** 1 hari + smoke test mendalam.

---

## 5. Roadmap Eksekusi

### 5.1 Timeline

```
Sprint 1 (2 minggu): FOUNDATION
├─ WS-D1  Enum & helpers        (1 hari)
├─ WS-D2  Repository & service  (2-3 hari)
└─ WS-D7  Barcode scanner       (0.5 hari)

Sprint 2 (2 minggu): STATE
├─ WS-D3  DeliveryProvider      (3-4 hari, TDD)
└─ WS-D5  Stepper & photo       (1.5 hari)

Sprint 3 (2 minggu): UI DECOMPOSITION (part 1)
├─ WS-D4  List & card           (2 hari)
└─ WS-D6  Detail views          (4-5 hari, paling berat)

Sprint 4 (1 minggu): POLISH
└─ WS-D8  Final shell rewrite   (1 hari + smoke)
```

### 5.2 Urutan Berdasarkan Dampak × Effort

| Prioritas | Workstream | Dampak | Effort |
|---|---|---|---|
| ★★★ | WS-D3 Provider | Sangat Tinggi | Tinggi |
| ★★★ | WS-D6 Detail views | Sangat Tinggi | Sangat Tinggi |
| ★★☆ | WS-D2 Service layer | Tinggi | Sedang |
| ★★☆ | WS-D4 List & card | Tinggi | Sedang |
| ★★☆ | WS-D1 Enum & helpers | Sedang | Rendah |
| ★☆☆ | WS-D5 Stepper & photo | Sedang | Rendah |
| ★☆☆ | WS-D7 Barcode | Rendah | Sangat Rendah |
| ★☆☆ | WS-D8 Final rewrite | Sedang | Rendah |

---

## 6. Success Metrics

### 6.1 KPI Kuantitatif

| Metrik | Baseline (2026-07-21) | Target |
|---|---|---|
| `delivery_page.dart` LOC | 3.936 | < 300 |
| File > 500 LOC di `lib/widgets/delivery/` | 0 (semua inline) | 0 |
| File > 300 LOC di `lib/widgets/delivery/` | 0 | < 5 |
| `setState` di `delivery_page.dart` | ~30 | ≤ 2 |
| Inline `PresenceService()` di `delivery_page.dart` | 8 | 0 |
| Inline `SharedPreferences` di `delivery_page.dart` | 3 | 0 |
| Cabang `widget.orderFor == '...'` (string) | ~20 | 0 (pakai enum) |
| File test untuk delivery | 0 | ≥ 10 |
| `flutter analyze` issues di delivery | TBD | 0 |

### 6.2 KPI Kualitatif

- **Confidence refactor** — developer tidak takut ubah kode karena ada test + lint.
- **Onboarding** — fitur baru (mis. "tambah field X ke detail order") cukup sentuh 1 file widget, bukan membaca 3.936 LOC.
- **Pattern konsisten** — sama dengan home refactor: 1 file per widget + Provider injection.

---

## 7. Risk Register

| ID | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| RD1 | Detail view (WS-D6) pecah fitur existing | Tinggi | Tinggi | Pecah per-section dengan smoke test antar merge; retention `_buildOnlineOrderDetailView` lama sebagai backup sampai verify |
| RD2 | PDF print behavior beda setelah pindah service | Sedang | Sedang | Test PDF output byte-identical; profile dengan order sampel |
| RD3 | `mobile_scanner` breaking change saat pindah file | Rendah | Rendah | Cukup pindah file, tidak ubah API usage |
| RD4 | Provider terlalu besar (gabung list+form+print) | Sedang | Sedang | Pertimbangkan split jadi `DeliveryListProvider` + `DeliveryFormProvider` bila >500 LOC |
| RD5 | Conflict dengan feature work selama 4 sprint | Tinggi | Sedang | Branch short-lived; koordinasi dengan roadmap |
| RD6 | Stiker local-state (SharedPreferences) hilang saat pindah repo | Rendah | Sedang | Migrate key `'printed_stickers'` tanpa ubah format |

---

## 8. Out of Scope

- Migrasi `CreateSalesOrderOnlinePage` (832 LOC, file terbesar #5) — sprint terpisah.
- Backend changes untuk endpoint delivery — sudah dikerjakan terpisah (multi-image JSON).
- Ganti `mobile_scanner` ke package lain.
- Refactor `ThermalPrinterService` (di luar wrapping di `StickerPrintOrchestrator`).
- Migrasi routing ke `go_router` (WS-03 di PRD induk).

---

## 9. Acceptance Criteria Keseluruhan

- [ ] `delivery_page.dart` ≤ 300 LOC.
- [ ] 0 state field bisnis di widget (semua via Provider).
- [ ] 0 inline `PresenceService()` / `SharedPreferences` / `http.get` di widget.
- [ ] 0 string comparison `orderFor == '1'/'3'` (pakai `OrderMode` enum).
- [ ] `DeliveryProvider` punya unit test (≥ 15 test case).
- [ ] Minimal 8 widget test di `test/widgets/delivery/`.
- [ ] `flutter analyze` → 0 error/warning di seluruh file delivery.
- [ ] Smoke test manual lulus semua skenario di WS-D8.

---

## 10. Appendix

### A. Referensi
- `PRD_CODEBASE_IMPROVEMENT.md` §2.2 (audit file terbesar).
- Hasil refactor `home_page.dart` (1945 → 402 LOC) sebagai proof of pattern.
- `lib/widgets/home/` sebagai template struktur folder.

### B. Glosarium
- **God Widget** — widget > 500 LOC dengan terlalu banyak tanggung jawab.
- **OrderMode** — enum pengganti string `orderFor` ('1' direct, '3' online).
- **DeliveryStatusRepository** — abstraction atas `SharedPreferences` untuk printed stickers & admin role.
- **PaymentProofPdfService** — service builder dokumen A4 PDF bukti pembayaran.

---

**Akhir dokumen.**
