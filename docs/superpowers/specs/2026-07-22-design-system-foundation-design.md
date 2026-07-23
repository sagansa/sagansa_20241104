# PRD: Design System Foundation — Sagansa Mobile

**Versi:** 1.1 (revisi setelah review kritis — fix 6 kekurangan)
**Tanggal:** 2026-07-22
**Status:** Draft
**Scope:** `mobiles/sagansa/lib/widgets/`, `lib/theme/`, `lib/utils/`
**Reference implementation:** `mobiles/sagansa/lib/pages/delivery_page.dart` (3.936 LOC — pattern source terkaya)
**Spec induk:** `PRD_CODEBASE_IMPROVEMENT.md` §2 (audit codebase), §3 (arsitektur target)

---

## 1. Konteks & Masalah

Audit codebase menemukan **9 pola UI diduplikasi di 8-22 halaman**. Dua widget reusable sudah ada (`StatusBadge`, `EmptyState`) tapi hanya dipakai di 3-5 halaman — 8-10 halaman lain masih membuat versi sendiri. Hasilnya: inkonsistensi visual, kode membengkak, dan sulit menerapkan perubahan global.

**`delivery_page.dart`** adalah sumber pattern terkaya karena memuat hampir semua pola sekaligus: loading/error/empty switch, list paginasi, photo uploader, detail row, filter chips, section card, status badge, stepper. Menjadikannya **reference implementation** memastikan komponen yang dibuat benar-benar cocok untuk page paling kompleks.

### 1.1 Audit Konkret (per 2026-07-22)

| Pola | Halaman duplikat | Widget sudah ada? | Adopsi |
|---|---:|---|---:|
| Loading/error/empty body switch | ~22 | ❌ | 0/22 |
| Paginated list + infinite scroll | ~22 | ❌ | 0/22 |
| Photo uploader (single/multi) | 12+ | ❌ | 0/12 |
| Empty state inline | ~12 | ✅ `EmptyState` | 3/12 |
| Status badge inline | 10+ | ✅ `StatusBadge` | 5/15 |
| Detail row (label:value) | 9 | ❌ | 0/9 |
| Filter chip row | 9+ | ❌ (1 private) | 0/9 |
| Section card (header + body) | 6+ | ❌ | 0/6 |
| Search field | 8 | ✅ under-used | 4/8 |

### 1.2 Kenapa pakai delivery_page sebagai basis?

`delivery_page.dart` memuat **7 dari 9 pola** dalam satu file:
- `_buildOrderListView` (line 1129) — list paginasi + loading footer + empty state inline
- `_buildPhotoUploader` (line 323) — multi-photo grid + dropzone + remove
- `_buildDetailRow` (line 3807) — fixed-width label + expanded value
- `_buildEmptyState` (line 3770) — inline duplicate of `EmptyState`
- `_getDeliveryStatusColor`/`_getPaymentStatusColor` (line 656/1030) — inline duplicate of `StatusBadge`
- Inline `Card` detail sections (line 1790, 1959, 2130, 2273, 2410, 2523) — section card pattern
- `_buildDeliveryStepper` (line 1594) — horizontal stepper

Jika komponen yang dibuat bisa menggantikan semua pattern di delivery_page tanpa regression, komponen itu **terbukti production-ready** untuk 22+ halaman lain.

---

## 2. Tujuan

Selama **2 sprint (4 minggu)**, buat **7 komponen reusable** yang menghilangkan duplikasi UI di seluruh codebase. Setiap komponen divalidasi dengan menggunakannya di `delivery_page.dart` sebagai smoke test paling ketat.

**Prinsip:**
- **delivery_page sebagai spec**: setiap komponen harus bisa menggantikan pattern di delivery_page tanpa mengubah tampilan/behavior.
- **Backward compatible**: widget yang sudah ada (`StatusBadge`, `EmptyState`) di-extend, bukan di-breaking.
- **TDD**: setiap komponen punya widget test sebelum dipakai.
- **Adopsi bertahap**: setelah komponen jadi, migrasi page lain dilakukan per-sprint (bukan big-bang).

---

## 3. Arsitektur Target

