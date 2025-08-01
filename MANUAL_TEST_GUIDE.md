# Manual Testing Guide untuk Auto-Login

## Langkah-langkah Testing:

### 1. Persiapan Testing
```bash
# Build dan install app
flutter build apk --debug
# Install ke device/emulator
flutter install
```

### 2. Test Auto-Login

#### Test 1: Login Pertama Kali
1. Buka app
2. Masukkan credentials yang valid
3. Login berhasil → masuk ke home page
4. **Periksa log console** untuk memastikan token tersimpan:
   ```
   AuthService: Token saved successfully
   AuthService: User data saved: [username]
   ```

#### Test 2: Auto-Login Setelah Restart
1. **Tutup app sepenuhnya** (kill process, bukan minimize)
2. **Buka app lagi**
3. **Hasil yang diharapkan**: Langsung masuk ke home page tanpa login
4. **Periksa log console**:
   ```
   AuthProvider: Starting initialization...
   AuthService: Retrieved token: exists
   AuthProvider: Token exists: true
   AuthProvider: Auto-login successful
   ```

#### Test 3: Jika Auto-Login Gagal
Jika masih diminta login, periksa log untuk error:

**Log Normal (Auto-login berhasil):**
```
AuthProvider: Starting initialization...
AuthService: Retrieved token: exists (xxx chars)
AuthService: Retrieved user data: [username]
AuthProvider: Token exists: true
AuthProvider: UserData exists: true
AuthProvider: Auto-login successful
AuthProvider: Initialization complete. State: AuthState.success
```

**Log Error (Auto-login gagal):**
```
AuthProvider: Starting initialization...
AuthService: Retrieved token: null
AuthProvider: Token exists: false
AuthProvider: No stored credentials found
AuthProvider: Initialization complete. State: AuthState.idle
```

### 3. Debugging Steps

#### Jika Token Tidak Tersimpan:
1. Periksa apakah login API mengembalikan token
2. Periksa permission secure storage
3. Test dengan credentials yang berbeda

#### Jika Token Tersimpan Tapi Tidak Terbaca:
1. Restart device/emulator
2. Clear app data dan test ulang
3. Periksa Android/iOS keychain permissions

#### Jika Token Terbaca Tapi Auto-login Gagal:
1. Periksa validasi token di background
2. Test dengan network disabled
3. Periksa response dari server

### 4. Test dengan Versi Simple (Tanpa Validasi Server)

Jika masih bermasalah, gunakan versi simple untuk isolasi masalah:

1. **Ganti import di main.dart** (sementara):
   ```dart
   // Ganti
   import 'providers/auth_provider.dart';
   // Dengan
   import 'providers/auth_provider_simple.dart';
   
   // Dan ganti
   ChangeNotifierProvider(create: (_) => AuthProvider()),
   // Dengan
   ChangeNotifierProvider(create: (_) => AuthProviderSimple()),
   ```

2. **Test ulang** dengan langkah yang sama
3. **Jika versi simple bekerja**, masalah ada di validasi token
4. **Jika versi simple tidak bekerja**, masalah ada di secure storage

### 5. Reset untuk Testing Bersih

```bash
# Clear app data
adb shell pm clear com.example.sagansa

# Atau uninstall dan install ulang
flutter clean
flutter build apk --debug
flutter install
```

### 6. Expected Behavior

**Skenario Normal:**
1. Login pertama → Token disimpan → Masuk home
2. Tutup app → Buka app → Auto-login → Langsung ke home
3. Logout → Token dihapus → Kembali ke login page
4. Tutup app → Buka app → Tetap di login page

**Log yang Menunjukkan Success:**
- Login: "Token saved successfully"
- Auto-login: "Auto-login successful"
- State: "AuthState.success"

### 7. Common Issues

1. **Secure Storage Permission**: Android mungkin memerlukan unlock device
2. **Network Issues**: Validasi token gagal karena network
3. **Server Issues**: Endpoint user-presence tidak tersedia
4. **State Management**: AuthProvider tidak mempertahankan state

### 8. Quick Fix untuk Testing

Jika ingin test cepat tanpa validasi server, comment out baris ini di `auth_provider.dart`:

```dart
// Comment out this line temporarily
// _validateTokenInBackground();
```

Ini akan membuat auto-login bekerja tanpa validasi server.