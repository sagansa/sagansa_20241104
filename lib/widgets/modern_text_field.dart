import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/app_animations.dart';

class ModernTextField extends StatefulWidget {
  final String labelText;
  final String? hintText;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
<<<<<<< HEAD
  final List<String>? autofillHints;
  final String? errorText;
  final String? helperText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final bool readOnly;
=======
>>>>>>> parent of f54562b (update token, password remember, logo)

  const ModernTextField({
    super.key,
    required this.labelText,
    required this.controller,
    this.hintText,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = false,
    this.enableSuggestions = false,
    this.inputFormatters,
    this.enabled = true,
<<<<<<< HEAD
    this.autofillHints,
    this.errorText,
    this.helperText,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.readOnly = false,
=======
>>>>>>> parent of f54562b (update token, password remember, logo)
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.durationMedium,
      vsync: this,
    );
    _focusAnimation = CurvedAnimation(
      parent: _animationController,
      curve: AppAnimations.curveDefault,
    );
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Color _getBorderColor() {
    if (widget.errorText != null) {
      return AppColors.error;
    }
    if (_isFocused) {
      return AppColors.primary;
    }
    if (!widget.enabled) {
      return AppColors.outline.withOpacity(0.5);
    }
    return AppColors.outline;
  }

  Color _getLabelColor() {
    if (widget.errorText != null) {
      return AppColors.error;
    }
    if (_isFocused) {
      return AppColors.primary;
    }
    return AppColors.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _focusAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.borderRadiusMD,
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  onTap: widget.onTap,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  decoration: InputDecoration(
                    labelText: widget.labelText,
                    hintText: widget.hintText,
                    prefixIcon: widget.prefixWidget ??
                        (widget.prefixIcon != null
                            ? Icon(
                                widget.prefixIcon,
                                color: _isFocused
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                              )
                            : null),
                    suffixIcon: widget.suffixIcon,
                    filled: true,
                    fillColor: widget.enabled
                        ? AppColors.surfaceVariant.withOpacity(0.3)
                        : AppColors.surfaceVariant.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMD,
                      borderSide: BorderSide(color: _getBorderColor()),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMD,
                      borderSide: BorderSide(color: _getBorderColor()),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMD,
                      borderSide: BorderSide(
                        color: _getBorderColor(),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMD,
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMD,
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 2,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMD,
                      borderSide: BorderSide(
                        color: AppColors.outline.withOpacity(0.5),
                      ),
                    ),
                    contentPadding: AppSpacing.paddingMD,
                    labelStyle: AppTypography.bodyMedium.copyWith(
                      color: _getLabelColor(),
                    ),
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    errorText: widget.errorText,
                    helperText: widget.helperText,
                    errorStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                    helperStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    counterStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  style: AppTypography.bodyMedium.copyWith(
                    color: widget.enabled
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                  keyboardType: widget.keyboardType,
                  obscureText: widget.obscureText,
                  textCapitalization: widget.textCapitalization,
                  autocorrect: widget.autocorrect,
                  enableSuggestions: widget.enableSuggestions,
                  inputFormatters: widget.inputFormatters,
                  autofillHints: widget.autofillHints,
                  maxLines: widget.maxLines,
                  minLines: widget.minLines,
                  maxLength: widget.maxLength,
                ),
              );
            },
          ),
<<<<<<< HEAD
        ],
=======
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.black),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
          suffixIcon: suffixIcon,
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        textCapitalization: textCapitalization,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        inputFormatters: inputFormatters,
>>>>>>> parent of f54562b (update token, password remember, logo)
      );
    } catch (e) {
      debugPrint('Error in ModernTextField: $e');
      return Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.error),
          borderRadius: AppSpacing.borderRadiusMD,
        ),
        child: Center(
          child: Text(
            'TextField Error: $e',
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ),
      );
    }
  }
}