```
lib/
├── theme/
│   ├── app_colors.dart           (existing — tambah token jika perlu)
│   └── app_spacing.dart          (existing)
├── widgets/
│   ├── status_badge.dart         (existing — extend + migrasi 10+ helper)
│   ├── empty_state.dart          (existing)
│   ├── error_state.dart          (NEW — turunan EmptyState untuk error+retry)
│   ├── paged_body_view.dart      (NEW — loading/error/empty/data switch)
│   ├── paginated_list_view.dart  (NEW — infinite scroll generic)
│   ├── photo_uploader.dart       (NEW — single/multi, grid/horizontal)
│   ├── detail_row.dart           (NEW — label:value, 2 varian)
│   ├── filter_chip_row.dart      (NEW — horizontal chip group generic)
│   ├── section_card.dart         (NEW — card + optional header icon)
│   └── search_text_field.dart    (NEW — search dengan clear button)
└── utils/
    └── status_mappers.dart       (NEW — domain status → StatusType maps)
```

---

## 4. Workstream Detail

### 4.1 [WS-DS1] `PagedBodyView` + `PaginatedListView<T>` — The Foundation

**Masalah:** 22 halaman punya nested ternary identik:
```dart
body: _isLoading
    ? Center(CircularProgressIndicator)
    : _errorMessage != null
        ? Center(Column[Icon(error), Text(msg), ElevatedButton(retry)])
        : _items.isEmpty
            ? Center(Column[Icon, Text])
            : RefreshIndicator(ListView.builder(paginated))
```
Plus `ScrollController` + `_onScroll` + `_loadMore` + `_hasMore` + `_page` boilerplate di tiap State class.

**Solusi:**

**⚠️ Penting: sliver-based, bukan ListView-only.** delivery_page punya struktur kompleks di atas list: search field + scan button (online only) + "Cetak Semua" button (admin only) + list. Kalau `PagedBodyView` cuma wrap `ListView`, header ini tidak bisa sticky/scroll bareng list. Solusi: gunakan `CustomScrollView` + sliver, sehingga header bisa berupa `SliverToBoxAdapter` / `SliverPersistentHeader` dan list pakai `SliverList`/`SliverChildBuilderDelegate`.

```dart
/// Switch otomatis antara loading / error / empty / data berdasarkan state.
/// Mendukung header sliver (sticky search field, action button) di atas list.
class PagedBodyView<T> extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final bool isEmpty;
  final List<T> items;
  final Widget Function(BuildContext, int) itemBuilder;
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onLoadMore;
  final bool hasMore;

  /// Header sliver opsional (e.g., search field, filter chips, action buttons).
  /// Dirender SEBELUM list di CustomScrollView. Bisa pakai SliverToBoxAdapter
  /// atau SliverPersistentHeader untuk sticky behavior.
  final Widget? sliverHeader;

  /// Empty/error state config.
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;
  final VoidCallback? onRetry;
  final EdgeInsets? padding;

  /// Builder untuk loading footer saat loadMore.
  final Widget Function(BuildContext)? loadingMoreBuilder;

  const PagedBodyView({...});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(CircularProgressIndicator);
    if (error != null) return ErrorState(message: error!, onRetry: onRetry);
    // Selalu bungkus dengan RefreshIndicator + AlwaysScrollableScrollPhysics
    // agar pull-to-refresh berfungsi di semua kondisi (termasuk empty/error).
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (sliverHeader != null) sliverHeader!,
          if (isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(icon: emptyIcon, title: emptyTitle, ...),
            )
          else
            PagedSliverList<T>(items: items, itemBuilder: itemBuilder, ...),
        ],
      ),
    );
  }
}

/// Sliver-based infinite scroll — compose di CustomScrollView bersama header.
/// Menggantikan PaginatedListView yang ListView-only.
class PagedSliverList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, int) itemBuilder;
  final bool hasMore;
  final Future<void> Function() onLoadMore;
  final Widget Function(BuildContext)? loadingMoreBuilder;
  final ScrollController? controller;
  final double loadMoreThreshold; // default 200
  // ...
}
```

