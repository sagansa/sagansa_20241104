# Sprint 1 Quick Wins Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eksekusi 4 workstream "quick wins" (WS-01, WS-11, WS-12, WS-14) dari `PRD_CODEBASE_IMPROVEMENT.md` dalam 1 sprint: hapus duplikasi `ErrorWidget.builder` di `main.dart`, perbaiki logika `closingStoreUrl`, tighten `analysis_options.yaml`, dan audit dependency.

**Architecture:** Murni cleanup tanpa mengubah behavior runtime. Setiap task menghasilkan kode yang dapat di-build dan lulus `flutter analyze`. Strategi: (1) siapkan quality gate dulu, (2) jalankan auto-fix, (3) perbaiki sisa manual, (4) dokumentasikan.

**Tech Stack:** Flutter SDK, `flutter_lints ^6.0.0`, Dart analyzer, `dart fix`.

**Spec:** `PRD_CODEBASE_IMPROVEMENT.md` §4.1 (WS-01), §4.11 (WS-11), §4.12 (WS-12), §4.14 (WS-14).

**Direktori kerja:** `/Users/dityo/Codings/sagansa/mobiles/sagansa/` (semua path di bawah relatif ke sini).

---

## Aturan Umum

1. **Satu task = satu commit.** Pesan commit pakai conventional commits (`refactor:`, `chore:`, `style:`, `docs:`).
2. **Jangan lanjut sebelum `flutter analyze` dan `flutter test` bersih.**
3. **Behavior tidak boleh berubah.** Bila ragu, jalankan app di emulator sebelum & sesudah untuk smoke test.
4. **Backup baseline:** di Task 0, catat metrik awal sebagai pembanding.

---

## File Structure

### Modify
- `lib/main.dart` — hapus duplikasi `ErrorWidget.builder` (Task 1)
- `lib/utils/constants.dart` — rewrite `closingStoreUrl` (Task 2)
- `analysis_options.yaml` — tighten rules (Task 3)
- Banyak file `lib/*.dart` — auto-fixed by `dart fix --apply` (Task 4)
- `pubspec.yaml` — hapus komentar "Atau versi terbaru", pin version (Task 5)

### Create
- `test/utils/closing_store_url_test.dart` — unit test untuk WS-11 (Task 2)
- `docs/health-reports/2026-07-20-baseline.md` — snapshot metrik awal (Task 0)
- `.github/renovate.json` atau `docs/dependency-audit.md` — config (Task 5)
- `scripts/codebase_health.sh` — script health check (Task 0)

### Delete
- Tidak ada file yang dihapus.

---

## Task 0: Snapshot Baseline & Health Script

**Files:**
- Create: `scripts/codebase_health.sh`
- Create: `docs/health-reports/2026-07-20-baseline.md`

**Tujuan:** Punya angka pembanding sebelum/sesudah biar progres terukur.

- [ ] **Step 1: Buat script `codebase_health.sh`**

