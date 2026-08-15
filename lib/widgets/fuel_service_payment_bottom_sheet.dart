import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fuel_service_payment_provider.dart';
import '../services/image_service.dart';
import '../services/procurement_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/format_utils.dart';
import '../widgets/safe_bottom_bar.dart';

/// Bottom sheet untuk upload bukti transfer + catatan + submit
/// payment receipt bensin/servis.
///
/// Pakai FuelServicePaymentProvider untuk state (selected ids, image, notes).
/// Saat submit → call ProcurementService.createFuelServicePaymentReceipt.
class FuelServicePaymentBottomSheet extends StatefulWidget {
  const FuelServicePaymentBottomSheet({super.key});

  /// Tampilkan bottom sheet. Return true jika sukses submit.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const FuelServicePaymentBottomSheet(),
    );
  }

  @override
  State<FuelServicePaymentBottomSheet> createState() =>
      _FuelServicePaymentBottomSheetState();
}

class _FuelServicePaymentBottomSheetState
    extends State<FuelServicePaymentBottomSheet> {
  final _procurementService = ProcurementService();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final photo = await ImageService.selectAndPickImage(context);
      if (photo != null && mounted) {
        context.read<FuelServicePaymentProvider>().setImageFile(photo);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    }
  }

  Future<void> _submit() async {
    final provider = context.read<FuelServicePaymentProvider>();
    if (!provider.canSubmit) return;

    provider.setSubmitting(true);
    try {
      await _procurementService.createFuelServicePaymentReceipt(
        fuelServiceIds: provider.selectedFuelServiceIds,
        transferAmount: provider.totalAmount,
        notes: provider.notes.isNotEmpty ? provider.notes : null,
        image: provider.imageFile,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment receipt berhasil dibuat.'),
          backgroundColor: AppColors.success,
        ),
      );
      provider.clearSelection();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) provider.setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final provider = context.watch<FuelServicePaymentProvider>();
    final paddingBottom =
        MediaQuery.of(context).viewInsets.bottom + context.systemBottomInset;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: cs.surface.withValues(alpha: 0.85),
          child: Padding(
            padding: EdgeInsets.only(bottom: paddingBottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bukti Transfer Bensin/Servis',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${provider.selectedCount} item dipilih',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          FormatUtils.formatCurrency(provider.totalAmount),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bukti transfer image
                  Text(
                    'Bukti Pembayaran (Opsional)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (provider.imageFile != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            provider.imageFile!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.6),
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: Colors.white),
                              onPressed: () => provider.setImageFile(null),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(
                        provider.imageFile == null
                            ? Icons.add_a_photo_rounded
                            : Icons.edit_rounded,
                        size: 18,
                      ),
                      label: Text(
                        provider.imageFile == null
                            ? 'Unggah Bukti Transfer'
                            : 'Ganti Foto Bukti',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (v) => provider.setNotes(v),
                  ),
                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: provider.canSubmit ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.gold,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMD),
                        ),
                      ),
                      child: provider.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.gold,
                              ),
                            )
                          : Text(
                              'Buat Payment Receipt (${FormatUtils.formatCurrency(provider.totalAmount)})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
