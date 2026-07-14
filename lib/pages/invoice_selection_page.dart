import 'package:flutter/material.dart';
import '../../models/procurement_model.dart';
import '../../services/procurement_service.dart';
import '../../theme/app_spacing.dart';
import 'create_payment_receipt_page.dart';
import '../../widgets/list_thumbnail.dart';

class InvoiceSelectionPage extends StatefulWidget {
  final Set<int> initialSelectedIds;

  const InvoiceSelectionPage({
    super.key,
    this.initialSelectedIds = const {},
  });

  @override
  State<InvoiceSelectionPage> createState() => _InvoiceSelectionPageState();
}

class _InvoiceSelectionPageState extends State<InvoiceSelectionPage> {
  final ProcurementService _procurementService = ProcurementService();
  List<InvoicePurchase> _invoices = [];
  Set<int> _selectedIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelectedIds);
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _procurementService.getInvoices(
        paymentStatus: '1',
        perPage: 50,
      );
      if (!mounted) return;
      setState(() {
        _invoices = result.items.where((inv) => inv.paymentTypeId == 1).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat invoice: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _proceed() {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu invoice')),
      );
      return;
    }
    final selected =
        _invoices.where((inv) => _selectedIds.contains(inv.id)).toList();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePaymentReceiptPage(invoices: selected),
      ),
    );
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Invoice'),
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
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: _fetchInvoices,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _invoices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 48,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5)),
                          AppSpacing.gapVerticalMD,
                          Text('Tidak ada invoice Transfer yang belum dibayar.',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _fetchInvoices,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 16, 16, 100),
                              itemCount: _invoices.length,
                              itemBuilder: (context, idx) {
                                final inv = _invoices[idx];
                                final selected =
                                    _selectedIds.contains(inv.id);
                          return Card(
                                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                                  child: InkWell(
                                    borderRadius: AppSpacing.borderRadiusLG,
                                    onTap: () => _toggleSelection(inv.id),
                                    child: Padding(
                                      padding: AppSpacing.cardPadding,
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: selected,
                                            onChanged: (_) =>
                                                _toggleSelection(inv.id),
                                          ),
                                          AppSpacing.gapHorizontalSM,
                                          const ListThumbnail(
                                            placeholderIcon: Icons.receipt_long,
                                          ),
                                          AppSpacing.gapHorizontalSM,
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(inv.storeName,
                                                    style: theme
                                                        .textTheme.bodyMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                const SizedBox(height: AppSpacing.xs),
                                                Text(
                                                  '${inv.supplierName ?? "-"} • ${inv.date}',
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            'Rp ${_formatAmount(inv.totalPrice)}',
                                            style: theme
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(
                              16, 12, 16, 24),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            border: Border(
                              top: BorderSide(
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                ),
                                onPressed:
                                    _selectedIds.isEmpty ? null : _proceed,
                                icon: const Icon(Icons.payments),
                                label: Text(
                                  'Buat Payment Receipt (${_selectedIds.length})',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
