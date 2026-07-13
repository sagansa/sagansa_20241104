# Audit Kebijakan Apple App Store — Sagansa

Dokumen ini memetakan permission, data yang dikumpulkan, dan fitur Sagansa
terhadap [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/),
untuk meminimalkan risiko penolakan saat submit.

> Paralel dengan `play-policy-audit.md` (Android). Apple punya beberapa
> perbedaan kunci vs Play Store yang dibahas di bawah.

> **Status rilis publik pertama:** permission & fitur paling sensitif (background
> location, Firebase push, APNs) sengaja **dilepas/defer** dari rilis awal agar
> lolos review cepat. Lihat bagian 6 untuk catatan rilis berikutnya.

---

## 1. Info.plist Permission Strings — Status

| Permission Key | Use Case | Status |
|---|---|---|
| `NSLocationWhenInUseUsageDescription` | Presensi (check-in/check-out) saat app foreground | ✅ Ada |
| `NSLocationAlwaysUsageDescription` | Pencarian lokasi terdekat | ✅ Ada — ⚠️ lihat bagian 3 |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Combo lokasi | ✅ Ada — ⚠️ lihat bagian 3 |
| `NSCameraUsageDescription` | Foto saat presensi, form aset/pemasok/dokumen | ✅ Ada |
| `NSPhotoLibraryUsageDescription` | Pilih gambar dari galeri (image_picker) | ✅ Ada (baru ditambahkan) |
| `NSPhotoLibraryAddUsageDescription` | Simpan foto ke galeri | ✅ Ada (baru ditambahkan) |
| `NSLocalNetworkUsageDescription` | Cetak ke thermal printer via WiFi (ESC/POS TCP) | ✅ Ada |

### Permission yang TIDAK dideklarasikan (sengaja)

| Permission | Alasan | Kapan aktifkan |
|---|---|---|
| `NSBluetoothAlwaysUsageDescription` / `NSBluetoothPeripheralUsageDescription` | Printer thermal pakai **WiFi (TCP)**, bukan Bluetooth. Tidak ada kode Bluetooth aktif. | Hanya jika integrasi printer Bluetooth di masa depan |
| `NSMicrophoneUsageDescription` | App tidak merekam audio | — |
| `NSContactsUsageDescription` | App tidak akses address book | — |
| `NSCalendarsUsageDescription` | Kalender pakai in-app Syncfusion widget, bukan EventKit native | — |
| `NSFaceIDUsageDescription` | Tidak ada biometric auth | — |
| `NSUserTrackingUsageDescription` | Tidak ada tracking / IDFA / SDK iklan | — |

---

## 2. App Privacy (App Store Connect) — "Privacy Nutrition Label"

App Store Connect mewajibkan deklarasi **"App Privacy"** (data yang dikumpulkan).
Berikut mapping berdasarkan kode & permission aktif. Harus konsisten dengan
`PrivacyInfo.xcprivacy` (yang sudah dibuat di `ios/Runner/`).

| Data Type | Apple Category | Purpose | Linked to User | Used for Tracking |
|---|---|---|---|---|
| **Lokasi tepat** (lat/long saat check-in) | Location | App Functionality (absensi) | Ya | Tidak |
| **Foto & video** (kamera/galeri) | Photos or Videos | App Functionality | Ya | Tidak |
| **User ID** (login email/password) | Identifiers | App Functionality (akun) | Ya | Tidak |
| **Data transaksi** (penjualan, stok, karyawan) | Other User Content | App Functionality | Ya | Tidak |
| **Email kontak** | Contact Info | App Functionality | Ya | Tidak |

### Pertanyaan App Privacy — jawaban:
- **Apakah app mengumpulkan data?** Ya
- **Apakah data ditautkan ke user?** Ya
- **Apakah data dipakai untuk tracking?** **Tidak** (tidak ada IDFA, tidak ada SDK iklan)
- **Apakah data dipakai untuk pihak ketiga?** Tidak

> ⚠️ Jawaban App Privacy **harus konsisten** dengan `PrivacyInfo.xcprivacy` dan
> dengan Data Safety Form di Play Store. Ketidakkonsistenan = alasan reject.

---

## 3. ⚠️ Location "Always" Permission — RISIKO REVIEW TINGGI

### Masalah
Info.plist mendeklarasikan **`NSLocationAlwaysUsageDescription`** dan
**`NSLocationAlwaysAndWhenInUseUsageDescription`**. Kode Dart
(`presence_controller.dart`, `location_tracking_service.dart`) me-request
permission **`LocationPermission.always`**.

