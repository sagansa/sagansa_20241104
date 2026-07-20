import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Dialog full-screen untuk menampilkan gambar (URL network) saat di-tap.
class ImagePreviewDialog {
  static Future<void> show(BuildContext context, String imageUrl,
      {String? title}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
            title: title != null
                ? Text(title, style: const TextStyle(color: Colors.white))
                : null,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, size: 64, color: Colors.white70),
                    SizedBox(height: 8),
                    Text('Gagal memuat gambar',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thumbnail gambar yang bisa di-tap untuk membuka preview full-screen.
class ImageThumbnail extends StatelessWidget {
  final String imageUrl;
  final double size;
  final String? label;
  final VoidCallback? onRemoved;

  const ImageThumbnail({
    super.key,
    required this.imageUrl,
    this.size = 48,
    this.label,
    this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final child = ClipRRect(
      borderRadius: AppSpacing.borderRadiusSM,
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          child: Icon(Icons.broken_image, size: size * 0.4, color: cs.onSurfaceVariant),
        ),
      ),
    );

    return Stack(
      children: [
        GestureDetector(
          onTap: () => ImagePreviewDialog.show(
            context,
            imageUrl,
            title: label,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
              borderRadius: AppSpacing.borderRadiusSM,
            ),
            child: child,
          ),
        ),
        if (onRemoved != null)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemoved,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
