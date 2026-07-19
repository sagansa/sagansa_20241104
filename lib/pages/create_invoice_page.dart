import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/procurement_model.dart';
import '../../services/procurement_service.dart';
import '../../services/supplier_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/procurement_approval.dart';
import '../widgets/supplier_picker_modal.dart';
import '../widgets/supplier_payment_info_card.dart';

class CreateInvoicePage extends StatefulWidget {
  final int requestId;
  final List<int>? requestIds;
  final List<DetailRequestItem>? approvedItems;

  const CreateInvoicePage({
    super.key,
    required this.requestId,
    this.requestIds,
    this.approvedItems,
  });

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final ProcurementService _procurementService = ProcurementService();
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  bool _isSubmitting = false;
  bool _isLoading = true;

  int? _selectedSupplierId;
  String _selectedSupplierName = '';
  Map<String, dynamic>? _selectedSupplier;

  // Payment type: 1 = Transfer, 2 = Tunai (default Transfer)
  int _selectedPaymentTypeId = 1;

  /// Setiap item state terikat ke request asalnya (untuk invoice lintas-request).
  List<_ItemState> _itemStates = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      // Jika approvedItems sudah diberikan (single request), gunakan apa adanya.
      if (widget.approvedItems != null) {
        _seedItems({
          widget.requestId: widget.approvedItems!,
        });
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Beberapa request -> kumpulkan item approved dari tiap request.
      final ids = widget.requestIds ?? [widget.requestId];
      final Map<int, List<DetailRequestItem>> grouped = {};
      for (final id in ids) {
        final req = await _procurementService.getRequestDetail(id);
        grouped[id] = req.detailRequests
            .where((i) => i.status == '4' || i.status == '2')
            .toList();
      }
      if (mounted) {
        _seedItems(grouped);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat item: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _seedItems(Map<int, List<DetailRequestItem>> grouped) {
    _itemStates = grouped.entries.expand((entry) {
      final reqId = entry.key;
      return entry.value.map((item) {
        return _ItemState(
          requestId: reqId,
          detailRequest: item,
          priceController: TextEditingController(text: '0'),
          qtyCtrl: TextEditingController(
            text: item.quantityPlan
                .toStringAsFixed(item.quantityPlan == item.quantityPlan.roundToDouble() ? 0 : 2),
          ),
        );
      });
    }).toList();
  }

  @override
  void dispose() {
    for (var state in _itemStates) {
      state.priceController.dispose();
      state.qtyCtrl.dispose();
    }
    super.dispose();
  }

  int get _totalPrice {
    int total = 0;
    for (var state in _itemStates) {
      if (state.selected) {
        final totalPrice =
            double.tryParse(state.priceController.text) ?? 0;
        total += totalPrice.round();
      }
    }
    return total;
  }

  Future<void> _pickSupplier() async {
    final supplierService = SupplierService();
    List<dynamic> suppliers;
    try {
      final list = await supplierService.getSuppliers();
      suppliers = list.map((s) => {
            'id': s.id,
            'name': s.name,
            'address': s.address,
            'no_telp': s.noTelp,
            'bank_name': s.bankName,
            'bank_account_name': s.bankAccountName,
            'bank_account_no': s.bankAccountNo,
            'qris': s.qris,
          }).toList();
    } catch (_) {
      suppliers = [];
    }

    if (suppliers.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada supplier tersedia.')),
      );
      return;
    }

    final result = await SupplierPickerModal.show(
      context: context,
      suppliers: suppliers,
      selectedSupplierId: _selectedSupplierId,
    );
    if (result != null) {
      setState(() {
        _selectedSupplierId = result['id'];
        _selectedSupplierName = result['name'];
        _selectedSupplier = result;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih supplier terlebih dahulu.')),
      );
      return;
    }

    final selectedStates = _itemStates.where((s) => s.selected).toList();
    if (selectedStates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 item.')),
      );
      return;
    }

    final items = selectedStates.map((s) {
      final totalPrice = double.tryParse(s.priceController.text) ?? 0;
      final qty = double.tryParse(s.qtyCtrl.text) ?? 0;
      final unitPrice = qty > 0 ? (totalPrice / qty).round() : 0;

      // Compute cash-deviation flag (spec section 6.1)
      final needsApproval = needsCashDeviationApproval(
        invoicePaymentTypeId: _selectedPaymentTypeId,
        productPaymentTypeId: s.detailRequest.paymentTypeId,
      );

      return {
        'detail_request_id': s.detailRequest.id,
        'price': unitPrice,
        'quantity': qty.toInt(),
        if (needsApproval) 'needs_approval': true,
        if (needsApproval) 'status': kPendingApprovalStatus,
      };
    }).toList();

    // Kirim semua request-id terlibat agar backend mengizinkan item lintas-request.
    final allRequestIds = _itemStates.map((s) => s.requestId).toSet().toList();

    setState(() => _isSubmitting = true);
    try {
      final invoiceId = await _procurementService.createInvoice(
        widget.requestId,
        supplierId: _selectedSupplierId!,
        items: items,
        requestIds: allRequestIds,
        paymentTypeId: _selectedPaymentTypeId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice berhasil dibuat.')),
      );
      Navigator.pop(context, invoiceId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat invoice: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Invoice'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: AppSpacing.paddingMD,
                        children: [
                          InkWell(
                            onTap: _pickSupplier,
                            borderRadius: AppSpacing.borderRadiusXS,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Pilih Supplier *',
                                suffixIcon: Icon(Icons.search),
                              ),
                              child: Text(
                                _selectedSupplierName,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: _selectedSupplierName.isEmpty
                                      ? colorScheme.onSurfaceVariant
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          if (_selectedSupplier != null) ...[
                            const SizedBox(height: 4),
                            SupplierPaymentInfoCard(selectedSupplier: _selectedSupplier),
                          ],
                          AppSpacing.gapVerticalLG,
                          // Payment Type Selector
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Tipe Pembayaran Invoice',
                              prefixIcon: Icon(Icons.payment),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedPaymentTypeId,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('💳 Transfer (bank)')),
                                  DropdownMenuItem(value: 2, child: Text('💵 Tunai (cash)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedPaymentTypeId = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          if (_selectedPaymentTypeId == 2)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                border: Border.all(color: Colors.orange.shade200),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade700),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Item dengan tipe Transfer akan butuh approval admin (cash deviation).',
                                      style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          AppSpacing.gapVerticalLG,
                          Text(
                            'Pilih Item & Masukkan Harga',
                            style: textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: AppSpacing.sectionGap),
                          ..._buildGroupedItems(theme, colorScheme),
                        ],
                      ),
                    ),
                    Container(
                      padding: AppSpacing.paddingMD,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border(
                          top: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Total',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_totalPrice.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m.group(1)}.')}',
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppSpacing.gapHorizontalMD,
                            ElevatedButton(
                              onPressed: _submit,
                              child: Text(
                                'Buat Invoice',
                                style: textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  List<Widget> _buildGroupedItems(ThemeData theme, ColorScheme colorScheme) {
    // Kelompokkan item berdasarkan request asal agar user tahu item dari req mana.
    final Map<int, List<_ItemState>> grouped = {};
    for (final s in _itemStates) {
      grouped.putIfAbsent(s.requestId, () => []).add(s);
    }

    final widgets = <Widget>[];
    grouped.forEach((reqId, states) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4, top: 8),
          child: Text(
            'Request #$reqId',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
          ),
        ),
      );
      for (final state in states) {
        widgets.add(_buildItemCard(state, theme, colorScheme));
      }
    });
    return widgets;
  }

  Widget _buildItemCard(_ItemState state, ThemeData theme, ColorScheme colorScheme) {
    final detailRequest = state.detailRequest;
    final priceCtrl = state.priceController;
    final qtyCtrl = state.qtyCtrl;

    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sectionGap),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: state.selected,
                  onChanged: (val) {
                    setState(() => state.selected = val ?? false);
                  },
                ),
                Expanded(
                  child: Text(
                    detailRequest.productName,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (state.selected) ...[
              AppSpacing.gapVerticalSM,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: qtyCtrl,
                      decoration: InputDecoration(
                        labelText: 'Jumlah',
                        suffixText: detailRequest.unitName,
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                  Expanded(
                    child: TextFormField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Harga Total',
                        prefixText: 'Rp ',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              Builder(
                builder: (_) {
                  final totalPrice = double.tryParse(priceCtrl.text) ?? 0;
                  final qty = double.tryParse(qtyCtrl.text) ?? 0;
                  final unitPrice = qty > 0 ? (totalPrice / qty) : 0.0;
                  if (totalPrice <= 0) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calculate_outlined,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Harga Satuan: ${_currencyFormatter.format(unitPrice.round())} / ${detailRequest.unitName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemState {
  final int requestId;
  final DetailRequestItem detailRequest;
  final TextEditingController priceController;
  final TextEditingController qtyCtrl;
  bool selected = true;

  _ItemState({
    required this.requestId,
    required this.detailRequest,
    required this.priceController,
    required this.qtyCtrl,
  });
}
