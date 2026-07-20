import 'dart:io';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  static const int _quality = 75;

  /// Kompres gambar di perangkat untuk meminimalkan data yang dikirim ke server.
  ///
  /// Android  -> WebP lossy (~30% lebih kecil dari JPEG pada kualitas setara).
  /// iOS      -> JPEG (flutter_image_compress tidak mendukung encoder WebP di iOS).
  /// Web      -> mengembalikan file asli (kIsWeb).
  ///
  /// Jika encoder native tidak tersedia (mis. Android API <28 tanpa hardware
  /// WebP encoder), [FlutterImageCompress] mengembalikan null dan method ini
  /// fallback ke file asli sehingga alur tidak putus.
  static Future<File> compressImage(String sourcePath, {int? quality}) async {
    if (kIsWeb) {
      return File(sourcePath);
    }

    final useWebP = defaultTargetPlatform == TargetPlatform.android;

    final dir = await getTemporaryDirectory();
    final ext = useWebP ? 'webp' : 'jpg';
    final name = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final targetPath = p.join(dir.path, name);

    final xfile = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      quality: quality ?? _quality,
      format: useWebP ? CompressFormat.webp : CompressFormat.jpeg,
      keepExif: false,
    );

    if (xfile == null) {
      return File(sourcePath);
    }

    return File(xfile.path);
  }
}
