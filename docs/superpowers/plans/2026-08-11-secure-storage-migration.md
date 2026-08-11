# Migrasi Token & Kredensial ke Secure Storage — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Memindahkan JWT access token dari plain `SharedPreferences` (tidak terenkripsi) ke `flutter_secure_storage` (Keychain iOS / EncryptedSharedPreferences Android), menghapus penyimpanan password plaintext, dan memusatkan akses token via abstraction `TokenStore`. User yang sudah login tidak perlu login ulang (migrasi one-shot).

**Architecture:** Buat `TokenStore` singleton yang membungkus `flutter_secure_storage`. Migrasi data lama dijalankan sekali di `main()` sebelum `runApp`. Semua titik akses token (6 file) diubah untuk memanggil `TokenStore` alih-alih langsung akses SharedPreferences. Password plaintext (`saved_password`) dihapus total — email autofill tetap.

**Tech Stack:** Flutter/Dart, `flutter_secure_storage ^9.2.2`, `shared_preferences`, `provider`.

## Aturan Umum

- **Idempotensi wajib.** `TokenStore.migrateFromPrefs()` harus aman dipanggil berkali-kali (saat test, saat restart).
- **Jangan ubah signature public provider/service.** `AuthProvider.login`, `AuthService.login`, `ApiClient.get`, dll. tetap return tipe yang sama. Hanya internal storage yang berubah.
- **Token & token_type** → secure storage. **User, loginData, saved_email** → tetap SharedPreferences (non-sensitif).
- **`saved_password` dihapus total** — tidak boleh ada baca/tulis key ini di kode final.
- **Error handling ketat di migration.** Jika secure storage gagal (mis. device tidak support), fallback: token tidak dimigrasi, user diminta login ulang. Jangan crash.
- **Jangan commit API key / token asli** ke test fixture.
- Setiap task diakhiri commit dengan pesan Conventional Commits.

**Spec reference:** `mobiles/sagansa/docs/superpowers/specs/2026-08-11-secure-storage-migration-design.md`

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `mobiles/sagansa/pubspec.yaml` | Modify | Tambah dependency `flutter_secure_storage` |
| `mobiles/sagansa/lib/services/token_store.dart` | **Create** | Abstraction `TokenStore` (read/write/clear/migrate) |
| `mobiles/sagansa/lib/services/auth_service.dart` | Modify | `_saveUserData`, `logout` pakai `TokenStore` |
| `mobiles/sagansa/lib/services/api_client.dart` | Modify | `_getToken` pakai `TokenStore` |
| `mobiles/sagansa/lib/providers/auth_provider.dart` | Modify | `_loadToken`, `logout`, `updateToken` pakai `TokenStore` |
| `mobiles/sagansa/lib/main.dart` | Modify | Panggil `migrateFromPrefs()`, baca token via `TokenStore` |
| `mobiles/sagansa/lib/pages/login_page.dart` | Modify | Hapus simpan/baca `saved_password` |

---

## Task 1: Tambah dependency `flutter_secure_storage`

**Files:**
- Modify: `mobiles/sagansa/pubspec.yaml`

**Interfaces:**
- Produces: package `flutter_secure_storage: ^9.2.2` pada `dependencies`

- [ ] **Step 1: Tambah ke pubspec**

Buka `mobiles/sagansa/pubspec.yaml`, cari `dependencies:`. Tambahkan baris:

```yaml
  flutter_secure_storage: ^9.2.2
```

Tempatkan pada urutan alfabetis sesuai pola yang sudah ada (setelah `flutter_native_splash` atau sesuai posisi yang menjaga urutan).

- [ ] **Step 2: Resolve dependency**

Run:
```bash
cd mobiles/sagansa && flutter pub get
```
Expected: `Got dependencies!` tanpa conflict. Versi `flutter_secure_storage` muncul di `.dart_tool/package_config.json`.

- [ ] **Step 3: Commit**

```bash
git add mobiles/sagansa/pubspec.yaml mobiles/sagansa/pubspec.lock
git commit -m "chore(mobile): add flutter_secure_storage dependency"
```

---

## Task 2: Buat `TokenStore` abstraction

**Files:**
- Create: `mobiles/sagansa/lib/services/token_store.dart`

**Interfaces:**
- Produces:
  - `TokenStore.instance` (singleton)
  - `Future<String?> readToken()`
  - `Future<String?> readTokenType()`
  - `Future<void> writeToken(String token, {String? tokenType})`
  - `Future<void> clear()`
  - `Future<void> migrateFromPrefs()` (idempotent)

- [ ] **Step 1: Buat file `lib/services/token_store.dart`**

