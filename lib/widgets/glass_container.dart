import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'safe_bottom_bar.dart';

/// Reusable glassmorphism container.
///
/// Encapsulates `BackdropFilter` + semi-transparent surface + subtle border
/// following the pattern established in `ModernBottomNav`.
///
/// Use [blurSigma] to control blur intensity, [opacity] for background
/// translucency, and [borderRadius] for corner rounding.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double opacity;
  final BorderRadius borderRadius;
  final Color? borderColor;
  final double borderOpacity;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  /// True untuk factory [bottomBar] — otomatis menambahkan inset sistem bawah
  /// (nav bar / home indicator) ke padding bawah agar bar aksi tak tertutup.
  final bool isBottomBar;

  const GlassContainer({
    super.key,
    required this.child,
    this.blurSigma = 18,
    this.opacity = 0.78,
    this.borderRadius =
        const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLG)),
    this.borderColor,
    this.borderOpacity = 0.45,
    this.boxShadow,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.isBottomBar = false,
  });

  /// Factory for bottom-bar style glass (top border, upward shadow).
  const GlassContainer.bottomBar({
    super.key,
    required this.child,
    this.blurSigma = 18,
    this.opacity = 0.78,
    this.borderOpacity = 0.45,
    this.boxShadow,
    this.padding,
    this.margin,
    this.backgroundColor,
  })  : borderRadius = const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLG)),
        borderColor = null,
        isBottomBar = true;

  /// Factory for card-style glass (full border radius, subtle shadow).
  const GlassContainer.card({
    super.key,
    required this.child,
    this.blurSigma = 16,
    this.opacity = 0.72,
    this.borderOpacity = 0.3,
    this.boxShadow,
    this.padding,
    this.margin,
    this.backgroundColor,
  })  : borderRadius =
            const BorderRadius.all(Radius.circular(AppSpacing.radiusMD)),
        borderColor = null,
        isBottomBar = false;

  /// Factory for sheet-style glass (top-rounded, drag indicator friendly).
  const GlassContainer.sheet({
    super.key,
    required this.child,
    this.blurSigma = 20,
    this.opacity = 0.85,
    this.borderOpacity = 0.4,
    this.boxShadow,
    this.padding,
    this.margin,
    this.backgroundColor,
  })  : borderRadius = const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXL)),
        borderColor = null,
        isBottomBar = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBorderColor = borderColor ?? colorScheme.outlineVariant;
    final effectiveBg =
        backgroundColor ?? colorScheme.surface.withValues(alpha: opacity);
    final effectiveShadow = boxShadow ??
        [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ];

    // Bar aksi bawah otomatis aman dari nav bar / home indicator.
    final effectivePadding = isBottomBar
        ? (padding ?? EdgeInsets.zero).add(
            EdgeInsets.only(bottom: context.systemBottomInset),
          )
        : padding;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: effectivePadding,
          margin: margin,
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: borderRadius,
            border: Border.all(
              color: effectiveBorderColor.withValues(alpha: borderOpacity),
            ),
            boxShadow: effectiveShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