**Kenapa sliver, bukan ListView?**
- delivery_page search field + scan button + "Cetak Semua" button harus scroll bareng list (bukan fixed di atas). Dengan sliver, header jadi `SliverToBoxAdapter` yang ikut scroll, lalu list pakai `PagedSliverList`.
- Banyak page lain (closing_store, procurement_workflow) juga punya filter chips di atas list — pattern yang sama.
- Untuk page simpel (cuma list tanpa header), `sliverHeader: null` → langsung render list.

**Acceptance Criteria:**
- [ ] `PagedBodyView` + `PagedSliverList` di `lib/widgets/`.
- [ ] Pull-to-refresh berfungsi di **semua** kondisi (loading, error, empty, data) — diverifikasi di delivery_page.
- [ ] Loading footer otomatis muncul saat `hasMore == true`.
- [ ] Threshold scroll (default 200px) dapat dikonfigurasi.
- [ ] `sliverHeader` slot teruji: search field + button dirender benar di atas list, scroll bareng.
- [ ] Widget test: 7 skenario (initial loading, error+retry, empty, data only, data+loadMore, data+lastPage, **data+sliverHeader**).
- [ ] `delivery_page._buildOrderListView` di-migrasi pakai komponen ini (search + cetak button jadi `sliverHeader`). Tampilan & scroll behavior identik.

**File:** `lib/widgets/paged_body_view.dart`, `paged_sliver_list.dart`, `test/widgets/paged_body_view_test.dart`.

**Effort:** 2.5 hari (naik dari 2 karena sliver lebih kompleks dari ListView).

---

### 4.2 [WS-DS2] `ErrorState` + Adopsi `EmptyState`

**Masalah:** `EmptyState` sudah ada tapi 8+ halaman masih inline. Error view (icon + message + retry) diduplikasi di 5+ halaman dengan markup identik.

**Solusi:**

**⚠️ Prasyarat: modifikasi `EmptyState`** untuk menerima `iconColor` (default `AppColors.info` agar backward-compat). Saat ini `EmptyState` hardcode `color: AppColors.info` (line 33), sehingga `ErrorState` yang inherit akan salah warna (biru, bukan merah).

```dart
// lib/widgets/empty_state.dart — MODIFY (tambah iconColor)
class EmptyState extends StatelessWidget {
  final IconData icon;
  final Color? iconColor; // NEW — default AppColors.info via _resolveIconColor
  final String title;
  // ... existing fields
}

// lib/widgets/error_state.dart — NEW
/// Error state dengan retry button. Turunan pola EmptyState.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon; // default Icons.error_outline
  const ErrorState({...});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      iconColor: AppColors.error, // ← fix: warna merah untuk error
      title: message,
      action: onRetry != null
          ? ElevatedButton(onPressed: onRetry, child: Text('Coba Lagi'))
          : null,
    );
  }
}
```

**Acceptance Criteria:**
- [ ] `ErrorState` di `lib/widgets/`.
- [ ] `delivery_page._buildEmptyState` dihapus, ganti `EmptyState` langsung.
- [ ] Error view inline di `fuel_service_list_page`, `procurement_workflow_page`, `daily_salary_list_page`, `leave_page`, `closing_store_page` di-migrasi ke `ErrorState` (5 halaman dalam scope ini, sisanya sprint berikutnya).
- [ ] Widget test untuk `ErrorState`.

**File:** `lib/widgets/error_state.dart`, `test/widgets/error_state_test.dart`.

**Effort:** 0.5 hari.

---

### 4.3 [WS-DS3] `PhotoUploader` — Multi/Single, Grid/Horizontal

**Masalah:** 12+ halaman re-implement photo picker dengan core flow identik (source picker modal → `pickImage(maxWidth:1024, imageQuality:75)` → `ImageUtils.compressImage` → thumbnail + remove). Layout bervariasi: grid 3-kolom (delivery), horizontal list (asset_check), single-card (readiness/supplier), per-row button (utility_usage).

**Solusi:** Satu komponen dengan layout mode:

```dart
enum PhotoUploaderLayout { grid, horizontal, singleCard }

class PhotoUploader extends StatefulWidget {
  final List<File> photos;
  final ValueChanged<List<File>> onChanged; // add/remove callback
  final int maxPhotos; // default 1, untuk single; null = unlimited
  final PhotoUploaderLayout layout; // default grid
  final String label; // "Unggah Foto Bukti Pengiriman"
  final String? subtitle; // "Ketuk untuk membuka kamera / galeri"
  final String? directory; // upload directory, default 'images/Delivery'
  final bool required; // show asterisk

  /// Internal: _showImageSourceSheet (camera/gallery) shared helper.
  const PhotoUploader({...});
}
```

