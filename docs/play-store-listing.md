# Sagansa — Play Store Listing Template

Template siap-pakai untuk mengisi Store Listing di Google Play Console.
Sesuaikan bagian dalam `[...]` sesuai kebutuhan.

---

## App Name
```
Sagansa
```
(Maks 30 karakter)

---

## Short Description (≤80 karakter)

Pilih salah satu, atau edit:

```
Manajemen operasional & POS untuk UMKM Indonesia
```
(49 karakter)

Alternatif:
```
Kasir, stok, absensi & operasional bisnis dalam satu app
```
(56 karakter)

---

## Full Description (≤4000 karakter)

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

KENAPA SAGANSA?

✅ Terdesain untuk Indonesia — Bahasa Indonesia, mendukung printer thermal
   umum di pasaran lokal, terintegrasi dengan kebutuhan operasional UMKM
✅ Satu app, banyak fungsi — tidak perlu install app terpisah untuk kasir,
   stok, absensi, dan keuangan
✅ Mudah digunakan — antarmuka sederhana untuk operator hingga pemilik
✅ Multi-cabang — kelola beberapa toko/lokasi dalam satu akun

Sagansa cocok untuk:
- Toko ritel & minimarket
- Rumah makan, kafe, F&B
- Jasa (salon, bengkel, klinik)
- Distributor & agen
- Bisnis multi-cabang

Mulai kelola bisnis Anda lebih efisien hari ini.

Butuh bantuan? Hubungi support@sagansa.id atau kunjungi sagansa.id
```

---

## Feature Graphic & Ikon — Checklist Aset

| Aset | Spesifikasi | File | Status |
|---|---|---|---|
| App icon (Play Store) | 512×512 PNG, 32-bit alpha | `icon-512.png` | [ ] generate |
| Feature graphic | 1024×500 PNG/JPG, no alpha | `feature-graphic.png` | [ ] generate |
| Phone screenshot | 320–3840px (min 2, ideal 4–8) | `screenshot-phone-*.png` | [ ] capture |
| Tablet 7" screenshot | 1024×500 minimum | `screenshot-tablet7-*.png` | [ ] opsional |
| Tablet 10" screenshot | 1200×1920 minimum | `screenshot-tablet10-*.png` | [ ] opsional |

### Rekomendasi screenshot (urutan tampil di Play Store):
1. **Dashboard utama** — tunjukkan overview bisnis
2. **POS/Kasir** — tunjukkan transaksi
3. **Stok gudang** — tunjukkan manajemen inventory
4. **Absensi** — tunjukkan check-in karyawan
5. **Laporan keuangan** — tunjukkan insight bisnis
6. **Multi-cabang** — tunjukkan skalabilitas

> Screenshot tidak bisa digenerate — harus di-capture dari app yang berjalan di
> device/emulator. Pakai emulator (lihat tool android-emulator) atau device real.

---

## Release Notes Template

### Versi 1.0.0 (rilis awal)
```
Selamat datang di Sagansa 1.0.0! 🎉

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

## Privacy Policy Template

Sediakan sebagai halaman web publik (URL wajib di Play Console). Template
minimum yang memenuhi syarat Play Policy:

```markdown
# Kebijakan Privasi Sagansa

Terakhir diperbarui: [TANGGAL]

Sagansa ("kami") menghormati privasi pengguna ("Anda"). Kebijakan ini
menjelaskan data yang kami kumpulkan dan bagaimana kami menggunakannya.

## Data yang Kami Kumpulkan

1. **Informasi Akun**
   - Nama, alamat email, nomor telepon
   - Nama & detail bisnis (toko, cabang)

2. **Lokasi**
   - Lokasi GPS saat Anda melakukan check-in/check-out absensi
   - Dikumpul HANYA saat app terbuka dan Anda melakukan absensi
   - Tidak dilacak di latar belakang

3. **Foto**
   - Foto struk/bukti pembayaran, bukti pengiriman, dokumentasi aset
   - Hanya diambil ketika Anda memilih untuk mengunggah

4. **Data Transaksi Bisnis**
   - Penjualan, pembelian, mutasi stok, data karyawan
   - Tersimpan di server Sagansa untuk fungsionalitas app

5. **Data Teknis**
   - ID perangkat, versi app, log error (untuk peningkatan kualitas)

## Bagaimana Kami Menggunakan Data

- Menyediakan & memelihara fitur app (kasir, stok, absensi, keuangan)
- Mengamankan akun & mendeteksi penyalahgunaan
- Meningkatkan performa & fitur app
- Customer support

## Pembagian Data

Kami TIDAK menjual data Anda. Data hanya dibagikan:
- Kepada penyedia infrastruktur (server hosting) yang terikat kontrak
- Jika diwajibkan hukum

## Keamanan

Data dienkripsi saat transmisi (HTTPS). Akses internal dibatasi sesuai prinsip
least-privilege.

## Hak Anda

- **Akses:** minta salinan data Anda
- **Koreksi:** perbaiki data yang tidak akurat
- **Hapus:** minta penghapusan akun & data terkait
- **Portabilitas:** minta ekspor data

Hubungi admin Sagansa via app atau support@sagansa.id untuk menggunakan hak ini.

## Anak-anak

App tidak ditujukan untuk anak-anak di bawah 18. Kami tidak sengaja mengumpulkan
data anak-anak.

## Perubahan Kebijakan

Kami akan memberi tahu perubahan signifikan via app atau email.

## Kontak

Email: support@sagansa.id
Website: sagansa.id
```

---

## Aset yang Perlu Disiapkan Developer/Designer

- [ ] App icon 512×512 (generate dari `assets/images/logo.png`)
- [ ] Feature graphic 1024×500 (background brand color + logo)
- [ ] 4–8 screenshot phone (capture dari emulator/device)
- [ ] Privacy Policy di-hosting (GitHub Pages / hosting Sagansa)
- [ ] Email support (`support@sagansa.id` atau similar)
- [ ] Domain sagansa.id aktif (untuk credibility & privacy policy)
