# Sagansa — App Store Listing Template

Template siap-pakai untuk mengisi App Store listing di App Store Connect.
Sesuaikan bagian dalam `[...]` sesuai kebutuhan. Konten deskripsi bisa dipakai
ulang dari `play-store-listing.md`.

> Paralel dengan `play-store-listing.md` (Android). App Store Connect punya field
> yang sedikit berbeda (subtitle, keywords terpisah, promotional text).

---

## App Name (≤30 karakter)
```
Sagansa
```

---

## Subtitle (≤30 karakter) — iOS only

Ringkasan satu baris di bawah app name.

```
Operasional & kasir untuk UMKM
```
(30 karakter)

Alternatif:
```
Kasir, stok, absensi bisnis dalam satu app
```
(42 karakter — potong jadi 30 jika dipakai)

---

## Description (≤4000 karakter)

Bisa dipakai ulang dari `play-store-listing.md` bagian Full Description.
Ringkasan:

```
Sagansa — Satu App untuk Seluruh Operasional Bisnis Anda

Sagansa adalah platform manajemen operasional terpadu untuk UMKM dan bisnis
modern di Indonesia. Kelola penjualan, stok, absensi karyawan, hingga
keuangan dalam satu aplikasi yang dirancang khusus untuk ritel, F&B, dan
jasa.

FITUR UTAMA

🛒 Point of Sale (Kasir)
- Transaksi penjualan cepat dengan dukungan struk digital & cetak
- Manajemen produk, harga, dan kategori
- Multi-channel pricing: harga berbeda per cabang/channel

📦 Manajemen Stok
- Pantau stok gudang real-time
- Notifikasi stok menipis
- Audit stok berkala & laporan mutasi
- Pengiriman barang antar cabang

👤 Absensi & Manajemen Karyawan
- Check-in/check-out dengan verifikasi lokasi
- Jadwal shift karyawan
- Laporan kehadiran otomatis

💰 Keuangan
- Pencatatan pemasukan & pengeluarangan
- Rekonsiliasi kas per shift
- Laporan laba rugi bisnis

🏠 Lainnya
- Manajemen aset & jadwal pemeliharaan
- Pengingat pemeriksaan aset
- Pengelolaan pengiriman (delivery)
- Dashboard monitoring untuk pemilik/pengelola

Sagansa cocok untuk toko ritel, rumah makan/kafe, jasa, distributor, dan
bisnis multi-cabang.

Butuh bantuan? Hubungi support@sagansa.id atau kunjungi sagansa.id
```

---

## Keywords (≤100 karakter, comma-separated)

Keyword dipakai App Store search algorithm. **Tidak boleh mengulang kata dari
app name** (sudah ter-index).

```
kasir,point of sale,pos,manajemen stok,absensi,karyawan,invoice,laporan,umkm,bisnis,kas kecil
```
(99 karakter)

---

## Promotional Text (≤170 karakter)

Teks promosi yang **bisa diubah tanpa re-review**. Gunakan untuk info diskon,
fitur baru, atau event musiman.

```
Kelola toko Anda jadi lebih mudah dengan Sagansa — kasir, stok, absensi, dan
keuangan dalam satu app. Daftar gratis di sagansa.id
```
(143 karakter)

---

## What's New / Release Notes

### Versi 1.0.0 (rilis awal)
```
Selamat datang di Sagansa!

Rilis perdana platform manajemen operasional bisnis Sagansa. Fitur yang
tersedia di versi ini:

• Point of Sale (Kasir) dengan dukungan struk
• Manajemen stok gudang & mutasi
• Absensi karyawan dengan check-in lokasi
• Laporan keuangan & rekonsiliasi kas
• Manajemen aset & pengingat pemeliharaan
• Dukungan printer thermal untuk struk

Daftar akun di sagansa.id untuk mulai menggunakan app.
```

---

## Screenshot — Spesifikasi & Requirement

App Store Connect mewajibkan screenshot untuk ukuran device tertentu. Mulai
2024, **screenshot 6.7" wajib** untuk app iPhone.

