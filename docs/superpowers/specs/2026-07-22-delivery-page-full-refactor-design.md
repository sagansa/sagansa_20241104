# PRD: Delivery Page Full Refactor — Sagansa Mobile

**Versi:** 1.0
**Tanggal:** 2026-07-22
**Status:** Draft — Ready for Implementation
**Scope:** `mobiles/sagansa/lib/pages/delivery_page.dart` (3.936 LOC → target <300 LOC)
**Prasyarat:** Design System Foundation (8 komponen + 74 tests) ✅ sudah selesai

---

## 1. Konteks

`delivery_page.dart` = **3.936 LOC**, God Widget terbesar #1 di codebase. Menanggung 6+ tanggung jawab sekaligus: daftar order paginasi, detail order (online 1.080 LOC + direct 648 LOC), form upload foto, stepper status, PDF print A4, thermal print stiker, barcode scanner, admin actions.

**Design System Foundation sudah selesai** — 8 komponen reusable dengan 74 tests siap pakai. Refactor ini sekarang jauh lebih mudah karena tinggal **susun komponen** alih-alih bangun dari nol.

### Strategi: Satu Pass, Emppat Lapis

```
Layer 1: Ganti inline UI → design system components  (~400 LOC hilang)
Layer 2: Extract UI sections → widget files          (~2000 LOC pindah)
Layer 3: Extract state → DeliveryProvider             (~800 LOC pindah)
Layer 4: Extract print logic → services               (~300 LOC pindah)
```

Hasil: `delivery_page.dart` jadi **shell ringkas <300 LOC**.

---

## 2. Inventory delivery_page.dart (baseline)

### 2.1 State fields (25 field)

| Group | Field | Tipe |
|---|---|---|
| Controllers | `_receiptController`, `_receiverController`, `_notesController`, `_scrollController` | TextEditingController/ScrollController |
| Loading | `_isLoadingSearch`, `_isLoadingSubmit`, `_isLoadingReadyToShip`, `_isPrintingPaymentProof`, `_isPrintingSticker`, `_isLoadingList` | bool |
| Order data | `_selectedOrder`, `_orders`, `_currentPage`, `_hasMore`, `_selectedStatus` | Map/List/int/bool |
| Photo | `_imageFiles`, `_picker` | List<File>/ImagePicker |
| Role | `_isAdmin`, `_isUpdatingPaymentStatus` | bool |
| Sticker | `_printedStickers` | Set<int> |

### 2.2 Build methods (13)

| Method | LOC | Render |
|---|---|---|
| `build` | 56 | Scaffold root |
| `_buildOrderListView` | 440 | List + search + paginasi |
| `_buildOnlineOrderDetailView` | 1080 | Detail online (TERBESAR) |
| `_buildOrderDetailView` | 648 | Dispatcher detail |
| `_buildDeliveryStepper` | 152 | Stepper 3/4 step |
| `_buildStickerPrintButton` | 111 | Thermal printer button |
| `_buildPhotoUploader` | 99 | Multi-upload grid |
| `_buildEmptyState` | 36 | Empty placeholder |
| `_buildDetailRow` | 25 | Label:value row |
| `_buildDashedLine` | 23 | Dekorasi |
| `_buildGoldTextField` | 23 | Search field |
| `_buildAdminPaymentStatusField` | 41 | Admin dropdown |
| `_buildAdminProductEditSection` | 33 | Placeholder stub |

### 2.3 Async methods (16)

`_loadPrintedStickers`, `_savePrintedSticker`, `_loadAdminRole`, `_loadInitialOrders`, `_loadMoreOrders`, `_searchOrder`, `_takePhoto`, `_processPickedImage`, `_submitDelivery`, `_markReadyToShip`, `_downloadImageBytes`, `_printPaymentProofs`, `_printSticker`, `_printAllPendingPaymentProofs`, `_updatePaymentStatus`, `_scanBarcode`.