Isi sesuai design spec. Gunakan template berikut (perhatikan import `package:flutter/foundation.dart` untuk `@visibleForTesting`):

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth untuk JWT access token.
///
/// Token dipindahkan dari plain SharedPreferences ke secure storage
/// (Keychain iOS / EncryptedSharedPreferences / Keystore Android) untuk
/// mencegah exposure pada device rooted / backup forensic.
///
/// Data NON-sensitif (user object, loginData, saved_email) tetap di
/// SharedPreferences — lihat spec secure-storage-migration.
class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  static const _keyToken = 'token';
  static const _keyTokenType = 'token_type';

  FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Hanya untuk unit test — inject mock storage.
  @visibleForTesting
  void setStorageForTest(FlutterSecureStorage storage) =>
      _storage = storage;

  Future<String?> readToken() => _storage.read(key: _keyToken);
  Future<String?> readTokenType() => _storage.read(key: _keyTokenType);

  Future<void> writeToken(String token, {String? tokenType}) async {
    await _storage.write(key: _keyToken, value: token);
    if (tokenType != null) {
      await _storage.write(key: _keyTokenType, value: tokenType);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyTokenType);
  }

  /// One-shot migration: pindahkan token dari SharedPreferences (versi lama)
  /// ke secure storage, lalu hapus dari prefs. Idempoten.
  ///
  /// Dijalankan di main() SEBELUM runApp, sehingga semua code path setelahnya
  /// membaca dari secure storage. Aman dipanggil berkali-kali: bila token
  /// sudah ada di secure storage, prefs hanya dibersihkan tanpa overwrite.
  Future<void> migrateFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString('token');
      final legacyType = prefs.getString('token_type');

      if (legacyToken != null && legacyToken.isNotEmpty) {
        final existing = await readToken();
        if (existing == null || existing.isEmpty) {
          await writeToken(legacyToken, tokenType: legacyType);
        }
      }

      // Selalu bersihkan prefs (baik ada token lama maupun tidak), agar
      // prefs tidak lagi menyimpan token setelah migration pertama.
      await prefs.remove('token');
      await prefs.remove('token_type');
    } catch (e) {
      // Migration gagal (mis. secure storage tidak support). Jangan crash —
      // biarkan code path normal berjalan; user akan diminta login ulang
      // karena readToken() mengembalikan null.
      debugPrint('TokenStore.migrateFromPrefs failed: $e');
    }
  }
}
```

- [ ] **Step 2: Verifikasi analisis**

Run:
```bash
cd mobiles/sagansa && flutter analyze lib/services/token_store.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add mobiles/sagansa/lib/services/token_store.dart
git commit -m "feat(mobile): add TokenStore abstraction for secure token storage"
```

---

## Task 3: Ubah `AuthService` pakai `TokenStore`

**Files:**
- Modify: `mobiles/sagansa/lib/services/auth_service.dart`

**Interfaces:**
- Consumes: `TokenStore.instance.writeToken(...)`, `TokenStore.instance.clear()`

- [ ] **Step 1: Tambah import**

Di bagian import (atas file), tambahkan:

```dart
import 'token_store.dart';
```

- [ ] **Step 2: Ubah `_saveUserData` (line 42-70)**

Ganti blok simpan token:

```dart
// Simpan token (secure storage, bukan prefs)
final token = data['access_token'];
if (token != null) {
  await TokenStore.instance.writeToken(
    token.toString(),
    tokenType: data['token_type']?.toString() ?? 'Bearer',
  );
  debugPrint('Token tersimpan di secure storage');
}
```

Hapus baris:
```dart
await prefs.setString(AppConstants.tokenKey, token.toString());
await prefs.setString('token_type', data['token_type'] ?? 'Bearer');
```

**Penting:** `user` dan `loginData` tetap pakai `prefs.setString('user', ...)` dan `prefs.setString(AppConstants.loginDataKey, ...)` — tidak diubah.

- [ ] **Step 3: Ubah `logout` (line 113-122)**

Ganti bagian "Bersihkan SharedPreferences" menjadi:

```dart
// 3. Bersihkan token dari secure storage
try {
  await TokenStore.instance.clear();
} catch (e) {
  debugPrint('AuthService.logout: TokenStore.clear failed ($e)');
}

// 4. Bersihkan data non-token dari SharedPreferences
try {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('user');
  await prefs.remove(AppConstants.loginDataKey);
} catch (e) {
  debugPrint('AuthService.logout: clearing prefs failed ($e)');
}
```

Hapus baris yang hapus `token` & `token_type` dari prefs (sudah digantikan `TokenStore.clear()`).

- [ ] **Step 4: Verifikasi analisis**

Run:
```bash
cd mobiles/sagansa && flutter analyze lib/services/auth_service.dart
```
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add mobiles/sagansa/lib/services/auth_service.dart
git commit -m "refactor(mobile): route token via TokenStore in AuthService"
```

