import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/procurement_model.dart';
import '../../services/procurement_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/constants.dart';
import '../../utils/format_utils.dart';

class PaymentReceiptDetailPage extends StatefulWidget {
  final int receiptId;

  const PaymentReceiptDetailPage({super.key, required this.receiptId});

  @override
  State<PaymentReceiptDetailPage> createState() =>
      _PaymentReceiptDetailPageState();
}

class _PaymentReceiptDetailPageState extends State<PaymentReceiptDetailPage> {
  final ProcurementService _procurementService = ProcurementService();
  PaymentReceipt? _receipt;
  bool _isLoading = true;
  String? _errorMessage;
  bool _qrisLoading = false;
  Map<String, dynamic>? _qrisData;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final receipt =
          await _procurementService.getPaymentReceiptDetail(widget.receiptId);
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat detail: $e';
        _isLoading = false;
      });
    }
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.');
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '${ApiConstants.baseUrl}/media/$path';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Payment Receipt'),
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
                        Text(_errorMessage!,
                            style: TextStyle(color: colorScheme.error)),
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
                        if (_receipt!.image != null)
                          _buildImageCard(theme, colorScheme),
                        if (_receipt!.supplierName != null)
                          _buildSupplierCard(theme, colorScheme),
                        _buildPaymentCard(theme, colorScheme),
                        _buildQrisCard(theme, colorScheme),
                        if (_receipt!.notes != null &&
                            _receipt!.notes!.isNotEmpty)
                          _buildNotesCard(theme, colorScheme),
                        AppSpacing.gapVerticalMD,
                        Text(
                          'Invoice Terkait (${_receipt!.invoicePurchases.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.gapVerticalSM,
                        ..._receipt!.invoicePurchases.map(
                          (inv) => _buildInvoiceCard(inv, theme, colorScheme),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildImageCard(ThemeData theme, ColorScheme colorScheme) {
    final url = _imageUrl(_receipt!.image);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.image, size: 20, color: colorScheme.primary),
                  AppSpacing.gapHorizontalSM,
                  Text(
                    'Bukti Pembayaran',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              ClipRRect(
                borderRadius: AppSpacing.borderRadiusMD,
                child: GestureDetector(
                  onTap: () => _showImageFullscreen(url),
                  child: Image.network(
                    url,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          size: 48,
                        ),
                      ),
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 200,
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageFullscreen(String url) {
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

  Widget _buildSupplierCard(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.business, size: 20, color: colorScheme.primary),
                  AppSpacing.gapHorizontalSM,
                  Text(
                    'Supplier',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(
                _receipt!.supplierName ?? '-',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt, size: 20, color: colorScheme.primary),
                  AppSpacing.gapHorizontalSM,
                  Text(
                    'Informasi Pembayaran',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              _infoRow('Tanggal', _receipt!.createdAt.substring(0, 10), theme),
              AppSpacing.gapVerticalSM,
              _infoRow(
                'Total Invoice',
                'Rp ${_formatAmount(_receipt!.totalAmount)}',
                theme,
              ),
              AppSpacing.gapVerticalSM,
              _infoRow(
                'Jumlah Transfer',
                'Rp ${_formatAmount(_receipt!.transferAmount)}',
                theme,
                valueColor: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadQris() async {
    if (_qrisLoading || _qrisData != null) return;
    setState(() => _qrisLoading = true);
    try {
      final data = await _procurementService.getPaymentReceiptQris(widget.receiptId);
      if (mounted) {
        setState(() {
          _qrisData = data;
          _qrisLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _qrisLoading = false);
    }
  }

  Widget _buildQrisCard(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.qr_code, size: 20, color: colorScheme.primary),
                  AppSpacing.gapHorizontalSM,
                  Text(
                    'QRIS Pembayaran',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              if (_qrisData != null) ...[
                Center(
                  child: QrImageView(
                    data: _qrisData!['payload'] as String,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: colorScheme.surface,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: colorScheme.onSurface,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sectionGap),
                _qrInfoRow('Merchant', _qrisData!['merchant_name'] as String?, theme),
                if (_qrisData!['merchant_nmid'] != null)
                  _qrInfoRow('NMID', _qrisData!['merchant_nmid'] as String?, theme),
                _qrInfoRow('Nominal', 'Rp ${_formatAmount(_qrisData!['amount'] as int)}', theme),
                AppSpacing.gapVerticalSM,
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: _qrisData!['payload'] as String,
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QRIS payload disalin'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Salin QRIS Payload'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                    ),
                  ),
                ),
              ] else if (_qrisLoading) ...[
                const Center(child: CircularProgressIndicator()),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loadQris,
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: const Text('Generate QRIS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _qrInfoRow(String label, String? value, ThemeData theme) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }

  Widget _buildNotesCard(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notes, size: 20, color: colorScheme.primary),
                  AppSpacing.gapHorizontalSM,
                  Text(
                    'Catatan',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapVerticalSM,
              Text(
                FormatUtils.stripHtml(_receipt!.notes!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(
      InvoicePurchase inv, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
      child: Card(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      inv.storeName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Rp ${_formatAmount(inv.totalPrice)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapVerticalXS,
              Text(
                inv.date,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (inv.detailInvoices.isNotEmpty) ...[
                const Divider(height: AppSpacing.md),
                ...inv.detailInvoices.take(3).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppSpacing.gapHorizontalSM,
                          Text(
                            '${item.quantityProduct.toStringAsFixed(0)} ${item.unitName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )),
                if (inv.detailInvoices.length > 3)
                  Text(
                    '+${inv.detailInvoices.length - 3} item lainnya',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, ThemeData theme,
      {Color? valueColor}) {
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
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
