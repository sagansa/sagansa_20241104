# Migrasi Token & Kredensial ke Secure Storage — Design Spec

**Date:** 2026-08-11
**Status:** Draft
**Scope:** `mobiles/sagansa` (auth & HTTP layer)

## Problem

Saat ini app menulis data sensitif ke `SharedPreferences` (plain file XML di disk, tidak terenkripsi):

| Data | Key | File | Baris |
|---|---|---|---|
| JWT access token | `token` | `lib/services/auth_service.dart` | 48 |
| token type | `token_type` | `lib/services/auth_service.dart` | 49 |
| user object (berisi role, email, dll) | `user` | `lib/services/auth_service.dart` | 56 |
| full login response | `loginData` | `lib/services/auth_service.dart` | 63-69 |
| **email** user (autofill) | `saved_email` | `lib/pages/login_page.dart` | 73 |
| **password plaintext** user (autofill) | `saved_password` | `lib/pages/login_page.dart` | 74 |

Risiko:
- Pada device **rooted** / **jailbroken**, file `SharedPreferences.xml` bisa dibaca langsung — JWT & **password plaintext** ter-expose.
- Pada backup `adb backup` (legacy) atau tool forensic, data tidak terenkripsi ikut ter-backup.
- Password disimpan **plaintext** — praktik terburuk; sebaiknya tidak disimpan sama sekali, cukup token.

`SharedPreferences` didesain untuk preferensi (theme, bahasa), bukan secret.

## Context (current state)

Lokasi baca/tulis token & user data tersebar di banyak file:

- `lib/main.dart:181-183` — baca token saat startup untuk tentukan `initialRoute`.
- `lib/services/auth_service.dart:42-70` — tulis token/user/loginData (`_saveUserData`).
- `lib/services/auth_service.dart:113-122` — hapus saat logout.
- `lib/services/api_client.dart:49-52` — baca token untuk header `Authorization`.
- `lib/providers/auth_provider.dart:34-66` — baca token & user (`_loadToken`).
- `lib/providers/auth_provider.dart:134-142` — hapus saat logout.
- `lib/providers/auth_provider.dart:161-165` — update token.
- `lib/providers/auth_provider.dart:233-250` — baca loginData untuk `loadUserInfo`.
- `lib/pages/login_page.dart:34-49` — baca `saved_email` / `saved_password`.
- `lib/pages/login_page.dart:72-85` — tulis `saved_email` / `saved_password`, baca `user`.

`pubspec.yaml` tidak punya dependency `flutter_secure_storage` sama sekali.

## Requirements

1. **R1 — Token ke secure storage.** JWT (`token`, `token_type`) dipindah dari SharedPreferences ke `flutter_secure_storage`. SharedPreferences tidak boleh menyimpan token lagi.
2. **R2 — Hapus penyimpanan password plaintext.** Key `saved_password` dihapus total; data lama di-disk dibersihkan saat app upgrade (one-shot migration). Email (`saved_email`) boleh tetap di SharedPreferences (bukan secret, hanya preference untuk autofill).
3. **R3 — User object & loginData tetap di SharedPreferences.** Data ini (role, nama, company) bukan secret dan dibaca banyak provider secara sync-like; pindah ke secure storage menambah overhead async yang tidak sepadan. Hanya token (yang dipakai sebagai kunci otorisasi) yang wajib aman.
4. **R4 — Backward-compat migration.** Saat app pertama jalan setelah upgrade, baca token dari SharedPreferences lama (jika ada), pindahkan ke secure storage, lalu hapus dari SharedPreferences. User yang sudah login tidak perlu login ulang.
5. **R5 — Single source of truth.** Semua baca/tulis token harus melalui satu abstraction (`TokenStore`), bukan langsung akses `SharedPreferences` / `FlutterSecureStorage` tersebar di banyak file.
6. **R6 — Tidak ada perubahan UX.** Flow login, autofill email, persistent session — semua tetap sama dari sisi user.
7. **R7 — Tidak menangani 401 / token expired.** Itu scope spec terpisah (`2026-08-11-unauthorized-auto-logout-design.md`).

## Architecture Decision: Abstraksi `TokenStore` + migrasi one-shot

**Pendekatan:** Buat class `TokenStore` (singleton, async API) yang membungkus `flutter_secure_storage`. Semua akses token (baca, tulis, hapus, update) hanya boleh melalui `TokenStore`. Migrasi dari SharedPreferences lama dijalankan sekali di `main()` sebelum `runApp`.

**Alasan:**
- **Mencegah regression.** Token sebelumnya diakses di ≥6 file. Tanpa abstraction, pindah storage berarti edit 6+ titik dengan pola berbeda, rawan ada yang terlewat. `TokenStore` memusatkan logic.
- **Async-safe.** `flutter_secure_storage` async (berbeda dari SharedPreferences yang juga async tapi punya in-memory cache). `main()` sudah `await` beberapa hal; menambah `await TokenStore.instance.migrateFromPrefs()` konsisten dengan pola yang ada.
- **Testable.** `TokenStore` bisa di-mock di unit test tanpa menyentuh plugin native.
- **Migrasi one-shot** di `main()` (bukan lazy saat dibutuhkan) memastikan semua code path setelah `runApp` sudah menggunakan storage baru — tidak ada race condition.

**Alternatif yang ditolak:**
- *Pindah langsung tanpa abstraction* → rawan ada titik akses token yang terlewat, terutama `api_client.dart` dan `main.dart`. Ditolak.
- *Migrasi lazy di `_loadToken`* → race: `main()` dan `ApiClient` bisa baca token bersamaan saat startup, salah satu dapat storage kosong. Ditolak.
- *Pindah user & loginData juga ke secure storage* → overengineering; data tersebut tidak sensitif dan overhead async pada read-path yang sering dipanggil (`loadUserInfo`) menambah jank. Ditolak.

