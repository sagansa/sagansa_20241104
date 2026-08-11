# Auto-Logout saat 401 Unauthorized — Design Spec

**Date:** 2026-08-11
**Status:** Draft
**Scope:** `mobiles/sagansa` (HTTP & auth layer)

## Problem

Backend Sagansa mengeluarkan JWT berbasis expiry (lihat response `/login` → `access_token`). Saat token expired atau di-revoke di sisi server, app **tidak pernah tahu**. Akibatnya:

1. App cold-start: token string masih ada di storage → `initialRoute = '/home'` (`main.dart:183`). User masuk home dengan token kadaluwarsa.
2. Setiap API call di `/home` dapat response **401** → `_handleResponse` (`api_client.dart:282-301`) melempar `Exception(json['message'])`. UI menampilkan error generik ("Unauthenticated." atau pesan dari server) per request, bukan mengarahkan user ke login.
3. Tidak ada cleanup: token invalid tetap di storage → cold-start berikutnya tetap masuk `/home` → siklus error berulang.

Konstanta `AppConstants.statusUnauthorized = 401` (`constants.dart:177`) sudah didefinisikan tetapi **tidak pernah direferensikan** di mana pun — dead code, konfirmasi belum ada handling.

Satu-satunya auto-logout yang ada saat ini: `home_page.dart:100-108` logout ketika pesan error mengandung literal string `'User data not found'` (data-driven, bukan status-code-driven) — fragile.

## Context (current state)

- HTTP layer: `lib/services/api_client.dart` — singleton, semua request (`get`, `post`, `put`, `delete`, `multipart`, `getRaw`, `postRaw`, `multipartRaw`) lewat method ini atau turunannya.
- Semua method request memanggil satu dari `_get`/`_post`/`_put`/`_delete`/`request.send` (multipart), lalu response diproses di `_handleResponse` atau inline.
- **5 jalur response handling**:
  1. `_handleResponse` (line 282-301) — dipakai `get`, `post`, `put`, `delete`, `multipart`, `multipartRaw`.
  2. `getRaw` inline handler (line 120-135).
  3. `postRaw` inline handler (line 170-185).
  4. `multipartRaw` inline handler (line 273-280) — sebagian, sisanya `_handleResponse`.
  5. Login & logout (`AuthService`) pakai `ApiClient.post('login')` / `post('logout')` — lewat `_handleResponse`.
- Logout: `AuthProvider.logout` (`auth_provider.dart:116-148`) → `AuthService.logout` → backend call + clear storage + UI navigate ke `/login`.
- Navigasi logout saat ini: `home_page.dart:127-131` & `app_drawer.dart:172-177` pakai `Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false)`.
- Backend 401 response body: `{"message": "Unauthenticated.", "status": "error"}` (Laravel default `auth:api` middleware) — tidak ada field khusus. Deteksi wajib via HTTP status code.

## Requirements

1. **R1 — Deteksi 401 terpusat.** Setiap response 401 dari backend (kecuali endpoint `login`) memicu auto-logout. Tidak boleh ada handler 401 tersebar di tiap page/provider.
2. **R2 — Auto-logout side-effect.** Saat 401 terdeteksi: hapus token dari storage, hapus data user, deregister FCM/periodic task (sama dengan logout manual), lalu navigasi ke `/login` dan reset stack.
3. **R3 — Debounce.** Multiple request concurrent yang semuanya dapat 401 (mis. dashboard load beberapa endpoint) hanya boleh memicu **satu** logout action, bukan bertumpuk.
4. **R4 — Jangan trigger pada endpoint publik.** Request ke `/login` yang dapat 401 (kredensial salah) **tidak boleh** memicu auto-logout (tidak ada yang di-logout). Begitu juga request yang belum punya token.
5. **R5 — Pesan user-friendly.** Saat auto-logout terpicu, tampilkan satu notifikasi (snackbar/dialog) "Sesi Anda telah berakhir, silakan login kembali" — bukan error generik per request.
6. **R6 — Non-blocking untuk caller.** Method request (`get`, `post`, dll.) tetap melempar exception seperti biasa setelah 401 (agar caller UI tidak lanjut mengolah data kosong), tetapi side-effect logout sudah di-schedule di background.
7. **R7 — Tidak mengubah flow login.** `AuthService.login` tetap dapat 401 (wrong password) tanpa trigger auto-logout.
8. **R8 — Dapat di-disable di test.** Ada kill switch untuk menonaktifkan auto-logout di unit/integration test.

## Architecture Decision: Interceptor pattern via callback di `ApiClient`

