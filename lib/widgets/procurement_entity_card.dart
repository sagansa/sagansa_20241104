import 'package:flutter/material.dart';
import '../models/procurement_model.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';

/// Generic entity card untuk halaman procurement workflow.
/// Memiliki 3 factory mode: requestMode, invoiceMode, paymentMode.
///
/// Per spec section 4.5. Layout dasar:
///   - Border kiri 4px warna stage
///   - Header: title + meta + amount + badge
///   - Body: stepper mini (opsional) + link pill M:N + inline actions
class ProcurementEntityCard extends StatelessWidget {
  final Color borderColor;
  final String title;
  final String metaLine;
  final String? amountText;
  final Color? amountColor;
  final Widget? badge;
  final Widget? stepperOrLinks;
  final List<Widget>? actions;
  final VoidCallback? onTapCard;
  final bool isSelected;
  final Widget? leadingCheckbox;

  const ProcurementEntityCard._({
    super.key,
    required this.borderColor,
    required this.title,
    required this.metaLine,
    this.amountText,
    this.amountColor,
    this.badge,
    this.stepperOrLinks,
    this.actions,
    this.onTapCard,
    this.isSelected = false,
    this.leadingCheckbox,
  });

  /// Mode Request.
  factory ProcurementEntityCard.requestMode({
    Key? key,
    required RequestPurchase request,
    required List<InvoicePurchase> linkedInvoices,
    bool isSelected = false,
    VoidCallback? onTapCard,
    VoidCallback? onTapCreateInvoice,
    void Function(InvoicePurchase inv)? onTapLinkInvoice,
    bool showCheckbox = false,
    bool? checkboxValue,
    ValueChanged<bool>? onCheckboxChanged,
  }) {
    final isSiapInvoice = request.detailRequests.isNotEmpty;
    final badgeText = linkedInvoices.isEmpty
        ? (isSiapInvoice ? 'Siap Invoice' : 'Kosong')
        : 'Sudah Jadi Invoice (${linkedInvoices.length})';
    final badgeColor =
        linkedInvoices.isEmpty ? AppColors.warning : AppColors.success;

    final linkPills = linkedInvoices.map((inv) {
      final status = inv.paymentStatus == '2' ? '✅' : '🔴';
      return _LinkPill(
        label: '↳ INV #${inv.id} $status',
        onTap: () => onTapLinkInvoice?.call(inv),
      );
    }).toList();

    return ProcurementEntityCard._(
      key: key,
      borderColor: const Color(0xFFFF9800), // orange
      title: 'REQ #${request.id} • ${request.storeName}',
      metaLine:
          '${request.userName} • ${request.detailRequests.length} item • ${request.date}',
      badge: _Badge(text: badgeText, color: badgeColor),
      stepperOrLinks: linkedInvoices.isEmpty
          ? (isSiapInvoice
              ? Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onTapCreateInvoice,
                        icon: const Icon(Icons.arrow_forward, size: 14),
                        label: const Text('Buat Invoice',
                            style: TextStyle(fontSize: 10)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          minimumSize: const Size(0, 30),
                        ),
                      ),
                    ),
                    if (showCheckbox) ...[
                      const SizedBox(width: 6),
                      Checkbox(
                        value: checkboxValue ?? false,
                        onChanged: (v) =>
                            onCheckboxChanged?.call(v ?? false),
                      ),
                    ],
                  ],
                )
              : null)
          : Wrap(spacing: 4, runSpacing: 4, children: linkPills),
      onTapCard: onTapCard,
      isSelected: isSelected,
    );
  }

  /// Mode Invoice.
  factory ProcurementEntityCard.invoiceMode({
    Key? key,
    required InvoicePurchase invoice,
    required List<int> linkedRequestIds,
    bool showCheckbox = false,
    bool? checkboxValue,
    ValueChanged<bool>? onCheckboxChanged,
    VoidCallback? onTapCard,
    VoidCallback? onTapBayar,
  }) {
    final isPaid = invoice.paymentStatus == '2';
    final canBayar = !isPaid;

    Widget? badge;
    if (isPaid) {
      badge = const _Badge(text: 'Lunas', color: AppColors.success);
    } else {
      badge = const _Badge(text: 'Siap Dibayar', color: AppColors.info);
    }

    final linkPills = linkedRequestIds.isEmpty
        ? <Widget>[]
        : [_LinkPill(label: '↳ REQ ${linkedRequestIds.join(",")}')];

    final actions = <Widget>[];
    if (canBayar && onTapBayar != null) {
      actions.add(ElevatedButton.icon(
        onPressed: onTapBayar,
        icon: const Icon(Icons.payment, size: 14),
        label: const Text('Bayar', style: TextStyle(fontSize: 10)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.info,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 6),
          minimumSize: const Size(0, 30),
        ),
      ));
    }

    // Format date dari ISO yyyy-MM-dd ke dd-MM-yyyy.
    String fmtDate(String raw) {
      if (raw.length < 10) return raw;
      final parts = raw.substring(0, 10).split('-');
      if (parts.length != 3) return raw;
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }

    return ProcurementEntityCard._(
      key: key,
      borderColor: const Color(0xFF2196F3), // blue
      title: 'INV #${invoice.id} • ${invoice.storeName}',
      metaLine:
          'Supplier: ${invoice.supplierName ?? "-"} • Tgl: ${fmtDate(invoice.date)} • ${invoice.paymentTypeText}',
      amountText: FormatUtils.formatCurrency(invoice.totalPrice),
      amountColor: const Color(0xFF1976D2),
      badge: badge,
      stepperOrLinks: linkPills.isEmpty
          ? null
          : Wrap(spacing: 4, runSpacing: 4, children: linkPills),
      actions: actions.isEmpty ? null : actions,
      onTapCard: onTapCard,
      isSelected: checkboxValue ?? false,
      leadingCheckbox: showCheckbox && canBayar
          ? Checkbox(
              value: checkboxValue ?? false,
              onChanged: (v) => onCheckboxChanged?.call(v ?? false),
            )
          : null,
    );
  }

  /// Mode Payment.
  factory ProcurementEntityCard.paymentMode({
    Key? key,
    required PaymentReceipt receipt,
    required bool isTunai,
    VoidCallback? onTapCard,
  }) {
    final isMulti = receipt.invoicePurchases.length > 1;
    final linkPills = receipt.invoicePurchases
        .map((inv) => _LinkPill(label: '↳ INV #${inv.id}'))
        .toList();

    // Format createdAt dari ISO (2026-07-19T...) ke dd-MM-yyyy.
    final rawDate = receipt.createdAt;
    String formattedDate = rawDate;
    if (rawDate.length >= 10) {
      final iso = rawDate.substring(0, 10); // yyyy-MM-dd
      final parts = iso.split('-');
      if (parts.length == 3) {
        formattedDate = '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    }

    return ProcurementEntityCard._(
      key: key,
      borderColor: const Color(0xFF9C27B0), // purple
      title: 'Kwit #${receipt.id} • ${receipt.supplierName ?? "Supplier"}',
      metaLine: 'Tgl Bayar: $formattedDate',
      amountText: FormatUtils.formatCurrency(receipt.totalAmount),
      amountColor: AppColors.success,
      // Selalu tampilkan badge "Lunas" (payment receipt = sudah dibayar),
      // dan tambahkan badge "N Invoice Gabungan" jika gabungan multi-invoice.
      badge: isMulti
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Badge(text: 'Lunas', color: AppColors.success),
                const SizedBox(height: 2),
                _Badge(
                  text: '${receipt.invoicePurchases.length} Invoice Gabungan',
                  color: const Color(0xFF9C27B0),
                ),
              ],
            )
          : const _Badge(text: 'Lunas', color: AppColors.success),
      stepperOrLinks: Wrap(spacing: 4, runSpacing: 4, children: linkPills),
      // Tidak ada inline actions di payment mode (display-only).
      actions: null,
      onTapCard: onTapCard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                    color: borderColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    spreadRadius: 1)
              ]
            : [
                BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1))
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTapCard,
        borderRadius: BorderRadius.circular(10),
        // Stack: konten menentukan tinggi natural; accent strip menempel
        // full-height via Positioned. Menghindari IntrinsicHeight yang
        // bisa menyebabkan 1px overflow saat konten padat.
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leadingCheckbox != null) ...[
                    leadingCheckbox!,
                    const SizedBox(width: 6)
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    metaLine,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant),
                                  ),
                                  if (amountText != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      amountText!,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: amountColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (badge != null) badge!,
                          ],
                        ),
                        if (stepperOrLinks != null) ...[
                          const SizedBox(height: 6),
                          stepperOrLinks!,
                        ],
                        if (actions != null && actions!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, runSpacing: 6, children: actions!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Left accent strip 4px, full-height via Positioned.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: borderColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _LinkPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _LinkPill({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 9, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
