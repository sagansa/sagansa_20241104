import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const ModernButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Mengandalkan ElevatedButtonTheme dari ThemeProvider agar tombol
    // selalu mengikuti tema aktif (light/dark) secara konsisten.
    return ElevatedButton(
      onPressed: onPressed == null
          ? null
          : () {
              if (!isLoading) {
                onPressed!();
              }
            },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        padding: AppSpacing.paddingVerticalMD,
      ),
      child: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.onPrimary,
                strokeWidth: 2.5,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon),
                  AppSpacing.gapHorizontalSM,
                ],
                Text(text),
              ],
            ),
    );
  }
}
