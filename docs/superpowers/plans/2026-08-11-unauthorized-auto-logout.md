# Auto-Logout saat 401 Unauthorized — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Saat backend mengembalikan HTTP 401 (token expired/revoked), app otomatis logout (hapus token, data user, deregister FCM), menampilkan notifikasi "Sesi telah berakhir", dan navigasi ke `/login` dengan reset stack. Multiple request 401 concurrent hanya memicu satu logout (debounced).

**Architecture:** Buat `AuthSession` singleton sebagai orchestrator — di-trigger dari `ApiClient` saat 401, debounced via flag, membersihkan storage via `AuthService.logout`, dan navigasi via `GlobalKey<NavigatorState>` yang di-inject dari `MyApp`. `ApiClient` tidak tahu tentang UI; `AuthSession` jembatan antara HTTP layer dan Navigator.

**Tech Stack:** Flutter/Dart, `package:http`, `provider`, Flutter Navigator.

## Aturan Umum

- **`ApiClient` tidak boleh import `package:flutter/widgets.dart`.** Navigasi sepenuhnya via `AuthSession` + `GlobalKey`. Service layer tetap pure Dart.
- **Exception tetap dilempar.** Setelah trigger `_onUnauthorized`, method request tetap `throw` seperti biasa — caller UI tetap dapat error, tidak lanjut mengolah data kosong.
- **Endpoint `/login` dikecualikan.** 401 dari login = kredensial salah, bukan sesi expired.
- **Debounce wajib.** Flag `_loggingOut` di `AuthSession` mencegah multiple logout saat dashboard load beberapa endpoint bersamaan.
- **Kill switch untuk test.** `AuthSession.instance.enabled = false` di setup test.
- **Tidak ada dependency baru.** Semua pakai library yang sudah ada (`http`, Flutter SDK).
- Setiap task diakhiri commit dengan pesan Conventional Commits.

**Spec reference:** `mobiles/sagansa/docs/superpowers/specs/2026-08-11-unauthorized-auto-logout-design.md`

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `mobiles/sagansa/lib/services/auth_session.dart` | **Create** | Orchestrator auto-logout (debounce, cleanup, navigate) |
| `mobiles/sagansa/lib/services/api_client.dart` | Modify | Deteksi 401 di 5 jalur response, panggil `AuthSession` |
| `mobiles/sagansa/lib/main.dart` | Modify | Inject `navigatorKey`, configure `AuthSession` |

---

## Task 1: Buat `AuthSession` orchestrator

**Files:**
- Create: `mobiles/sagansa/lib/services/auth_session.dart`

**Interfaces:**
- Produces:
  - `AuthSession.instance` (singleton)
  - `void configure(GlobalKey<NavigatorState> key)` — inject dari `MyApp`
  - `Future<void> handleUnauthorized()` — dipanggil `ApiClient` saat 401
  - `bool enabled` — kill switch (default `true`)

- [ ] **Step 1: Buat file `lib/services/auth_session.dart`**

```dart
import 'package:flutter/material.dart';

import 'auth_service.dart';

/// Orchestrator auto-logout saat response 401 dari backend.
///
/// Dipanggil ApiClient. Idempotent dalam window logout: bila beberapa
/// request concurrent dapat 401 bersamaan, hanya SATU proses logout yang
/// berjalan; sisanya no-op. Setelah navigasi selesai, flag di-reset agar
/// sesi berikutnya (setelah user login ulang) bisa trigger lagi.
class AuthSession {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _loggingOut = false;

  /// Kill switch untuk test. Set false untuk disable auto-logout.
  bool enabled = true;

  /// Di-set dari MyApp.initState. Dipakai untuk navigasi tanpa BuildContext.
  void configure(GlobalKey<NavigatorState> key) => _navigatorKey = key;

  /// Dipanggil ApiClient ketika response.statusCode == 401.
  /// Tidak throws — failure di-silent agar tidak mengganggu caller.
  Future<void> handleUnauthorized() async {
    if (!enabled || _loggingOut) return;
    _loggingOut = true;

    try {
      // Bersihkan token, data user, FCM/periodic task. AuthService.logout
      // sudah swallow error internal (backend call gagal tetap lanjut clear
      // storage). Timeout 5s mencegah hang kalau backend benar-benar down.
      await AuthService().logout().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Best-effort cleanup; navigasi tetap dijalankan.
    }

    _navigateToLogin();
  }

  void _navigateToLogin() {
    final nav = _navigatorKey?.currentState;
    if (nav == null) {
      // Navigator belum ready (mis. masih di splash / belum configure).
      // Reset flag; ApiClient tetap throw 401 ke caller — main() route gate
      // akan arahkan ke /login karena token sudah dihapus.
      _loggingOut = false;
      return;
    }

    nav.pushNamedAndRemoveUntil('/login', (route) => false);

    // Tampilkan pesan user-friendly via overlay context (best-effort; tidak
    // fatal kalau overlay null).
    final ctx = nav.overlay?.context;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Sesi Anda telah berakhir, silakan login kembali.'),
          duration: Duration(seconds: 4),
        ),
      );
    }

    _loggingOut = false;
  }
}
```