```bash
#!/usr/bin/env bash
# scripts/codebase_health.sh — Snapshot metrik kesehatan codebase Sagansa Mobile.
# Jalankan dari root project: ./scripts/codebase_health.sh [report-name]

set -e

REPORT_NAME="${1:-snapshot-$(date +%Y-%m-%d-%H%M%S)}"
REPORT_DIR="docs/health-reports"
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/$REPORT_NAME.md"

if [ ! -f pubspec.yaml ]; then
  echo "ERROR: jalankan dari root project mobiles/sagansa/"
  exit 1
fi

{
  echo "# Sagansa Mobile — Codebase Health Report"
  echo ""
  echo "**Tanggal:** $(date)"
  echo "**Branch:** $(git rev-parse --abbrev-ref HEAD)"
  echo "**Commit:** $(git rev-parse --short HEAD)"
  echo ""
  echo "## Metrik"
  echo ""
  echo "| Metrik | Nilai |"
  echo "|---|---|"
  echo "| Total file \`lib/*.dart\` | $(find lib -name '*.dart' | wc -l | tr -d ' ') |"
  echo "| Total LOC | $(find lib -name '*.dart' -exec cat {} + | wc -l | tr -d ' ') |"
  echo "| Files > 500 LOC | $(find lib -name '*.dart' -exec wc -l {} + | awk '\$1>500 && \$2!=\"total\"' | wc -l | tr -d ' ') |"
  echo "| Files > 300 LOC | $(find lib -name '*.dart' -exec wc -l {} + | awk '\$1>300 && \$2!=\"total\"' | wc -l | tr -d ' ') |"
  echo "| \`setState\` count | $(grep -rc 'setState' lib/ | awk -F: '{sum+=$2} END {print sum}') |"
  echo "| \`Navigator.push\` count | $(grep -rc 'Navigator.push' lib/ | awk -F: '{sum+=$2} END {print sum}') |"
  echo "| Magic number status | $(grep -rE "status == '[0-9]'" lib/ | wc -l | tr -d ' ') |"
  echo "| \`print()\` statements | $(grep -rn '^[[:space:]]*print(' lib/ | wc -l | tr -d ' ') |"
  echo "| \`debugPrint\` count | $(grep -rc 'debugPrint' lib/ | awk -F: '{sum+=$2} END {print sum}') |"
  echo "| \`developer.log\` count | $(grep -rc 'developer.log' lib/ | awk -F: '{sum+=$2} END {print sum}') |"
  echo "| File test | $(find test -name '*.dart' 2>/dev/null | wc -l | tr -d ' ') |"
  echo ""
  echo "## Top 10 File Terbesar"
  echo ""
  echo "| LOC | File |"
  echo "|---|---|"
  find lib -name '*.dart' -exec wc -l {} + | sort -rn | head -11 | grep -v '^ *[0-9]* total$' | awk '{printf "| %d | %s |\\n", $1, $2}'
  echo ""
  echo "## flutter analyze (ringkasan)"
  echo ""
  echo '```'
  flutter analyze 2>&1 | tail -5 || true
  echo '```'
} > "$REPORT_FILE"

echo "Report saved to: $REPORT_FILE"
cat "$REPORT_FILE"
```

- [ ] **Step 2: Buat script executable**

Run: `chmod +x scripts/codebase_health.sh`
Expected: tidak ada output, exit code 0.

- [ ] **Step 3: Jalankan script untuk snapshot baseline**

Run: `./scripts/codebase_health.sh 2026-07-20-baseline`
Expected: file `docs/health-reports/2026-07-20-baseline.md` terbuat, isinya tabel metrik.

- [ ] **Step 4: Verifikasi isi report**

Run: `cat docs/health-reports/2026-07-20-baseline.md`
Expected: melihat tabel dengan angka baseline (~208 file, ~58k LOC, 713 setState, dll.).

- [ ] **Step 5: Commit**

```bash
git add scripts/codebase_health.sh docs/health-reports/2026-07-20-baseline.md
git commit -m "chore(scripts): add codebase health snapshot tool + baseline"
```

---

## Task 1: Hapus Duplikasi `ErrorWidget.builder` di `main.dart` (WS-01)

**Files:**
- Modify: `lib/main.dart:144-195`

**Masalah:**
Di `main()`, blok `ErrorWidget.builder = (...) { ... }` di-set **dua kali** identik di baris 150-152 dan 155-157. Salah satunya mungkin hasil merge conflict yang lupa dihapus.

- [ ] **Step 1: Verifikasi duplikasi masih ada**

Run: `grep -n "ErrorWidget.builder" lib/main.dart`
Expected output:
```
150:    ErrorWidget.builder = (FlutterErrorDetails details) {
155:    ErrorWidget.builder = (FlutterErrorDetails details) {
```
Bila hanya 1 baris, task ini sudah dikerjakan — skip ke Task 2.

- [ ] **Step 2: Baca blok main() saat ini untuk konteks**

Run: `sed -n '144,170p' lib/main.dart` (atau gunakan editor)
Expected: melihat fungsi `main()` dengan dua assignment `ErrorWidget.builder`.

- [ ] **Step 3: Edit — hapus duplikasi**

Ganti blok berikut di `lib/main.dart`:

```dart
    // Set up global error handling
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return CustomErrorWidget(errorDetails: details);
    };

    // Set up global error handling
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return CustomErrorWidget(errorDetails: details);
    };

    // Set orientasi ke portrait