Tanpa `UIBackgroundModes: location` di Info.plist (tidak ada), app **tidak bisa
benar-benar track lokasi di background**. Jadi permission "Always" di-request
tapi fungsionalitas background-nya tidak aktif.

### Risiko
App Store reviewer (Guideline 5.1.1 - Privacy) sering menanyakan:
> "Mengapa app butuh akses lokasi 'Always'? Fitur background location apa yang
> digunakan?"

Jika tidak ada jawaban konkret + demo background location, **bisa ditolak**.

### Rekomendasi (pilih satu)

**Opsi A — Downgrade ke WhenInUse (rekomendasi untuk v1):**
- Hapus `NSLocationAlwaysUsageDescription` dan `NSLocationAlwaysAndWhenInUseUsageDescription`
  dari Info.plist
- Ubah `LocationPermission.always` → `LocationPermission.whileInUse` di
  `lib/controllers/presence_controller.dart` dan `location_tracking_service.dart`
- Absensi tetap berfungsi (lokasi didapat saat app foreground)
- Risiko review: **RENDAH** — sejalan dengan permission Play Store v1

**Opsi B — Pertahankan "Always" + siapkan justifikasi:**
- Tambah `UIBackgroundModes: [location]` di Info.plist
- Aktifkan capability Background Modes di Xcode
- Siapkan demo video & jawaban untuk reviewer:
  "App track lokasi karyawan saat shift aktif untuk keperluan absensi & operasional"
- Risiko review: **SEDANG–TINGGI** — butuh justifikasi kuat, review lebih lama

> Sesuai komentar di `play-policy-audit.md`, modul lokasi on-demand karyawan
> sengaja di-defer. **Opsi A paling konsisten** dengan strategi rilis awal.

---

## 4. Age Rating (Content Questionnaire)

App Store Connect age rating questionnaire. Jawaban untuk Sagansa:

| Pertanyaan | Jawaban |
|---|---|
| Cartoon violence | None |
| Realistic violence | None |
| Prolonged graphic or sadistic violence | None |
| Profanity or crude humor | None |
| Fear/Horror | None |
| Medical/Treatment info | None |
| Alcohol, tobacco, or drug use | None |
| Simulated gambling | None |
| Sexual content/Nudity | None |
| Unrestricted web access | No (url_launcher hanya buka URL admin panel, bukan browser terintegrasi) |
| Gambling with real currency | No (POS = transaksi bisnis, bukan gambling) |

**Rating yang diharapkan: 4+** (setara "Everyone" di Play Store).

---

## 5. Guideline-Specific Compliance Check

| Guideline | Topic | Status Sagansa |
|---|---|---|
| **1.1** Objectionable content | Tidak ada konten terlarang | ✅ Aman |
| **1.2** User-generated content | App punya form input, tapi tidak public feed. Tidak perlu reporting/blocking feature | ✅ Aman |
| **2.1** App completeness | **Wajib test menyeluruh via TestFlight sebelum submit.** Crash di review = reject instan | ⚠️ Pastikan smoke test |
| **2.3** Accurate metadata | Deskripsi harus match fitur aktual. Screenshot harus dari app nyata | ✅ Listing disiapkan |
| **2.5.6** Signing | App harus di-sign dengan distribution certificate (bukan development) | ✅ Via Xcode signing |
| **3.1.1** In-app purchase | App tidak punya IAP. POS = transaksi fisik offline, bukan digital goods | ✅ Aman |
| **3.1.3(f)** Free standalone apps | Sagansa gratis di App Store, akun via web sagansa.id | ✅ Aman |
| **4.0** Design | Minimum function: app fungsional penuh, bukan web wrapper | ✅ Aman |
| **4.2** Minimum functionality | App native Flutter dengan 50+ halaman fitur | ✅ Aman |
| **4.3** Spam | Satu app Sagansa (bukan duplikat). Bundle ID unik | ✅ Aman |
| **5.1.1** Data collection & storage | ⚠️ Lihat bagian 3 (location Always). Data lain terjustifikasi | ⚠️ Mitigasi di bagian 3 |
| **5.1.2** Data use & sharing | Data untuk app functionality, tidak dijual. Privacy policy ada | ✅ Aman |
| **5.1.5** Location services | ⚠️ Lihat bagian 3. Background location butuh justifikasi | ⚠️ Opsi A rekomendasi |
| **5.2.5** HTTP (non-HTTPS) | Production API = `https://api.sagansa.id` (HTTPS). Tidak perlu ATS exception. ⚠️ Dev fallback `http://...` jangan dipakai di production build | ✅ Aman (prod) |

