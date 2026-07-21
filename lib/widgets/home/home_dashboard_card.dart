import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// Dashboard card untuk grid staff (icon + title + value + subtitle).
///
/// Berbeda dari [HomeCompactCard] (square card admin yang dipakai untuk grid 3 kolom),
/// card ini lebih tinggi dan cocok untuk grid dengan maxCrossAxisExtent.
class HomeDashboardCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;

  const HomeDashboardCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMD,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: AppSpacing.paddingXS,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSM,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              AppSpacing.gapVerticalXS,
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.gapVerticalXS,
                      Text(
                        value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          height: 1.15,
                        ),
                      ),
                      AppSpacing.gapVerticalXS,
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