| Device Class | Dimensi (potret) | Status | Jumlah |
|---|---|---|---|
| **iPhone 6.7"** (15 Pro Max / 14 Plus) | 1290×2796 | **Wajib** | min 1, ideal 3–5 |
| iPhone 6.5" (11 Pro Max / XS Max) | 1242×2688 | Opsional (auto-generate dari 6.7") | — |
| iPhone 5.5" (8 Plus) | 1242×2208 | Opsional | min 1 jika diisi |
| **iPad 12.9"** (6th gen) | 2048×2732 | Wajib jika support iPad | min 1 |
| iPad 11" | 1668×2388 | Opsional | — |

> App Sagansa `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone + iPad), jadi **screenshot
> iPad wajib** disiapkan.

### Cara capture screenshot resmi

1. **Via iOS Simulator** (paling akurat):
   ```bash
   # Buka simulator iPhone 15 Pro Max
   xcrun simctl boot "iPhone 15 Pro Max"
   open -a Simulator

   # Setelah app jalan, capture:
   xcrun simctl io booted screenshot screenshot-iphone-1.png
   ```
   Atau: Simulator menu → File → Screenshot (Cmd+S).

2. **Via device real** + Xcode:
   - Window → Devices and Simulators → pilih device → Take Screenshot.

3. **Aturan konten:**
   - Tidak boleh mockup frame device (App Store auto-render device frame)
   - Status bar boleh ada (auto-replaced dengan clean status bar)
   - Tidak boleh ada konten placeholder/debug

### Rekomendasi screenshot (urutan tampil di App Store):
1. **Dashboard utama** — overview bisnis
2. **POS/Kasir** — transaksi penjualan
3. **Manajemen stok** — daftar produk/inventory
4. **Absensi karyawan** — check-in dengan lokasi
5. **Laporan keuangan** — insight & grafik bisnis

> Screenshot harus di-capture dari app yang berjalan. Tidak bisa digenerate.
> Pakai iOS Simulator (tool ios-simulator) atau device real.

---

## App Preview Video (opsional, tapi meningkatkan konversi)

| Spesifikasi | Nilai |
|---|---|
| Durasi | 15–30 detik |
| Resolusi | 886×1920 atau 1080×1920 (potret) |
| Format | H.264, MOV/MP4/M4V |
| Ukuran maks | 500 MB |
| Audio | opsional (boleh musik/narasi, tidak wajib) |

### Rekomendasi storyboard video:
1. Detik 0–3: Splash + tagline "Satu app untuk bisnis Anda"
2. Detik 4–10: Demo transaksi POS cepat
3. Detik 11–17: Cek stok real-time + notifikasi
4. Detik 18–24: Absensi karyawan dengan lokasi
5. Detik 25–30: Laporan keuangan + logo Sagansa + CTA

---

## App Icon — Status

| Aset | Status |
|---|---|
| 1024×1024 PNG (App Store Connect upload) | ✅ Ada di `AppIcon.appiconset/Icon-App-1024x1024@1x.png` |
| Icon untuk device (semua ukuran) | ✅ Ter-generate via `flutter_launcher_icons` |
| Alpha channel / transparan | ⚠️ Verifikasi: icon 1024×1024 **tidak boleh transparan**. Jika error ITMS-90717, flatten: buka di image editor, isi background solid, re-export PNG tanpa alpha |

---

## Privacy Policy URL (wajib)

Sama dengan Play Store — bisa dipakai ulang. Lihat `play-store-listing.md`
bagian Privacy Policy Template.

URL wajib accessible publik. Contoh:
- `https://sagansa.id/privacy-policy`
- `https://sagansa.github.io/privacy-policy/`

---

## Support URL (wajib)

App Store Connect mewajibkan URL support yang accessible:
- `https://sagansa.id/support` (atau halaman kontak)
- Atau minimal: `https://sagansa.id`

---

## Aset yang Perlu Disiapkan

- [ ] Screenshot iPhone 6.7" (3–5 buah) — wajib
- [ ] Screenshot iPad 12.9" (3–5 buah) — wajib (karena support iPad)
- [ ] App preview video 15–30 detik (opsional, tapi direkomendasikan)
- [ ] Verifikasi icon 1024×1024 tanpa alpha channel
- [ ] Privacy Policy URL aktif
- [ ] Support URL aktif
- [ ] Marketing URL (opsional: `https://sagansa.id`)
- [ ] Copyright string: `© 2024 PT Sagansa` (atau nama legal entity)
