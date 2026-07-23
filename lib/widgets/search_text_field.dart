import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCleared;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixWidget;
  final TextInputAction? textInputAction;

  const SearchTextField({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onCleared,
    this.hintText = 'Cari...',
    this.prefixIcon = Icons.search,
    this.suffixWidget,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      style: TextStyle(color: colorScheme.onSurface),
      textInputAction: textInputAction ?? TextInputAction.search,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(prefixIcon, color: AppColors.info),
        suffixIcon: suffixWidget ??
            (controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      controller.clear();
                      onCleared?.call();
                    },
                  )
                : null),
      ),
    );
  }
}
