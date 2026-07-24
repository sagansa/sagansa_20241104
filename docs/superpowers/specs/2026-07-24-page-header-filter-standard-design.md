# PRD: Standarisasi Header & Filter Halaman — Sagansa Mobile

**Versi:** 1.0
**Tanggal:** 2026-07-24
**Status:** Draft — Ready for Implementation
**Scope:** `mobiles/sagansa/lib/pages/` (semua halaman list/dashboard)
**Spec induk:** Audit codebase 2026-07-24 (filter inconsistency)

---

## 1. Konteks & Masalah

Audit 16+ halaman list/dashboard menemukan **3 pola filter yang berbeda** dengan konsumsi ruang layar sangat bervariasi (0–4 baris). Tidak ada standar tunggal, sehingga halaman "penjualan" dan "pembelian" terlihat seperti aplikasi berbeda.

**Worst offenders (3-4 baris fixed header, ~200+dp):**
- `daily_salary_list_page.dart` — 5 filter (Karyawan, Status, Pembayaran, Range Tanggal)
- `salary_page.dart` — 3 filter (Karyawan, Periode, Status)
- `utility_usage_list_page.dart` — 3 filter (Toko, Jenis, Utility)
- `procurement_workflow_page.dart` — PreferredSize 64-110dp + StageTabs + StatsStrip + SubFilter + search expand
- `payment_receipt_dashboard_page.dart` — search + summary card + filter chips (3 blok)

Di handphone kecil, header ini bisa makan **30-40% tinggi layar** sebelum list muncul.

### 1.1 Inkonsistensi konkret

| Sisi | Konsistensi | Pola |
|------|-------------|------|
| Penjualan | ✅ konsisten | AppBar + TabBar (opsional) + 1 chip row periode |
| Pembelian | ❌ terpecah 3 cara | procurement (PreferredSize+stage+stats), invoice (tab only), payment_receipt (search+summary+chips) |

**Root cause:** Tidak ada komponen/aturan tunggal. Setiap halaman buat filter-nya sendiri. Widget `FilterChipRow` sudah dibuat (design system foundation) tapi **0 adopter**.

---

## 2. Standar (1 spec, 2 varian)

**Prinsip:** Satu-satunya yang boleh beda antar halaman adalah **ada TabBar atau tidak**. Selebihnya — search, filter, summary, stats — aturannya identik di kedua varian.

```
┌─ AppBar ──────────────────────────────┐
│  Judul           [🔍] [⚙️³] [⋮]       │  search icon + filter icon(badge) + overflow
├───────────────────────────────────────┤
│  [ Tab A ] [ Tab B ] [ Tab C ]         │  HANYA jika multi-tahap/kategori (opsional)
├───────────────────────────────────────┤
│  (konten/list langsung)                │
└───────────────────────────────────────┘

Varian 1 — ADA tab:    AppBar + TabBar + list
Varian 2 — TIDAK ada:  AppBar + list
```

### 2.1 Aturan identik untuk kedua varian

| Elemen | Aturan |
|--------|--------|
| **Search** | IconButton `🔍` di AppBar → toggle 1 baris inline saat aktif. Bukan default terbuka. |
| **Filter ≥2 atau dinamis** | IconButton `⚙️` dengan badge angka (jumlah filter aktif) → bottom sheet. Saat idle = 0 baris. |
| **Filter cepat terpisah (opsional)** | **1 slot** inline 1 baris chip row, posisi terpisah dari bottom sheet. Opsional — tidak semua halangan pakai. Detail tunda, lihat §2.3. |
| **Summary/stats/counter** | **Tidak di header.** Pindah jadi **badge di tab** (mis. `Request ③`), atau ringkasan yang ikut scroll di list. |
| **Navigasi tahap/kategori/tipe** | Satu-satunya alasan pakai TabBar di AppBar `bottom`. Termasuk tipe penjualan (Online/Employee/Direct) — lihat §2.4. |

### 2.2 Aturan ringkas (3 baris)

> ≤1 filter cepat inline (opsional); ≥2 atau dinamis = bottom sheet;
> navigasi tahap/tipe = TabBar; summary/stats = badge di tab (bukan baris sendiri).

### 2.3 Slot filter cepat terpisah (opsional)

Disediakan **1 slot inline 1 baris chip row** yang posisinya **terpisah** dari filter bottom sheet. Karakteristik:

- **Opsional** — halaman yang tidak butuh tidak pakai. Tergantung kebutuhan experience kedepan.
- **Maksimal 1 filter** di slot ini. Jika butuh >1, sisanya masuk bottom sheet.
- **Nilai cepat** — filter yang sering diubah (periode, status utama, scope). Bukan dropdown dinamis.
- **Posisi** — inline 1 baris langsung di bawah AppBar/TabBar, terpisah dari IconButton `⚙️`.

> Catatan: detail UI slot ini (komponen, layout) **ditunda** — yang penting spec-nya mencatat bahwa opsi ini dimungkinkan. Implementasi menyusul saat ada halaman yang benar-benar butuh.

### 2.4 Tipe penjualan sebagai TabBar

Saat ini `transaction_dashboard_page.dart` menampilkan dialog "Pilih Tipe Penjualan" (Online/Employee/Direct) saat tap menu Penjualan — masing-masing push ke halaman berbeda.

**Standar baru:** 3 tipe penjualan → **1 halaman dengan TabBar 3 tab**. User switch tipe via tab, tanpa bolak-balik ke menu utama.

```
┌─ AppBar ──────────────────────────────┐
│  Penjualan                 [🔍] [⋮]    │
├───────────────────────────────────────┤
│  [ Online ] [ Employee ] [ Direct ]    │  ← TabBar (3 tipe)
├───────────────────────────────────────┤
│  (list sesuai tipe aktif)              │
└───────────────────────────────────────┘
```

- Hapus dialog pilih tipe (`showDialog` di transaction_dashboard).
- `DeliveryPage(orderMode: OrderMode.online)` → jadi konten Tab Online.
- `SalesOrderEmployeeListPage` → jadi konten Tab Employee.
- Direct order → jadi konten Tab Direct.
- Ini varian 1 (ada tab) — semua aturan filter/search tetap berlaku identik.

---

## 3. Komponen yang Dibutuhkan

### 3.1 `FilterBottomSheet` (new widget)

Generic bottom sheet untuk filter. Terima list `FilterField`, tampilkan dalam bottom sheet, return nilai terpilih saat "Terapkan".

**File:** `lib/widgets/filter_bottom_sheet.dart`

```dart
/// Field spec untuk FilterBottomSheet.
abstract class FilterField<T> {
  final String label;
  final T value;          // current value (null = belum pilih)
  const FilterField({required this.label, required this.value});
}

/// Dropdown field (karyawan, status, dll — nilai dari API).
class DropdownFilterField<T> extends FilterField<T?> {
  final List<(T, String)> options;  // (value, label)
  const DropdownFilterField({...});
}

/// Date-range field.
class DateRangeFilterField extends FilterField<(DateTime, DateTime)?> {
  const DateRangeFilterField({...});
}

/// Bottom sheet generik.
/// Panggil: FilterBottomSheet.show(context, fields: [...], onApply: (...) {})
class FilterBottomSheet extends StatefulWidget { ... }
```

**Footer:** tombol "Reset" (kosongkan semua) + "Terapkan" (apply + close).

### 3.2 `FilterAppBarAction` (new widget)

IconButton `⚙️` dengan badge counter. Tap → panggil `FilterBottomSheet.show()`.

```dart
/// AppBar action untuk filter.
/// [activeCount] = jumlah filter aktif (tampil sebagai badge).
/// [onTap] = biasanya buka FilterBottomSheet.
class FilterAppBarAction extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;
  const FilterAppBarAction({...});
  // Render: Badge(label: activeCount.toString(), child: IconButton(Icons.tune))
}
```

### 3.3 `SearchAppBarAction` (new widget)

IconButton `🔍` yang toggle inline search bar (1 baris) di body.

### 3.4 `FilterChipRow` (sudah ada — adopsi)

Widget design-system yang sudah dibuat tapi 0 adopter. Dipakai untuk kasus ≤1 filter cepat inline.

---

## 4. Pemetaan Migrasi

