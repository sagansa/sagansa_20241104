# Panduan Upload Sagansa ke Google Play Console

Panduan langkah-demi-langkah dari akun developer hingga app live di Play Store.

---

## Prasyarat

- [ ] Akun Google (pribadi/bisnis) untuk daftar Play Console
- [ ] Kartu kredit untuk biaya pendaftaran **$25 (sekali bayar)**
- [ ] KTP/SIM/Paspor untuk verifikasi identitas (wajib sejak 2023)
- [ ] App bundle (`.aab`) hasil build release — lihat bagian Build di bawah
- [ ] Aset listing: ikon 512×512, feature graphic 1024×500, screenshot (lihat
      `play-store-listing.md`)
- [ ] URL Privacy Policy (wajib) — lihat bagian Privacy Policy di bawah

---

## Langkah 1 — Daftar Google Play Developer Account

1. Buka https://play.google.com/console/signup
2. Login dengan Google account yang akan jadi pemilik app **selamanya** (tidak
   bisa dipindah-pindah kepemilikan dengan mudah).
3. Bayar **$25** via Google Pay/kartu kredit.
4. Verifikasi identitas:
   - Upload foto KTP/SIM
   - Selfie verifikasi wajah
   - Tunggu verifikasi **1–3 hari kerja** (kadang instan)
5. Isi detail developer: **nama developer** (terlihat user di Play Store),
   email kontak, no. telepon, website.

> ⚠️ **Pilih nama developer dengan hati-hati** — "Sagansa" atau "PT Sagansa"
> misalnya. Ubah nama butuh review ulang.

---

## Langkah 2 — Buat Aplikasi Baru di Play Console

1. Login ke https://play.google.com/console
2. Klik **"Create app"** (tombol kanan atas)
3. Isi:
   - **App name:** `Sagansa`
   - **Default language:** Indonesian (`id`)
   - **App type:** Aplikasi (bukan game)
   - **Pricing:** Free
4. Deklarasi: centang semua "Declarations" (US export laws, dst.)
5. **Create app.**

---

## Langkah 3 — Play App Signing (otomatis saat first upload)

Google Play App Signing adalah mekanisme di mana **Google menyimpan app signing
key** di server mereka, dan Anda hanya mengelola **upload key**.

1. Saat Anda upload `.aab` pertama kali (Langkah 8), Play akan otomatis menawarkan
   "Opt in to Play App Signing". **Pilih ikut serta** (rekomendasi).
2. Google akan generate **app signing key** baru untuk distribusi.
3. **Upload key** Anda = `my-release-key.jks` yang dipakai untuk sign `.aab`.
4. (Opsional) Daftarkan upload key Anda via "Upload key rotation" jika ingin
   pakai fingerprint yang sudah dikenal.

> Kenapa pakai Play App Signing? Jika upload key bocor, Anda bisa reset tanpa
> distribusi app terpengaruh. Tanpa App Signing, signing key compromised =
> app tidak bisa di-update selamanya.

### Jika upload key Anda berbeda dari harapan Play

Play mungkin minta Anda reset upload key (mis. karena key lama sudah di git
history). Mekanismenya:
1. Play Console → **Setup → App integrity → Request upload key reset**
2. Generate key baru lokal, kirim `.pem` fingerprint ke Play
3. Tunggu konfirmasi (1–2 hari)

---

## Langkah 4 — Isi Store Listing (Main store listing)

Menu: **Grow → Store presence → Main store listing**

1. **App details:**
   - App name: `Sagansa`
   - Short description (≤80 char): lihat `play-store-listing.md`
   - Full description (≤4000 char): lihat `play-store-listing.md`
2. **App icon:** upload `icon-512.png` (512×512, PNG, 32-bit)
3. **Feature graphic:** upload `feature-graphic.png` (1024×500, PNG/JPG)
4. **Phone screenshots:** minimal 2, ideal 4–8 (lihat checklist listing)
5. **Tablet screenshots (7"/10"):** opsional tapi disarankan
6. **App category:** Business
7. **Tags:** `Business`, `Productivity`, `Finance` (pilih 1–5)
8. **Privacy Policy URL:** wajib (lihat bagian Privacy Policy di bawah)

---

## Langkah 5 — Data Safety Form (wajib)

Menu: **App content → Data safety**

1. Klik **"Start" / "Next"**
2. **"Does your app collect or share data?"** → **Yes**
3. Pilih tipe data yang dikumpul (lihat mapping di `play-policy-audit.md`):
   - Location → Approximate / Precise
   - Photos and videos
   - Personal info (email, name)
   - Financial info (purchase history)
4. Untuk tiap tipe, isi: purpose, whether shared, whether required
5. **"Is all data encrypted in transit?"** → **Yes**
6. **"Can users request data deletion?"** → **Yes** (pastikan ada mekanisme —
   via admin Sagansa atau email support)
7. **"Has your app been verified under Google Play's Families policy?"** → **No**
8. Submit. Status berubah "In review" → "Approved" otomatis.

---

## Langkah 6 — Content Rating (IARC)

Menu: **App content → Content rating**