---

## Task 4: Ubah `ApiClient._getToken` pakai `TokenStore`

**Files:**
- Modify: `mobiles/sagansa/lib/services/api_client.dart`

**Interfaces:**
- Consumes: `TokenStore.instance.readToken()`

- [ ] **Step 1: Tambah import**

```dart
import 'token_store.dart';
```

- [ ] **Step 2: Ubah `_getToken` (line 49-52)**

Ganti isi method:

```dart
Future<String?> _getToken() => TokenStore.instance.readToken();
```

Hapus import `shared_preferences` **hanya jika** tidak dipakai lagi di file ini. Cek dulu dengan grep — jika `prefs`/`SharedPreferences` tidak muncul di tempat lain, hapus import-nya.

- [ ] **Step 3: Verifikasi analisis & cek unused import**

Run:
```bash
cd mobiles/sagansa && flutter analyze lib/services/api_client.dart
```
Expected: `No issues found!` (kalau ada warning `unused_import` untuk `shared_preferences`, hapus import tersebut).

- [ ] **Step 4: Commit**

```bash
git add mobiles/sagansa/lib/services/api_client.dart
git commit -m "refactor(mobile): read token via TokenStore in ApiClient"
```

---

## Task 5: Ubah `AuthProvider` pakai `TokenStore`

**Files:**
- Modify: `mobiles/sagansa/lib/providers/auth_provider.dart`

**Interfaces:**
- Consumes: `TokenStore.instance.readToken()`, `TokenStore.instance.clear()`, `TokenStore.instance.writeToken(...)`

- [ ] **Step 1: Tambah import**

```dart
import '../services/token_store.dart';
```

- [ ] **Step 2: Ubah `_loadToken` (line 34-66)**

Ganti baris baca token:

```dart
_token = await TokenStore.instance.readToken() ?? '';
```

Hapus baris `final prefs = await SharedPreferences.getInstance();` + `_token = prefs.getString(AppConstants.tokenKey) ?? '';`.

**Catatan:** Pembacaan `user` object (line 43-53) tetap pakai `prefs.getString('user')` — tidak diubah.

- [ ] **Step 3: Ubah `logout` (line 116-148)**

Di blok `finally`, ganti bagian hapus token:

```dart
try {
  await TokenStore.instance.clear();
} catch (e) {
  debugPrint('AuthProvider: TokenStore.clear failed: $e');
}

try {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('user');
  await prefs.remove(AppConstants.loginDataKey);
} catch (e) {
  debugPrint('AuthProvider: Error clearing prefs in finally: $e');
}
```

Hapus `prefs.remove(AppConstants.tokenKey)` + `prefs.remove('token_type')`.

- [ ] **Step 4: Ubah `updateToken` (line 161-166)**

```dart
Future<void> updateToken(String newToken) async {
  _token = newToken;
  await TokenStore.instance.writeToken(newToken);
  notifyListeners();
}
```

Hapus baris `final prefs = await SharedPreferences.getInstance();` + `await prefs.setString(...)`.

- [ ] **Step 5: Verifikasi analisis**

Run:
```bash
cd mobiles/sagansa && flutter analyze lib/providers/auth_provider.dart
```
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add mobiles/sagansa/lib/providers/auth_provider.dart
git commit -m "refactor(mobile): route token via TokenStore in AuthProvider"
```

---

## Task 6: Ubah `main.dart` — migrasi & baca token via `TokenStore`

**Files:**
- Modify: `mobiles/sagansa/lib/main.dart`

**Interfaces:**
- Consumes: `TokenStore.instance.migrateFromPrefs()`, `TokenStore.instance.readToken()`

- [ ] **Step 1: Tambah import**

```dart
import 'services/token_store.dart';
```

- [ ] **Step 2: Panggil migrasi di `main()`**

Setelah `FlutterNativeSplash.preserve(...)` dan safety timer, **sebelum** `SharedPreferences.getInstance()`, tambahkan:

```dart
// Migrasi one-shot: pindahkan token dari SharedPreferences lama ke secure
// storage (idempotent — aman dijalankan setiap startup).
await TokenStore.instance.migrateFromPrefs();
```

- [ ] **Step 3: Ubah cara baca token**

Ganti:

```dart
final prefs = await SharedPreferences.getInstance();
final String? token = prefs.getString(AppConstants.tokenKey);
```

Menjadi:

```dart
final String? token = await TokenStore.instance.readToken();
```

**Catatan:** `final prefs = await SharedPreferences.getInstance();` boleh dihapus jika tidak dipakai setelah ini di `main()`. Verifikasi: di `main.dart` setelah line 183, tidak ada `prefs` lain.

- [ ] **Step 4: Verifikasi analisis**

Run:
```bash
cd mobiles/sagansa && flutter analyze lib/main.dart
```
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add mobiles/sagansa/lib/main.dart
git commit -m "feat(mobile): migrate token to secure storage on startup"
```

