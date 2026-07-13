# Panduan Upload Sagansa ke Apple App Store

Panduan langkah-demi-langkah dari akun Apple Developer hingga app live di App Store
/ TestFlight.

> Paralel dengan `play-console-upload-guide.md` (Android). Beberapa aset
> (deskripsi, privacy policy, screenshot) bisa dipakai ulang dari
> `play-store-listing.md`.

---

## Prasyarat

- [ ] Mac dengan macOS terbaru (wajib — Xcode hanya jalan di macOS)
- [ ] [Xcode](https://developer.apple.com/xcode/) versi terbaru (gratis di Mac App Store)
- [ ] Akun **Apple Developer Program** — biaya **$99/tahun** (berulang, bukan sekali bayar)
- [ ] Flutter SDK ter-install + berfungsi (`flutter doctor` hijau)
- [ ] CocoaPods ter-install (`sudo gem install cocoapods` atau via Homebrew)
- [ ] App icon 1024×1024 (sudah ada di `ios/Runner/Assets.xcassets/AppIcon.appiconset/`)
- [ ] Screenshot iPhone & iPad (lihat `app-store-listing.md`)
- [ ] URL Privacy Policy (wajib — bisa dipakai ulang dari Play Store)

> ⚠️ Berbeda dari Play Store ($25 sekali bayar), Apple **menagih $99 setiap
> tahun**. Jika tidak diperpanjang, app dihapus dari App Store.

---

## Langkah 1 — Daftar Apple Developer Program

1. Buka https://developer.apple.com/programs/
2. Sign in dengan Apple ID (2FA wajib diaktifkan).
3. Klik **"Enroll"** → pilih tipe:
   - **Individual / Sole Proprietor** — nama pribadi, review cepat (1–2 hari)
   - **Organization** — butuh D-U-N-S Number (gratis, proses 1–2 minggu), nama
     legal entity tampil sebagai developer
4. Bayar **$99/tahun** (kartu kredit).
5. Tunggu approval (Individual: biasanya <24 jam; Organization: 1–2 minggu).
6. Setelah aktif, login ke https://developer.apple.com/account → catat **Team ID**
   (10 karakter, contoh `A1B2C3D4E5`) dari halaman Membership.

> ⚠️ **Pilih tipe dengan hati-hati.** Individual tidak bisa diubah ke Organization
> tanpa mendaftar akun baru. Untuk app bisnis, **Organization** direkomendasikan.

---

## Langkah 2 — Buat App ID & Provisioning Profile

### Cara mudah (rekomendasi): Automatic Signing via Xcode

Lewati langkah ini — Xcode auto-manage signing akan membuat App ID, certificate, dan
provisioning profile otomatis saat Anda buka project (Langkah 3). Cukup pastikan
Team ID Anda terdaftar.

### Cara manual (jika perlu)

1. **App ID:** https://developer.apple.com/account/resources/identifiers/list
   - Klik "+" → App IDs → App
   - Description: `Sagansa`
   - Bundle ID: **Explicit** → `id.sagansa.app`
   - Capabilities: biarkan default (lokasi & kamera tidak butuh explicit toggle)
   - Register

2. **Distribution Certificate:**
   https://developer.apple.com/account/resources/certificates/list
   - Klik "+" → **App Store and Ad Hoc**
   - Buat CSR di Keychain Access → upload → download `.cer` → double-click install

3. **Provisioning Profile:**
   https://developer.apple.com/account/resources/profiles/list
   - Klik "+" → **App Store**
   - Pilih App ID `id.sagansa.app` → pilih certificate → download

---

## Langkah 3 — Konfigurasi Signing di Xcode

1. Buka project:
   ```bash
   cd mobiles/sagansa/ios
   open Runner.xcworkspace
   ```
   > **Penting:** buka `.xcworkspace`, **bukan** `.xcodeproj`. Workspace include
   > Pods (CocoaPods dependencies).

2. Pilih target **Runner** di sidebar kiri → tab **Signing & Capabilities**.

3. Untuk config **Debug** dan **Release**:
   - Centang **"Automatically manage signing"**
   - **Team:** pilih tim Apple Developer Anda
   - Xcode akan membuat provisioning profile otomatis. Status: hijau ✓

4. Jika muncul error "Failed to register bundle identifier":
   - Bundle ID `id.sagansa.app` sudah dipakai orang lain → ganti ke yang unik
   - Atau belum terdaftar di akun Anda → buat manual (Langkah 2)

> Signing config (DEVELOPMENT_TEAM) **sengaja tidak di-hardcode** di project agar
> tidak bentrok antar developer. Setiap developer pilih Team-nya sendiri di Xcode.

---

## Langkah 4 — Setup Dependencies (Pod install)

Karena `ios/Podfile.lock` pernah rusak (merge conflict) dan dihapus, perlu
diregenerasi fresh:

```bash
cd mobiles/sagansa

# Pastikan dependencies Flutter up-to-date
flutter pub get

# Regenerasi Podfile.lock + install pods
cd ios
pod install
```

Jika error "CocoaPods not installed":
```bash
sudo gem install cocoapods
# atau
brew install cocoapods
```

Setelah `pod install` berhasil, `Podfile.lock` baru akan ter-generate dengan
daftar pod yang akurat (sesuai pubspec.yaml terkini). **Commit file ini** agar
build reproducible antar developer.

> ℹ️ Mulai sekarang, selalu buka `Runner.xcworkspace` (bukan `.xcodeproj`) karena
> Pods sudah ter-integrasi di workspace.

---

## Langkah 5 — Build Archive

### Opsi A: Via Xcode (rekomendasi untuk first-time)

1. Di Xcode, pilih device target **"Any iOS Device (arm64)"** (bukan simulator).
2. Menu **Product → Archive** (Cmd+Shift+B lalu pilih Archive, atau menu bar).
3. Tunggu proses archive selesai. **Organizer** window otomatis terbuka.
4. Di Organizer, pilih archive terbaru → klik **"Distribute App"**.

### Opsi B: Via command line (flutter build ipa)

```bash
cd mobiles/sagansa

# Clean build dulu untuk memastikan tidak ada artifact lama
flutter clean
flutter pub get
cd ios && pod install && cd ..

# Build IPA dengan export options
flutter build ipa --export-options-plist=ios/ExportOptions.plist
```

Output: `build/ios/ipa/Sagansa.ipa`

> ⚠️ Sebelum jalankan Opsi B, edit `ios/ExportOptions.plist`: ganti `TEAM_ID`
> dan `PROVISIONING_PROFILE_UUID` dengan nilai asli Anda (lihat komentar di
> file tersebut). Jika pakai automatic signing, export options bisa lebih
> sederhana — konsultasi dokumentasi Flutter `flutter build ipa --help`.

---

## Langkah 6 — Upload ke App Store Connect

### Opsi A: Via Xcode Organizer (rekomendasi)

1. Setelah Archive (Langkah 5 Opsi A), Organizer terbuka otomatis.
2. Pilih archive → **"Distribute App"** → **"App Store Connect"**.
3. Pilih **"Upload"** (bukan "Export").
4. Ikuti wizard:
   - **App Store Connect API** (opsional): skip / sign in
   - **Bitcode** → OFF (Flutter tidak pakai bitcode)
   - **Symbols** → ON (upload dSYM untuk crash symbolication)
5. Klik **"Upload"**. Tunggu proses upload + processing (5–15 menit).

### Opsi B: Via altool (command line)

```bash
# Upload IPA ke App Store Connect
xcrun altool --upload-app \
  -f build/ios/ipa/Sagansa.ipa \
  -t ios \
  -u "apple-id@email.com" \
  -p "app-specific-password"
```

> Untuk `-p`, buat **app-specific password** di
> https://appleid.apple.com → Sign-In and Security → App-Specific Passwords.

### Opsi C: Via Transporter app (GUI)

Download **Transporter** (gratis di Mac App Store) → drag-drop `.ipa` → upload.

---

## Langkah 7 — Buat App Record di App Store Connect

1. Buka https://appstoreconnect.apple.com
2. **My Apps → "+" → New App**
3. Isi:
   - **Platforms:** iOS
   - **Name:** `Sagansa` (cek ketersediaan — harus unik global)
   - **Primary Language:** Indonesian
   - **Bundle ID:** `id.sagansa.app` (muncul setelah upload di Langkah 6 diproses)
   - **SKU:** internal ID, mis. `sagansa.ios` (tidak terlihat user)
   - **User Access:** Full Access
4. **Create.**

---

## Langkah 8 — Isi App Information & Listing

Menu: **App Information** dan **App Store** tab.

1. **App Information:**
   - **Category:** Primary = **Business**, Secondary = **Productivity** atau
     **Finance**
   - **Content Rights:** tidak ada third-party content
   - **Age Rating:** isi questionnaire (lihat `app-store-policy-audit.md` §4)
   - **URL:** Privacy Policy URL (wajib, bisa dipakai ulang dari Play Store)

2. **App Store tab — bagian "App Store" localization (Indonesia):**
   - **App Name:** `Sagansa`
   - **Subtitle:** (≤30 char) lihat `app-store-listing.md`
   - **Description:** (≤4000 char) lihat `app-store-listing.md`
   - **Keywords:** (≤100 char, comma-separated) lihat listing
   - **Promotional Text:** (≤170 char, bisa diubah tanpa re-review)
   - **Screenshots:** wajib 6.7" iPhone (iPhone 15 Pro Max), opsional 6.5", 5.5",
     iPad 12.9" dan 11" — lihat `app-store-listing.md`
   - **App Preview Video:** opsional (15–30 detik)

3. **Build:** setelah upload (Langkah 6) selesai diproses, pilih build di sini.

> 📱 **iOS 17+ screenshot requirement:** App Store Connect sekarang mewajibkan
> screenshot 6.7" (iPhone 15 Pro Max / 1290×2796). Capture via simulator
> tersebut.

---

## Langkah 9 — TestFlight (Internal Testing)

Sebelum submit ke review, uji via TestFlight:

1. Menu: **TestFlight** tab di App Store Connect.
2. Bagian **Internal Testing** → add tester (tim Sagansa, Apple ID mereka).
3. Klik **"Add Build to Test"** → pilih build dari Langkah 6.
4. Tester akan dapat invite email → install app **TestFlight** → install Sagansa.
5. Smoke test di device real iPhone/iPad.

> Internal testing: tanpa review, instant. External testing (100 orang+): butuh
> beta app review (lebih cepat dari production review).

---

## Langkah 10 — Submit untuk Review

1. Pastikan semua checklist hijau di App Store Connect (listing, build, privacy,
   age rating).
2. Menu: **App Store** tab → bagian **"Submit for Review"** (kanan atas).
3. Isi export compliance otomatis jika `ITSAppUsesNonExemptEncryption = false`
   di Info.plist (sudah diset). Tidak perlu jawab manual kuesioner.
4. **Content Rights:** pilih yang sesuai (tidak ada third-party content).
5. **Advertising Identifier:** **No** (tidak ada IDFA / iklan).
6. Submit.
7. Status: **"Waiting for Review"** → **"In Review"** → **"Ready for Sale"**
   (atau "Rejected").

### Estimasi waktu review
- First submission: **1–3 hari** (kadang sampai 1 minggu)
- Update submission: **12–24 jam**
- 50% app lolos dalam 24 jam setelah first submit

---

## Troubleshooting Umum

| Masalah | Solusi |
|---|---|
| "No profiles for 'id.sagansa.app' were found" | Buka Xcode → Signing & Capabilities → centang "Automatically manage signing" → pilih Team |
| "bundle id has not been registered via Apple Developer" | Buat App ID di developer.apple.com, atau pakai automatic signing |
| "ITMS-91053: Missing API declaration" | `PrivacyInfo.xcprivacy` belum ter-bundle. Pastikan file ada di Copy Bundle Resources (sudah di-wire di project). Cek: Build Phases → Copy Bundle Resources harus ada PrivacyInfo.xcprivacy |
| "ITMS-90717: Invalid App Store Icon" | Icon 1024×1024 tidak boleh punya alpha channel/transparan. Regenerate: `flutter pub run flutter_launcher_icons` |
| Archive gagal: "no such module" | Jalankan `flutter pub get` lalu `cd ios && pod install` |
| "iPad multitasking not supported" | Tambah `UIRequiresFullScreen = true` di Info.plist, ATAU pastikan semua orientasi iPad didukung (sudah ada) |
| Upload stuck "Authenticating with iTunes" | Restart Xcode, cek koneksi, atau gunakan Transporter app |
| Review ditolak: Guideline 5.1.1 (location) | Lihat `app-store-policy-audit.md` §3 — siapkan justifikasi penggunaan lokasi "Always" |
| Review ditolak: Guideline 2.1 (crash) | Test menyeluruh via TestFlight di device real sebelum submit |

---

## Checklist Akhir Sebelum Submit

- [ ] Akun Apple Developer aktif ($99/thn)
- [ ] Signing configured di Xcode (Team dipilih, status hijau)
- [ ] `flutter pub get` + `pod install` berhasil, `Podfile.lock` ter-commit
- [ ] Bundle ID = `id.sagansa.app`
- [ ] `PrivacyInfo.xcprivacy` ada & ter-bundle
- [ ] Archive berhasil tanpa warning kritis
- [ ] Upload ke App Store Connect sukses, build muncul
- [ ] App record dibuat, Bundle ID terpilih
- [ ] Listing lengkap (nama, deskripsi, keywords, screenshot 6.7")
- [ ] Privacy Policy URL aktif
- [ ] Age rating questionnaire diisi
- [ ] Smoke test via TestFlight di iPhone real
- [ ] App icon 1024×1024 tanpa alpha channel
- [ ] Version (`CFBundleShortVersionString`) dan build number (`CFBundleVersion`)
      naik dari submission sebelumnya

---

## Versioning

Versi diambil dari `pubspec.yaml` line `version: 1.0.0+2`:
- `CFBundleShortVersionString` = `1.0.0` (marketing version, terlihat user)
- `CFBundleVersion` = `2` (build number, harus naik tiap upload)

**Tiap upload baru ke App Store Connect, naikkan angka setelah `+`.** Misal
`1.0.0+2` → `1.0.0+3` untuk upload ulang versi yang sama, atau `1.0.1+3` untuk
minor update. Build number tidak boleh sama dengan upload sebelumnya.
