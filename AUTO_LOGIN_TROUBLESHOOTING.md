# Auto-Login Troubleshooting Guide

## Masalah: App meminta login setiap kali dibuka

### Langkah Debugging:

1. **Periksa Log Console**
   - Jalankan app dalam debug mode
   - Perhatikan log yang dimulai dengan "AuthProvider:" dan "AuthService:"
   - Log akan menunjukkan apakah token tersimpan dan berhasil dibaca

2. **Periksa Penyimpanan Token**
   ```
   AuthService: Retrieved token: exists/null
   AuthProvider: Token exists: true/false
   AuthProvider: UserData exists: true/false
   ```

3. **Periksa Status Inisialisasi**
   ```
   AuthProvider: Auto-login successful
   AuthProvider: Initialization complete. State: AuthState.success
   ```

### Kemungkinan Penyebab:

1. **Token tidak tersimpan saat login**
   - Periksa apakah login berhasil menyimpan token
   - Log: "AuthService: Retrieved token: null"

2. **Secure Storage tidak berfungsi**
   - Masalah permission atau konfigurasi platform
   - Token tersimpan tapi tidak bisa dibaca

3. **Validasi token gagal**
   - Server mengembalikan 401 untuk token yang valid
   - Network error saat validasi

4. **State management issue**
   - AuthProvider tidak mempertahankan state success

### Solusi:

1. **Pastikan Login Menyimpan Token**
   ```dart
   // Di AuthService.login()
   await _secureStorage.write(key: tokenKey, value: token);
   await _secureStorage.write(key: userDataKey, value: json.encode(userData));
   ```

2. **Periksa Konfigurasi Secure Storage**
   ```dart
   static const _secureStorage = FlutterSecureStorage(
     aOptions: AndroidOptions(
       encryptedSharedPreferences: true,
     ),
     iOptions: IOSOptions(
       accessibility: KeychainAccessibility.first_unlock_this_device,
     ),
   );
   ```

3. **Disable Validasi Token Sementara**
   - Untuk testing, comment out `_validateTokenInBackground()`
   - Jika auto-login bekerja, masalah ada di validasi token

4. **Reset Secure Storage**
   ```dart
   await _authService.clearAuthData();
   ```

### Test Manual:

1. Login ke app
2. Tutup app sepenuhnya (kill process)
3. Buka app lagi
4. Periksa apakah langsung masuk ke home page

### Log yang Diharapkan untuk Auto-Login Sukses:

```
AuthProvider: Starting initialization...
AuthService: Retrieved token: exists
AuthService: Retrieved user data: [username]
AuthProvider: Token exists: true
AuthProvider: UserData exists: true
AuthProvider: Auto-login successful
AuthProvider: Initialization complete. State: AuthState.success
```

### Jika Masih Bermasalah:

1. Periksa apakah endpoint `/user-presence` berfungsi dengan token
2. Test dengan Postman menggunakan token yang sama
3. Periksa response code dari server
4. Pastikan token tidak expired di server