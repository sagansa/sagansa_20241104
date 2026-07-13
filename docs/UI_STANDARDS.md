# UI Standards — Sagansa Mobile (Flutter)

Standar tampilan untuk aplikasi `mobiles/sagansa`. Dokumen ini adalah **sumber kebenaran** untuk cara membangun UI yang konsisten antar halaman. Target pembaca: setiap kontributor yang menulis atau menyentuh kode UI.

> **Prinsip utama:** satu sumber kebenaran. Semua warna, jarak, ukuran, dan tipografi **harus** lewat token (`AppColors`, `AppSpacing`, `AppTypography`) atau lewat `Theme.of(context)`. Tidak ada angka/nilai hardcoded di dalam `lib/pages/`.

---

## Daftar Isi

1. [Lapisan Design System](#1-lapisan-design-system)
2. [Aturan Warna & Dark Mode](#2-aturan-warna--dark-mode)
3. [Spacing & Radius](#3-spacing--radius)
4. [Tipografi](#4-tipografi)
5. [Komponen: Scaffold & AppBar](#5-komponen-scaffold--appbar)
6. [Komponen: Tombol](#6-komponen-tombol)
7. [Komponen: Input & Form](#7-komponen-input--form)
8. [Komponen: Dropdown / Select](#8-komponen-dropdown--select)
9. [Komponen: Date Picker](#9-komponen-date-picker)
10. [Komponen: Card](#10-komponen-card)
11. [Komponen: List & List Item](#11-komponen-list--list-item)
12. [Komponen: Status Badge / Chip](#12-komponen-status-badge--chip)
13. [Komponen: Modal / Dialog](#13-komponen-modal--dialog)
14. [Komponen: Bottom Sheet](#14-komponen-bottom-sheet)
15. [Komponen: Snackbar / Toast](#15-komponen-snackbar--toast)
16. [Komponen: Loading State](#16-komponen-loading-state)
17. [Komponen: Empty State](#17-komponen-empty-state)
18. [Komponen: Error State](#18-komponen-error-state)
19. [Komponen: FAB](#19-komponen-fab)
20. [Komponen: TabBar](#20-komponen-tabbar)
21. [Komponen: Bottom Navigation](#21-komponen-bottom-navigation)
22. [Struktur Halaman: List Page Template](#22-struktur-halaman-list-page-template)
23. [Anti-pattern yang DILARANG](#23-anti-pattern-yang-dilarang)
24. [Checklist Code Review](#24-checklist-code-review)

---

## 1. Lapisan Design System

Aplikasi memiliki 3 lapisan. Tulis kode di lapisan yang tepat.

```
lib/theme/         ← Token (warna, jarak, tipografi, elevasi). TIDAK ada widget.
  app_colors.dart        AppColors
  app_typography.dart    AppTypography
  app_spacing.dart       AppSpacing, AppElevation
  app_animations.dart    AppAnimations
lib/providers/
  theme_provider.dart    ThemeData (light/dark) — mengkonsumsi token di atas
lib/widgets/       ← Komponen reusable (ModernButton, AppCard, dll.)
lib/pages/         ← Halaman. Hanya menyusun komponen, TIDAK mendefinisikan gaya.
```

**Sumber kebenaran:** `ThemeProvider.lightTheme` / `darkTheme` adalah satu-satunya `ThemeData`. Didaftarkan di `main.dart` (`theme:`/`darkTheme:`/`themeMode:`).

> ⚠️ `lib/utils/themes.dart` (`class AppTheme`) adalah **sistem tema lama** yang sudah deprecated. Jangan dipakai. Lihat [§23](#23-anti-pattern-yang-dilarang).

### Cara mengakses tema di dalam widget

```dart
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;     // PAKAI INI untuk warna
final textTheme = theme.textTheme;          // PAKAI INI untuk teks
```

---

## 2. Aturan Warna & Dark Mode

Ini aturan paling penting. Pelanggaran di sini adalah penyebab utama tampilan "berbeda-beda" antar halaman.

### ✅ WAJIB — pakai `colorScheme` (auto light/dark)

```dart
color: colorScheme.surface              // background card/scaffold
color: colorScheme.onSurface            // teks utama
color: colorScheme.onSurfaceVariant     // teks sekunder/muted
color: colorScheme.primary              // emas brand
color: colorScheme.onPrimary            // teks di atas primary
color: colorScheme.surfaceVariant       // input/chip background
color: colorScheme.outline              // garis border
color: colorScheme.outlineVariant       // garis border halus
color: colorScheme.error                // merah error
color: colorScheme.primaryContainer     // chip/area emas lembut
```

`colorScheme` sudah otomatis resolve: di light mode pakai `AppColors.surface`, di dark mode pakai `AppColors.darkSurface`. **Anda tidak perlu tahu apakah sedang dark atau light.**

### ❌ DILARANG — ternary `isDark`

```dart
// DILARANG — duplikasi logika tema yang sudah ada di ThemeProvider
backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
foregroundColor: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
```

Aturan: jika Anda menulis `isDark ? AppColors.dark...`, **hentikan**. Itu tanda Anda harus pakai `colorScheme.X` sebagai gantinya. Pengecualian hanya untuk kasus yang benar-benar tidak ada di colorScheme (mis. gradient).

### Kapan boleh pakai `AppColors` langsung?

- Di dalam `lib/theme/` dan `lib/providers/theme_provider.dart` (definisi token).
- Untuk status color yang **tidak ada** di `ColorScheme`: `AppColors.success`, `AppColors.warning`, `AppColors.info` beserta container-nya.
- Untuk gradient: `AppColors.primaryGradient`, `cardGradient`.

### Token warna status (semantik)

| Token | Light | Dark | Untuk |
|---|---|---|---|
| `colorScheme.error` / `AppColors.error` | merah lembut | merah lembut | error, tolak, gagal |
| `AppColors.errorContainer` | — | — | background pesan error |
| `AppColors.success` | hijau | hijau | sukses, setujui, selesai |
| `AppColors.successContainer` | — | — | background badge sukses |
| `AppColors.warning` | oranye | oranye | pending, menunggu |
| `AppColors.warningContainer` | — | — | background badge pending |
| `AppColors.info` | biru muted | biru muted | info, tips |

> Jangan pernah `Colors.red` / `Colors.green` / `Colors.black` / `Colors.white` hardcoded di `lib/pages/`. Pakai token di atas.

---

## 3. Spacing & Radius

Semua jarak mengikuti grid 8px. **Dilarang menulis angka literal** di `EdgeInsets` atau `SizedBox`.

### Spacing scale — `AppSpacing`

| Token | Nilai | Pakai untuk |
|---|---|---|
| `xs` | 4 | jarak sangat kecil, gap dalam chip |
| `sm` | 8 | gap antar elemen rapat |
| `md` | 16 | gap standar, padding dalam card |
| `lg` | 24 | padding antar section |
| `xl` | 32 | jarak besar |
| `xxl` | 48 | jarak vertikal besar |

### Padding semantik (PAKAI INI, bukan `EdgeInsets.all(16)`)

```dart
AppSpacing.screenPadding      // padding body halaman (h:12, v:12)
AppSpacing.cardPadding        // padding dalam Card (all:12)
AppSpacing.listItemPadding    // padding item list (h:12, v:8)
AppSpacing.paddingMD          // 16 all
AppSpacing.paddingLG          // 24 all
AppSpacing.paddingHorizontalMD // 16 horizontal
```

### Gap (SizedBox pre-built)

```dart
AppSpacing.gapVerticalSM   // SizedBox(height: 8)
AppSpacing.gapVerticalMD   // SizedBox(height: 16)
AppSpacing.gapVerticalLG   // SizedBox(height: 24)
AppSpacing.gapHorizontalMD // SizedBox(width: 16)
AppSpacing.itemGap         // 8 (margin antar card/list-item)
AppSpacing.sectionGap      // 12 (margin antar section)
AppSpacing.rowGap          // 12 (gap antar elemen dalam Row)
```

### Border radius — 5 token SAJA

| Token | Nilai | Pakai untuk |
|---|---|---|
| `borderRadiusSM` | 8 | tile kecil, chip, ikon container |
| `borderRadiusMD` | 12 | **default**: card, input, tombol, dialog |
| `borderRadiusLG` | 16 | card besar, list item dengan avatar |
| `borderRadiusXL` | 20 | bottom sheet atas, modal besar |
| `borderRadiusXXL` | 24 | kartu hero / featured |

> ❌ Dilarang: `BorderRadius.circular(15)`, `circular(10)`, `circular(6)`, dll. Nilai 12 adalah default; 8/16/20/24 hanya bila ada alasan semantik.

---

## 4. Tipografi

Pakai `theme.textTheme.*`. Jangan hardcoded `TextStyle(fontSize:..., fontWeight:...)`.

| Style | Ukuran | Bobot | Pakai untuk |
|---|---|---|---|
| `displaySmall` | 36 | w400 | angka besar di dashboard |
| `headlineSmall` | 24 | w400 | judul halaman besar |
| `titleLarge` | 22 | w500 | **judul AppBar** |
| `titleMedium` | 16 | w500 | judul card, baris utama list |
| `titleSmall` | 14 | w500 | label section |
| `bodyLarge` | 16 | w400 | teks penting |
| `bodyMedium` | 14 | w400 | **teks body default** |
| `bodySmall` | 12 | w400 | teks sekunder (muted auto) |
| `labelLarge` | 14 | w500 | label form |
| `labelMedium` | 12 | w500 | badge, caption |
| `labelSmall` | 11 | w500 | label navigation |

### Aturan bobot

```dart
// ✅ Benar
Text('Judul', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))

// ❌ Dilarang
Text('Judul', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
Text('Error', style: TextStyle(color: Colors.red))
```

### Helper siap pakai (di `AppTypography`)

```dart
AppTypography.bodyMediumError(context)    // teks body warna error
AppTypography.bodyMediumSuccess(context)
AppTypography.labelMediumError(context)
AppTypography.titleLargeOnSurface(context)
```

---

## 5. Komponen: Scaffold & AppBar

### Scaffold

Jangan set `backgroundColor` manual — biarkan `scaffoldBackgroundColor` (sudah ada di tema) yang atur.

```dart
// ✅ Benar
return Scaffold(
  appBar: AppBar(title: const Text('Supplier')),
  body: ...,
);

// ❌ Dilarang
return Scaffold(
  backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
  appBar: AppBar(
    backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
    foregroundColor: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
    elevation: 0,
    title: Text('Supplier', style: textTheme.titleLarge?.copyWith(...)),
  ),
  ...
);
```

Semua properti AppBar di atas **sudah di-set di `appBarTheme`**. Menulisnya ulang = duplikasi.

### AppBar

- Judul: teks biasa, **jangan** set style manual (titleTextStyle sudah di-tema).
- `centerTitle`: konsisten per kategori. Default tema = `false`. Untuk halaman detail/form boleh `centerTitle: true`.
- Action: pakai `IconButton.filled`/`IconButton` dengan ikon dari `Icons.*_round` (varian rounded).
- Jika perlu `TabBar` di bawah AppBar, lihat [§20](#20-komponen-tabbar).

```dart
appBar: AppBar(
  title: const Text('Request & Purchase'),
  actions: [
    IconButton(
      icon: const Icon(Icons.filter_list_rounded),
      onPressed: _openFilter,
    ),
  ],
  bottom: const TabBar(...), // opsional
),
```

### Scaffold dengan TabBar

```dart
return DefaultTabController(
  length: 3,
  child: Scaffold(
    appBar: AppBar(
      title: const Text('Invoice'),
      bottom: const TabBar(
        tabs: [Tab(text: 'Draft'), Tab(text: 'Unpaid'), Tab(text: 'Done')],
      ),
    ),
    body: const TabBarView(...),
  ),
);
```

---

## 6. Komponen: Tombol

Pakai varian Material yang sudah di-tema: `ElevatedButton`, `OutlinedButton`, `TextButton`, `IconButton`. Tema sudah atur warna, padding, radius, dan tipografi.

### Tombol utama / submit

```dart
// Widget reusable untuk tombol full-width dengan loading
ModernButton(
  text: 'Simpan',
  icon: Icons.save_outlined,
  isLoading: _isSaving,
  onPressed: _save,
)
```

`ModernButton` (`lib/widgets/modern_button.dart`) mengandalkan `ElevatedButtonTheme` sehingga selalu ikut tema aktif. Gunakan ini untuk tombol submit/form utama.

### Varian lain

```dart
ElevatedButton.icon(           // primary, emas
  onPressed: () {},
  icon: const Icon(Icons.add_rounded),
  label: const Text('Tambah'),
)

OutlinedButton(                // sekunder, outline emas
  onPressed: () {},
  child: const Text('Batal'),
)

TextButton(                    // tersier / link
  onPressed: () {},
  child: const Text('Lihat Detail'),
)

IconButton(                    // aksi ikon
  icon: const Icon(Icons.delete_outline_rounded),
  onPressed: _delete,
)

IconButton.filled(             // aksi ikon primary (background emas)
  icon: const Icon(Icons.add_rounded),
  onPressed: _add,
)
```

### Aturan

- Tinggi tombol: jangan set `minimumSize` manual (tema sudah atur). `ModernButton` men-set `48` untuk tombol utama.
- Radius: ikut tema (`borderRadiusMD` = 12).
- Ikon: selalu varian `_rounded`/`_outline` (`Icons.add_rounded`, bukan `Icons.add`).
- Loading state: pakai `ModernButton(isLoading: true)` atau `CircularProgressIndicator` berukuran `SizedBox(width: 24, height: 24)`.

---

## 7. Komponen: Input & Form

Ada dua widget reusable:
- `ModernTextField` (`lib/widgets/modern_text_field.dart`) — `TextField`, prefixIcon **wajib**, tanpa validator.
- `ModernTextFormField` (`lib/widgets/modern_text_form_field.dart`) — `TextFormField`, prefixIcon opsional, dengan `validator`.

### TextField (tanpa validasi)

```dart
ModernTextField(
  labelText: 'Email',
  controller: _emailCtrl,
  prefixIcon: Icons.email_outlined,
  keyboardType: TextInputType.emailAddress,
)
```

### TextFormField (dengan validasi)

```dart
ModernTextFormField(
  labelText: 'Nama Supplier',
  controller: _nameCtrl,
  validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
  textCapitalization: TextCapitalization.words,
)
```

### Aturan input

- **Jangan** set `border`/`enabledBorder`/`focusedBorder`/`contentPadding` manual — `inputDecorationTheme` sudah atur (radius 12, padding 16, border emas saat fokus).
- `labelText` wajib (bukan `hintText`) agar label melayang.
- Ikon prefix: varian `_outlined` (`Icons.email_outlined`).
- Format input: pakai formatter dari `lib/utils/text_formatters.dart` (mis. `LowerCaseTextFormatter`).
- TextInputType: set sesuai konteks (`emailAddress`, `number`, `phone`, `multiline`).

### Text area (multi-line)

```dart
ModernTextFormField(
  labelText: 'Catatan',
  controller: _noteCtrl,
  maxLines: 4,
)
```

---

## 8. Komponen: Dropdown / Select

Pakai `ModernDropdown<T>` (`lib/widgets/modern_dropdown.dart`).

```dart
ModernDropdown<String>(
  value: _selectedCategory,
  hint: 'Pilih Kategori',
  items: _categories,
  getLabel: (c) => c.name,
  onChanged: (v) => setState(() => _selectedCategory = v),
)
```

### Aturan

- Generic `<T>` — jangan passing index `int` lalu map manual; passing objek/model.
- `getLabel` wajib untuk menentukan teks yang ditampilkan.
- **Jangan** set `border`/`contentPadding` manual (tema sudah atur).
- Untuk dropdown dengan banyak opsi atau search, pertimbangkan `ModernBottomSheet` berisi ListView.

---

## 9. Komponen: Date Picker

### Tanggal tunggal — `ModernDateField`

```dart
ModernDateField(
  labelText: 'Tanggal Mulai',
  value: _startDate,
  firstDate: DateTime.now(),
  lastDate: DateTime.now().add(const Duration(days: 365)),
  onChanged: (d) => setState(() => _startDate = d),
)
```

### Rentang tanggal — `ModernDateRangePicker`

```dart
ModernDateRangePicker(
  startDate: _start,
  endDate: _end,
  minDate: DateTime(2024),
  maxDate: DateTime.now(),
  onDateRangeSelected: (start, end) => setState(() {
    _start = start;
    _end = end;
  }),
)
```

### Aturan

- Selalu set `firstDate`/`lastDate` agar user tidak memilih tanggal tidak valid.
- Format tampilan: `dd MMM yyyy` (sudah default di widget).

---

## 10. Komponen: Card

### Card biasa (dari tema)

```dart
Card(
  child: Padding(
    padding: AppSpacing.cardPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [...],
    ),
  ),
)
```

`cardTheme` sudah atur: warna surface, elevasi level 2, radius 12, border halus, margin 16. **Jangan** set `elevation`/`shape`/`margin`/`color` manual.

### Card kustom (dengan InkWell / klik)

Untuk list item yang bisa diklik dan butuh kontrol lebih, pakai pattern Container + InkWell (seragamkan ke token):

```dart
Container(
  margin: const EdgeInsets.only(bottom: AppSpacing.itemGap),
  decoration: BoxDecoration(
    color: colorScheme.surface,
    borderRadius: AppSpacing.borderRadiusLG,
    border: Border.all(
      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
    ),
  ),
  child: InkWell(
    borderRadius: AppSpacing.borderRadiusLG,
    onTap: () => _openDetail(),
    child: Padding(
      padding: AppSpacing.cardPadding,
      child: Row(children: [...]),
    ),
  ),
)
```

> TODO refactoring: pattern di atas diulang ~39x. Sebaiknya dibungkus widget `AppCard`/`AppListTile` reusable.

---

## 11. Komponen: List & List Item

### ListView standar

```dart
ListView.builder(
  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), // 100 = ruang FAB
  itemCount: _items.length,
  itemBuilder: (context, index) => _buildItem(_items[index]),
)
```

Aturan padding body list: `EdgeInsets.fromLTRB(16, 12, 16, 100)`. Bottom 100 memberi ruang agar item terakhir tidak tertutup FAB. Konsistenkan dengan `AppSpacing` bila sudah ada token-nya.

### Pull-to-refresh

```dart
RefreshIndicator(
  onRefresh: _loadData,
  child: ListView.builder(...),
)
```

### List item — avatar + info + trailing

Pola standar (lihat `supplier_list_page.dart`):

```
[Avatar 52x52 r:12] [Judul + badge]     [chevron_right_rounded]
                     [subteks + ikon]
                     [subteks + ikon]
```

- Avatar: `52x52`, `borderRadiusSM`, fallback = huruf pertama nama.
- Judul: `titleMedium` bold, `maxLines: 1`, `ellipsis`.
- Subteks: `bodySmall` `onSurfaceVariant`, dengan ikon `size: 13`.
- Trailing: `Icons.chevron_right_rounded`.

---

## 12. Komponen: Status Badge / Chip

Untuk menampilkan status (Draft, Pending, Valid, Ditolak, dll.).

### StatusBadge semantik (rekomendasi widget baru)

```dart
// Idealnya (widget yang harus dibuat):
StatusBadge(
  label: item.statusText,
  type: StatusType.success,   // .warning | .error | .info | .neutral
  size: BadgeSize.small,      // .medium
)
```

### Implementasi saat ini (FilterChip / Container manual)

Sampai widget `StatusBadge` ada, gunakan pola seragam ini di setiap page — **jangan menciptakan varian baru**:

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: _statusBgColor(status, isDark),   // warningContainer/successContainer
    borderRadius: AppSpacing.borderRadiusXL, // pill
  ),
  child: Text(
    label,
    style: textTheme.labelSmall?.copyWith(
      color: _statusColor(status),           // warning/success/error
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

### Aturan warna status (WAJIB konsisten)

| Status semantik | Text color | Background |
|---|---|---|
| sukses / selesai / valid | `AppColors.success` | `AppColors.successContainer` |
| pending / menunggu / draft | `AppColors.warning` | `AppColors.warningContainer` |
| gagal / tolak / ditolak / blacklist | `AppColors.error` | `AppColors.errorContainer` |
| info / netral | `colorScheme.onSurfaceVariant` | `colorScheme.surfaceVariant` |

### FilterChip

```dart
FilterChip(
  label: Text('Semua'),
  selected: _selected,
  onSelected: (v) => setState(() => _selected = v),
  selectedColor: colorScheme.primaryContainer,
  checkmarkColor: colorScheme.primary,
  labelStyle: textTheme.labelMedium?.copyWith(
    color: _selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
    fontWeight: _selected ? FontWeight.bold : FontWeight.normal,
  ),
  side: BorderSide(color: colorScheme.outlineVariant),
)
```

---

## 13. Komponen: Modal / Dialog

### AlertDialog — konfirmasi

```dart
final confirmed = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Konfirmasi'),
    content: const Text('Apakah Anda yakin ingin menghapus item ini?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Hapus'),
      ),
    ],
  ),
);
if (confirmed == true) { ... }
```

### Aturan dialog

- **Tombol kiri = batal/netral** (`TextButton`), **tombol kanan = aksi** (`FilledButton`/`ElevatedButton`).
- Aksi destruktif (hapus/keluar): teks jelas, bukan hanya "OK".
- Title pakai teks biasa (jangan set style manual). ❌ `TextStyle(color: Colors.red)` di title — biarkan ikon yang menyampaikan error.

### Dialog error — HENTI duplikasi

Saat ini pola "Gagal Menyimpan" + `TextStyle(color: Colors.red)` diulang di beberapa file (`closing_store_page`, `create_storage_stock_page`, `create_transfer_stock_page`). **Ganti** dengan snackbar [§15](#15-komponen-snackbar--toast) atau dialog tanpa hardcoded color.

### Dialog konfirmasi keluar

Pola "Apakah Anda yakin ingin keluar?" diulang 5x (`stock_dashboard`, `transaction_dashboard`, dll.). Bungkus jadi helper:

```dart
// Rekomendasi: lib/widgets/app_dialogs.dart
Future<bool> showConfirmExitDialog(BuildContext context) async { ... }
Future<void> showErrorDialog(BuildContext context, String message) async { ... }
```

---

## 14. Komponen: Bottom Sheet

Pakai `ModernBottomSheet` (`lib/widgets/modern_bottom_sheet.dart`).

```dart
final result = await ModernBottomSheet.show<String>(
  context: context,
  title: 'Pilih Supplier',
  child: Column(
    children: _suppliers.map((s) => ListTile(
      title: Text(s.name),
      onTap: () => Navigator.pop(context, s.id),
    )).toList(),
  ),
);
```

### Aturan

- Selalu pakai `ModernBottomSheet.show(...)` — bukan `showModalBottomSheet` langsung. Widget ini sudah atur background, radius atas (20), drag indicator, dan title.
- Untuk sheet berisi form: set `isScrollControlled: true` (sudah default) dan bungkus konten dengan `SingleChildScrollView`.
- Tinggi: biarkan `null` (wrap content) kecuali butuh setengah layar.

---

## 15. Komponen: Snackbar / Toast

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Item request disetujui.')),
);
```

### Aturan

- Pesan sukses: kalimat positif pendek ("Disetujui.", "Tersimpan.").
- Pesan error: sertakan penyebab (`'Gagal menyetujui item: $e'`).
- **Jangan** set `backgroundColor` manual untuk sukses/error kecuali memang perlu kontras kuat — default snackbar sudah cukup. Jika perlu warna status, gunakan token:
  ```dart
  SnackBar(
    content: Text('Berhasil'),
    backgroundColor: AppColors.success,
  )
  ```
- Durasi default 4 detik cukup; jangan set `duration` kecuali ada alasan.

> TODO: bungkus jadi helper `showSuccessSnackBar(context, msg)` / `showErrorSnackBar(context, msg)` agar konsisten.

---

## 16. Komponen: Loading State

### Default — spinner

```dart
if (_isLoading)
  const Center(child: CircularProgressIndicator())
```

### Skeleton (untuk list/card)

Pakai `SkeletonLoading` (`lib/widgets/skeleton_loading.dart`) untuk memberi kesan struktur sebelum data dimuat — lebih premium daripada spinner kosong.

```dart
SkeletonLoading(
  child: _buildSkeletonCard(),
)
```

### Aturan

- Saat memuat halaman penuh: spinner di tengah **atau** skeleton.
- Saat tombol submit: `ModernButton(isLoading: true)`.
- Saat load lebih/list: `CircularProgressIndicator` kecil di footer atau pull-to-refresh.
- **Jangan** campur: pilih satu strategi per halaman (spinner ATAU skeleton), jangan keduanya.

---

## 17. Komponen: Empty State

Saat data kosong (bukan error). **Seragamkan** struktur: ikon besar + judul + subteks, opsional tombol aksi.

```dart
Widget _buildEmpty() {
  return Center(
    child: Padding(
      padding: AppSpacing.paddingLG,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          AppSpacing.gapVerticalMD,
          Text(
            'Belum ada data',
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapVerticalSM,
          Text(
            'Data yang sesuai akan muncul di sini.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
```

### Aturan

- Ikon: varan `_outlined`/`_rounded`, `size: 64`, opacity 0.3–0.4.
- Judul: `titleMedium`.
- Subteks: `bodyMedium` `onSurfaceVariant`.
- Teks bahasa Indonesia, ramah ("Belum ada data", bukan "No data").

> TODO: bungkus jadi `EmptyState(icon:, title:, subtitle:, action:)` reusable.

---

## 18. Komponen: Error State

Saat request gagal. Sertakan tombol coba lagi.

```dart
Widget _buildError() {
  return Center(
    child: Padding(
      padding: AppSpacing.paddingLG,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.error,
          ),
          AppSpacing.gapVerticalMD,
          Text(
            _errorMessage!,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapVerticalMD,
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    ),
  );
}
```

### Aturan

- Pesan error: strip prefix `Exception: ` (`e.toString().replaceAll('Exception: ', '')`).
- Ikon error: `Icons.error_outline_rounded`, warna `AppColors.error`.
- Selalu sediakan tombol "Coba Lagi" → panggil fungsi load ulang.

---

## 19. Komponen: FAB

Pakai `AddFab` (`lib/widgets/add_fab.dart`) untuk FAB tambah standar, atau `CustomFab` untuk FAB dengan ikon kustom.

```dart
// FAB tambah standar
floatingActionButton: AddFab(onPressed: _openForm)

// FAB kustom
floatingActionButton: CustomFab(
  icon: Icons.qr_code_scanner_rounded,
  tooltip: 'Scan',
  onPressed: _scan,
)
```

### Aturan

- **Jangan** set `backgroundColor`/`foregroundColor` manual — `floatingActionButtonTheme` sudah atur (emas + onPrimary).
- Posisi: default (endFloat). `AddFab` sudah beri `SafeArea` + padding bawah.
- Sembunyikan saat tidak relevan: `floatingActionButton: _canManage ? AddFab(...) : null`.

---

## 20. Komponen: TabBar

```dart
appBar: AppBar(
  title: const Text('Invoice Purchase'),
  bottom: TabBar(
    controller: _tabController,
    labelColor: colorScheme.primary,
    unselectedLabelColor: colorScheme.onSurfaceVariant,
    indicatorColor: colorScheme.primary,
    isScrollable: true,        // bila tab banyak
    tabAlignment: TabAlignment.start,
    tabs: const [
      Tab(text: 'Draft'),
      Tab(text: 'Unpaid'),
      Tab(text: 'Done'),
    ],
  ),
),
```

### Aturan

- `labelColor`/`indicatorColor` = `colorScheme.primary` (konsisten di semua page ber-tab).
- `unselectedLabelColor` = `colorScheme.onSurfaceVariant`.
- `isScrollable: true` + `tabAlignment: TabAlignment.start` bila tab > 3 atau teks panjang.

---

## 21. Komponen: Bottom Navigation

Pakai `ModernBottomNav` (`lib/widgets/modern_bottom_nav.dart`) untuk navigasi utama halaman home/dashboard.

```dart
bottomNavigationBar: ModernBottomNav(
  currentIndex: _selectedIndex,
  onTap: (i) => setState(() => _selectedIndex = i),
)
```

Tema `bottomNavigationBarTheme` sudah atur warna selected/unselected dan ukuran ikon.

---

## 22. Struktur Halaman: List Page Template

Halaman list (supplier, storage, invoice, procurement, leave) harus mengikuti kerangka ini. Gunakan sebagai template saat membuat list page baru.

```dart
class XxxListPage extends StatefulWidget { ... }

class _XxxListPageState extends State<XxxListPage> {
  final XxxService _service = XxxService();
  final TextEditingController _searchCtrl = TextEditingController();
  List<XxxModel> _items = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async { /* setState loading -> try/catch */ }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xxx')),     // tanpa override tema
      floatingActionButton: _canManage ? AddFab(onPressed: _openForm) : null,
      body: Column(
        children: [
          _buildSearchAndFilter(),                   // search + chips (jika perlu)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildError()
                    : _items.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _fetchData,
                            child: _buildList(),
                          ),
          ),
        ],
      ),
    );
  }
}
```

### Urutan state di body (WAJIB)

1. `isLoading` → spinner/skeleton
2. `errorMessage != null` → error state + retry
3. `!hasSearched` (untuk search page) → prompt search
4. `items.isEmpty` → empty state
5. else → list + `RefreshIndicator`

---

## 23. Anti-pattern yang DILARANG

Daftar hal yang **tidak boleh** muncul di PR. Code reviewer wajib menolak.

### ❌ 1. Ternary `isDark` untuk warna

```dart
color: isDark ? AppColors.darkSurface : AppColors.surface   // DILARANG
backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary
```
→ Pakai `colorScheme.surface` / `colorScheme.primary`.

### ❌ 2. Override AppBar yang sudah ada di tema

```dart
AppBar(
  backgroundColor: isDark ? ... : ...,   // DILARANG
  foregroundColor: isDark ? ... : ...,
  elevation: 0,
  titleTextStyle: TextStyle(...),
)
```
→ Cukup `AppBar(title: Text('...'))`.

### ❌ 3. Import sistem tema lama

```dart
import '../utils/themes.dart';            // DILARANG
TextStyle(color: AppTheme.textLight)      // DILARANG
```
→ `utils/themes.dart` deprecated. Pakai `colorScheme.onSurface` / `textTheme`.

### ❌ 4. Hardcoded warna Material

```dart
TextStyle(color: Colors.red)             // DILARANG
color: Colors.black                       // DILARANG
color: Colors.white                       // DILARANG
```
→ `colorScheme.error`, `colorScheme.onSurface`, `colorScheme.surface`.

### ❌ 5. Magic number di spacing/radius

```dart
BorderRadius.circular(15)                // DILARANG
EdgeInsets.all(16)                       // DILARANG
SizedBox(height: 12)                      // DILARANG
```
→ `AppSpacing.borderRadiusMD`, `AppSpacing.paddingMD`, `AppSpacing.gapVerticalSM` (atau token terdekat).

### ❌ 6. Hardcoded TextStyle dengan ukuran

```dart
TextStyle(fontSize: 16, fontWeight: FontWeight.bold)  // DILARANG
```
→ `textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)`.

### ❌ 7. Manual border di widget input

```dart
InputDecoration(
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),   // DILARANG
  ),
)
```
→ Biarkan `inputDecorationTheme` atur. `ModernTextField`/`ModernTextFormField` sudah benar.

### ❌ 8. Scaffold dengan backgroundColor manual

```dart
Scaffold(backgroundColor: isDark ? ... : ...)  // DILARANG
```
→ Hapus properti. `scaffoldBackgroundColor` sudah di-tema.

### ❌ 9. Duplikasi dialog error/konfirmasi

```dart
AlertDialog(title: Text('Gagal', style: TextStyle(color: Colors.red)))  // DILARANG
AlertDialog(content: Text('Apakah Anda yakin ingin keluar?'))           // duplikasi
```
→ Pakai helper dialog / snackbar.

### ❌ 10. Card dengan properti tema di-hardcode ulang

```dart
Card(
  elevation: 4,                            // DILARANG (tema = 2)
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),  // DILARANG
  ),
)
```
→ Cukup `Card(child: ...)`.

---

## 24. Checklist Code Review

Sebelum mengirim PR, pastikan setiap file UI baru/diubah lulus checklist ini:

- [ ] **Warna**: semua dari `colorScheme.*` atau `AppColors` (status/gradient). Tidak ada `Colors.*` literal.
- [ ] **Dark mode**: tidak ada `isDark ?` untuk warna. Tampilan benar di light & dark.
- [ ] **Spacing**: tidak ada angka literal di `EdgeInsets`/`SizedBox`. Semua dari `AppSpacing`.
- [ ] **Radius**: hanya dari `AppSpacing.borderRadius*`. Default 12.
- [ ] **Tipografi**: dari `theme.textTheme.*`. Tidak ada `TextStyle(fontSize:...)` manual.
- [ ] **AppBar**: tidak override `backgroundColor`/`foregroundColor`/`elevation`/`titleTextStyle`.
- [ ] **Input**: pakai `ModernTextField`/`ModernTextFormField`. Tidak set border manual.
- [ ] **Tombol**: pakai `ModernButton`/`ElevatedButton`/`OutlinedButton`. Ikon varian `_rounded`.
- [ ] **Loading**: satu strategi (spinner atau skeleton).
- [ ] **Empty state**: ikon + judul + subteks, bahasa Indonesia.
- [ ] **Error state**: ikon error + pesan (strip "Exception:") + tombol "Coba Lagi".
- [ ] **Dialog**: kiri=batal, kanan=aksi. Tidak ada hardcoded red title.
- [ ] **Tidak import** `utils/themes.dart`.
- [ ] **State list page**: urutan loading → error → empty → list sesuai [§22](#22-struktur-halaman-list-page-template).

---

## Referensi cepat — file penting

| Untuk | Lihat |
|---|---|
| Semua token warna | `lib/theme/app_colors.dart` (`class AppColors`) |
| Skala tipografi | `lib/theme/app_typography.dart` (`class AppTypography`) |
| Spacing & radius | `lib/theme/app_spacing.dart` (`AppSpacing`, `AppElevation`) |
| ThemeData light/dark | `lib/providers/theme_provider.dart` (`ThemeProvider.lightTheme`/`darkTheme`) |
| Contoh benar | `lib/pages/design_demo_page.dart`, `lib/pages/supplier_list_page.dart` |
| Komponen reusable | `lib/widgets/modern_*.dart`, `add_fab.dart`, `skeleton_loading.dart` |
| Animasi/transisi | `lib/theme/app_animations.dart` (`class AppAnimations`) |

> Saat ragu, buka `lib/pages/design_demo_page.dart` — itu adalah showcase resmi dari design system. Tiru polanya.
