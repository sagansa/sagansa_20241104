import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageUtils {
  static const int _quality = 75;

  static Future<File> compressToWebP(String sourcePath, {int? quality}) async {
    final dir = await getTemporaryDirectory();
    final name = '${DateTime.now().millisecondsSinceEpoch}.webp';
    final targetPath = p.join(dir.path, name);

    final xfile = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      quality: quality ?? _quality,
      format: CompressFormat.webp,
      keepExif: false,
    );

    if (xfile == null) {
      return File(sourcePath);
    }

    return File(xfile.path);
  }
}