| Halaman | Varian | Perubahan vs sekarang | Prioritas |
|---------|--------|-----------------------|-----------|
| `sales_dashboard_page` | 1 (tab) | ✅ sudah cocok (periode row = 1 chip) | — |
| `invoice_dashboard_page` | 1 (tab) | ✅ pola emas | — |
| `fuel_service_list_page` | 2 (no tab) | ✅ sudah cocok (1 chip row fixed-height) | — |
| **`transaction_dashboard` → halaman Penjualan baru** | 1 (tab) | 🔴 Hapus dialog pilih tipe. Gabung Online/Employee/Direct jadi 1 halaman + 3 tab (§2.4) | **P1** |
| `procurement_workflow_page` | 1 (tab) | 🔴 StageTabs→TabBar, StatsStrip→badge di tab, search→icon, SubFilter→1 chip/sheet | **P1** |
| `payment_receipt_dashboard_page` | 2 (no tab) | 🔴 summary card keluar header, search→icon, chips→sheet atau tetap 1 row | **P1** |
| `daily_salary_list_page` | 2 (no tab) | 🔴 dropdown stack 4 baris → bottom sheet + badge | **P1** |
| `salary_page.dart` | 2 (no tab) | 🔴 dropdown stack 4 baris → bottom sheet + badge | **P2** |
| `utility_usage_list_page` | 2 (no tab) | 🔴 dropdown stack 3 baris → bottom sheet + badge | **P2** |
| `presence_monthly_page` | 2 (no tab) | 🟡 dropdown stack 3 baris → bottom sheet + badge | **P2** |
| `supplier_list_page` | 2 (no tab) | 🟡 search→icon, chip tetap | **P3** |
| `production_list_page` | 2 (no tab) | 🟡 2 chip group → konsistenkan | **P3** |
| `asset_list_page` | 2 (no tab) | 🟡 2 chip group → konsistenkan | **P3** |

> Catatan: `sales_order_employee_list_page` setelah migrasi penjualan (§2.4) menjadi konten Tab Employee di halaman Penjualan — bukan halaman standalone lagi.

---

## 5. Task Sequencing

1. **Task 1:** Bikin komponen `FilterBottomSheet` + `FilterAppBarAction` + `SearchAppBarAction` + unit tests
2. **Task 2:** Gabung 3 tipe penjualan → 1 halaman + TabBar (hapus dialog pilih tipe)
3. **Task 3:** Migrasi `procurement_workflow_page` (pilot — paling parah, paling impactful)
4. **Task 4:** Migrasi `payment_receipt_dashboard_page`
5. **Task 5:** Migrasi `daily_salary_list_page` + `salary_page` + `utility_usage_list_page` + `presence_monthly_page` (batch — pola mirip)
6. **Task 6:** Konsistenkan halaman P3 (supplier, production, asset)
7. **Task 7:** Smoke test + verifikasi semua halaman

---

## 6. Decision Log

- **Opsi 1 (badge di tab) dipilih** untuk StatsStrip procurement. Counter "butuh perhatian" (pending approval, siap invoice, siap bayar) → badge angka di tiap tab (`Request ③`). Alasan: paling konsisten dengan standar, tidak ada exception khusus.
- **Tidak ada varian khusus procurement.** Hanya 2 varian (ada tab / tidak ada tab).
- **Filter cepat ≤1 boleh inline**, ≥2 wajib bottom sheet. Alasan: 1 filter tidak makan banyak ruang; 2+ filter inline yang boros layar.
- **Slot filter cepat terpisah** (§2.3) — 1 slot inline opsional, terpisah dari bottom sheet. Detail tunda; yang penting spec mencatat opsi ini tersedia.
- **Tipe penjualan jadi TabBar** (§2.4) — 3 tipe (Online/Employee/Direct) dalam 1 halaman, hapus dialog pilih tipe. Alasan: user tidak perlu bolak-balik ke menu utama untuk switch tipe.
- **Summary/stats tidak di header.** Alasan: header harus tipis dan fokus pada navigasi + filter. Summary → badge di tab atau ikut scroll.

---

## 7. Self-Review

### Spec coverage

| Aturan | Komponen/Task |
|--------|---------------|
| Search → AppBar IconButton toggle | Task 1 (`SearchAppBarAction`) |
| Filter ≥2 → bottom sheet + badge | Task 1 (`FilterBottomSheet` + `FilterAppBarAction`) |
| Filter ≤1 → inline chip row | Pakai `FilterChipRow` (existing) |
| Navigasi tahap → TabBar | Task 2 (procurement migration) |
| Summary/stats → badge di tab | Task 2 (procurement migration) |
| 2 varian (ada tab / tidak) | Section 2 |

### Tidak ada exception khusus

Procurement, sales, purchase — semua ikut aturan yang sama. Tidak ada perlakuan khusus berdasarkan domain.

### Type consistency

- `FilterField<T>` — generic, dipakai semua field type
- `FilterAppBarAction.activeCount: int` — badge counter
- `FilterBottomSheet.show()` return `Map<String, dynamic>` — seragam
