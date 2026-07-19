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
    int pendingApprovalItemCount = 0,
    bool showCheckbox = false,
    bool? checkboxValue,
    ValueChanged<bool>? onCheckboxChanged,
    bool isAdmin = true,
    VoidCallback? onTapCard,
    VoidCallback? onTapBayar,
    VoidCallback? onTapReviewApprove,
  }) {
    final isPaid = invoice.paymentStatus == '2';
    final hasPending = pendingApprovalItemCount > 0;
    final canBayar = !isPaid && !hasPending;

    Widget? badge;
    if (hasPending) {
      badge = _Badge(
        text: '⚠️ $pendingApprovalItemCount item butuh approval',
        color: AppColors.warning,
      );
    } else if (isPaid) {
      badge = const _Badge(text: 'Lunas', color: AppColors.success);
    } else {
      badge = const _Badge(text: 'Siap Dibayar', color: AppColors.info);
    }

    final linkPills = linkedRequestIds.isEmpty
        ? <Widget>[]
        : [_LinkPill(label: '↳ REQ ${linkedRequestIds.join(",")}')];

    final actions = <Widget>[];
    if (hasPending && isAdmin && onTapReviewApprove != null) {
      actions.add(ElevatedButton.icon(
        onPressed: onTapReviewApprove,
        icon: const Icon(Icons.gavel, size: 14),
        label: const Text('Review & Approve',
            style: TextStyle(fontSize: 10)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warning,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 6),
          minimumSize: const Size(0, 30),
        ),
      ));
    } else if (canBayar && onTapBayar != null) {
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

    return ProcurementEntityCard._(
      key: key,
      borderColor: const Color(0xFF2196F3), // blue
      title: 'INV #${invoice.id} • ${invoice.storeName}',
      metaLine:
          'Supplier: ${invoice.supplierName ?? "-"} • Tgl: ${invoice.date} • ${invoice.paymentTypeText}',
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

    final actions = <Widget>[];
    if (isTunai) {
      actions.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '💵 Tunai — perlu reconcile closing store',
          style: TextStyle(
              fontSize: 9,
              color: AppColors.warning,
              fontWeight: FontWeight.w600),
        ),
      ));
    }

    return ProcurementEntityCard._(
      key: key,
      borderColor: const Color(0xFF9C27B0), // purple
      title: 'Kwit #${receipt.id} • ${receipt.supplierName ?? "Supplier"}',
      metaLine: 'Tgl Bayar: ${receipt.createdAt}',
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
      actions: actions.isEmpty ? null : actions,
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
        // Note: Flutter tidak mengizinkan borderRadius dengan border non-uniform
        // color. Gunakan border uniform tipis + left accent strip di dalam.
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left accent strip 4px (menggantikan border kiri non-uniform).
              Container(width: 4, color: borderColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
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
                    ], // inner Row children
                  ), // inner Row
                ), // Padding
              ), // outer Expanded
            ], // outer Row children
          ), // outer Row
        ), // IntrinsicHeight
      ), // InkWell
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
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