```

dengan:

```dart
    // Set up global error handler untuk menampilkan CustomErrorWidget
    // alih-alih red screen default di release build.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return CustomErrorWidget(errorDetails: details);
    };

    // Set orientasi ke portrait
```

- [ ] **Step 4: Verifikasi hanya 1 assignment tersisa**

Run: `grep -c "ErrorWidget.builder =" lib/main.dart`
Expected: `1`

- [ ] **Step 5: Pastikan masih kompilable**

Run: `flutter analyze lib/main.dart`
Expected: `No issues found!` atau hanya issue yang sudah ada sebelumnya.

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart
git commit -m "refactor(main): remove duplicate ErrorWidget.builder assignment"
```

---

## Task 2: Fix `closingStoreUrl` Logic dengan Unit Test (WS-11)

**Files:**
- Modify: `lib/utils/constants.dart:115-133`
- Create: `test/utils/closing_store_url_test.dart`

**Masalah:**
Logika `closingStoreUrl` pakai string matching rapuh (`contains('127.0.0.1')`, `startsWith('api.')`). Sulit dibaca, rawan typo, tidak teruji.

**Behavior yang harus dipertahankan (regression-safe):**

| Input `baseUrl` | Output `closingStoreUrl` |
|---|---|
| `https://api.sagansa.id` | `https://www.sagansa.id/admin/transaction/closings/panel/closing-stores` |
| `http://127.0.0.1:8001` | `http://127.0.0.1:8000/admin/transaction/closings/panel/closing-stores` |
| `http://localhost:8001` | `http://localhost:8000/admin/transaction/closings/panel/closing-stores` |
| `http://192.168.0.142:8001` | `http://192.168.0.142:8000/admin/transaction/closings/panel/closing-stores` |

**Catatan penting:** `ApiConstants.baseUrl` adalah `const String` yang di-resolve saat compile via `String.fromEnvironment('API_URL', defaultValue: ...)`. Karena `const`, **tidak bisa di-override di unit test**. Solusinya: ekstrak logika ke method pure-function yang menerima `baseUrl` sebagai parameter, lalu getter `closingStoreUrl` tinggal memanggilnya.

- [ ] **Step 1: Tulis failing test (TDD)**

Create `test/utils/closing_store_url_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/utils/constants.dart';

void main() {
  group('ApiConstants.resolveClosingStoreUrl', () {
    test('production URL: api.sagansa.id → www.sagansa.id', () {
      final result = ApiConstants.resolveClosingStoreUrl(
        'https://api.sagansa.id',
      );
      expect(
        result,
        'https://www.sagansa.id/admin/transaction/closings/panel/closing-stores',
      );
    });

    test('localhost:8001 → localhost:8000', () {
      final result = ApiConstants.resolveClosingStoreUrl(
        'http://localhost:8001',
      );
      expect(
        result,
        'http://localhost:8000/admin/transaction/closings/panel/closing-stores',
      );
    });

    test('127.0.0.1:8001 → 127.0.0.1:8000', () {
      final result = ApiConstants.resolveClosingStoreUrl(
        'http://127.0.0.1:8001',
      );
      expect(
        result,
        'http://127.0.0.1:8000/admin/transaction/closings/panel/closing-stores',
      );
    });

    test('192.168.x.x:8001 → 192.168.x.x:8000', () {
      final result = ApiConstants.resolveClosingStoreUrl(
        'http://192.168.0.142:8001',
      );
      expect(
        result,
        'http://192.168.0.142:8000/admin/transaction/closings/panel/closing-stores',
      );
    });

    test('non-api subdomain di production tetap diawali www', () {
      final result = ApiConstants.resolveClosingStoreUrl(
        'https://api.staging.sagansa.id',
      );
      expect(
        result,
        'https://www.staging.sagansa.id/admin/transaction/closings/panel/closing-stores',
      );
    });

    test('HTTPS production tanpa port eksplisit', () {
      final result = ApiConstants.resolveClosingStoreUrl(
        'https://api.sagansa.id:443',
      );
      expect(
        result,
        'https://www.sagansa.id/admin/transaction/closings/panel/closing-stores',
      );
    });
  });
}
```

