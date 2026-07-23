import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class MarkReadyToShipCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onMarkReady;

  const MarkReadyToShipCard({
    super.key,
    required this.isLoading,
    required this.onMarkReady,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order Belum Siap Dikirim',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tandai order ini sebagai siap dikirim sebelum mengunggah bukti pengiriman.',
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: isLoading ? null : onMarkReady,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.local_shipping, color: Colors.white),
                label: Text(
                  isLoading ? 'Memproses...' : 'Tandai Siap Dikirim',
                  style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubmitDeliveryCard extends StatelessWidget {
  final int selectedStatus;
  final bool isSubmitting;
  final bool hasPhotos;
  final Widget receiverField;
  final Widget notesField;
  final Widget photoUploader;
  final ValueChanged<int> onStatusChanged;
  final VoidCallback onSubmit;

  const SubmitDeliveryCard({
    super.key,
    required this.selectedStatus,
    required this.isSubmitting,
    required this.hasPhotos,
    required this.receiverField,
    required this.notesField,
    required this.photoUploader,
    required this.onStatusChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedStatus == 6
                  ? 'Laporkan Barang Kembali'
                  : 'Kirim Bukti Pengiriman',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Sudah Dikirim')),
                    selected: selectedStatus == 3,
                    onSelected: (selected) {
                      if (selected) onStatusChanged(3);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Dikembalikan')),
                    selected: selectedStatus == 6,
                    onSelected: (selected) {
                      if (selected) onStatusChanged(6);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedStatus == 3) receiverField else notesField,
            const SizedBox(height: 16),
            photoUploader,
            const SizedBox(height: 20),
            _buildSubmitButton(colorScheme, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: hasPhotos ? AppColors.primaryGradient : null,
        color: hasPhotos
            ? null
            : colorScheme.outlineVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: hasPhotos
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasPhotos ? onSubmit : null,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    selectedStatus == 6
                        ? 'Laporkan Barang Kembali'
                        : 'Kirim Bukti Pengiriman',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasPhotos
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class RefundButton extends StatelessWidget {
  final VoidCallback onRefund;

  const RefundButton({super.key, required this.onRefund});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.error,
        side: BorderSide(color: colorScheme.error.withValues(alpha: 0.6)),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.assignment_return, size: 20),
      label: const Text('Refund / Kembalikan Order',
          style: TextStyle(fontWeight: FontWeight.bold)),
      onPressed: onRefund,
    );
  }
}