---

## 3. Target Arsitektur

```
lib/
├── models/enums/
│   ├── order_mode.dart                 (enum OrderMode { direct, online })
│   └── delivery_status.dart            (enum + label/color extension)
├── services/
│   ├── payment_proof_pdf_service.dart  (A4 PDF builder)
│   └── sticker_print_orchestrator.dart (thermal print wrapper)
├── providers/
│   └── delivery_provider.dart          (ChangeNotifier: list + form + actions)
├── utils/
│   └── status_mappers.dart             (existing ✅)
├── widgets/
│   ├── [9 design system components]    (existing ✅)
│   └── delivery/
│       ├── order_list_view.dart        (list + search + scan)
│       ├── order_list_card.dart        (1 card di list)
│       ├── delivery_stepper.dart       (3/4 step indicator)
│       ├── photo_uploader_section.dart (compose PhotoUploader + form fields)
│       ├── online_order_detail_view.dart
│       ├── direct_order_detail_view.dart
│       ├── delivery_actions.dart       (ready/submit/refund buttons)
│       └── barcode_scanner_page.dart   (pindah dari private class)
└── pages/
    └── delivery_page.dart              (shell: ≤300 LOC)
```

---

## 4. Implementation Plan — 4 Layer, 8 Task

### Layer 1: Design System Migration (ganti inline UI)

#### Task 1: Enum + inline UI replacement

**Goal:** Ganti semua inline UI helper dengan design system components yang sudah ada. Tidak extract file, hanya swap di tempus.

**Changes:**
- Tambah `enum OrderMode { direct('1'), online('3') }` + `DeliveryStatus` enum
- `_buildEmptyState()` → `EmptyState(icon: Icons.local_gas_station_outlined, title: 'Belum ada order')`
- inline error view → `ErrorState(message: ..., onRetry: _loadInitialOrders)`
- `_buildDetailRow(label, value)` → `DetailRow(label: ..., value: ...)`
- `_getDeliveryStatusColor/Text(code)` → `StatusBadge(type: StatusMappers.deliveryStatus(code), label: StatusMappers.deliveryLabel(code))`
- `_getPaymentStatusColor/Text(code)` → `StatusBadge(type: StatusMappers.paymentStatus(code), label: StatusMappers.paymentLabel(code))`
- `_buildPhotoUploader({label})` → `PhotoUploader(photos: _imageFiles, onChanged: (v) => setState(() => _imageFiles = v), layout: PhotoUploaderLayout.grid, maxPhotos: 999)`
- `_buildGoldTextField(...)` → `SearchTextField(controller: ..., suffixWidget: ...)` (4 call site)
- 6 inline `Card(borderRadius: 16, side: BorderSide...)` di detail view → `SectionCard(title: ..., icon: ..., child: ...)`

**Acceptance:**
- [ ] `flutter analyze` → 0 error
- [ ] Tampilan identik (visual smoke test)
- [ ] delivery_page LOC turun ~150

---

### Layer 2: Extract UI Sections → Widget Files

#### Task 2: Barcode scanner + Stepper extraction

**Files create:**
- `lib/widgets/delivery/barcode_scanner_page.dart` — pindah `_BarcodeScannerPage` (private class) ke public
- `lib/widgets/delivery/delivery_stepper.dart` — extract `_buildDeliveryStepper`

**Changes:**
- Hapus `_BarcodeScannerPage` class dari delivery_page (line 3847-3935)
- Hapus `_buildDeliveryStepper` method (line 1594-1745)
- `delivery_page.dart` import & pakai kedua widget

**Acceptance:**
- [ ] Barcode scanner tetap berfungsi (push page → scan → return code)
- [ ] Stepper render benar untuk 6 skenario (pending/ready/delivered/returned × direct/online)
- [ ] Widget test untuk stepper

#### Task 3: List view + card extraction