---

## 6. PrivacyInfo.xcprivacy — Status

✅ **Sudah dibuat** di `ios/Runner/PrivacyInfo.xcprivacy` dan di-wire ke
Copy Bundle Resources.

Deklarasi:
- `NSPrivacyTracking` = false
- `NSPrivacyTrackingDomains` = [] (kosong)
- `NSPrivacyCollectedDataTypes`: Lokasi, Foto, User ID
- `NSPrivacyAccessedAPITypes`:
  - `NSPrivacyAccessedAPICategoryUserDefaults` → reason `CA92.1` (shared_preferences)
  - `NSPrivacyAccessedAPICategoryFileTimestamp` → reason `C617.1` (path_provider/sqflite)

> Tanpa file ini, upload ke App Store Connect memicu warning
> **ITMS-91053: Missing API declaration**. Walau masih bisa upload, warning ini
> bisa menjadi alasan reject di review.

---

## 7. Catatan untuk Rilis Berikutnya

Berikut fitur yang **di-defer** dan persiapan saat diaktifkan kembali:

### 7.1 Firebase Cloud Messaging (FCM) / Push Notification

**Status saat ini:** Kode Dart ada (`firebase_core`, `firebase_messaging` di
pubspec), tapi native iOS **belum dikonfigurasi** (tidak ada
`GoogleService-Info.plist`, tidak ada APNs entitlement). `location_tracking_service.dart`
init Firebase dengan fail-silent.

**Saat mengaktifkan:**
1. Tambah `GoogleService-Info.plist` (dari Firebase Console) ke `ios/Runner/`
2. Buat entitlements file (`Runner.entitlements`) dengan:
   ```xml
   <key>aps-environment</key>
   <string>production</string>
   ```
3. Aktifkan capability **Push Notifications** di Xcode
4. Tambah `UIBackgroundModes: [remote-notification]` di Info.plist (untuk silent FCM)
5. Generate APNs Auth Key di Apple Developer → upload ke Firebase Console
6. Build ulang + test push via Firebase Console

### 7.2 Background Location (Modul Lokasi Karyawan)

Lihat bagian 3 Opsi B. Persiapan:
1. `UIBackgroundModes: [location]` di Info.plist
2. Aktifkan Background Modes capability di Xcode
3. Siapkan justifikasi & demo video untuk reviewer
4. Estimasi review: **3–7 hari**, bisa lebih untuk first-time approval

### 7.3 workmanager (Background Periodic Task)

`workmanager` (kirim lokasi tiap ~2 jam) di-defer. Di iOS, butuh:
- `UIBackgroundModes: [fetch]` atau `[processing]` di Info.plist
- iOS sangat membatasi background execution (lebih ketat dari Android)
- Pertimbangkan: apakah worth it untuk iOS, atau buat Android-only path

> ⚠️ Tanpa `UIBackgroundModes`, `workmanager` di iOS **tidak akan berjalan di
> background**. Saat ini efektif Android-only — ini OK untuk v1.

---

## Ringkasan Status Rilis Awal

| Item | Status |
|---|---|
| Bundle ID valid (`id.sagansa.app`) | ✅ |
| Info.plist permission strings lengkap | ✅ |
| PrivacyInfo.xcprivacy (wajib 2024) | ✅ |
| No tracking / no IDFA / no ATT needed | ✅ |
| No IAP / no Sign in with Apple needed | ✅ |
| Production API HTTPS (no ATS exception) | ✅ |
| App Privacy mapping (siap isi di App Store Connect) | ✅ |
| Age rating questionnaire (siap isi) | ✅ |
| Location "Always" permission tanpa background mode | ⚠️ **Mitigasi: downgrade ke WhenInUse (Opsi A)** |
| Firebase/push iOS | ⚠️ Deferred — fail-silent, OK untuk v1 |
| workmanager background | ⚠️ Android-only — OK untuk v1 |

**Profil risiko review: SEDANG** (turun ke RENDAH jika Opsi A location
dipilih). Satu-satunya risk flag signifikan adalah location "Always" — sebaiknya
downgrade ke WhenInUse sebelum submit pertama.