- [ ] **Step 2: Jalankan test — harus FAIL (method belum ada)**

Run: `flutter test test/utils/closing_store_url_test.dart`
Expected: FAIL dengan error `Method not found: 'ApiConstants.resolveClosingStoreUrl'` atau `The getter doesn't exist`.

- [ ] **Step 3: Implementasi — tambahkan method pure-function**

Edit `lib/utils/constants.dart`. Ganti blok getter `closingStoreUrl` yang lama (baris 115-133):

```dart
  static Map<String, String> headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static String get closingStoreUrl {
    return resolveClosingStoreUrl(baseUrl);
  }

  /// Resolusi URL admin panel closing store dari [apiBaseUrl] yang diberikan.
  ///
  /// Aturan (regression-safe terhadap implementasi lama):
  /// - Host yang diawali `api.` → diganti jadi `www.` (production-like).
  /// - Localhost / 127.0.0.1 / 192.168.x.x → port admin web 8000.
  /// - HTTPS production (port 443 atau tidak ada port) → tidak menampilkan port.
  ///
  /// Dipisah sebagai method pure-function agar bisa di-unit-test (karena
  /// [baseUrl] adalah `const`, tidak bisa di-override di runtime).
  static String resolveClosingStoreUrl(String apiBaseUrl) {
    final api = Uri.parse(apiBaseUrl);
    final adminHost = _resolveAdminHost(api.host);
    final adminPort = _resolveAdminPort(api);
    final adminScheme = adminHost == api.host ? api.scheme : 'https';

    final admin = api.replace(
      scheme: adminScheme,
      host: adminHost,
      port: adminPort,
      path: '/admin/transaction/closings/panel/closing-stores',
      queryParameters: {},
      fragment: '',
    );

    // Hilangkan port eksplisit untuk HTTPS 443 / HTTP 80.
    final portPart = (admin.scheme == 'https' && admin.port == 443) ||
            (admin.scheme == 'http' && admin.port == 80)
        ? ''
        : ':${admin.port}';

    return '${admin.scheme}://${admin.host}$portPart${admin.path}';
  }

  static String _resolveAdminHost(String apiHost) {
    if (apiHost.startsWith('api.')) {
      return 'www.${apiHost.substring(4)}';
    }
    return apiHost;
  }

  static int _resolveAdminPort(Uri api) {
    // Lokal dev: admin web jalan di port 8000.
    if (api.host == '127.0.0.1' || api.host == 'localhost') return 8000;
    if (api.host.startsWith('192.168.')) return 8000;
    // Production HTTPS standar.
    return api.port == 0 ? 443 : api.port;
  }
```

- [ ] **Step 4: Jalankan test — harus PASS**

Run: `flutter test test/utils/closing_store_url_test.dart`
Expected: `+6` atau `All tests passed!`

- [ ] **Step 5: Pastikan tidak ada regression di pemanggil**

Run: `grep -rn "closingStoreUrl" lib/`
Expected: melihat daftar file yang memanggil getter (mis. di page closing store). Catat file-nya untuk verifikasi manual.

- [ ] **Step 6: Smoke test manual**

Run:
```bash
flutter run --flavor dev 2>/dev/null || flutter run
```
Buka halaman yang memakai `closingStoreUrl` (biasanya `closing_store_page.dart`), pastikan tombol "Buka Panel" atau link masih mengarah ke URL yang benar.