**Files create:**
- `lib/widgets/delivery/order_list_view.dart` — compose `PagedBodyView` + search + scan button
- `lib/widgets/delivery/order_list_card.dart` — 1 card pakai `StatusBadge` + `SectionCard`

**Changes:**
- `_buildOrderListView` (440 LOC) → extract ke `OrderListView` widget
- Card inline di list → `OrderListCard` widget
- List + scroll boilerplate → pakai `PagedBodyView` dengan `sliverHeader`

**Acceptance:**
- [ ] List paginasi tetap berfungsi
- [ ] Search + scan button di header sliver
- [ ] Pull-to-refresh di semua kondisi
- [ ] Widget test untuk OrderListCard

#### Task 4: Detail views extraction (THE BIG ONE)

**Files create:**
- `lib/widgets/delivery/online_order_detail_view.dart` — compose SectionCard + DetailRow + PhotoUploader + DeliveryStepper
- `lib/widgets/delivery/direct_order_detail_view.dart` — section equivalent untuk direct
- `lib/widgets/delivery/delivery_actions.dart` — ready/submit/refund buttons
- `lib/widgets/delivery/sticker_print_button.dart` — extract `_buildStickerPrintButton`

**Changes:**
- `_buildOnlineOrderDetailView` (1.080 LOC) → pecah ke section-section kecil
- `_buildOrderDetailView` (648 LOC dispatcher) → ganti branching ke 2 widget
- `_buildStickerPrintButton` (111 LOC) → widget terpisah

**Acceptance:**
- [ ] Detail online render identik (stepper + items + photo + actions)
- [ ] Detail direct render identik
- [ ] Refund dialog tetap berfungsi
- [ ] Admin payment status field tetap berfungsi
- [ ] Widget test untuk kedua detail view

---

### Layer 3: Extract State → DeliveryProvider

#### Task 5: Service extraction (print + repository)

**Files create:**
- `lib/services/payment_proof_pdf_service.dart` — pindah `_printPaymentProofs` + `_downloadImageBytes` + `_printAllPendingPaymentProofs`
- `lib/services/sticker_print_orchestrator.dart` — pindah `_printSticker` + wrap ThermalPrinterService
- `lib/services/delivery_status_repository.dart` — pindah `_loadPrintedStickers` + `_savePrintedSticker` + `_loadAdminRole` (SharedPreferences wrapper)

**Acceptance:**
- [ ] PDF print tetap berfungsi (multi-page A4)
- [ ] Thermal sticker print tetap berfungsi (WiFi + Spooler)
- [ ] Printed stickers tetap persist di SharedPreferences
- [ ] Admin role load tetap berfungsi
- [ ] Unit test untuk repository (mock SharedPreferences)

#### Task 6: DeliveryProvider

**File create:**
- `lib/providers/delivery_provider.dart`

**State groups:**
```dart
@immutable
class DeliveryListState {
  final List<Map<String, dynamic>> orders;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
}

@immutable
class DeliveryFormState {
  final Map<String, dynamic>? selectedOrder;
  final List<File> photoFiles;
  final int selectedStatus; // 3=delivered, 6=returned
  final String receiverName;
  final String notes;
  final bool isSubmitting;
  final bool isMarkingReady;
}
```

**Loaders/actions:**
- `loadInitialOrders()`, `loadMoreOrders()`, `searchOrder(receiptNo)`
- `submitDelivery()`, `markReadyToShip()`, `updatePaymentStatus()`
- `printAllPendingPaymentProofs()`, `printSticker(order)`
- Form mutators: `selectOrder()`, `clearSelection()`, `addPhoto()`, `removePhotoAt()`, `setReceiver()`, `setNotes()`, `setStatus()`

**Acceptance:**
- [ ] Register di `main.dart` MultiProvider
- [ ] delivery_page baca via `context.select`/`context.read`
- [ ] 0 state field bisnis di widget (hanya UI flags)
- [ ] Unit test ≥ 10 test case

