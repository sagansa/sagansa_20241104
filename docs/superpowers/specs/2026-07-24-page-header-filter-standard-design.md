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
| **Filter = 1 status/periode cepat** | Boleh inline 1 baris chip row (opsional). Bisa juga masuk bottom sheet. |
| **Summary/stats/counter** | **Tidak di header.** Pindah jadi **badge di tab** (mis. `Request ③`), atau ringkasan yang ikut scroll di list. |
| **Navigasi tahap/kategori** | Satu-satunya alasan pakai TabBar di AppBar `bottom`. |

### 2.2 Aturan ringkas (3 baris)

> ≤1 filter inline = chip row; ≥2 atau dinamis = bottom sheet;
> navigasi tahap = TabBar; summary/stats = badge di tab (bukan baris sendiri).

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
| `procurement_workflow_page` | 1 (tab) | 🔴 StageTabs→TabBar, StatsStrip→badge di tab, search→icon, SubFilter→1 chip/sheet | **P1** |
| `payment_receipt_dashboard_page` | 2 (no tab) | 🔴 summary card keluar header, search→icon, chips→sheet atau tetap 1 row | **P1** |
| `daily_salary_list_page` | 2 (no tab) | 🔴 dropdown stack 4 baris → bottom sheet + badge | **P1** |
| `salary_page.dart` | 2 (no tab) | 🔴 dropdown stack 4 baris → bottom sheet + badge | **P2** |
| `utility_usage_list_page` | 2 (no tab) | 🔴 dropdown stack 3 baris → bottom sheet + badge | **P2** |
| `presence_monthly_page` | 2 (no tab) | 🟡 dropdown stack 3 baris → bottom sheet + badge | **P2** |
| `supplier_list_page` | 2 (no tab) | 🟡 search→icon, chip tetap | **P3** |
| `sales_order_employee_list_page` | 2 (no tab) | 🟡 1 dropdown → bisa tetap inline atau masuk sheet | **P3** |
| `production_list_page` | 2 (no tab) | 🟡 2 chip group → konsistenkan | **P3** |
| `asset_list_page` | 2 (no tab) | 🟡 2 chip group → konsistenkan | **P3** |

---

## 5. Task Sequencing

1. **Task 1:** Bikin komponen `FilterBottomSheet` + `FilterAppBarAction` + `SearchAppBarAction` + unit tests
2. **Task 2:** Migrasi `procurement_workflow_page` (pilot — paling parah, paling impactful)
3. **Task 3:** Migrasi `payment_receipt_dashboard_page`
4. **Task 4:** Migrasi `daily_salary_list_page` + `salary_page` + `utility_usage_list_page` + `presence_monthly_page` (batch — pola mirip)
5. **Task 5:** Konsistenkan halaman P3 (supplier, sales_order_employee, production, asset)
6. **Task 6:** Smoke test + verifikasi semua halaman

---

## 6. Decision Log

- **Opsi 1 (badge di tab) dipilih** untuk StatsStrip procurement. Counter "butuh perhatian" (pending approval, siap invoice, siap bayar) → badge angka di tiap tab (`Request ③`). Alasan: paling konsisten dengan standar, tidak ada exception khusus.
- **Tidak ada varian khusus procurement.** Hanya 2 varian (ada tab / tidak ada tab).
- **Filter ≤1 cepat boleh inline**, ≥2 wajib bottom sheet. Alasan: 1 filter tidak makan banyak ruang; 2+ filter inline yang boros layar.
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
