import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class LeaveStatsHeader extends StatelessWidget {
  final int totalCount;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final String? activeStatus;
  final ValueChanged<String?>? onStatusSelected;

  const LeaveStatsHeader({
    super.key,
    required this.totalCount,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    this.activeStatus,
    this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ringkasan Cuti & Izin',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (pendingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 13, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        '$pendingCount menunggu',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard(
                  context: context,
                  title: 'Total',
                  count: totalCount,
                  icon: Icons.event_note_rounded,
                  color: colorScheme.primary,
                  statusValue: null,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  context: context,
                  title: 'Pending',
                  count: pendingCount,
                  icon: Icons.pending_actions_rounded,
                  color: AppColors.warning,
                  statusValue: '1',
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  context: context,
                  title: 'Disetujui',
                  count: approvedCount,
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  statusValue: '2',
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  context: context,
                  title: 'Ditolak',
                  count: rejectedCount,
                  icon: Icons.cancel_outlined,
                  color: AppColors.error,
                  statusValue: '3',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String? statusValue,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = activeStatus == statusValue;

    return GestureDetector(
      onTap: () {
        if (onStatusSelected != null) {
          onStatusSelected!(statusValue);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 105,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerLow,
          borderRadius: AppSpacing.borderRadiusMD,
          border: Border.all(
            color: isSelected ? color : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 18, color: color),
                Text(
                  '$count',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected ? color : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
