import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Card ringkas untuk KPI/menu dashboard ala home_page.
///
/// Layout (persegi, cocok untuk GridView.count):
/// ```
///   [icon]            [badge]
///
///        value (titleLarge bold)
///
///        label
/// ```
///
/// Untuk dashboard menu (bukan KPI angka), value bisa diisi judul menu
/// (mis. "Stok Gudang") dan label diisi subtitle singkat. Badge opsional
/// untuk status/counter (mis. "2 telat", "Sudah").
class CompactDashboardCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback? onTap;

  const CompactDashboardCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.badge,
    this.badgeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final card = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.paddingSM,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Row atas: icon kiri + badge kanan (opsional)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: AppSpacing.borderRadiusSM,
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                if (badge != null)
                  Flexible(
                    child: Text(
                      badge!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: badgeColor ?? colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
            // Value tengah
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            // Label bawah
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMD,
        child: card,
      );
    }
    return card;
  }
}
