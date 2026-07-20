import 'package:flutter/material.dart';
import '../../models/procurement_model.dart';
import '../../services/procurement_service.dart';
import '../../services/supplier_service.dart';
import '../../theme/app_spacing.dart';
import '../widgets/supplier_picker_modal.dart';

class EditInvoicePage extends StatefulWidget {
  final InvoicePurchase invoice;

  const EditInvoicePage({super.key, required this.invoice});

  @override
  State<EditInvoicePage> createState() => _EditInvoicePageState();
}

class _EditInvoicePageState extends State<EditInvoicePage> {
  final ProcurementService _procurementService = ProcurementService();
  bool _isSubmitting = false;

  int? _selectedSupplierId;
  String _selectedSupplierName = '';
  final _taxesController = TextEditingController();
  final _discountsController = TextEditingController();
  final _notesController = TextEditingController();
  List<Map<String, dynamic>> _itemStates = [];

  @override
  void initState() {
    super.initState();
    _selectedSupplierId = widget.invoice.supplierId;
    _selectedSupplierName = widget.invoice.supplierName ?? '';
    _taxesController.text = widget.invoice.taxes.toString();
    _discountsController.text = widget.invoice.discounts.toString();
    _notesController.text = widget.invoice.notes ?? '';
    _itemStates = widget.invoice.detailInvoices.map((item) {
      return {
        'detailInvoice': item,
        'priceController': TextEditingController(
          text: item.unitPrice.toStringAsFixed(0),
        ),
        'qtyController': TextEditingController(
          text: item.quantityProduct.toStringAsFixed(
            item.quantityProduct == item.quantityProduct.roundToDouble() ? 0 : 2,
          ),
        ),
      };
    }).toList();
  }

  @override
  void dispose() {
    _taxesController.dispose();
    _discountsController.dispose();
    _notesController.dispose();
    for (var state in _itemStates) {
      (state['priceController'] as TextEditingController).dispose();
      (state['qtyController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  int get _totalPrice {
    int total = 0;
    for (var state in _itemStates) {
      final price = int.tryParse((state['priceController'] as TextEditingController).text) ?? 0;
      final qty = int.tryParse((state['qtyController'] as TextEditingController).text) ?? 0;
      total += price * qty;
    }
    final taxes = int.tryParse(_taxesController.text) ?? 0;
    final discounts = int.tryParse(_discountsController.text) ?? 0;
    return total + taxes - discounts;
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

    setState(() => _isSubmitting = true);
    try {
      final updated = await _procurementService.updateInvoice(
        widget.invoice.id,
        supplierId: _selectedSupplierId,
        paymentTypeId: widget.invoice.paymentTypeId,
        taxes: int.tryParse(_taxesController.text) ?? 0,
        discounts: int.tryParse(_discountsController.text) ?? 0,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        items: _itemStates.map((s) {
          final detail = s['detailInvoice'] as DetailInvoiceItem;
          return {
            'detail_invoice_id': detail.id,
            'price': int.tryParse((s['priceController'] as TextEditingController).text) ?? 0,
            'quantity': int.tryParse((s['qtyController'] as TextEditingController).text) ?? 0,
          };
        }).toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice berhasil diperbarui.')),
      );
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui invoice: $e')),
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
        title: const Text('Edit Invoice'),
      ),
      body: _isSubmitting
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
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: _selectedSupplierName.isEmpty
                                  ? Theme.of(context).colorScheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapVerticalLG,
                      Text(
                        'Item & Harga',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: AppSpacing.sectionGap),
                      ..._itemStates.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final state = entry.value;
                        final detail = state['detailInvoice'] as DetailInvoiceItem;
                        final priceCtrl = state['priceController'] as TextEditingController;
                        final qtyCtrl = state['qtyController'] as TextEditingController;

                        return Card(
                          margin: EdgeInsets.only(bottom: AppSpacing.sectionGap),
                          child: Padding(
                            padding: AppSpacing.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detail.productName,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                AppSpacing.gapVerticalSM,
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: qtyCtrl,
                                        decoration: InputDecoration(
                                          labelText: 'Jumlah',
                                          suffixText: detail.unitName,
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
                                          labelText: 'Harga Satuan',
                                          prefixText: 'Rp ',
                                          isDense: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setState(() {}),
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
                      TextFormField(
                        controller: _taxesController,
                        decoration: const InputDecoration(
                          labelText: 'Pajak',
                          prefixText: 'Rp ',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                      AppSpacing.gapVerticalSM,
                      TextFormField(
                        controller: _discountsController,
                        decoration: const InputDecoration(
                          labelText: 'Diskon',
                          prefixText: 'Rp ',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                      AppSpacing.gapVerticalSM,
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: AppSpacing.paddingMD,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'Rp ${_totalPrice.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m.group(1)}.')}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.gapHorizontalMD,
                        ElevatedButton(
                          onPressed: _submit,
                          child: Text(
                            'Simpan',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
    }