Expected: URL yang dihasilkan sama dengan sebelum refactor.

- [ ] **Step 7: Commit**

```bash
git add lib/utils/constants.dart test/utils/closing_store_url_test.dart
git commit -m "refactor(constants): extract closingStoreUrl to testable pure function

Replace fragile string matching (contains/startsWith) with Uri-based
resolution. Add 6 unit tests covering production/localhost/LAN cases.
Behavior unchanged for existing callers."
```

---

## Task 3: Update `analysis_options.yaml` (WS-12)

**Files:**
- Modify: `analysis_options.yaml`

**Catatan:** Task ini **tidak menjalankan `dart fix`** dulu — itu Task 4. Di sini kita hanya update rules, lalu lihat seberapa banyak warning baru muncul. Bila terlalu banyak, pilih subset rules yang realistis.

- [ ] **Step 1: Catat baseline jumlah issue saat ini**

Run: `flutter analyze 2>&1 | tail -1`
Expected: baris seperti `6 issues found.` atau `No issues found!`. Catat angkanya.

- [ ] **Step 2: Backup `analysis_options.yaml` versi lama**

Run: `cp analysis_options.yaml analysis_options.yaml.bak`
(tidak di-commit, hanya safety net lokal).

- [ ] **Step 3: Tulis `analysis_options.yaml` baru**

Overwrite `analysis_options.yaml` dengan:

```yaml
# Konfigurasi analyzer untuk Sagansa Mobile.
# Lihat PRD_CODEBASE_IMPROVEMENT.md §4.12 untuk rasional aturan.
include: package:flutter_lints/flutter.yaml

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
    # Treat sebagai error (fail CI / review):
    missing_required_param: error
    missing_return: error
    avoid_print: error
    # Treat sebagai warning (perlu perhatian, tidak block):
    deprecated_member_use: warning
    # Ignore yang noisy:
    todo: ignore
    fixme: ignore

linter:
  rules:
    # === Style konsistensi ===
    prefer_single_quotes: true
    prefer_const_constructors: true
    prefer_const_constructors_in_immutables: true
    prefer_const_declarations: true
    prefer_const_literals_to_create_immutables: true
    prefer_final_fields: true
    prefer_final_locals: true
    require_trailing_commas: true
    # === Robustness ===
    avoid_print: true
    avoid_dynamic_calls: true
    always_declare_return_types: true
    type_annotate_public_apis: true
    # === Imports ===
    prefer_relative_imports: true
    directives_ordering: true
    # === Flutter-specific ===
    use_key_in_widget_constructors: true
    sized_box_for_whitespace: true
    use_build_context_synchronously: true
    # === Public API docs (off — project internal) ===
    public_member_api_docs: false
    lines_longer_than_80_chars: false
```

- [ ] **Step 4: Jalankan analyze — catat jumlah issue baru**

Run: `flutter analyze 2>&1 | tail -1`
Expected: angka issue naik signifikan (mungkin 100-500). **Ini normal** — Task 4 akan auto-fix sebagian besar.

- [ ] **Step 5: Cek breakdown issue per rule**

Run: `flutter analyze 2>&1 | grep -oE "info • [a-z_]+ •" | sort | uniq -c | sort -rn | head -20`
Expected: melihat rule mana yang paling banyak melanggar (biasanya `require_trailing_commas`, `prefer_single_quotes`, `prefer_const_constructors`).

- [ ] **Step 6: Bila jumlah issue > 1000, relax rule paling noisy**

Bila hasil Task 5 menunjukkan satu rule mendominasi (>50% issue), komentari rule itu dulu di `analysis_options.yaml`:

```yaml
# Sementara dimatikan sampai dart fix --apply dijalankan (Task 4):
# require_trailing_commas: true
```

Ulang Step 4. Tujuan: punya < 500 issue sebelum `dart fix`.

- [ ] **Step 7: Commit config (issue belum dibersihkan)**