- [ ] **Step 2: Verifikasi analisis**

Run:
```bash
cd mobiles/sagansa && flutter analyze lib/services/auth_session.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add mobiles/sagansa/lib/services/auth_session.dart
git commit -m "feat(mobile): add AuthSession orchestrator for 401 auto-logout"
```

---

## Task 2: Deteksi 401 di `ApiClient`

**Files:**
- Modify: `mobiles/sagansa/lib/services/api_client.dart`

**Interfaces:**
- Consumes: `AuthSession.instance.handleUnauthorized()`
- Produces: helper `_onUnauthorized({String? path})` internal

- [ ] **Step 1: Tambah import**

```dart
import 'auth_session.dart';
```

- [ ] **Step 2: Tambah helper `_onUnauthorized`**

Di dalam class `ApiClient`, tambahkan method private (dekat dengan `_handleResponse`):

```dart
/// Trigger auto-logout saat 401, kecuali untuk endpoint publik (login).
/// Fire-and-forget — tidak di-await agar caller tetap dapat exception 401.
void _onUnauthorized({String? path}) {
  // Endpoint login dikecualikan: 401 di login = kredensial salah, bukan
  // sesi expired.
  if (path != null && (path == 'login' || path.startsWith('login/'))) {
    return;
  }
  AuthSession.instance.handleUnauthorized();
}
```

- [ ] **Step 3: Tambah cek 401 di `_handleResponse` (line 282-301)**

Di awal method, setelah log debug, sebelum `jsonDecode`:

```dart
dynamic _handleResponse(http.Response response, {String? path}) {
  AppLogger.debug('ApiClient Response (${response.statusCode}): '
      '${AppLogger.preview(response.body)}');

  if (response.statusCode == 401) {
    _onUnauthorized(path: path);
  }

  final json = jsonDecode(response.body);
  // ... sisanya tetap
}
```

- [ ] **Step 4: Pass `path` dari setiap caller `_handleResponse`**

Update signature call di:
- `get` (line 72): `_handleResponse(response, path: path);`
- `post` (line 146): `_handleResponse(response, path: path);`
- `put` (line 196): `_handleResponse(response, path: path);`
- `delete` (line 217): `_handleResponse(response, path: path);`
- `multipart` (line 244): `_handleResponse(response, path: path);`
- `multipartRaw` fallback (line 279): `_handleResponse(response, path: path);`

- [ ] **Step 5: Tambah cek 401 di `getRaw` (line 110-135)**

Setelah `final response = await _get(...)`, sebelum `if (response.statusCode >= 200 ...)`:

```dart
if (response.statusCode == 401) {
  _onUnauthorized(path: path);
}
```

- [ ] **Step 6: Tambah cek 401 di `postRaw` (line 161-185)**

Sama, setelah dapat response:

```dart
if (response.statusCode == 401) {
  _onUnauthorized(path: path);
}
```

- [ ] **Step 7: Tambah cek 401 di `multipartRaw` (line 249-280)**

Di cabang non-2xx (sebelum `return _handleResponse(response, path: path);` sudah cover via signature baru). Untuk konsistensi, juga tambah eksplisit:

```dart
if (response.statusCode == 401) {
  _onUnauthorized(path: path);
}
```

sebelum blok `if (response.statusCode >= 200 ...)`.

- [ ] **Step 8: Verifikasi analisis**

Run:
```bash
cd mobiles/sagansa && flutter analyze lib/services/api_client.dart
```
Expected: `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add mobiles/sagansa/lib/services/api_client.dart
git commit -m "feat(mobile): detect 401 and trigger auto-logout in ApiClient"
```

---

## Task 3: Inject `navigatorKey` & configure `AuthSession` di `MyApp`

**Files:**
- Modify: `mobiles/sagansa/lib/main.dart`

**Interfaces:**
- Consumes: `AuthSession.instance.configure(...)`

- [ ] **Step 1: Tambah import**

```dart
import 'services/auth_session.dart';
```

- [ ] **Step 2: Tambah field `_navigatorKey` & configure di `_MyAppState`**

Di class `_MyAppState` (line 231), tambahkan field:

```dart
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
```

Di `initState` (line 238-243), tambahkan configure:

```dart
@override
void initState() {
  super.initState();
  _themeProvider.initialize();
  AuthSession.instance.configure(_navigatorKey);
}
```

- [ ] **Step 3: Pass `navigatorKey` ke `MaterialApp`**

Di `MaterialApp(...)` (line 296), tambahkan:

```dart
return AnnotatedRegion<SystemUiOverlayStyle>(
  value: overlayStyle,
  child: MaterialApp(
    navigatorKey: _navigatorKey,
    restorationScopeId: 'sagansa', // jika masih ada; ikut status fix splash
    ...
  ),
);
```

