import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'glass_container.dart';

/// Card dengan efek glassmorphism, drop-in replacement untuk [Card].
///
/// Menggunakan [GlassContainer.card] di belakang layar. `CardThemeData`
/// tidak bisa memakai `BackdropFilter` (theme hanya menerima warna solid),
/// jadi widget ini menyediakan API mirip [Card] dengan efek kaca.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final double opacity;
  final double borderOpacity;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.blurSigma = 16,
    this.opacity = 0.72,
    this.borderOpacity = 0.3,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: margin ?? AppSpacing.paddingMD,
      padding: padding,
      blurSigma: blurSigma,
      opacity: opacity,
      borderOpacity: borderOpacity,
      backgroundColor: backgroundColor,
      borderRadius: const BorderRadius.all(
        Radius.circular(AppSpacing.radiusMD),
      ),
      child: child,
    );
  }
}
