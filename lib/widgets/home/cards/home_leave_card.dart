import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/home_dashboard_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Staff "Cuti" dashboard card.
/// Baca leaveSalary.hasLeavesThisMonth/pendingLeavesCount dari provider.
class HomeLeaveCard extends StatelessWidget {
  const HomeLeaveCard({super.key});

  @override
  Widget build(BuildContext context) {
    final leaveSalary = context.select<HomeDashboardProvider,
        HomeLeaveSalaryState>((p) => p.leaveSalary);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: null,
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
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSM,
                ),
                child: Icon(Icons.receipt_long_outlined,
                    color: AppColors.warning, size: 28),
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
                        'Cuti',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.gapVerticalXS,
                      Text(
                        leaveSalary.isLoading
                            ? 'Loading...'
                            : (!leaveSalary.hasLeavesThisMonth
                                ? 'Kosong'
                                : (leaveSalary.pendingLeavesCount > 0
                                    ? '${leaveSalary.pendingLeavesCount} Pending'
                                    : 'Disetujui')),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          height: 1.15,
                        ),
                      ),
                      AppSpacing.gapVerticalXS,
                      Text(
                        'Cuti & Izin',
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
