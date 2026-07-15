import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum StatusType { success, warning, error, info, neutral }

enum BadgeSize { small, medium }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;
  final BadgeSize size;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusType.neutral,
    this.size = BadgeSize.small,
  });

  Color _textColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (type) {
      case StatusType.success:
        return AppColors.success;
      case StatusType.warning:
        return AppColors.warning;
      case StatusType.error:
        return cs.error;
      case StatusType.info:
      case StatusType.neutral:
        return AppColors.onSurfaceVariant;
    }
  }

  Color _bgColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (type) {
      case StatusType.success:
        return AppColors.successContainer;
      case StatusType.warning:
        return AppColors.warningContainer;
      case StatusType.error:
        return cs.errorContainer.withValues(alpha: 0.3);
      case StatusType.info:
      case StatusType.neutral:
        return AppColors.surfaceVariant;
    }
  }

  EdgeInsets _padding() {
    switch (size) {
      case BadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 3);
      case BadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: _padding(),
      decoration: BoxDecoration(
        color: _bgColor(context),
        borderRadius: AppSpacing.borderRadiusXL,
      ),
      child: Text(
        label,
        style: (size == BadgeSize.small ? textTheme.labelSmall : textTheme.labelMedium)?.copyWith(
          color: _textColor(context),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
