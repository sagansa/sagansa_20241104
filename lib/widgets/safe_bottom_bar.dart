import 'package:flutter/material.dart';

/// Inset bawah sistem (Android nav bar / iOS home indicator) dalam logical px.
///
/// Dibaca LANGSUNG dari view engine via [View.of] sehingga **bulletproof**
/// terhadap modifikasi [MediaQuery] oleh ancestor (SafeArea/Scaffold) — yang
/// pernah membuat `MediaQuery.viewPaddingOf` mengembalikan 0 di konteks tertentu
/// (mis. `Scaffold.bottomSheet`) dan menyebabkan bar aksi tertutup nav bar.
///
/// Pakai: `EdgeInsets.only(bottom: context.systemBottomInset)` untuk padding
/// konten custom, atau bungkus bar aksi dengan [SafeBottomBar].
extension SystemBottomInsetX on BuildContext {
  double get systemBottomInset {
    final view = View.of(this);
    return view.viewPadding.bottom / view.devicePixelRatio;
  }
}

/// Bar aksi yang menempel di tepi bawah layar (untuk `Scaffold.bottomSheet`,
/// `bottomNavigationBar`, FAB area, dst.) yang **otomatis** menambahkan inset
/// sistem bawah sehingga isinya tidak pernah tertutup nav bar / home indicator.
///
/// Pakai ini untuk SEMUA bar aksi bawah agar masalah "tertutup nav bar" tidak
/// berulang setiap ada fitur baru.
///
/// ```dart
/// Scaffold(
///   bottomSheet: SafeBottomBar(
///     child: Column(mainAxisSize: MainAxisSize.min, children: [ ... ]),
///   ),
/// )
/// ```
class SafeBottomBar extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsets padding;

  /// Tampilkan border atas (pemisah dari konten scroll).
  final bool showTopBorder;

  /// Tampilkan shadow halus di atas bar.
  final bool showShadow;

  const SafeBottomBar({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.showTopBorder = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inset = context.systemBottomInset;
    return Container(
      width: double.infinity,
      // Padding konten + inset sistem bawah (auto).
      padding: padding.copyWith(bottom: padding.bottom + inset),
      decoration: BoxDecoration(
        color: backgroundColor ?? cs.surface,
        border: showTopBorder
            ? Border(
                top:
                    BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
