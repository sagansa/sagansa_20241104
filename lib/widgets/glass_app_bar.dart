import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// AppBar with glassmorphism effect (frosted glass).
///
/// Wraps a standard [AppBar] with [BackdropFilter] to create
/// a translucent frosted-glass appearance. Use as a drop-in
/// replacement for [AppBar] in any [Scaffold].
///
/// ```dart
/// Scaffold(
///   appBar: GlassAppBar(title: Text('My Page')),
///   body: ...,
/// )
/// ```
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double blurSigma;
  final double opacity;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final PreferredSizeWidget? bottom;
  final double? leadingWidth;

  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.blurSigma = 18,
    this.opacity = 0.82,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.bottom,
    this.leadingWidth,
  });

  @override
  Size get preferredSize {
    final height = kToolbarHeight + (bottom?.preferredSize.height ?? 0);
    return Size.fromHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveBg = backgroundColor ??
        (isDark
            ? AppColors.darkSurface.withValues(alpha: opacity)
            : AppColors.surface.withValues(alpha: opacity));
    final effectiveFg = foregroundColor ??
        (isDark ? AppColors.darkOnSurface : AppColors.onSurface);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: AppBar(
          title: title,
          actions: actions,
          leading: leading,
          leadingWidth: leadingWidth,
          automaticallyImplyLeading: automaticallyImplyLeading,
          backgroundColor: effectiveBg,
          foregroundColor: effectiveFg,
          elevation: elevation,
          shadowColor: AppColors.shadow.withValues(alpha: isDark ? 0.3 : 0.1),
          surfaceTintColor: Colors.transparent,
          bottom: bottom,
        ),
      ),
    );
  }
}
