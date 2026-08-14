import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class ModernBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final double? height;
  final EdgeInsets? padding;

  const ModernBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.height,
    this.padding,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget child,
    double? height,
    EdgeInsets? padding,
    bool isDismissible = true,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: ModernBottomSheet(
          title: title,
          height: height,
          padding: padding,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Tambahkan bottom system inset (nav bar / gesture bar) secara sentral.
    // Pakai viewPaddingOf (bukan SafeArea/useSafeArea) agar konsisten dengan
    // idiom terpercaya codebase (lihat invoice_detail_page.dart) — SafeArea
    // biasa bisa kalah dikonsumsi ancestor pada mode edge-to-edge Android 15
    // (targetSdk 35) sehingga konten/aksi di bawah bottom sheet tertutup nav
    // bar. Caller tetap menangani keyboard via viewInsets.bottom pada child.
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Material(
          color: colorScheme.surface.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Padding(
            padding: (padding ?? AppSpacing.paddingMD).copyWith(
              bottom: (padding?.bottom ?? AppSpacing.md) + safeBottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: AppSpacing.borderRadiusXS,
                    ),
                  ),
                ),
                if (title != null) ...[
                  Text(
                    title!,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.gapVerticalMD,
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}