import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A reusable ticket/receipt container with rounded corners, elevated card feel,
/// and optional dashed divider to simulate a physical receipt/voucher cut.
class TicketCardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showHeaderAccent;

  const TicketCardContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.showHeaderAccent = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = backgroundColor ??
        (isDark ? theme.cardColor : AppColors.surface);
    final defaultBorder = borderColor ??
        (isDark ? Colors.white12 : AppColors.secondaryContainer.withValues(alpha: 0.5));

    return Container(
      margin: margin ?? AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: defaultBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
        border: Border.all(color: defaultBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHeaderAccent)
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold,
                      AppColors.secondary,
                    ],
                  ),
                ),
              ),
            Padding(
              padding: padding ?? AppSpacing.paddingLG,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal dashed divider widget used inside receipt cards.
class DashedDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const DashedDivider({
    super.key,
    this.height = 1,
    this.color = Colors.grey,
    this.dashWidth = 6,
    this.dashSpace = 4,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strokeColor = color == Colors.grey
        ? (isDark ? Colors.white24 : Colors.black12)
        : color;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(color: strokeColor),
              ),
            );
          }),
        );
      },
    );
  }
}
