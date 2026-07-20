import 'package:flutter/material.dart';
import '../models/procurement_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/format_utils.dart';

/// Visualisasi jaringan many-to-many alur procurement:
/// Request ──▶ Invoice ──▶ Kwitansi, dengan garis banyak-ke-satu.
///
/// Mapping yang dihitung di sini:
/// - requestToInvoices: requestId -> list invoice (dari _multiInvoiceMap).
/// - invoiceToRequests: invoiceId -> list request (kebalikan di atas).
/// - invoiceToReceipt:  invoiceId -> receipt (dari _receiptMap).
class ProcurementGraphView extends StatelessWidget {
  final List<RequestPurchase> requests;
  final List<InvoicePurchase> invoices;
  final List<PaymentReceipt> receipts;
  final Map<int, List<InvoicePurchase>> requestToInvoices;
  final Map<int, PaymentReceipt> invoiceToReceipt;

  final void Function(RequestPurchase)? onTapRequest;
  final void Function(InvoicePurchase)? onTapInvoice;
  final void Function(PaymentReceipt)? onTapReceipt;

  const ProcurementGraphView({
    super.key,
    required this.requests,
    required this.invoices,
    required this.receipts,
    required this.requestToInvoices,
    required this.invoiceToReceipt,
    this.onTapRequest,
    this.onTapInvoice,
    this.onTapReceipt,
  });