**Acceptance Criteria:**
- [ ] `PhotoUploader` di `lib/widgets/` support 3 layout mode.
- [ ] Shared `_showImageSourceSheet` (camera vs gallery bottom sheet) — tidak duplikat di tiap page.
- [ ] Compress image via `ImageUtils.compressImage` otomatis.
- [ ] Remove button per thumbnail.
- [ ] `maxPhotos` enforcement (disable add button saat penuh).
- [ ] Widget test: single add, multi add, remove, maxPhotos reached.
- [ ] `delivery_page._buildPhotoUploader` di-migrasi. Tampilan grid 3-kolom identik.

**File:** `lib/widgets/photo_uploader.dart`, `test/widgets/photo_uploader_test.dart`.

**Effort:** 2 hari.

---

### 4.4 [WS-DS4] Adopsi `StatusBadge` + `status_mappers.dart`

**Masalah:** `StatusBadge` sudah ada dan dipakai 5 halaman. Tapi 10+ halaman masih inline pill + **37 private `_statusColor`/`_getStatusColor` helper** tersebar (audit aktual 2026-07-22, bukan 14 seperti estimasi awal). Tidak ada pemetaan terpusat domain status → `StatusType`.

**⚠️ StatusBadge perlu variant `outline`:** kode aktual punya 2 style pill:
- **Filled** (background tinted) — yang `StatusBadge` sedang punya
- **Outline** (border only, transparent background) — dipakai di beberapa page (e.g., `fuel_service_list_page` status pill border-only)

`StatusBadge` perlu tambah `StatusBadgeStyle { filled, outline }` agar bisa menggantikan semua inline pill.

**Solusi:**

```dart
// lib/widgets/status_badge.dart — MODIFY (tambah style variant)
enum StatusBadgeStyle { filled, outline }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;
  final BadgeSize size;
  final StatusBadgeStyle style; // NEW — default filled (backward-compat)
  // ...
}

// lib/utils/status_mappers.dart
class StatusMappers {
  /// Delivery status (1=pending, 2=valid, 3=delivered, 4=ready, 6=returned)
  static StatusType deliveryStatus(int code) => switch (code) {
    2 || 3 => StatusType.success,
    6 => StatusType.error,
    4 => StatusType.info,
    _ => StatusType.warning,
  };
  static String deliveryLabel(int code) => switch (code) {
    1 => 'Pending',
    2 => 'Valid',
    3 => 'Sudah Dikirim',
    4 => 'Siap Dikirim',
    6 => 'Dikembalikan',
    _ => 'Unknown',
  };

  /// Payment status, payment proof status, procurement status, dst.
  // ... satu method per domain
}
```

**Acceptance Criteria:**
- [ ] `StatusBadge` ditambah variant `outline` (border-only, transparent bg).
- [ ] `status_mappers.dart` berisi mapper untuk: delivery, payment, paymentProof, procurement, leave, salary, hygiene, readiness.
- [ ] `delivery_page._getDeliveryStatusColor` + `_getDeliveryStatusText` + `_getPaymentStatusColor` + `_getPaymentStatusText` dihapus, ganti `StatusBadge(type: StatusMappers.deliveryStatus(code), label: StatusMappers.deliveryLabel(code))`.
- [ ] Unit test untuk semua mapper.
- [ ] **Migrasi konkret minimal 5 halaman** (lihat tabel di §4.9).
- [ ] **Inline `_statusColor` helper berkurang dari 37 → ≤ 15** (verifiable via `grep -rc "_getStatusColor\|_statusColor" lib/pages/`).

**File:** `lib/widgets/status_badge.dart` (modify), `lib/utils/status_mappers.dart`, `test/utils/status_mappers_test.dart`.

**Effort:** 2 hari (naik dari 1.5 karena variant outline + lebih banyak migrasi).

---

### 4.5 [WS-DS5] `DetailRow` + `IconDetailRow`

