import 'package:flutter/material.dart';
import '../../models/procurement_model.dart';
import '../../services/procurement_service.dart';
import '../../services/supplier_service.dart';
import '../../theme/app_spacing.dart';

class CreateInvoicePage extends StatefulWidget {
  final int requestId;
  final List<DetailRequestItem> approvedItems;

  const CreateInvoicePage({
    super.key,
    required this.requestId,
    required this.approvedItems,
  });

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final ProcurementService _procurementService = ProcurementService();
  bool _isSubmitting = false;

  int? _selectedSupplierId;
  String _selectedSupplierName = '';
  List<Map<String, dynamic>> _itemStates = [];

  @override
  void initState() {
    super.initState();
    _itemStates = widget.approvedItems.map((item) {
      return {
        'detailRequest': item,
        'selected': true,
        'priceController': TextEditingController(text: '0'),
        'qtyController': TextEditingController(
          text: item.quantityPlan.toStringAsFixed(item.quantityPlan == item.quantityPlan.roundToDouble() ? 0 : 2),
        ),
      };
    }).toList();
  }

  @override
  void dispose() {
    for (var state in _itemStates) {
      (state['priceController'] as TextEditingController).dispose();
      (state['qtyController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  int get _totalPrice {
    int total = 0;
    for (var state in _itemStates) {
      if (state['selected'] == true) {
        final price = int.tryParse((state['priceController'] as TextEditingController).text) ?? 0;
        final qty = int.tryParse((state['qtyController'] as TextEditingController).text) ?? 0;
        total += price * qty;
      }
    }
    return total;
  }

  Future<void> _pickSupplier() async {
    final supplierService = SupplierService();
    List<dynamic> suppliers;
    try {
      final list = await supplierService.getSuppliers();
      suppliers = list.map((s) => {'id': s.id, 'name': s.name}).toList();
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

    final result = await _showSupplierSearchDialog(suppliers);
    if (result != null) {
      setState(() {
        _selectedSupplierId = result['id'];
        _selectedSupplierName = result['name'];
      });
    }
  }

  Future<Map<String, dynamic>?> _showSupplierSearchDialog(List<dynamic> suppliers) async {
    String query = '';
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = suppliers.where((s) {
              if (query.isEmpty) return true;
              return (s['name'] ?? '').toString().toLowerCase().contains(query.toLowerCase());
            }).toList();

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xxl + AppSpacing.xl,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: AppSpacing.paddingSM,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Cari supplier...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (v) => setDialogState(() => query = v),
                      autofocus: true,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('Tidak ada supplier'))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) => ListTile(
                              title: Text(filtered[i]['name'] ?? ''),
                              onTap: () => Navigator.pop(ctx, {
                                'id': filtered[i]['id'],
                                'name': filtered[i]['name'],
                              }),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih supplier terlebih dahulu.')),
      );
      return;
    }

    final selectedItems = _itemStates.where((s) => s['selected'] == true).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 item.')),
      );
      return;
    }

    final items = selectedItems.map((s) {
      final detailRequest = s['detailRequest'] as DetailRequestItem;
      return {
        'detail_request_id': detailRequest.id,
        'price': int.tryParse((s['priceController'] as TextEditingController).text) ?? 0,
        'quantity': int.tryParse((s['qtyController'] as TextEditingController).text) ?? 0,
      };
    }).toList();

    setState(() => _isSubmitting = true);
    try {
      final invoiceId = await _procurementService.createInvoice(
        widget.requestId,
        supplierId: _selectedSupplierId!,
        items: items,
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
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: AppSpacing.paddingMD,
                    children: [
                      // Supplier selector
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
                              color: _selectedSupplierName.isEmpty ? colorScheme.onSurfaceVariant : null,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapVerticalLG,
                      Text(
                        'Pilih Item & Masukkan Harga',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: AppSpacing.sectionGap),
                      ..._itemStates.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final state = entry.value;
                        final detailRequest = state['detailRequest'] as DetailRequestItem;
                        final priceCtrl = state['priceController'] as TextEditingController;
                        final qtyCtrl = state['qtyController'] as TextEditingController;
                        final isSelected = state['selected'] as bool;

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
                                      value: isSelected,
                                      onChanged: (val) {
                                        setState(() => _itemStates[idx]['selected'] = val);
                                      },
                                    ),
                                    Expanded(
                                      child: Text(
                                        detailRequest.productName,
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSelected) ...[
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
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                // Bottom bar with total + submit
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
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