  Map<int, List<RequestPurchase>> get _invoiceToRequests {
    final map = <int, List<RequestPurchase>>{};
    for (final req in requests) {
      final invs = requestToInvoices[req.id] ?? [];
      for (final inv in invs) {
        map.putIfAbsent(inv.id, () => []).add(req);
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (requests.isEmpty && invoices.isEmpty && receipts.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data alur procurement.',
          style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    final invToReq = _invoiceToRequests;

    // Invoices yang sudah ter-link ke minimal 1 request (via requestToInvoices).
    final linkedInvoiceIds = <int>{};
    for (final invs in requestToInvoices.values) {
      for (final inv in invs) {
        linkedInvoiceIds.add(inv.id);
      }
    }

    // Orphan invoices = invoice yang tidak ter-link ke request manapun.
    final orphanInvoices =
        invoices.where((inv) => !linkedInvoiceIds.contains(inv.id)).toList();

    return SingleChildScrollView(
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegend(cs),
          AppSpacing.gapVerticalMD,
          ...requests.map((req) {
            final reqInvoices = requestToInvoices[req.id] ?? [];
            return _buildRequestRow(
              context: context,
              req: req,
              invoices: reqInvoices,
              invToReq: invToReq,
            );
          }),
          if (orphanInvoices.isNotEmpty) ...[
            if (requests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  'Invoice Tanpa Request',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            _buildOrphanInvoices(context, orphanInvoices),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend(ColorScheme cs) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _legendChip(cs, AppColors.primary, 'Request'),
        _legendChip(cs, AppColors.info, 'Invoice'),
        _legendChip(cs, AppColors.success, 'Kwitansi'),
      ],
    );
  }

  Widget _legendChip(ColorScheme cs, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildRequestRow({
    required BuildContext context,
    required RequestPurchase req,
    required List<InvoicePurchase> invoices,
    required Map<int, List<RequestPurchase>> invToReq,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasInvoice = invoices.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kolom Request
          SizedBox(
            width: 130,
            child: _RequestNode(
              req: req,
              onTap: onTapRequest != null ? () => onTapRequest!(req) : null,
            ),
          ),
          // Edge + Kolom Invoice
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasInvoice)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, top: 14),
                    child: Row(
                      children: [
                        _edgeLine(cs, false),
                        Text('— belum di-invoice',
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  )
                else
                  ...invoices.map((inv) {
                    final rec = invoiceToReceipt[inv.id];
                    final reqsForInv = invToReq[inv.id] ?? [];
                    final isMerged = reqsForInv.length > 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              _edgeLine(cs, true),
                              if (isMerged)
                                Container(
                                  width: 2,
                                  height: 18,
                                  color: AppColors.info.withValues(alpha: 0.5),
                                ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InvoiceNode(
                                  inv: inv,
                                  isMerged: isMerged,
                                  mergedCount: reqsForInv.length,
                                  onTap: onTapInvoice != null
                                      ? () => onTapInvoice!(inv)
                                      : null,
                                ),
                                if (rec != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _edgeLine(cs, true, color: AppColors.success),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: _ReceiptNode(
                                          rec: rec,
                                          isMerged:
                                              rec.invoicePurchases.length > 1,
                                          mergedInvoiceCount:
                                              rec.invoicePurchases.length,
                                          onTap: onTapReceipt != null
                                              ? () => onTapReceipt!(rec)
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrphanInvoices(
    BuildContext context,
    List<InvoicePurchase> orphanInvoices,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: orphanInvoices.map((inv) {
        final rec = invoiceToReceipt[inv.id];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 130,
                child: Text('—', style: TextStyle(color: cs.onSurfaceVariant)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InvoiceNode(
                      inv: inv,
                      isMerged: false,
                      onTap: onTapInvoice != null ? () => onTapInvoice!(inv) : null,
                    ),
                    if (rec != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _edgeLine(cs, true, color: AppColors.success),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _ReceiptNode(
                              rec: rec,
                              isMerged: rec.invoicePurchases.length > 1,
                              mergedInvoiceCount: rec.invoicePurchases.length,
                              onTap: onTapReceipt != null
                                  ? () => onTapReceipt!(rec)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _edgeLine(ColorScheme cs, bool done, {Color? color}) {
    return Container(
      width: 26,
      height: 2,
      margin: const EdgeInsets.only(top: 18),
      color: done
          ? (color ?? AppColors.info).withValues(alpha: 0.6)
          : cs.outlineVariant,
    );
  }
}

class _RequestNode extends StatelessWidget {
  final RequestPurchase req;
  final VoidCallback? onTap;
  const _RequestNode({required this.req, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final approved = req.detailRequests.any((i) => i.statusEnum.isPartiallyApproved);
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusSM,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.35),
          borderRadius: AppSpacing.borderRadiusSM,
          border: Border.all(
            color: approved ? AppColors.primary : cs.outlineVariant,
            width: approved ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REQ #${req.id}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(req.storeName,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _InvoiceNode extends StatelessWidget {
  final InvoicePurchase inv;
  final bool isMerged;
  final int mergedCount;
  final VoidCallback? onTap;
  const _InvoiceNode(
      {required this.inv, this.isMerged = false, this.mergedCount = 1, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final paid = inv.paymentStatus == '2';
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusSM,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: paid
              ? AppColors.success.withValues(alpha: 0.12)
              : AppColors.info.withValues(alpha: 0.12),
          borderRadius: AppSpacing.borderRadiusSM,
          border: Border.all(
            color: paid ? AppColors.success : AppColors.info,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('INV #${inv.id}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (isMerged)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('x$mergedCount',
                        style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info)),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(FormatUtils.formatCurrency(inv.totalPrice),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: paid ? AppColors.success : AppColors.info,
                  fontWeight: FontWeight.w600,
                )),
            if (inv.supplierName != null)
              Text(inv.supplierName!,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ReceiptNode extends StatelessWidget {
  final PaymentReceipt rec;
  final bool isMerged;
  final int mergedInvoiceCount;
  final VoidCallback? onTap;
  const _ReceiptNode({
    required this.rec,
    this.isMerged = false,
    this.mergedInvoiceCount = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusSM,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: AppSpacing.borderRadiusSM,
          border: Border.all(color: AppColors.success, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('KWT #${rec.id}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (isMerged)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('gabung $mergedInvoiceCount inv',
                        style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success)),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(FormatUtils.formatCurrency(rec.totalAmount),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}