---

### Layer 4: Final Shell Rewrite

#### Task 7: Rewrite delivery_page.dart jadi shell

**Goal:** Setelah semua di-extract, delivery_page tinggal Scaffold + AppBar + body switch + FAB + bottom nav.

**Result:**
```dart
class DeliveryPage extends StatelessWidget {
  final OrderMode orderMode;
  const DeliveryPage({super.key, this.orderMode = OrderMode.online});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DeliveryProvider(...)..loadInitialOrders(),
      child: _DeliveryScaffold(orderMode: orderMode),
    );
  }
}
// _DeliveryScaffold: AppBar + body (list/detail switch) + FAB + ModernBottomNav
// ≤ 200 LOC
```

**Acceptance:**
- [ ] `delivery_page.dart` ≤ 300 LOC
- [ ] 0 inline `PresenceService()` / `SharedPreferences`
- [ ] 0 `widget.orderFor == '1'/'3'` string comparison
- [ ] `setState` ≤ 2 (UI flags only)
- [ ] `flutter analyze` → 0 issues

#### Task 8: Full smoke test + cleanup

**Manual test checklist:**
- [ ] List load + paginasi + pull-to-refresh
- [ ] Search receipt + scan barcode
- [ ] Detail online: stepper, items, photo upload, submit delivery
- [ ] Detail direct: stepper, admin payment status, photo upload, submit
- [ ] Refund/retur flow
- [ ] Print payment proof PDF (single + batch)
- [ ] Print sticker thermal (WiFi + Spooler)
- [ ] Admin FAB → create order
- [ ] Dark mode toggle tidak break

---

## 5. Roadmap

```
Sprint A (1 minggu): Layer 1+2 (UI extraction)
├─ Task 1: Enum + design system migration     (1 hari)
├─ Task 2: Barcode + Stepper                  (0.5 hari)
├─ Task 3: List view + card                   (1 hari)
└─ Task 4: Detail views (paling berat)        (2.5 hari)

Sprint B (1 minggu): Layer 3+4 (State + shell)
├─ Task 5: Service extraction                 (1 hari)
├─ Task 6: DeliveryProvider                   (2 hari, TDD)
├─ Task 7: Shell rewrite                      (0.5 hari)
└─ Task 8: Smoke test + cleanup               (1 hari)
```

---

## 6. Success Metrics

| Metrik | Baseline | Target |
|---|---|---|
| `delivery_page.dart` LOC | 3.936 | < 300 |
| File > 300 LOC di `widgets/delivery/` | 0 | < 3 |
| `setState` di delivery_page | ~30 | ≤ 2 |
| Inline `PresenceService()` | 8 | 0 |
| Inline `SharedPreferences` | 3 | 0 |
| `widget.orderFor ==` string branching | ~20 | 0 |
| Widget test untuk delivery | 0 | ≥ 8 |
| `flutter analyze` issues | TBD | 0 |

---

## 7. Risk Register

| ID | Risk | Mitigasi |
|---|---|---|
| R1 | Detail view (Task 4) pecah fitur existing | Pecah per-section dengan smoke test antar merge |
| R2 | PDF print behavior beda setelah pindah service | Test PDF output byte-identical |
| R3 | Provider terlalu besar (>500 LOC) | Split jadi ListProvider + FormProvider bila perlu |
| R4 | Stiker local-state hilang saat pindah repo | Migrate key `'printed_stickers'` tanpa ubah format |
| R5 | `PagedBodyView` sliver tidak fit delivery header | Header jadi `SliverToBoxAdapter` di `sliverHeader` slot |

---

## 8. Out of Scope

- Migrasi page lain ke design system (ongoing, di luar PRD ini)
- Refactor `CreateSalesOrderOnlinePage` (832 LOC, sprint terpisah)
- Backend changes (multi-image JSON sudah dikerjakan)
- `go_router` integration

---

**Akhir dokumen.**