```bash
git add analysis_options.yaml
git commit -m "chore(lint): tighten analysis_options with strict mode + new rules

Enable strict-casts/inference/raw-types, avoid_print as error, and
Flutter-specific rules. Some auto-fixable; will be cleaned in dart fix
follow-up."
```

---

## Task 4: Auto-Fix dengan `dart fix --apply`

**Files:**
- Modify: banyak file `lib/*.dart`

- [ ] **Step 1: Jalankan `dart fix` dalam mode dry-run dulu**

Run: `dart fix --dry-run`
Expected: daftar perubahan yang akan dilakukan. Catat total count.

- [ ] **Step 2: Apply fixes**

Run: `dart fix --apply`
Expected: banyak file dimodifikasi. Output ringkasan "Made N fixes across M files."

- [ ] **Step 3: Jalankan analyze lagi**

Run: `flutter analyze 2>&1 | tail -1`
Expected: angka issue turun drastis dari Task 3 Step 4. Target: < 100 issue tersisa.

- [ ] **Step 4: Verifikasi test masih hijau**

Run: `flutter test`
Expected: `All tests passed!` atau jumlah failure sama dengan sebelum Task 4 (tidak boleh naik).

- [ ] **Step 5: Review diff per kategori**

Run:
```bash
git diff --stat
git diff --name-only | head -30
```
Expected: melihat banyak file terkompak diubah (umumnya auto-style).

- [ ] **Step 6: Aktifkan kembali rule yang dimatikan di Task 3 Step 6**

Bila di Task 3 Step 6 ada rule yang dikomentari, buka kembali `analysis_options.yaml` dan uncomment.

Run: `flutter analyze 2>&1 | tail -1`
Expected: angka issue tetap rendah (sebagian besar sudah ter-auto-fix).

- [ ] **Step 7: Commit dalam batch agar review-able**

Bila `dart fix --apply` mengubah > 50 file, pecah commit per-domain:

```bash
# Batch 1: services
git add lib/services/ && git commit -m "style(services): apply dart fix auto-formatting"

# Batch 2: pages
git add lib/pages/ && git commit -m "style(pages): apply dart fix auto-formatting"

# Batch 3: sisanya
git add lib/ analysis_options.yaml
git commit -m "style: apply dart fix across remaining lib + re-enable strict rules"
```

Bila < 50 file, satu commit saja:

```bash
git add -A
git commit -m "style: apply dart fix --apply across codebase

Auto-fixes: prefer_single_quotes, prefer_const_constructors,
prefer_final_locals, require_trailing_commas, etc. No behavior change."
```

- [ ] **Step 8: Verifikasi app masih jalan**

Run: `flutter run`
Expected: app build & launch tanpa error. Lakukan smoke test cepat: login, buka home page, navigasi bottom nav.

---

## Task 5: Dependency Audit & `pubspec.yaml` Cleanup (WS-14)

**Files:**
- Modify: `pubspec.yaml`
- Create: `docs/dependency-audit.md` (atau `.github/renovate.json` bila project di GitHub)

- [ ] **Step 1: Cek dependency outdated**

Run: `flutter pub outdated`
Expected: tabel dengan kolom "Package Name", "Upgradable", "Resolvable".

- [ ] **Step 2: Catat temuan ke `docs/dependency-audit.md`**

Create `docs/dependency-audit.md`:

```markdown
# Dependency Audit Report

**Tanggal:** 2026-07-20
**Flutter:** $(flutter --version | head -1)
**Dart:** $(dart --version)

## Status Outdated

Salin tabel dari `flutter pub outdated` ke sini.

## Catatan Kompatibilitas

### Firebase (perlu verifikasi iOS deployment target)
- `firebase_core: ^3.6.0`
- `firebase_messaging: ^15.1.3`
- **Action:** cek apakah kombinasi ini compatible dengan iOS deployment target
  di `ios/Podfile` (minimum `platform :ios, '13.0'` atau lebih tinggi).

### Syncfusion (commercial license)
- `syncfusion_flutter_calendar: ^33.2.6`
- `syncfusion_flutter_datepicker: ^33.2.6`
- `syncfusion_localizations: ^33.2.6`
- **Action:** pastikan license key terdaftar bila app sudah publish (community
  license berlaku untuk company < $1M revenue).

## Rekomendasi Upgrade Minor (safe)
...

## Rekomendasi Upgrade Major (perlu testing)
...
```

