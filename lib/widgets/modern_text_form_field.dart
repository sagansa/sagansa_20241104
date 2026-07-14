import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModernTextFormField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final int? maxLines;
  final String? Function(String?)? validator;
  final bool? enabled;

  const ModernTextFormField({
    super.key,
    required this.labelText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = false,
    this.enableSuggestions = false,
    this.inputFormatters,
    this.suffixIcon,
    this.maxLines = 1,
    this.validator,
    this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    // Mengandalkan InputDecorationTheme dari ThemeProvider agar input
    // selalu mengikuti tema aktif (light/dark) secara konsisten.
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: suffixIcon,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
    );
  }
}