**Masalah:** 9 halaman punya `_buildDetailRow`/`_buildInfoRow`/`_buildRowItem` dengan 2 varian visual: (1) fixed-width label horizontal (delivery), (2) icon + vertical label-over-value + divider (utility_usage, supplier).

**Solusi:** Dua widget:

```dart
/// Varian 1: horizontal, fixed-width label (delivery style).
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth; // default 120
  final bool valueBold;
  const DetailRow({...});
}

/// Varian 2: icon + vertical label-over-value + divider (utility/supplier style).
class IconDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap; // copy-to-clipboard
  final bool showDivider;
  const IconDetailRow({...});
}
```

**Acceptance Criteria:**
- [ ] 2 widget di `lib/widgets/`.
- [ ] `delivery_page._buildDetailRow` di-migrasi ke `DetailRow`.
- [ ] Migrasi 2 halaman lain (utility_usage_detail, supplier_detail) ke `IconDetailRow`.
- [ ] Widget test untuk kedua varian.

**File:** `lib/widgets/detail_row.dart`, `test/widgets/detail_row_test.dart`.

**Effort:** 1 hari.

---

### 4.6 [WS-DS6] `FilterChipRow<T>` + `SectionCard`

**Masalah:** 9+ halaman re-implement horizontal filter chip row (`SingleChildScrollView + Row + ChoiceChip/FilterChip`). 6+ halaman punya private `_buildInfoCard`/`_buildCard` dengan markup Card identik.

**Solusi:**

```dart
/// Horizontal scrollable chip group generic.
class FilterChipRow<T> extends StatelessWidget {
  final List<T> options;
  final T? selected;
  final ValueChanged<T?> onSelected;
  final String Function(T) getLabel;
  final bool scrollable; // default true
  const FilterChipRow({...});
}

/// Card dengan optional header (circular icon + title).
class SectionCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? icon;
  final Color? iconColor;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  const SectionCard({...});
}
```

**Acceptance Criteria:**
- [ ] 2 widget di `lib/widgets/`.
- [ ] `delivery_page` inline filter (jika ada) + 6 inline detail Card di-migrasi ke `SectionCard`.
- [ ] Migrasi filter chip di fuel_service_list_page + utility_usage_list_page ke `FilterChipRow`.
- [ ] Widget test untuk kedua komponen.

**File:** `lib/widgets/filter_chip_row.dart`, `section_card.dart`, `test/widgets/`.

**Effort:** 1.5 hari.

---

### 4.7 [WS-DS7] `SearchTextField`

**Masalah:** 8 halaman re-implement search TextField dengan prefix icon + clear button. `ModernTextField` sudah ada tapi under-used.

**Solusi:**

```dart
/// Search field dengan prefix icon + optional clear button.
/// Built on top of ModernTextField untuk konsistensi theme.
class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCleared;
  final String hintText;
  final IconData prefixIcon; // default Icons.search
  final Widget? suffixWidget; // optional (e.g., scan barcode button)
  const SearchTextField({...});
}
```

**Acceptance Criteria:**
- [ ] `SearchTextField` di `lib/widgets/`.
- [ ] `delivery_page._buildGoldTextField` di-migrasi (4 call site).
- [ ] Widget test.

**File:** `lib/widgets/search_text_field.dart`, `test/widgets/search_text_field_test.dart`.

**Effort:** 0.5 hari.

---

### 4.8 [WS-DS8] Storybook / Demo Page Update

**Masalah:** `lib/pages/design_demo_page.dart` sudah ada (359 LOC) tapi hanya demo header/button/input/card/loading/list. **Tidak demo** komponen design system baru (StatusBadge, EmptyState, ErrorState, PagedBodyView, PhotoUploader, DetailRow, FilterChipRow, SectionCard, SearchTextField). Developer baru tidak punya cara lihat semua variant di 1 tempat.

**Solusi:** Extend `design_demo_page.dart` dengan section per komponen baru. Setiap section tunjukkan semua variant (e.g., StatusBadge section: 5 StatusType × 2 style × 2 size = 20 kombinasi).

