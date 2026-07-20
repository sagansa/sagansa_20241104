import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/image_service.dart';
import '../theme/app_colors.dart';

class SupplierPaymentInfoCard extends StatelessWidget {
  final Map<String, dynamic>? selectedSupplier;
  final String? bankName;
  final String? bankAccountName;
  final String? bankAccountNo;
  final String? qris;

  const SupplierPaymentInfoCard({
    super.key,
    this.selectedSupplier,
    this.bankName,
    this.bankAccountName,
    this.bankAccountNo,
    this.qris,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedSupplier == null &&
        bankAccountNo == null &&
        bankName == null &&
        qris == null) {
      return const SizedBox.shrink();
    }

    final effectiveBankName =
        (selectedSupplier?['bank_name'] ?? bankName ?? '').toString();
    final effectiveAccountName = (selectedSupplier?['bank_account_name'] ??
            bankAccountName ??
            '')
        .toString();
    final effectiveAccountNo = (selectedSupplier?['bank_account_no'] ??
            bankAccountNo ??
            '')
        .toString();
    final effectiveQris =
        (selectedSupplier?['qris'] ?? qris ?? '').toString();

    final hasBank = effectiveAccountNo.isNotEmpty || effectiveBankName.isNotEmpty;
    final hasQris = effectiveQris.isNotEmpty;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!hasBank && !hasQris) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Supplier ini belum memiliki info Rekening Bank atau QRIS terdaftar.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Info Pembayaran Supplier (Validasi)',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bank Account Section
          if (hasBank) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance_outlined,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        effectiveBankName.isNotEmpty
                            ? 'Bank $effectiveBankName'
                            : 'Rekening Bank',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Row(
                        children: [
                          SelectableText(
                            effectiveAccountNo.isNotEmpty
                                ? effectiveAccountNo
                                : '-',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (effectiveAccountNo.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: effectiveAccountNo),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No. rekening berhasil disalin!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Icon(
                                  Icons.copy_rounded,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (effectiveAccountName.isNotEmpty)
                        Text(
                          'a.n. $effectiveAccountName',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          if (hasBank && hasQris) const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),

          // QRIS Section
          if (hasQris) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QRIS Supplier',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Tersedia',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    _showQrisDialog(context, effectiveQris);
                  },
                  icon: const Icon(Icons.crop_free, size: 16),
                  label: const Text('Lihat QRIS'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showQrisDialog(BuildContext context, String qris) {
    final imageUrl = ImageService.buildUrl(qris);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('QRIS Supplier'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  height: 280,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SelectableText(
                      qris,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              SelectableText(
                qris,
                textAlign: TextAlign.center,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
