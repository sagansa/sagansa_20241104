import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/printer_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class StickerPrintButton extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isPrinting;
  final VoidCallback onPrint;

  const StickerPrintButton({
    super.key,
    required this.order,
    required this.isPrinting,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<PrinterProvider>(
      builder: (context, provider, _) {
        final bool thermalReady = provider.isEnabled;

        return Card(
          color: colorScheme.surface,
          child: Padding(
            padding: AppSpacing.paddingMD,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      thermalReady ? Icons.wifi : Icons.receipt_long,
                      color: thermalReady
                          ? AppColors.success
                          : colorScheme.primary,
                      size: 20,
                    ),
                    AppSpacing.gapHorizontalSM,
                    Expanded(
                      child: Text(
                        'Cetak Resi Stiker',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildModeBadge(thermalReady),
                  ],
                ),
                AppSpacing.gapVerticalXS,
                Text(
                  thermalReady
                      ? 'Printer: ${provider.formattedEndpoint} • '
                          '${provider.formattedSize} • ${provider.copies}x'
                      : 'Ukuran: ${provider.formattedSize} • '
                          'Aktifkan thermal di Pengaturan untuk WiFi.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                AppSpacing.gapVerticalSM,
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isPrinting ? null : onPrint,
                  icon: isPrinting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: colorScheme.primary,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          thermalReady
                              ? Icons.print
                              : Icons.receipt_outlined,
                          size: 18,
                        ),
                  label: Text(
                    isPrinting
                        ? 'Mencetak...'
                        : 'Cetak Stiker Resi'
                            '${provider.copies > 1 ? ' (${provider.copies}x)' : ''}',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeBadge(bool thermalReady) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: thermalReady
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.info.withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadiusSM,
      ),
      child: Text(
        thermalReady ? 'WiFi' : 'Spooler',
        style: TextStyle(
          color: thermalReady ? AppColors.success : AppColors.info,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