**Acceptance Criteria:**
- [ ] `design_demo_page.dart` ditambah section untuk tiap komponen baru (9 section).
- [ ] Tiap section tunjukkan semua variant yang tersedia.
- [ ] Storybook accessible via route tersembunyi (debug-only) atau di drawer admin.
- [ ] Screenshot baseline disimpan untuk visual regression check manual.

**File:** `lib/pages/design_demo_page.dart` (modify), `docs/design-system-baseline/` (screenshot folder).

**Effort:** 1 hari.

---

### 4.9 Tabel Migrasi Konkret (per komponen → page target)

PRD ini menetapkan **minimal 5 halaman migrasi** per komponen sebagai proof-of-pattern. Daftar konkret:

| Komponen | Page yang harus di-migrasi di Sprint 1-2 |
|---|---|
| `PagedBodyView` | delivery_page, fuel_service_list_page, procurement_workflow_page, supplier_list_page, leave_page |
| `ErrorState` + `EmptyState` | delivery_page, fuel_service_list_page, closing_store_page, daily_salary_list_page, leave_page |
| `PhotoUploader` | delivery_page, fuel_service_form_page, asset_check_form_page, supplier_form_page, readiness_page |
| `StatusBadge` + `status_mappers` | delivery_page, fuel_service_list_page, procurement_detail_page, leave_page, salary_page, transfer_stock_detail_page |
| `DetailRow` + `IconDetailRow` | delivery_page, utility_usage_detail_page, supplier_detail_page, procurement_detail_page, invoice_detail_page |
| `FilterChipRow` | fuel_service_list_page, utility_usage_list_page, calendar_page, production_list_page, sales_dashboard_page |
| `SectionCard` | delivery_page (6 inline card), utility_usage_detail_page, supplier_detail_page |
| `SearchTextField` | delivery_page, supplier_list_page, asset_list_page |

**Sisanya** (page yang tidak masuk tabel di atas) di-migrasi di sprint berikutnya secara ongoing. Target akhir: 0 inline `_statusColor` helper, 0 inline empty/error view, semua list page pakai `PagedBodyView`.

---

## 4.10 Design Token Audit (Prasyarat)

**Masalah:** `AppColors` dan `AppSpacing` sudah ada token yang baik, tapi banyak page **hardcode** nilai spacing/radius alih-alih pakai token. Audit cepat menemukan variasi:
- `borderRadius: 12` vs `borderRadius: 10` vs `AppSpacing.borderRadiusSM` (8) di page berbeda
- `SizedBox(height: 16)` vs `AppSpacing.md` (16) — nilai sama tapi tidak konsisten pakai token
- `padding: EdgeInsets.all(8)` vs `AppSpacing.paddingSM`

**Solusi:** Sebelum buat komponen baru, lakukan audit 1 jam:
1. Grep `borderRadius: [0-9]` dan `EdgeInsets.(all|symmetric)\([0-9]` di `lib/pages/`.
2. Identifikasi token yang sering di-hardcode (kemungkinan: radius 10/12/16, padding 8/12/16).
3. Tambahkan token yang kurang ke `AppSpacing` (e.g., `borderRadiusMD = 12` bila sering dipakai).
4. Buat aturan: **komponen design system baru WAJIB pakai token**, bukan hardcoded number.

**Acceptance Criteria:**
- [ ] Audit grep dilakukan, hasil terdokumentasi di section ini.
- [ ] Token yang kurang ditambahkan ke `AppSpacing` / `AppColors`.
- [ ] Semua komponen baru di WS-DS1 sampai WS-DS7 pakai token (bukan hardcoded number).

**Effort:** 0.5 hari (audit cepat + tambah token).

---

## 5. Roadmap Eksekusi

### 5.1 Timeline

```
Sprint 1 (2 minggu): CORE COMPONENTS
├─ §4.10   Design Token Audit                  (0.5 hari) ★ prasyarat
├─ WS-DS2  ErrorState + EmptyState modify      (0.5 hari)
├─ WS-DS1  PagedBodyView + PagedSliverList     (2.5 hari) ★ foundation, naik dari 2
├─ WS-DS3  PhotoUploader                        (2 hari)
└─ WS-DS4  StatusBadge outline + status_mappers (2 hari) ★ naik dari 1.5

Sprint 2 (2 minggu): COMPLETION + DELIVERY MIGRATION
├─ WS-DS5  DetailRow + IconDetailRow           (1 hari)
├─ WS-DS6  FilterChipRow + SectionCard         (1.5 hari)
├─ WS-DS7  SearchTextField                     (0.5 hari)
├─ WS-DS8  Storybook update                    (1 hari) ★ NEW
└─ Delivery migration checkpoint               (1 hari)
    └─ Verifikasi delivery_page pakai semua 8 komponen
```

