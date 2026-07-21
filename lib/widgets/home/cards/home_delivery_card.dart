import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/home_dashboard_provider.dart';
import '../../../theme/app_spacing.dart';

/// Staff "Pengiriman" dashboard card.
/// Baca orders.pendingOnlineOrderCount/pendingDirectOrderCount dari provider.
class HomeDeliveryCard extends StatelessWidget {
  const HomeDeliveryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.select<HomeDashboardProvider, HomeOrdersState>(
        (p) => p.orders);
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
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSM,
                ),
                child: Icon(Icons.local_shipping_outlined,
                    color: colorScheme.primary, size: 28),
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
                        'Pengiriman',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.gapVerticalXS,
                      Text(
                        orders.isLoading
                            ? 'Loading...'
                            : '${orders.pendingOnlineOrderCount + orders.pendingDirectOrderCount} Total',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          height: 1.15,
                        ),
                      ),
                      AppSpacing.gapVerticalXS,
                      Text(
                        'OS: ${orders.pendingOnlineOrderCount} | Dir: ${orders.pendingDirectOrderCount}',
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
