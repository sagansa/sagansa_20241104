import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class ModernTextField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;

  const ModernTextField({
    super.key,
    required this.labelText,
    required this.controller,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = false,
    this.enableSuggestions = false,
    this.inputFormatters,
    this.suffixIcon,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    // Mengandalkan InputDecorationTheme dari ThemeProvider agar input
    // selalu mengikuti tema aktif (light/dark) secara konsisten.
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.info,
        ),
        suffixIcon: suffixIcon,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
    );
  }
}