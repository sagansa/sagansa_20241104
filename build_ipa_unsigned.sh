#!/usr/bin/env bash
#
# build_ipa_unsigned.sh — Build Flutter iOS app menjadi .ipa TANPA signing.
#
# Dipakai untuk distribusi via platform sideloading (FlekSt0re, dll) di mana
# platform yang melakukan re-signing, BUKAN kita.
#
# Output: build/Sagansa-v<version>.ipa
#
# === PERHATIAN ===
# IPA unsigned ini HANYA untuk:
#   - Internal testing / beta via sideload platform
#   - Upload ke FlekSt0re (FlekSt0re yang re-sign)
# IPA ini TIDAK bisa langsung di-install ke iPhone (butuh signing).
# Untuk App Store / TestFlight, gunakan `flutter build ipa` dengan signing
# proper (lihat docs/app-store-upload-guide.md).
#
# Usage:
#   ./build_ipa_unsigned.sh
#   ./build_ipa_unsigned.sh --clean   # flutter clean dulu
#
set -euo pipefail

cd "$(dirname "$0")"

# ── Config ──────────────────────────────────────────────────────────────────
APP_NAME="Sagansa"
# Baca versi dari pubspec.yaml (format: version: 1.0.0+2)
VERSION=$(grep '^version:' pubspec.yaml | head -1 | sed 's/version: //; s/+.*//')
BUILD_SUFFIX="unsigned"

echo "============================================"
echo "  Build IPA Unsigned — ${APP_NAME} v${VERSION}"
echo "============================================"
echo ""

# ── Preflight ───────────────────────────────────────────────────────────────
if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter SDK tidak ditemukan. Install: https://flutter.dev"
  exit 1
fi

if [ ! -f pubspec.yaml ]; then
  echo "❌ Bukan direktori project Flutter (pubspec.yaml tidak ada)."
  exit 1
fi

# ── Optional clean ──────────────────────────────────────────────────────────
if [ "${1:-}" = "--clean" ]; then
  echo "🧹 flutter clean..."
  flutter clean
  echo ""
fi

# ── Step 1: flutter pub get ─────────────────────────────────────────────────
echo "📦 flutter pub get..."
flutter pub get
echo ""

# ── Step 2: pod install (pastikan Pods up-to-date) ──────────────────────────
echo "📦 pod install..."
cd ios
if [ ! -f Podfile.lock ]; then
  echo "   Podfile.lock belum ada, menjalankan pod install fresh..."
fi
pod install
cd ..
echo ""

# ── Step 3: Build iOS tanpa signing ─────────────────────────────────────────
echo "🔨 flutter build ios --no-codesign..."
flutter build ios --no-codesign --release
echo ""

# ── Step 4: Verifikasi Runner.app ada ───────────────────────────────────────
APP_PATH="build/ios/iphoneos/Runner.app"
if [ ! -d "$APP_PATH" ]; then
  echo "❌ $APP_PATH tidak ditemukan setelah build. Build gagal?"
  exit 1
fi

# ── Step 5: Package jadi .ipa ───────────────────────────────────────────────
OUTPUT_DIR="build"
IPA_NAME="${APP_NAME}-v${VERSION}-${BUILD_SUFFIX}.ipa"
IPA_PATH="${OUTPUT_DIR}/${IPA_NAME}"

echo "📦 Packaging ke ${IPA_NAME}..."

# Buat working dir sementara
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "${TMP_DIR}/Payload"
cp -R "$APP_PATH" "${TMP_DIR}/Payload/"

# Zip jadi .ipa (struktur: Payload/Runner.app di root zip)
cd "$TMP_DIR"
zip -rq "${OLDPWD}/${IPA_PATH}" Payload/
cd "$OLDPWD"

# ── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "============================================"
echo "  ✅ Build selesai!"
echo "============================================"
echo ""
echo "File IPA: ${IPA_PATH}"
echo "Ukuran:   $(du -h "$IPA_PATH" | cut -f1)"
echo ""
echo "Langkah berikutnya (upload ke FlekSt0re):"
echo "  Lihat docs/flekstore-distribution.md"
