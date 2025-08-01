import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/app_animations.dart';

enum ModernButtonType { elevated, outlined, text }

enum ModernButtonSize { small, medium, large }

class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ModernButtonType type;
  final ModernButtonSize size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final bool fullWidth;

  const ModernButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.type = ModernButtonType.elevated,
    this.size = ModernButtonSize.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.fullWidth = true,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.durationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppAnimations.curveDefault,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _resetAnimation();
  }

  void _handleTapCancel() {
    _resetAnimation();
  }

  void _resetAnimation() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  EdgeInsetsGeometry get _padding {
    switch (widget.size) {
      case ModernButtonSize.small:
        return AppSpacing.paddingVerticalSM + AppSpacing.paddingHorizontalMD;
      case ModernButtonSize.medium:
        return AppSpacing.paddingVerticalMD + AppSpacing.paddingHorizontalLG;
      case ModernButtonSize.large:
        return AppSpacing.paddingVerticalLG + AppSpacing.paddingHorizontalXL;
    }
  }

  double get _minHeight {
    switch (widget.size) {
      case ModernButtonSize.small:
        return 36;
      case ModernButtonSize.medium:
        return 48;
      case ModernButtonSize.large:
        return 56;
    }
  }

  TextStyle get _textStyle {
    switch (widget.size) {
      case ModernButtonSize.small:
        return AppTypography.buttonSmall;
      case ModernButtonSize.medium:
        return AppTypography.buttonMedium;
      case ModernButtonSize.large:
        return AppTypography.buttonLarge;
    }
  }

  Widget _buildButton() {
    switch (widget.type) {
      case ModernButtonType.elevated:
        return ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor ?? AppColors.primary,
            foregroundColor: widget.foregroundColor ?? AppColors.onPrimary,
            minimumSize: Size(
              widget.fullWidth ? double.infinity : 0,
              _minHeight,
            ),
            padding: _padding,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMD,
            ),
            textStyle: _textStyle,
            elevation: _isPressed ? 1 : 3,
            shadowColor: AppColors.shadow.withOpacity(0.3),
          ),
          child: _buildButtonContent(),
        );
      case ModernButtonType.outlined:
        return OutlinedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.foregroundColor ?? AppColors.primary,
            minimumSize: Size(
              widget.fullWidth ? double.infinity : 0,
              _minHeight,
            ),
            padding: _padding,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMD,
            ),
            side: BorderSide(
              color: widget.backgroundColor ?? AppColors.primary,
              width: _isPressed ? 2 : 1.5,
            ),
            textStyle: _textStyle,
          ),
          child: _buildButtonContent(),
        );
      case ModernButtonType.text:
        return TextButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: TextButton.styleFrom(
            foregroundColor: widget.foregroundColor ?? AppColors.primary,
            minimumSize: Size(
              widget.fullWidth ? double.infinity : 0,
              _minHeight,
            ),
            padding: _padding,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMD,
            ),
            textStyle: _textStyle,
          ),
          child: _buildButtonContent(),
        );
    }
  }

  Widget _buildButtonContent() {
    if (widget.isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.type == ModernButtonType.elevated
                ? AppColors.onPrimary
                : AppColors.primary,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: _getIconSize()),
          AppSpacing.gapHorizontalSM,
        ],
        Text(widget.text),
      ],
    );
  }

  double _getIconSize() {
    switch (widget.size) {
      case ModernButtonSize.small:
        return 16;
      case ModernButtonSize.medium:
        return 20;
      case ModernButtonSize.large:
        return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: widget.width,
              child: _buildButton(),
            ),
          );
        },
      ),
    );
  }
}
