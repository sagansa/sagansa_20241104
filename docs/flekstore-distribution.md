# Distribusi Sagansa via FlekSt0re (Internal / Beta)

Panduan build & upload `.ipa` ke FlekSt0re untuk distribusi **internal/beta**
tanpa App Store dan tanpa jailbreak.

> FlekSt0re adalah platform sideloading iOS yang me-re-sign app Anda dengan
> sertifikat/MDM milik mereka, sehingga user bisa install tanpa PC dan tanpa
> Apple Developer account sendiri.

> ⚠️ **Hanya untuk internal/beta.** Untuk distribusi publik luas, gunakan Apple
> App Store (`docs/app-store-upload-guide.md`). Lihat bagian "Tradeoff" di bawah.

---

## Kapan pakai FlekSt0re?

✅ **Cocok:**
- Beta testing untuk tim internal Sagansa
- Distribusi awal sambil nunggu App Store approve
- Demo ke klien tanpa perlu invite TestFlight satu-satu
- User yang tidak punya Apple Developer account

❌ **Tidak cocok untuk:**
- Distribusi publik massal (App Store lebih reliable)
- Produksi jangka panjang (cert revocation = app berhenti)
- User non-teknis awam (install via profile = membingungkan)

---

## Prasyarat

- [ ] Mac dengan Flutter SDK + Xcode (untuk build)
- [ ] Script `build_ipa_unsigned.sh` sudah ada di root project
- [ ] Akun FlekSt0re (daftar di platform FlekSt0re)
- [ ] App icon 1024×1024 untuk listing FlekSt0re
- [ ] (Opsional) Screenshot app untuk listing

---

## Langkah 1 — Build .ipa Unsigned

Jalankan script build di Mac:

```bash
cd mobiles/sagansa

# Build pertama kali (recommended: --clean)
./build_ipa_unsigned.sh --clean
```

Atau tanpa clean (build inkremental, lebih cepat):

```bash
./build_ipa_unsigned.sh
```

**Output:**
```
build/Sagansa-v1.0.0-unsigned.ipa
```

Script ini otomatis:
1. `flutter pub get`
2. `pod install` (regenerasi Podfile.lock jika perlu)
3. `flutter build ios --no-codesign --release`
4. Package `Runner.app` → `.ipa` (struktur `Payload/Runner.app`)

> Verifikasi: file `.ipa` adalah zip biasa. Bisa dicek dengan
> `unzip -l build/Sagansa-v1.0.0-unsigned.ipa` — harus ada `Payload/Runner.app/`.

---

## Langkah 2 — Upload ke FlekSt0re

> ⚠️ Langkah spesifik bisa berubah mengikuti UI FlekSt0re. Ini panduan umum
> berdasarkan alur platform sideloading standar.

1. Login ke dashboard/platform FlekSt0re Anda.

2. **Upload app / Add new app:**
   - Pilih file `.ipa`: `build/Sagansa-v1.0.0-unsigned.ipa`
   - Tunggu proses upload + parse selesai.

3. **Isi metadata listing:**
   - **App name:** Sagansa
   - **Bundle ID:** `id.sagansa.app` (otomatis terbaca dari .ipa)
   - **Version:** 1.0.0 (otomatis terbaca)
   - **App icon:** upload 1024×1024 (atau FlekSt0re auto-extract dari .ipa)
   - **Description:** lihat `app-store-listing.md` (bisa dipakai ulang)
   - **Category:** Business
   - **Screenshot:** opsional (lihat `app-store-listing.md`)

4. **Submit untuk signing:**
   - FlekSt0re akan me-re-sign `.ipa` dengan sertifikat mereka.
   - Tunggu proses signing selesai (biasanya 1–10 menit).

5. **Setelah approved/signed:**
   - App tersedia untuk install via link FlekSt0re atau profile.
   - Bagikan link install ke beta tester Anda.

---

## Langkah 3 — Install di iPhone (user side)

User (beta tester) melakukan:

1. Buka link install FlekSt0re di Safari iPhone.
2. **Install profile FlekSt0re** (Settings → Profile Downloaded → Install).
   - Trust profile: Settings → General → VPN & Device Management → trust.
3. Install app Sagansa via FlekSt0re.
4. **First launch:** Settings → General → VPN & Device Management → trust
   developer certificate Sagansa.

> iOS menampilkan warning "Unverified App" / "Not from App Store" — ini normal
> untuk sideloaded app. User harus explicit trust.

---

## Update App di FlekSt0re

Saat ada versi baru:

1. Naikkan versi di `pubspec.yaml`:
   ```yaml
   version: 1.0.1+3   # naikkan angka setelah + tiap build baru
   ```

2. Build ulang:
   ```bash
   ./build_ipa_unsigned.sh --clean
   ```

3. Upload `.ipa` baru ke FlekSt0re → replace version lama.

4. User akan dapat notifikasi/ketahuan ada update saat buka app.

---

## Tradeoff: FlekSt0re vs App Store

| Aspek | FlekSt0re (sideload) | Apple App Store |
|---|---|---|
| **Apple review** | ❌ Tidak | ✅ Ya (1–3 hari) |
| **Biaya** | Gratis / murah | $99/tahun |
| **Certificate revocation** | ⚠️ **Sering** — Apple bisa cabut cert FlekSt0re, app berhenti jalan sampai re-sign | ✅ Tidak pernah |
| **User experience install** | Ribet (install profile, trust cert) | 1 klik |
| **Update** | Manual re-upload | Otomatis ke semua user |
| **Kepercayaan user** | Rendah (warning "unverified") | Tinggi (verified ✓) |
| **Limit jumlah device** | Tergantung paket FlekSt0re | Tidak terbatas |
| **Background execution** | Sama seperti App Store | Sama |
| **Firebase/Push** | Sama (perlu config terpisah) | Sama |

---

## Troubleshooting

| Masalah | Solusi |
|---|---|
| `pod install` gagal | Hapus `ios/Podfile.lock` + `ios/Pods/`, jalankan ulang script |
| Build gagal "no such module" | `flutter clean` lalu `./build_ipa_unsigned.sh --clean` |
| `.ipa` terlalu besar (>100MB) | Flutter debug symbols ikut. Normal untuk release build. Bisa dikurangi dengan `--split-debug-info` |
| FlekSt0re reject "bundle id already used" | Bundle ID `id.sagansa.app` sudah dipakai orang lain di FlekSt0re. Ganti di project atau hubungi admin FlekSt0re |
| App crash saat launch di iPhone | Re-signing FlekSt0re gagal atau entitlements tidak cocok. Test `.ipa` via Xcode manual install dulu untuk isolasi |
| "App cannot be verified" terus-menerus | Cert FlekSt0re di-revoke Apple. Tunggu FlekSt0re re-sign, atau pindah ke TestFlight |
| Push notification tidak jalan | Sideloaded app sering tidak dapat APNs entitlement. Defer Firebase push untuk sideload (sudah di-defer di v1) |

---

## Checklist

- [ ] `build_ipa_unsigned.sh` executable (`chmod +x build_ipa_unsigned.sh`)
- [ ] Build `.ipa` berhasil, file ada di `build/`
- [ ] `.ipa` terverifikasi (`unzip -l` menunjukkan `Payload/Runner.app`)
- [ ] Upload ke FlekSt0re sukses, app ter-signed
- [ ] Test install di iPhone real (bukan simulator)
- [ ] Smoke test fitur utama (login, presensi, POS, dll)
- [ ] Bagikan link install ke beta tester