**Catatan:** `restorationScopeId` sudah dihapus di fix splash-screen terpisah. Jika merge kedua branch, pastikan tidak re-add. Tidak relevan di task ini.

- [ ] **Step 4: Verifikasi analisis**

Run:
```bash
cd mobiles/sagansa && flutter analyze lib/main.dart
```
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add mobiles/sagansa/lib/main.dart
git commit -m "feat(mobile): wire navigatorKey to AuthSession for logout navigation"
```

---

## Task 4: Verifikasi akhir & smoke test

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

- [ ] **Step 3: Smoke test — single 401 trigger logout**

Setup:
1. Login ke app dengan kredensial valid → masuk `/home`.
2. **Manual invalidate token**: via `adb shell` (rooted) atau backend admin, revoke token user. Atau: clear `token` di storage lalu set string invalid `"invalid.jwt.token"`.

```bash
# Alternatif tanpa root: ubah value token di secure storage via debug backend
# atau paksa server-side revoke.
```

3. Di `/home`, pull-to-refresh (atau navigasi ke page yang trigger API call).
4. Expected:
   - Snackbar muncul: "Sesi Anda telah berakhir, silakan login kembali."
   - Otomatis navigasi ke `/login` (stack reset).
   - Token di storage sudah terhapus.

- [ ] **Step 4: Smoke test — multiple concurrent 401 (debounce)**

1. Login valid → `/home`.
2. Invalidate token (sama seperti Step 3).
3. Pull-to-refresh dashboard (load `sales-dashboard`, `inventory-anomalies`, `presences/today`, `salaries` bersamaan).
4. Expected:
   - Hanya **SATU** snackbar muncul (bukan 4).
   - Hanya **SATU** navigasi ke `/login`.
   - Log menunjukkan `AuthSession.handleUnauthorized` dipanggil sekali; 3 call berikutnya di-skip (`_loggingOut = true`).

- [ ] **Step 5: Smoke test — login 401 tidak trigger logout**

1. Logout dari app (atau fresh install).
2. Login dengan password salah → backend return 401.
3. Expected:
   - Error dialog muncul ("Invalid credentials" atau pesan dari server).
   - **Tidak ada** snackbar "Sesi telah berakhir".
   - **Tidak ada** navigasi otomatis (tetap di `/login`).

- [ ] **Step 6: Smoke test — 401 saat belum configure navigator (cold start)**

Scenario: token di storage expired, app cold-start.
1. Login valid → `/home`. Revoke token server-side.
2. Kill app (force stop).
3. Buka app lagi → `main()` baca token (masih ada) → `initialRoute = '/home'`.
4. `HomePage.initState` → load data → 401 → `AuthSession.handleUnauthorized`.
5. Expected: `AuthSession._navigatorKey.currentState` sudah ready (karena `runApp` sudah jalan dan `initState` sudah configure). Logout terpicu, navigasi ke `/login`.

**Catatan edge case:** bila 401 terjadi sebelum `MyApp.initState` (sangat cepat), `_navigateToLogin` handle `nav == null` dengan reset flag. Caller throw 401 → `HomePage` error → user lihat error screen, lalu manual refresh / restart. Tidak crash. Acceptable untuk v1.

- [ ] **Step 7: Final commit (jika ada perubahan)**

Jika semua smoke test lulus tanpa perubahan kode, skip. Jika ada fix:

```bash
git add -A
git commit -m "fix(mobile): 401 auto-logout post-review fixes"
```

---

## Risk & Mitigation

| Risk | Mitigation |
|---|---|
| `navigatorKey` null saat 401 pertama kali terjadi (race dengan `initState`) | `_navigateToLogin` handle null: reset flag, biarkan caller throw; main route gate pakai token (sudah dihapus) → cold start berikutnya ke `/login`. Tidak crash. |
| Multiple `AuthService.logout` dari debounce failure | Flag `_loggingOut` hanya reset setelah navigasi sync (cepat). Worst case 2 logout call paralel — `AuthService.logout` idempoten (clear storage yang sudah clear tetap OK). |
| Snackbar muncul di context yang salah (overlay null) | Cek `nav.overlay?.context` null; kalau null, skip snackbar, tetap navigasi. Tidak fatal. |
| Token expired tapi backend return 200 + flag `auth_error` (non-standard) | Out of scope. Backend Sagansa pakai standar Laravel 401 untuk unauthenticated. Tidak handle non-401 auth error di v1. |
| Interaksi dengan spec secure-storage-migration | Kedua spec kompatibel: `AuthSession` panggil `AuthService.logout` yang abstrak terhadap *di mana* token disimpan. Urutan merge bebas. Kalau secure-storage sudah merged, `AuthService.logout` sudah pakai `TokenStore.clear()` — `AuthSession` tidak perlu tahu. |
| User di tengah input form saat 401 terjadi | Form data hilang saat navigasi. Acceptable untuk v1 (sesi expired = harus login ulang). Future: konfirmasi dialog sebelum navigasi. Out of scope. |