### 5.2 Validation Strategy: delivery_page sebagai smoke test

Setelah **setiap** workstream selesai, migrasikan pattern terkait di `delivery_page.dart`. Ini berfungsi sebagai:
1. **Regression test** — jika tampilan delivery berubah, komponen salah.
2. **Documentation live** — developer lain bisa lihat cara pakai di page paling kompleks.
3. **LOC reduction checkpoint** — delivery_page harus turun bertahap.

| Setelah WS- | delivery_page LOC target | Catatan |
|---|---|---|
| Baseline | 3.936 | |
| WS-DS1 (PagedBodyView + sliver) | ~3.820 (−116) | loading/empty/footer boilerplate hilang |
| WS-DS2 (ErrorState) | ~3.800 (−20) | `_buildEmptyState` hapus |
| WS-DS3 (PhotoUploader) | ~3.750 (−50) | `_buildPhotoUploader` + `_processPickedImage` hapus |
| WS-DS4 (StatusBadge) | ~3.680 (−70) | `_getDeliveryStatusColor/Text`, `_getPaymentStatusColor/Text` hapus |
| WS-DS5 (DetailRow) | ~3.650 (−30) | `_buildDetailRow` hapus |
| WS-DS6 (SectionCard) | ~3.520 (−130) | 6 inline Card detail sections jadi 1 komponen |
| WS-DS7 (SearchTextField) | ~3.500 (−20) | `_buildGoldTextField` hapus |

**Total realistis: ~436 LOC berkurang** (bukan 686 seperti estimasi awal). Ini karena komponen design system hanya menggantikan UI primitive — bukan menghapus logic. Bagian besar yang **tidak tersentuh** oleh PRD ini:
- `_buildOnlineOrderDetailView` (1.080 LOC) — butuh refactor terpisah (lihat PRD delivery refactor)
- `_buildOrderDetailView` (648 LOC dispatcher) — butuh refactor terpisah
- PDF print logic (200+ LOC) — butuh `PaymentProofPdfService` terpisah
- Thermal sticker print (60+ LOC) — butuh `StickerPrintOrchestrator` terpisah

**Sisanya (~3.500 LOC) adalah kandidat untuk PRD delivery refactor terpisah** (`2026-07-21-delivery-page-refactor-design.md`). Design system foundation ini adalah **prasyarat** — bukan pengganti — untuk refactor delivery_page penuh.

---

## 6. Success Metrics

### 6.1 KPI Kuantitatif

| Metrik | Baseline | Target Sprint 2 |
|---|---|---|
| Komponen reusable baru | 0 | **8** (7 baru + StatusBadge modify) |
| Widget test baru | 0 | **≥ 28** |
| `delivery_page.dart` LOC | 3.936 | **< 3.500** (realistis, bukan 3.300) |
| Halaman yang pakai `PagedBodyView` | 0 | **≥ 5** (lihat tabel §4.9) |
| Halaman yang pakai `PhotoUploader` | 0 | **≥ 5** |
| Halaman yang pakai `StatusBadge` | 5 | **≥ 11** |
| Halaman yang pakai `EmptyState`/`ErrorState` | 3 | **≥ 8** |
| Private `_statusColor` helper tersisa | 37 | **≤ 15** (verifiable via grep) |
| Section di `design_demo_page` | 6 | **≥ 15** (6 lama + 9 baru) |
| `flutter analyze` issues di widget baru | — | **0** |

### 6.2 KPI Kualitatif

- **Konsistensi visual** — semua list page punya loading/error/empty/pagination behavior identik.
- **DX** — tambah list page baru cukup pakai `PagedBodyView` + `itemBuilder`, tidak perlu copy ScrollController boilerplate.
- **Maintainability** — ubah style badge/empty/error di 1 tempat, langsung efek ke semua halaman.

---