**Pendekatan:** Tambah mekanisme interceptor di `ApiClient`: saat response 401 terdeteksi di titik manapun (baik di `_handleResponse` maupun inline handler `getRaw`/`postRaw`/`multipartRaw`), panggil `AuthSession.instance.handleUnauthorized()` — singleton yang debounce, bersihkan storage, dan navigasi ke `/login`. `ApiClient` tidak tahu tentang `BuildContext` / Navigator; navigasi dilakukan via `globalKey` yang di-set dari `MyApp`.

**Alasan:**
- **Centralized.** 5 jalur response di `ApiClient` cukup tambahkan satu cek `if (response.statusCode == 401)` di masing-masing. Logic logout di satu tempat (`AuthSession`).
- **Decoupled dari UI.** `ApiClient` (service layer) tidak boleh import `package:flutter/widgets.dart` atau pegang `BuildContext`. `AuthSession` jembatan: menerima `navigatorKey` yang di-inject dari `MyApp`.
- **Debounce sederhana.** `AuthSession` pakai flag `bool _loggingOut` — request 401 kedua dan seterusnya di-skip kalau logout sudah in-flight. Setelah navigasi selesai, flag di-reset.
- **Exception tetap dilempar.** Setelah trigger `handleUnauthorized()`, method request tetap `throw Exception(...)` seperti sebelumnya — caller tidak break.

**Alternatif yang ditolak:**
- *`dio` interceptor* → app pakai `package:http` (bukan `dio`), migrasi ke `dio` out-of-scope dan menyentuh banyak file.
- *Wrapper di setiap service* (`UserService`, `LeaveService`, dll.) → tersebar di 10+ service, rawan terlewat. Ditolak.
- *`ApiClient` langsung panggil `Navigator.pushNamedAndRemoveUntil`* → service layer tidak boleh pegang `BuildContext`; `ApiClient` perlu global key; tetap perlu indirection. `AuthSession` lebih clean.
- *Global callback stream* → overkill untuk kebutuhan satu event type (401).

## Design

### 1. `AuthSession` — orchestrator auto-logout

File baru: `lib/services/auth_session.dart`

```dart
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'token_store.dart';

/// Orchestrator auto-logout saat response 401 dari backend.
///
/// Dipanggil oleh ApiClient. Idempotent dalam window logout: bila beberapa
/// request concurrent dapat 401 bersamaan, hanya SATU proses logout yang
/// berjalan; sisanya no-op. Setelah navigasi selesai, flag di-reset agar
/// sesi berikutnya (setelah user login ulang) bisa trigger lagi.
class AuthSession {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _loggingOut = false;

  /// Di-set dari MyApp.initState. Dipakai untuk navigasi tanpa BuildContext.
  void configure(GlobalKey<NavigatorState> key) => _navigatorKey = key;

  /// Kill switch untuk test. Set false untuk disable auto-logout.
  bool enabled = true;

  /// Dipanggil ApiClient ketika response.statusCode == 401.
  /// Tidak throws — failure di-silent agar tidak mengganggu caller.
  Future<void> handleUnauthorized() async {
    if (!enabled || _loggingOut) return;
    _loggingOut = true;
    try {
      // Bersihkan token, data user, FCM/periodic task (sama dengan logout
      // manual). AuthService.logout sudah swallow error internal.
      await AuthService().logout().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Best-effort cleanup; navigasi tetap dijalankan.
    }
    _navigateToLogin();
  }

  void _navigateToLogin() {
    final nav = _navigatorKey?.currentState;
    if (nav == null) {
      // Navigator belum ready (mis. masih di splash). Reset flag; ApiClient
      // tetap throw 401 ke caller — main() route gate akan arahkan ke login
      // karena token sudah dihapus.
      _loggingOut = false;
      return;
    }
    nav.pushNamedAndRemoveUntil('/login', (route) => false);
    _loggingOut = false;
  }
}
```

### 2. Inject navigatorKey dari `MyApp`

Di `lib/main.dart` `_MyAppState`:

```dart
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

@override
void initState() {
  super.initState();
  _themeProvider.initialize();
  AuthSession.instance.configure(_navigatorKey);
}
```

Lalu di `MaterialApp`:
```dart
MaterialApp(
  navigatorKey: _navigatorKey,
  ...
)
```

### 3. `ApiClient` — deteksi 401 di semua jalur response

Buat helper private:
```dart
void _onUnauthorized() {
  // Fire-and-forget; side-effect di background. Tidak await agar pemanggil
  // request tetap dapat exception 401 secara sinkron-ish.
  AuthSession.instance.handleUnauthorized();
}
```

Tambahkan pengecekan di titik response:

**a) `_handleResponse` (line 282-301)** — tambah di paling atas, sebelum decode:
```dart
dynamic _handleResponse(http.Response response) {
  AppLogger.debug('ApiClient Response (${response.statusCode}): ...');
  if (response.statusCode == 401) {
    _onUnauthorized();
  }
  final json = jsonDecode(response.body);
  ...
}
```

**b) `getRaw` inline (line 120-135)** — tambah setelah dapat response, sebelum cek status:
```dart
if (response.statusCode == 401) {
  _onUnauthorized();
}
```

**c) `postRaw` inline (line 170-185)** — sama.

**d) `multipartRaw` inline (line 273-280)** — sama, di cabang yang cek 2xx.

**e) Endpoint `/login` dikecualikan** — tidak perlu special-case eksplisit karena:
- Saat login, token lama (jika ada) akan dihapus oleh `AuthService.login` → `_saveUserData` overwrite. Tetap aman.
- Bila user belum login & call `/login` dapat 401 (wrong password), `handleUnauthorized` akan `AuthService.logout()` yang idempotent (cleans up nothing). Tidak ada efek samping buruk.
- Namun untuk efisiensi & kejelasan intent, skip `_onUnauthorized` untuk path yang diawali `/login`:

Di setiap method request (`get`, `post`, dll.) atau di `_onUnauthorized`, tambahkan guard:
```dart
void _onUnauthorized({String? path}) {
  if (path != null && (path == 'login' || path.startsWith('login'))) return;
  AuthSession.instance.handleUnauthorized();
}
```

Lalu pass `path` dari setiap call site yang tahu path-nya. Untuk `multipart`, pass `path` juga.

### 4. Pesan user-friendly

`AuthSession._navigateToLogin` bisa langsung tampilkan snackbar setelah navigasi:
```dart
final ctx = nav.overlay?.context;
if (ctx != null) {
  ScaffoldMessenger.of(ctx).showSnackBar(
    const SnackBar(content: Text('Sesi Anda telah berakhir, silakan login kembali.')),
  );
}
```

(Catatan: snackbar overlay bisa null pada edge case; fallback tetap navigasi.)

### 5. Data Flow — Multiple 401 dari dashboard load

```
[HomeDashboardProvider.loadAll()]  ← concurrent: sales, anomaly, presence, salary
   │
   ├── ApiClient.get('sales-dashboard') → 401 → _onUnauthorized()
   │       │
   │       └── AuthSession.handleUnauthorized()
   │              ├── _loggingOut = true
   │              ├── AuthService.logout() (clear token, FCM, prefs)
   │              └── navigate to /login (reset stack)
   │
   ├── ApiClient.get('inventory-anomalies') → 401 → _onUnauthorized()
   │       └── AuthSession.handleUnauthorized() → _loggingOut=true → SKIP
   │
   ├── ApiClient.get('presences/today') → 401 → _onUnauthorized()
   │       └── AuthSession.handleUnauthorized() → SKIP
   │
   └── (caller masing-masing throw Exception, provider catch, UI no-op)
```

## Files to Create/Modify

| File | Action |
|---|---|
| `mobiles/sagansa/lib/services/auth_session.dart` | **Create** — orchestrator auto-logout |
| `mobiles/sagansa/lib/services/api_client.dart` | Modify — deteksi 401 di 5 jalur, panggil `_onUnauthorized` |
| `mobiles/sagansa/lib/main.dart` | Modify — inject `navigatorKey`, configure `AuthSession` |
| `mobiles/sagansa/lib/utils/constants.dart` | Modify — reference `statusUnauthorized` (atau biarkan dead) |

## Out of Scope

- **Migrasi ke `dio`.** App tetap `package:http`. Interceptor pattern di-emulate via helper method.
- **Refresh token / silent re-auth.** Backend tidak punya refresh endpoint. Saat 401 → logout langsung, user login ulang. Future work kalau backend sudah support refresh.
- **Secure storage.** `AuthSession` memanggil `AuthService.logout` yang membersihkan storage; *di mana* token disimpan (SharedPreferences vs secure storage) adalah scope spec terpisah: `2026-08-11-secure-storage-migration-design.md`. Dua spec ini kompatibel — urutan eksekusi bebas.
- **Retry request setelah re-login.** Setelah user login ulang, app masuk `/home` fresh; request lama yang gagal tidak di-replay. Out of scope.
- **Offline queue.** Penanganan 401 saat offline (network error vs auth error) sudah jelas — 401 hanya muncul kalau request sampai ke server.
- **Endpoint-level policy.** Semua endpoint (kecuali `/login`) diperlakukan sama saat 401. Tidak ada whitelist per-endpoint selain `/login`.
- **Telemetri / log 401 ke backend.** Future analytics work.