Isi bagian "Rekomendasi" berdasarkan output `flutter pub outdated`. Hindari major bump di task ini (simpan untuk PR terpisah).

- [ ] **Step 3: Bersihkan komentar "Atau versi terbaru"**

Hapus komentar redundan di `pubspec.yaml` yang bilang "Atau versi terbaru" — versi sudah explicit via caret (`^`), comment ini menyesatkan.

Edit `pubspec.yaml`, contoh:

```yaml
# Sebelum:
intl: ^0.20.2 # Atau versi terbaru
connectivity_plus: ^7.1.1 # Atau versi terbaru

# Sesudah:
intl: ^0.20.2
connectivity_plus: ^7.1.1
```

Lakukan untuk semua dependency yang punya comment tersebut.

- [ ] **Step 4: Tambah Renovate config (opsional, bila project di GitHub)**

Cek apakah ini repo GitHub:
Run: `git remote -v`
Bila ada `github.com`, create `.github/renovate.json`:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended", "schedule:weekly"],
  "packageRules": [
    {
      "groupName": "flutter sdk",
      "matchPackagePatterns": ["^flutter$", "^sdk.flutter"]
    },
    {
      "groupName": "firebase",
      "matchPackagePatterns": ["^firebase", "^cloud_firestore"]
    },
    {
      "groupName": "syncfusion",
      "matchPackagePatterns": ["^syncfusion"],
      "schedule": ["on the first day of the month"]
    }
  ],
  "lockFileMaintenance": {
    "enabled": true,
    "schedule": ["on the first day of the month"]
  }
}
```

Bila **bukan** repo GitHub (mis. self-hosted GitLab), skip step ini — catat di `docs/dependency-audit.md` bahwa automasi upgrade tidak di-setup.

- [ ] **Step 5: Verifikasi `pub get` masih sukses**

Run: `flutter pub get`
Expected: `Got dependencies!` tanpa warning conflict.

- [ ] **Step 6: Verifikasi build masih sukses**

Run: `flutter analyze lib/main.dart`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml docs/dependency-audit.md
# Bila ada renovate.json:
git add .github/renovate.json
git commit -m "chore(deps): audit + cleanup pubspec comments

- Remove redundant 'Atau versi terbaru' comments
- Document Firebase/Syncfusion compatibility notes
- Add Renovate config for automated weekly updates"
```

---

## Task 6: Final Verification & Health Snapshot Compare

**Files:**
- Create: `docs/health-reports/2026-07-20-sprint1-final.md`

- [ ] **Step 1: Jalankan health script untuk snapshot akhir**

Run: `./scripts/codebase_health.sh 2026-07-20-sprint1-final`
Expected: file report baru terbuat.

- [ ] **Step 2: Compare baseline vs final**

Run:
```bash
diff docs/health-reports/2026-07-20-baseline.md docs/health-reports/2026-07-20-sprint1-final.md
```

Atau buka kedua file berdampingan di editor.

**Expected changes:**
- `flutter analyze` issues: turun signifikan (baseline mungkin beberapa issue → final mendekati 0).
- `print()` count: tetap (tidak di-sentuh di Sprint 1).
- LOC, file count: tetap.
- Tidak ada angka yang **naik**.

- [ ] **Step 3: Full test run**

Run: `flutter test`
Expected: semua test lulus, termasuk `closing_store_url_test.dart` baru.

- [ ] **Step 4: Full analyze run**

Run: `flutter analyze`
Expected: `< 10 issues`. Idealnya 0.