## 7. Risk Register

| ID | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| R1 | `PagedBodyView` terlalu rigid untuk edge case (e.g., delivery punya search field di atas list) | Sedang | Tinggi | Support `header` slot widget; jika tetap tidak fit, fallback ke komposisi manual |
| R2 | `PhotoUploader` layout varian tidak cukup cover semua use case | Sedang | Sedang | Mulai dengan 3 mode (grid/horizontal/singleCard); tambah mode bila ada page yang tidak fit |
| R3 | Migrasi `StatusBadge` breaking karena warna sedikit beda | Rendah | Sedang | Side-by-side compare sebelum hapus kode lama |
| R4 | Delivery migration memakan waktu lebih lama dari estimasi | Tinggi | Sedang | Migrasi per-pattern setelah WS selesai, bukan batch di akhir |
| R5 | Komponen baru conflict dengan theme dark mode | Sedang | Sedang | Test di light + dark; pakai `Theme.of(context)` bukan hardcoded color |
| R6 | `PagedBodyView` sliver-based terlalu kompleks untuk page simpel | Sedang | Sedang | Tetap dukung mode non-sliver (sliverHeader: null → pure sliver list); dokumentasikan di storybook kapan pakai header |
| R7 | Migrasi 5 page per komponen memakan waktu lebih lama dari estimasi | Tinggi | Sedang | Migrasi paling mudah dulu (EmptyState/ErrorState), baru yang kompleks (PagedBodyView); jangan batch |

---

## 8. Out of Scope

- **Refactor state delivery_page** (Provider migration, WS-D3 di PRD delivery) — sprint terpisah.
- **HorizontalStepper** generic (hanya 2 pemakai, tunggu yang ke-3).
- **Migrasi semua 22 halaman ke `PagedBodyView`** — Sprint 1-2 hanya migrasi 5 page per komponen (lihat §4.9). Sisanya ongoing.
- **Refactor page besar lain** (closing_store, sales_dashboard, supplier_form).
- **Detail view decomposition** (`_buildOnlineOrderDetailView` 1.080 LOC) — di PRD delivery refactor terpisah.
- **PDF/thermal print service extraction** — di PRD delivery refactor terpisah.

---

## 9. Acceptance Criteria Keseluruhan

- [ ] 8 komponen reusable (7 baru + 1 modify `StatusBadge`) di `lib/widgets/` (+ `status_mappers.dart` di `lib/utils/`).
- [ ] Setiap komponen punya widget test (total ≥ 28 test case).
- [ ] `delivery_page.dart` memakai semua 8 komponen — tampilan identik sebelum/sesudah.
- [ ] `delivery_page.dart` LOC < 3.500 (turun ≥ 400 dari pure component extraction — angka realistis).
- [ ] ≥ 5 halaman lain mulai migrasi per komponen (lihat tabel §4.9).
- [ ] Inline `_statusColor` helper berkurang dari 37 → ≤ 15.
- [ ] `design_demo_page.dart` punya section untuk semua 9 komponen baru.
- [ ] `flutter analyze` → 0 error/warning di semua file baru + file yang di-migrasi.
- [ ] Pull-to-refresh berfungsi di semua kondisi (loading/error/empty/data) — diverifikasi di delivery_page.
- [ ] Storybook accessible & screenshot baseline tersimpan.

---

## 10. Appendix

### A. Referensi
- `delivery_page.dart` sebagai reference implementation (line references di tiap WS).
- Hasil audit reusable component (agent exploration, 2026-07-22).
- `PRD_CODEBASE_IMPROVEMENT.md` §3 (arsitektur target widget layer).
- Refactor `home_page.dart` sebagai proof of pattern (1945 → 402 LOC).

### B. Komponen yang sudah ada (di-extend, bukan baru)
- `StatusBadge` — extend dengan adopsi + `status_mappers`.
- `EmptyState` — extend dengan turunan `ErrorState`.

### C. Urutan komponen berdasarkan dependensi
```
WS-DS2 (ErrorState)     → dipakai WS-DS1 (PagedBodyView)
WS-DS1 (PagedBodyView)  → foundation, tidak depend WS lain
WS-DS3-7                → independen, bisa paralel
```

---

**Akhir dokumen.**
