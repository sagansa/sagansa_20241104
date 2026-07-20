import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Thumbnail 56×56 yang reusable untuk kartu list.
///
/// Menampilkan [Image.network] bila [imageUrl] valid (non-null & non-empty),
/// lengkap dengan loading spinner dan error fallback ke placeholder ikon.
/// Bila [imageUrl] null/empty, langsung tampilkan placeholder ikon.
///
/// Bila [onTap] disediakan, thumbnail dibungkus GestureDetector dengan
/// HitTestBehavior.opaque agar klik di area thumbnail tidak memicu
/// InkWell/GestureDetector kartu induk.
class ListThumbnail extends StatelessWidget {
  final String? imageUrl;
  final IconData placeholderIcon;
  final double size;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const ListThumbnail({
    super.key,
    this.imageUrl,
    this.placeholderIcon = Icons.receipt_long,
    this.size = 56,
    this.onTap,
    this.borderRadius,
  });

  bool get _hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? AppSpacing.borderRadiusSM;

    final content = _hasImage
        ? ClipRRect(
            borderRadius: radius,
            child: Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(colorScheme, radius),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return _loadingBox(colorScheme, radius);
              },
            ),
          )
        : _placeholder(colorScheme, radius);

    if (onTap == null) return content;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }

  Widget _placeholder(ColorScheme colorScheme, BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: radius,
      ),
      child: Icon(
        placeholderIcon,
        size: size * 0.5,
        color: AppColors.info,
      ),
    );
  }

  Widget _loadingBox(ColorScheme colorScheme, BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: radius,
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.286,
          height: size * 0.286,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
