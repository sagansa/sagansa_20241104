import 'dart:io';

import 'package:flutter/material.dart';
import '../photo_uploader.dart';

class PhotoUploaderSection extends StatelessWidget {
  final List<File> photos;
  final ValueChanged<List<File>> onChanged;
  final int maxPhotos;
  final String label;

  const PhotoUploaderSection({
    super.key,
    required this.photos,
    required this.onChanged,
    this.maxPhotos = 999,
    this.label = 'Unggah Foto',
  });

  @override
  Widget build(BuildContext context) {
    return PhotoUploader(
      photos: photos,
      onChanged: onChanged,
      layout: PhotoUploaderLayout.grid,
      maxPhotos: maxPhotos,
      label: label,
    );
  }
}