- [ ] **Step 5: Smoke test final di emulator**

Run: `flutter run`
Test manual:
- [ ] Login dengan akun demo
- [ ] Buka HomePage — pastikan render normal
- [ ] Tap bottom nav ke semua 5 dashboard
- [ ] Buka halaman closing store — tap tombol yang pakai `closingStoreUrl`
- [ ] Logout

Expected: tidak ada crash, behavior normal.

- [ ] **Step 6: Tulis summary commit (opsional, bila ingin 1 commit wrap-up)**

```bash
git add docs/health-reports/2026-07-20-sprint1-final.md
git commit -m "docs(health): sprint 1 final snapshot — analyze issues reduced"
```

---

## Acceptance Criteria (dari PRD §4.1, §4.11, §4.12, §4.14)

Checklist akhir — semua harus ✓:

### WS-01 — Duplikasi main.dart
- [ ] Hanya ada **1** assignment `ErrorWidget.builder` di `lib/main.dart`.
- [ ] `flutter analyze lib/main.dart` → 0 issue baru.

### WS-11 — closingStoreUrl
- [ ] Tidak ada lagi `.contains('127.0.0.1')` / `.contains('192.168.')` di `constants.dart`.
- [ ] 6 unit test di `test/utils/closing_store_url_test.dart` lulus.
- [ ] Behavior app tidak berubah (smoke test closing store lolos).

### WS-12 — analysis_options
- [ ] `analysis_options.yaml` mengaktifkan `strict-casts`, `strict-inference`, `strict-raw-types`.
- [ ] `flutter analyze` setelah `dart fix --apply` → < 10 issue (target: 0).

### WS-14 — Dependency
- [ ] `docs/dependency-audit.md` ada dengan audit lengkap.
- [ ] Komentar "Atau versi terbaru" dihapus dari `pubspec.yaml`.
- [ ] Bila GitHub: `.github/renovate.json` ada.
- [ ] `flutter pub get` sukses tanpa conflict.

### Sprint-level
- [ ] `docs/health-reports/2026-07-20-sprint1-final.md` ada.
- [ ] `flutter analyze` global → 0 issue.
- [ ] `flutter test` → semua lulus.
- [ ] App build & jalan di emulator.

---

## Troubleshooting

### `dart fix --apply` mengubah terlalu banyak file

Normal. Pecah commit per-domain (services/pages/widgets) untuk review-ability. Bila reviewer complain, pecah lagi per-feature.

### `flutter analyze` masih banyak warning setelah `dart fix`

Beberapa rule tidak bisa di-auto-fix:
- `avoid_dynamic_calls` — butuh refactor manual (hapus `.x` access pada `dynamic`).
- `type_annotate_public_apis` — butuh tambah type annotation manual.

**Strategi:** disable rule tersebut di `analysis_options.yaml` untuk Sprint 1, jadikan task terpisah di Sprint mendatang. Catat di `docs/dependency-audit.md` atau issue tracker.

### Test `closing_store_url_test.dart` gagal untuk case edge

Bila ada kasus yang tidak sesuai implementasi lama, **jangan ubah test**. Periksa apakah itu bug lama yang kebetulan ke-cover — bila ya, fix implementasinya sesuai behavior yang benar, update test untuk dokumentasikan.

### `flutter pub get` conflict setelah edit `pubspec.yaml`

Kemungkinan version constraint terlalu ketat. Jalankan `flutter pub outdated` lagi, cek konflik, longgarkan constraint satu per satu.

---

## Out of Scope (untuk sprint ini)

- Refactor HomePage (WS-02) — Sprint 3.
- Type-safe `ApiClient` (WS-04) — Sprint 2.
- `go_router` migration (WS-03) — Sprint 5+.
- `freezed` models (WS-07) — Sprint 4+.
- AppLogger (WS-10) — Sprint 2.
- Service injection (WS-06) — ongoing.

Lihat `PRD_CODEBASE_IMPROVEMENT.md` §5 untuk roadmap lengkap.