1. Klik **"Start questionnaire"**
2. Isi jawaban (lihat `play-policy-audit.md` bagian 4):
   - Kekerasan: Tidak
   - Seksual: Tidak
   - Bahasa kasar: Tidak
   - Konten dewasa: Tidak
   - Perjudian: Tidak (POS = transaksi bisnis, bukan gambling)
   - Target anak-anak: Tidak
3. Submit. Rating: **Everyone** (diharapkan).

---

## Langkah 7 — Target Audience & Other Settings

Menu: **App content** (beberapa sub-menu):

1. **Target audience:** 18+ → reason: "Fungsionalitas bisnis untuk pelaku UMKM"
2. **News app:** No
3. **COVID-19 contact tracing:** No
4. **Ads:** **No** (tidak ada SDK iklan — konsisten dengan hapus `AD_ID`)
5. **Government apps:** No
6. **Financial features:** **Yes** (app memungkinkan transaksi POS) — isi
   penjelasan singkat: "Sagansa menyediakan POS untuk UMKM; pembayaran
   diproses oleh gateway eksternal, app tidak menyimpan instrumen pembayaran."
7. **Data security / Privacy Policy:** sudah di Langkah 5

---

## Langkah 8 — Build & Upload App Bundle (AAB)

### Build lokal

```bash
cd mobiles/sagansa

# Pastikan key.properties ada (lihat android/key.properties.example)
cat android/key.properties   # verify exists & filled

# Clean + build AAB release
flutter clean
flutter pub get
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Verifikasi signing AAB

```bash
# Cek AAB ter-sign dengan key Anda (bukan debug)
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
# Harus: "jar verified."

# Lihat fingerprint signing key
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

### Upload ke Play Console

Menu: **Release → Production** (atau mulai dari testing track dulu)

1. Klik **"Create new release"**
2. App Bundle: drag-drop `app-release.aab`
   - Play akan verifikasi signing → tawarkan Play App Signing (Langkah 3)
3. **Release name:** `1.0.0` (atau versi dari pubspec)
4. **Release notes:** lihat template di `play-store-listing.md`
5. **Save → Review release → Start rollout**

### Rekomendasi: mulai dari Internal Testing dulu

Jangan langsung production. Gunakan bertahap:
1. **Internal testing** — tim Sagansa saja, instant review
2. **Closed testing** — beta tester pilihan (20–100 orang)
3. **Open testing** — publik tapi label beta
4. **Production** — rilis penuh

---

## Langkah 9 — Privacy Policy (wajib)

Play Console mewajibkan URL Privacy Policy yang accessible publik.

### Option A: GitHub Pages (gratis, rekomendasi)
1. Buat repo `sagansa-legal` (atau pakai repo existing dengan folder `docs/`)
2. Buat file `privacy-policy.md`, konversi ke HTML atau pakai template Jekyll
3. Enable GitHub Pages: Settings → Pages → Source: `main` / `docs`
4. URL: `https://sagansa.github.io/privacy-policy/` (atau custom domain)

### Option B: Hosting sendiri
Upload HTML ke server web Sagansa: `https://sagansa.id/privacy-policy`

### Konten minimum Privacy Policy (lihat template di `play-store-listing.md`)
- Data yang dikumpul (lokasi, foto, akun, transaksi)
- Tujuan pengumpulan
- Pihak yang mengakses (hanya Sagansa)
- Hak user (akses, hapus, koreksi)
- Kontak DPO/support
- Tanggal efektif

---

## Langkah 10 — Rollout ke Production

Setelah semua checklist di Dashboard Play Console hijau:

1. **Test di Internal Testing** minimal — pastikan app jalan di device real
2. Promote release dari Internal → Closed → Open → Production
3. **Production rollout:** pilih percentage (mulai 10%, naik bertahap ke 100%)
4. Tunggu review production **1–3 hari** (karena tidak ada background location,
   review cepat)
5. App live di Play Store 🎉

---

## Troubleshooting Umum

| Masalah | Solusi |
|---|---|
| "You uploaded an APK or app bundle that was signed in debug mode" | `key.properties` tidak ada / salah. Lihat `android/key.properties.example` |
| "versionCode already used" | Naikkan `version: x.y.z+N` di `pubspec.yaml` (angka setelah `+`) |
| "Upload key fingerprint mismatch" | Pakai Play App Signing reset, atau rebuild dengan key yang benar |
| Review ditolak: "Prominent disclosure" | Tidak relevan untuk rilis awal (no background location). Untuk rilis modul karyawan, lihat `play-policy-audit.md` bagian 7 |
| Data Safety Form "In review" lama | Pastikan semua field terisi konsisten dengan permission manifest |

---

## Checklist Akhir Sebelum Upload Production

- [ ] Akun Play Console terverifikasi
- [ ] Store listing lengkap (deskripsi, ikon, feature graphic, screenshot)
- [ ] Privacy Policy URL aktif
- [ ] Data Safety Form submitted & approved
- [ ] Content rating assigned
- [ ] Target audience diisi
- [ ] AAB ter-build dengan release signing
- [ ] Smoke test di device/emulator real (bukan hanya debug)
- [ ] versionCode naik dari build sebelumnya
- [ ] App sudah diuji di Internal Testing track