## Design

### 1. Dependency

Tambah di `pubspec.yaml`:
```yaml
dependencies:
  flutter_secure_storage: ^9.2.2
```

### 2. TokenStore abstraction

File baru: `lib/services/token_store.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth untuk JWT access token.
///
/// Token dipindahkan dari plain SharedPreferences ke secure storage
/// (Keychain iOS / EncryptedSharedPreferences / Keystore Android).
/// Data NON-sensitif (user object, loginData, saved_email) tetap di
/// SharedPreferences — lihat spec secure-storage-migration.
class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  static const _keyToken = 'token';
  static const _keyTokenType = 'token_type';

  // _storage bisa di-override untuk unit test (mock).
  FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @visibleForTesting
  void setStorageForTest(FlutterSecureStorage storage) => _storage = storage;

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
  /// ke secure storage, lalu hapus dari prefs. Idempoten — aman dipanggil
  /// berkali-kali.
  ///
  /// Dijalankan di main() SEBELUM runApp, sehingga semua code path setelahnya
  /// menggunakan secure storage.
  Future<void> migrateFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString('token');
    final legacyType = prefs.getString('token_type');

    if (legacyToken != null && legacyToken.isNotEmpty) {
      final existing = await readToken();
      // Hanya tulis kalau secure storage belum ada isinya (anti-overwrite).
      if (existing == null || existing.isEmpty) {
        await writeToken(legacyToken, tokenType: legacyType);
      }
    }

    // Hapus token-type juga (token-type tanpa token tidak berguna).
    await prefs.remove('token');
    await prefs.remove('token_type');
  }
}
```

### 3. Callers yang diubah

**`lib/services/auth_service.dart`** — `_saveUserData` & `logout`:
- `_saveUserData`: ganti `prefs.setString(AppConstants.tokenKey, ...)` → `TokenStore.instance.writeToken(...)`. `token_type` ikut di `writeToken(token, tokenType: ...)`. User & loginData tetap di prefs.
- `logout`: ganti `prefs.remove('token')` + `prefs.remove('token_type')` → `await TokenStore.instance.clear()`. Hapus `user` & `loginData` tetap pakai prefs.

**`lib/services/api_client.dart`** — `_getToken`:
- Ganti body jadi `return TokenStore.instance.readToken()` (sudah return `Future<String?>`, signature sama).

**`lib/providers/auth_provider.dart`** — `_loadToken`, `logout`, `updateToken`:
- `_loadToken`: `final token = await TokenStore.instance.readToken()` → `_token = token ?? ''`.
- `logout`: hapus via `TokenStore.instance.clear()`, sisanya tetap prefs.
- `updateToken`: ganti `prefs.setString` → `TokenStore.instance.writeToken`.

**`lib/main.dart`** — token gate startup:
- Setelah `FlutterNativeSplash.preserve` & sebelum baca token: `await TokenStore.instance.migrateFromPrefs()`.
- Baca token: `final String? token = await TokenStore.instance.readToken()`.

**`lib/pages/login_page.dart`** — saved credentials:
- `_loadSavedCredentials`: hapus baca `saved_password`. Email tetap.
- `_login` sukses: hapus tulis `saved_password`. Email tetap ditulis.

### 4. Data Migration Flow

```
[App upgrade, user sebelumnya login]
        |
        v
main() jalan
        |
        v
await TokenStore.instance.migrateFromPrefs()
   ├─ baca prefs['token'] (legacy)
   ├─ kalau ada & secure storage kosong → write ke secure storage
   └─ hapus prefs['token'] & prefs['token_type']
        |
        v
await TokenStore.instance.readToken()  ← dari secure storage
        |
        v
initialRoute = (token != null) ? '/home' : '/login'
```

## Files to Create/Modify

| File | Action |
|---|---|
| `mobiles/sagansa/pubspec.yaml` | Modify — tambah `flutter_secure_storage: ^9.2.2` |
| `mobiles/sagansa/lib/services/token_store.dart` | **Create** — abstraction `TokenStore` + migrasi |
| `mobiles/sagansa/lib/services/auth_service.dart` | Modify — `_saveUserData`, `logout` pakai `TokenStore` |
| `mobiles/sagansa/lib/services/api_client.dart` | Modify — `_getToken` pakai `TokenStore` |
| `mobiles/sagansa/lib/providers/auth_provider.dart` | Modify — `_loadToken`, `logout`, `updateToken` pakai `TokenStore` |
| `mobiles/sagansa/lib/main.dart` | Modify — jalankan `migrateFromPrefs()`, baca token via `TokenStore` |
| `mobiles/sagansa/lib/pages/login_page.dart` | Modify — hapus simpan/baca `saved_password` |

## Out of Scope

- **401 / token-expired auto-logout.** Scope terpisah: `2026-08-11-unauthorized-auto-logout-design.md`. Spesifikasi ini hanya soal *di mana token disimpan*, bukan *kapan token dianggap invalid*.
- **Refresh token mechanism.** Backend tidak menyediakan refresh token (lihat `AuthService.login` — hanya simpan `access_token`). Tidak di-scope.
- **Migrasi `user` / `loginData` ke secure storage.** Sengaja tetap di SharedPreferences (non-sensitif).
- **Biometric auth / PIN.** Bukan scope keamanan storage.
- **Certificate pinning.** Mitigasi terpisah di layer network, bukan storage.
- **App re-signing / obfuscation.** Build-time concern, di luar codebase Dart.
