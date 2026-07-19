import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/procurement_model.dart';
import '../../services/procurement_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/constants.dart';
import '../../utils/format_utils.dart';
import '../../utils/procurement_approval.dart';
import 'edit_invoice_page.dart';
import 'invoice_selection_page.dart';

class InvoiceDetailPage extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailPage({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  final ProcurementService _procurementService = ProcurementService();
  InvoicePurchase? _invoice;
  bool _isLoading = true;
  bool _isAdmin = false;
  int _currentUserId = 0;
  String? _errorMessage;
  List<PaymentReceipt> _paymentReceipts = [];
  bool _canReceive = false;
  bool _isReceiving = false;

  /// Compute apakah invoice punya item pending approval (cash-deviation).
  /// Asumsi: backend kirim `detail_invoice.status = 'pending_approval'` untuk
  /// item yang butuh approval. Fallback: jika field tidak ada, return false.
  bool get _hasPendingItems {
    final inv = _invoice;
    if (inv == null) return false;
    final statuses = inv.detailInvoices.map((d) => d.status).toList();
    return hasPendingApprovalItems(
      invoicePaymentTypeId: inv.paymentTypeId,
      itemStatuses: statuses,
    );
  }

  int get _pendingItemCount {
    final inv = _invoice;
    if (inv == null) return 0;
    return pendingItemCount(inv.detailInvoices.map((d) => d.status).toList());
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      final userData = json.decode(userString);
      final roles = List<String>.from(userData['roles'] ?? []);
      _isAdmin = roles.contains('admin') || roles.contains('super_admin');
      _currentUserId = userData['id'] ?? 0;
      _canReceive = roles.any((r) => ['staff', 'admin', 'super_admin'].contains(r));
    }
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final invoice = await _procurementService.getInvoiceDetail(widget.invoiceId);
      if (!mounted) return;

      List<PaymentReceipt> receipts = [];
      if (invoice.paymentStatus == '2') {
        try {
          final result = await _procurementService.getPaymentReceipts(
            invoiceId: invoice.id,
            perPage: 50,
          );
          receipts = result.items;
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _invoice = invoice;
        _paymentReceipts = receipts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat detail invoice: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToEdit() async {
    if (_invoice == null) return;
    final result = await Navigator.push<InvoicePurchase>(
      context,
      MaterialPageRoute(
        builder: (context) => EditInvoicePage(invoice: _invoice!),
      ),
    );
    if (result != null) {
      _fetchDetail();
    }
  }

  Future<void> _markAsReceived() async {
    if (_invoice == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tandai Sudah Diterima'),
        content: const Text(
          'Tandai invoice ini sudah diterima? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Tandai'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isReceiving = true);
    try {
      await _procurementService.receiveInvoice(widget.invoiceId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice ditandai sudah diterima.')),
      );
      _fetchDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isReceiving = false);
      }
    }
  }

  Color _paymentStatusColor(String status) {
    switch (status) {
      case '1': return AppColors.warning;
      case '2': return AppColors.success;
      case '3': return AppColors.error;
      default: return AppColors.onSurfaceVariant;
    }
  }

  Color _orderStatusColor(String status) {
    switch (status) {
      case '1': return AppColors.warning;
      case '2': return AppColors.success;
      case '3': return AppColors.error;
      default: return AppColors.onSurfaceVariant;
    }
  }

  Widget _buildDashedLine(Color color) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color.withValues(alpha: 0.5)),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Invoice',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isAdmin && _hasPendingItems)
            IconButton(
              icon: Badge(
                label: Text('$_pendingItemCount'),
                child: const Icon(Icons.gavel),
              ),
              tooltip: 'Approve pending items',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scroll ke item dengan status pending untuk approve.')),
                );
              },
            ),
          if (_invoice != null &&
              _invoice!.paymentStatus == '1' &&
              (_isAdmin || _invoice!.createdById == _currentUserId))
            IconButton(
              icon: const Icon(Icons.edit_note_outlined, size: 28),
              onPressed: _navigateToEdit,
              tooltip: 'Edit Invoice',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: AppSpacing.paddingLG,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                        AppSpacing.gapVerticalMD,
                        Text(_errorMessage!, style: TextStyle(color: colorScheme.error), textAlign: TextAlign.center),
                        AppSpacing.gapVerticalMD,
                        ElevatedButton.icon(
                          onPressed: _fetchDetail,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.paddingMD,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card 1: Informasi Utama Invoice (Digital Ticket/Voucher Style)
                        Card(
                          color: colorScheme.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'INVOICE PEMBELIAN',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _paymentStatusColor(_invoice!.paymentStatus).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: _paymentStatusColor(_invoice!.paymentStatus).withValues(alpha: 0.2)),
                                              ),
                                              child: Text(
                                                _invoice!.paymentStatusText,
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: _paymentStatusColor(_invoice!.paymentStatus),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _orderStatusColor(_invoice!.orderStatus).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: _orderStatusColor(_invoice!.orderStatus).withValues(alpha: 0.2)),
                                              ),
                                              child: Text(
                                                _invoice!.orderStatusText,
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: _orderStatusColor(_invoice!.orderStatus),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _invoice!.storeName,
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildDashedLine(colorScheme.outlineVariant),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _buildInfoRow('Tanggal', _invoice!.date, theme),
                                    const SizedBox(height: 8),
                                    if (_invoice!.supplierName != null) ...[
                                      _buildInfoRow('Supplier', _invoice!.supplierName!, theme),
                                      const SizedBox(height: 8),
                                    ],
                                    _buildInfoRow('Dibuat Oleh', _invoice!.createdByName, theme),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('Tipe Pembayaran', _invoice!.paymentTypeText, theme),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.gapVerticalMD,

                        // Card 2: Daftar Item Konsolidasi
                        Card(
                          color: colorScheme.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.shopping_bag_outlined, color: colorScheme.primary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Item Pembelian',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                                const SizedBox(height: 12),
                                if (_invoice!.detailInvoices.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                                    child: Center(
                                      child: Text(
                                        'Belum ada item dalam invoice ini.',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _invoice!.detailInvoices.length,
                                    separatorBuilder: (context, index) => Divider(height: 24, color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                                    itemBuilder: (context, index) {
                                      final item = _invoice!.detailInvoices[index];
                                      final unitPrice = item.unitPrice;
                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: colorScheme.secondary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.2)),
                                            ),
                                            child: Text(
                                              '${item.quantityProduct.toStringAsFixed(0)} ${item.unitName}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.secondary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.productName,
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.onSurface,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Rp ${unitPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.')} /${item.unitName}',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Rp ${item.subtotalInvoice != 0 ? item.subtotalInvoice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.') : '0'}',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        AppSpacing.gapVerticalMD,

                        // Card 3: Rincian Tagihan (Checkout Slip Style)
                        Card(
                          color: colorScheme.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.receipt_long, color: Colors.blue, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Rincian Tagihan',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                _buildInfoRow('Pajak', 'Rp ${_invoice!.taxes != 0 ? _invoice!.taxes.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.') : '0'}', theme),
                                const SizedBox(height: 8),
                                _buildInfoRow('Diskon', 'Rp ${_invoice!.discounts != 0 ? _invoice!.discounts.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.') : '0'}', theme),
                                const SizedBox(height: 16),
                                _buildDashedLine(colorScheme.outlineVariant),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'TOTAL AKHIR',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      'Rp ${_invoice!.totalPrice != 0 ? _invoice!.totalPrice.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.') : '0'}',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Catatan (jika ada)
                        if (_invoice!.notes != null && _invoice!.notes!.isNotEmpty) ...[
                          AppSpacing.gapVerticalMD,
                          Card(
                            color: colorScheme.surface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.notes, color: colorScheme.primary, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Catatan',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    FormatUtils.stripHtml(_invoice!.notes!),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        
                        // Bukti Pembayaran / Lampiran (jika ada)
                        if (_invoice!.paymentStatus == '2' && _paymentReceipts.isNotEmpty) ...[
                          AppSpacing.gapVerticalMD,
                          ..._paymentReceipts.map((receipt) {
                            final multi = receipt.invoicePurchases.length > 1;
                            return Card(
                              color: colorScheme.surface,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle, size: 20, color: AppColors.success),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Transaksi Pembayaran Sukses',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (receipt.image != null && receipt.image!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: GestureDetector(
                                          onTap: () => _showReceiptImage(_imageUrl(receipt.image)),
                                          child: Stack(
                                            alignment: Alignment.bottomCenter,
                                            children: [
                                              Image.network(
                                                _imageUrl(receipt.image),
                                                height: 180,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                                loadingBuilder: (_, child, progress) {
                                                  if (progress == null) return child;
                                                  return Container(
                                                    height: 180,
                                                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                                    child: const Center(child: CircularProgressIndicator()),
                                                  );
                                                },
                                              ),
                                              Container(
                                                width: double.infinity,
                                                color: Colors.black.withValues(alpha: 0.6),
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Ketuk untuk memperbesar gambar',
                                                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    _buildInfoRow('Jumlah Transfer', 'Rp ${FormatUtils.formatNumber(receipt.transferAmount)}', theme),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('Tanggal Verifikasi', receipt.createdAt.substring(0, 10), theme),
                                    if (multi) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        'Tergabung dalam pembayaran ${receipt.invoicePurchases.length} invoice',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
      bottomSheet: _hasPendingItems
          ? Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_pendingItemCount item butuh approval. Invoice tidak bisa dibayar sampai disetujui.',
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          : ((_invoice != null &&
                  _invoice!.paymentStatus == '1' &&
                  _invoice!.paymentTypeId == 1 &&
                  _isAdmin) ||
              (_invoice != null &&
                  _invoice!.orderStatus == '1' &&
                  _canReceive)
              ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Existing: Buat Payment Receipt (admin + draft + transfer type)
                  if (_invoice != null &&
                      _invoice!.paymentStatus == '1' &&
                      _invoice!.paymentTypeId == 1 &&
                      _isAdmin) ...[
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InvoiceSelectionPage(
                                  initialSelectedIds: {_invoice!.id},
                                ),
                              ),
                            );
                            if (result != null) {
                              _fetchDetail();
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.payments, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Buat Payment Receipt',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.gapVerticalSM,
                  ],
                  // New: Tandai Sudah Diterima (staff/admin/super_admin + order_status 1)
                  if (_invoice != null &&
                      _invoice!.orderStatus == '1' &&
                      _canReceive)
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isReceiving ? null : _markAsReceived,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: _isReceiving
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tandai Sudah Diterima',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
              : null),
    );
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '${ApiConstants.baseUrl}/media/$path';
  }

  void _showReceiptImage(String url) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.87),
            iconTheme: IconThemeData(color: colorScheme.surface),
            title: Text('Bukti Pembayaran',
                style: TextStyle(color: colorScheme.surface)),
          ),
          body: Container(
            color: Colors.black,
            child: Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.broken_image,
                    color: colorScheme.surface.withValues(alpha: 0.54),
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