---

## Task 7: Hapus `saved_password` dari `LoginPage`

**Files:**
- Modify: `mobiles/sagansa/lib/pages/login_page.dart`

**Interfaces:**
- N/A (UI cleanup)

- [ ] **Step 1: Ubah `_loadSavedCredentials` (line 34-49)**

Hapus baris baca password:

```dart
final savedPassword = prefs.getString('saved_password');
```

dan blok:

```dart
if (savedPassword != null) {
  setState(() {
    passwordController.text = savedPassword;
  });
}
```

`saved_email` tetap dipertahankan.

- [ ] **Step 2: Ubah `_login` (line 72-74)**

Hapus baris:

```dart
await prefs.setString('saved_password', passwordController.text);
```

`saved_email` tetap ditulis. Bila `prefs` tidak dipakai lagi di function ini setelah menghapus baris password (selain untuk email), biarkan tetap.

- [ ] **Step 3: Bersihkan data lama (opsional, recommended)**

Tambahkan di awal `_loadSavedCredentials`, hapus key legacy jika ada:

```dart
// One-shot cleanup: hapus password plaintext lama dari prefs (pre-migration).
if (prefs.containsKey('saved_password')) {
  await prefs.remove('saved_password');
}
```

- [ ] **Step 4: Verifikasi analisis**

Run:
```bash
cd mobiles/sagansa && flutter analyze lib/pages/login_page.dart
```
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add mobiles/sagansa/lib/pages/login_page.dart
git commit -m "fix(mobile): stop storing user password in plaintext"
```

---

## Task 8: Verifikasi akhir & smoke test

- [ ] **Step 1: Analyze seluruh project**

Run:
```bash
cd mobiles/sagansa && flutter analyze
```
Expected: `No issues found!`

- [ ] **Step 2: Build debug APK**

Run:
```bash
cd mobiles/sagansa && flutter build apk --debug
```
Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk` tanpa error.

- [ ] **Step 3: Smoke test manual — fresh install (tidak ada token lama)**

1. Uninstall app dari device.
2. Install APK baru.
3. Buka app → harusnya masuk `/login` (tidak ada token).
4. Login dengan kredensial valid → harusnya masuk `/home`.
5. Setelah login, cek via `adb shell` (device rooted) atau logs: token tidak boleh muncul di `shared_prefs.xml`.

```bash
adb shell run-as id.sagansa.app cat shared_prefs/*.xml
```
Expected: file prefs berisi `user`, `loginData`, `saved_email`, `thermal_printer_*` — **tidak ada** `token`, `token_type`, `saved_password`.

- [ ] **Step 4: Smoke test manual — upgrade (migrasi dari prefs lama)**

1. Install versi LAMA app (pre-migration), login dengan token.
2. Install APK baru (overwrite, **jangan uninstall** — gunakan `adb install -r` atau `flutter install`).
3. Buka app → harusnya **langsung masuk `/home`** (token termigrasi), tidak diminta login ulang.
4. Cek prefs: `token` & `token_type` sudah hilang (dimigrasi ke secure storage).
5. Logout dari drawer → harusnya balik ke `/login`. Login ulang → harusnya masuk `/home` lagi.

- [ ] **Step 5: Smoke test — password tidak terisi**

1. Fresh install.
2. Login dengan email `test@example.com` + password `rahasia123`.
3. Logout.
4. Di halaman login, email harus ter-autofill (`saved_email`), **field password harus kosong**.

- [ ] **Step 6: Final commit (jika ada perubahan)**

Jika semua smoke test lulus tanpa perubahan kode, skip. Jika ada fix:

```bash
git add -A
git commit -m "fix(mobile): secure storage migration post-review fixes"
```

---

## Risk & Mitigation

| Risk | Mitigation |
|---|---|
| Secure storage tidak support di device tertentu (rare, mis. custom ROM) | `migrateFromPrefs` dan operasi `TokenStore` dibungkus try-catch; user diminta login ulang, bukan crash |
| User rooted melihat token masih di prefs setelah upgrade | `migrateFromPrefs` selalu hapus prefs walau secure storage sudah ada isinya |
| Backward-incompat dengan user yang token-nya di prefs lama | Migration one-shot di `main()` — zero-downtime, user tidak perlu login ulang |
| Test mock sulit karena static singleton | `setStorageForTest(FlutterSecureStorage)` injection point untuk unit test |
