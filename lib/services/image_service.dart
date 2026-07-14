import 'dart:io';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';

class ImageService {
  // NOTE: Gambar disajikan via endpoint /media di api service (api.sagansa.id/media),
  // bukan img.sagansa.id/storage/, karena upload saat ini masih dilakukan dari apps/admin
  // yang menyimpan file ke storage yang di-serve oleh api service. Setelah migrasi
  // upload sepenuhnya ke img.sagansa.id, kembalikan base ini ke IMG_SERVICE_URL.
  static const String imgBaseUrl = String.fromEnvironment(
    'IMG_SERVICE_URL',
    defaultValue: ApiConstants.baseUrl,
  );

  /// Bangun URL publik dari path relatif atau URL absolut.
  static String? buildUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path; // Sudah URL absolut
    final clean = path.replaceAll(RegExp(r'^/+'), '');
    return '$imgBaseUrl/media/$clean';
  }

  static Future<File?> pickAndResizeImage({
    required ImageSource source,
    int maxWidth = 1024, // ukuran maksimal lebar
    int maxHeight = 1024, // ukuran maksimal tinggi
    int quality = 85, // kualitas kompresi (0-100)
  }) async {
    try {
      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile == null) return null;

      // Baca file sebagai bytes
      final File imageFile = File(pickedFile.path);
      final bytes = await imageFile.readAsBytes();

      // Decode image
      final img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) return null;

      // Resize image
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: maxWidth,
        height: maxHeight,
        interpolation: img.Interpolation.linear,
      );

      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;
      final String targetPath =
          '$tempPath/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Encode dan simpan image yang sudah diresize
      final File targetFile = File(targetPath);
      await targetFile.writeAsBytes(
        img.encodeJpg(resizedImage, quality: quality),
      );

      return targetFile;
    } catch (e) {
      debugPrint('Error resizing image: $e');
      return null;
    }
  }

  /// Tampilkan dialog pilihan Kamera / Galeri, lalu ambil dan resize gambar.
  static Future<File?> selectAndPickImage(BuildContext context) async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (dialogCtx) => Directionality(
        textDirection: TextDirection.ltr,
        child: SimpleDialog(
          title: const Text('Pilih Sumber Foto'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogCtx, ImageSource.camera),
              child: const Row(
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 10),
                  Text('Kamera'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogCtx, ImageSource.gallery),
              child: const Row(
                children: [
                  Icon(Icons.photo_library),
                  SizedBox(width: 10),
                  Text('Galeri'),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      return pickAndResizeImage(source: source);
    }
    return null;
  }
}
