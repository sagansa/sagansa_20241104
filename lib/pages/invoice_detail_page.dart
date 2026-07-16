import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/procurement_model.dart';
import '../../services/procurement_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/constants.dart';
import '../../utils/format_utils.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Invoice'),
        actions: _invoice != null &&
                _invoice!.paymentStatus == '1' &&
                (_isAdmin || _invoice!.createdById == _currentUserId)
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _navigateToEdit,
                  tooltip: 'Edit Invoice',
                ),
              ]
            : null,
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
                        Text(_errorMessage!, style: TextStyle(color: colorScheme.error)),
                        AppSpacing.gapVerticalMD,
                        ElevatedButton(
                          onPressed: _fetchDetail,
                          child: const Text('Coba Lagi'),
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
                        Card(
                          child: Padding(
                            padding: AppSpacing.paddingMD,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Informasi Invoice',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                AppSpacing.gapVerticalMD,
                                _buildInfoRow('Toko', _invoice!.storeName, theme),
                                AppSpacing.gapVerticalSM,
                                _buildInfoRow('Tanggal', _invoice!.date, theme),
                                AppSpacing.gapVerticalSM,
                                if (_invoice!.supplierName != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: _buildInfoRow('Supplier', _invoice!.supplierName!, theme),
                                  ),
                                _buildInfoRow('Dibuat oleh', _invoice!.createdByName, theme),
                                AppSpacing.gapVerticalSM,
                                _buildInfoRow('Tipe Pembayaran', _invoice!.paymentTypeText, theme),
                                AppSpacing.gapVerticalSM,
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: _paymentStatusColor(_invoice!.paymentStatus).withValues(alpha: 0.1),
                                        borderRadius: AppSpacing.borderRadiusXL,
                                      ),
                                      child: Text(
                                        _invoice!.paymentStatusText,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: _paymentStatusColor(_invoice!.paymentStatus),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    AppSpacing.gapHorizontalSM,
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: _orderStatusColor(_invoice!.orderStatus).withValues(alpha: 0.1),
                                        borderRadius: AppSpacing.borderRadiusXL,
                                      ),
                                      child: Text(
                                        _invoice!.orderStatusText,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: _orderStatusColor(_invoice!.orderStatus),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        AppSpacing.gapVerticalMD,
                        Text(
                          'Daftar Item',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.gapVerticalSM,
                        if (_invoice!.detailInvoices.isEmpty)
                          Center(
                            child: Padding(
                              padding: AppSpacing.paddingLG,
                              child: Text(
                                'Belum ada item dalam invoice ini.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          )
                        else
                          ..._invoice!.detailInvoices.map((item) {
                            final unitPrice = item.unitPrice;
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Padding(
                                padding: AppSpacing.cardPadding,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    AppSpacing.gapVerticalSM,
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _infoRowSimple('Harga',
                                            'Rp ${unitPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.')} /${item.unitName}',
                                            theme),
                                        ),
                                        AppSpacing.gapHorizontalSM,
                                        Text(
                                          '${item.quantityProduct.toStringAsFixed(0)} ${item.unitName}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    AppSpacing.gapVerticalXS,
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Subtotal',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          'Rp ${item.subtotalInvoice != 0 ? item.subtotalInvoice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.') : '0'}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        AppSpacing.gapVerticalMD,
                        Card(
                          child: Padding(
                            padding: AppSpacing.paddingMD,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rincian Harga',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                AppSpacing.gapVerticalMD,
                                _buildInfoRow('Pajak', 'Rp ${_invoice!.taxes != 0 ? _invoice!.taxes.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.') : '0'}', theme),
                                AppSpacing.gapVerticalSM,
                                _buildInfoRow('Diskon', 'Rp ${_invoice!.discounts != 0 ? _invoice!.discounts.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.') : '0'}', theme),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Rp ${_invoice!.totalPrice != 0 ? _invoice!.totalPrice.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.') : '0'}',
                                      style: theme.textTheme.titleMedium?.copyWith(
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
                        if (_invoice!.notes != null && _invoice!.notes!.isNotEmpty) ...[
                          AppSpacing.gapVerticalMD,
                          Card(
                          child: Padding(
                            padding: AppSpacing.paddingMD,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Catatan',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  AppSpacing.gapVerticalSM,
                                  Text(
                                    FormatUtils.stripHtml(_invoice!.notes!),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (_invoice!.paymentStatus == '2' && _paymentReceipts.isNotEmpty) ...[
                          AppSpacing.gapVerticalMD,
                          ..._paymentReceipts.map((receipt) {
                            final multi = receipt.invoicePurchases.length > 1;
                            return Card(
                              child: Padding(
                                padding: AppSpacing.paddingMD,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle, size: 20, color: AppColors.success),
                                        AppSpacing.gapHorizontalSM,
                                        Text(
                                          'Pembayaran',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (receipt.image != null && receipt.image!.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.sectionGap),
                                      ClipRRect(
                                        borderRadius: AppSpacing.borderRadiusMD,
                                        child: GestureDetector(
                                          onTap: () => _showReceiptImage(_imageUrl(receipt.image)),
                                          child: Image.network(
                                            _imageUrl(receipt.image),
                                            height: 160,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                            loadingBuilder: (_, child, progress) {
                                              if (progress == null) return child;
                                              return Container(
                                                height: 160,
                                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                                child: const Center(child: CircularProgressIndicator()),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.sectionGap),
                                    _buildInfoRow('Total', 'Rp ${FormatUtils.formatNumber(receipt.transferAmount)}', theme),
                                    AppSpacing.gapVerticalXS,
                                    _buildInfoRow('Tanggal', receipt.createdAt.substring(0, 10), theme),
                                    if (multi) ...[
                                      AppSpacing.gapVerticalSM,
                                      Text(
                                        'Tergabung dalam pembayaran ${receipt.invoicePurchases.length} invoice',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
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
      bottomSheet: (_invoice != null &&
              _invoice!.paymentStatus == '1' &&
              _invoice!.paymentTypeId == 1 &&
              _isAdmin) ||
              (_invoice != null &&
                  _invoice!.orderStatus == '1' &&
                  _canReceive)
          ? Container(
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: colorScheme.surface,
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
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
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                        ),
                        icon: const Icon(Icons.payments),
                        label: const Text(
                          'Buat Payment Receipt',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    AppSpacing.gapVerticalSM,
                  ],
                  // New: Tandai Sudah Diterima (staff/admin/super_admin + order_status 1)
                  if (_invoice != null &&
                      _invoice!.orderStatus == '1' &&
                      _canReceive)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isReceiving ? null : _markAsReceived,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                        icon: _isReceiving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(
                          _isReceiving ? 'Memproses...' : 'Tandai Sudah Diterima',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            )
          : null,
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

  Widget _infoRowSimple(String label, String value, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapHorizontalXS,
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
