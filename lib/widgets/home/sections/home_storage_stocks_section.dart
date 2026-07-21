import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/home_dashboard_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Section "Peringatan Stok Kritis (Low Stock)" di dashboard admin.
///
/// Subscribe ke [HomeDashboardProvider.adminStock] via `context.watch`.
/// Tombol refresh memanggil `loadAdminStock()` di provider.
class HomeStorageStocksSection extends StatelessWidget {
  const HomeStorageStocksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final adminStock =
        context.select<HomeDashboardProvider, HomeAdminStockState>(
            (p) => p.adminStock);
    final homeProvider = context.read<HomeDashboardProvider>();

    // Filter to only get low stock items for homepage alert display
    final lowStockItems = adminStock.monitoringItems.where((item) {
      final double calculatedTotal =
          double.tryParse(item['calculated_total_stock']?.toString() ?? '0') ??
              0.0;
      final double qtyLow =
          double.tryParse(item['quantity_low']?.toString() ?? '0') ?? 0.0;
      return calculatedTotal < qtyLow;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peringatan Stok Kritis (Low Stock)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (adminStock.latestStockDate.isNotEmpty) ...[
                    AppSpacing.gapVerticalXS,
                    Text(
                      'Pembaruan Terakhir: ${adminStock.latestStockDate}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => homeProvider.loadAdminStock(),
              tooltip: 'Segarkan Monitoring',
            ),
          ],
        ),
        AppSpacing.gapVerticalSM,
        adminStock.isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ),
              )
            : lowStockItems.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: AppColors.success, size: 24),
                          AppSpacing.gapHorizontalMD,
                          Expanded(
                            child: Text(
                              'Semua stok gudang dalam kondisi aman.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: lowStockItems.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = lowStockItems[index];
                        final name = item['name'] ?? '';
                        final double calculatedTotal =
                            double.tryParse(item['calculated_total_stock']
                                        ?.toString() ??
                                    '0') ??
                                0.0;
                        final double qtyLow =
                            double.tryParse(item['quantity_low']?.toString() ?? '0') ??
                                0.0;
                        final unit = item['unit_nickname'] ?? '';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          leading: Container(
                            padding: AppSpacing.paddingXS,
                            decoration: BoxDecoration(
                              color: colorScheme.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.warning_amber_rounded,
                                color: colorScheme.error, size: 20),
                          ),
                          title: Text(
                            name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Batas Min: ${qtyLow.toStringAsFixed(0)} $unit',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${calculatedTotal.toStringAsFixed(0)} $unit',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.error,
                                ),
                              ),
                              Text(
                                'Low Stock',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }
}
