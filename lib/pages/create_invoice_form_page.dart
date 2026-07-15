import 'package:flutter/material.dart';
import '../../models/procurement_model.dart';
import '../../services/procurement_service.dart';
import '../../services/supplier_service.dart';
import '../../services/presence_service.dart';
import '../../theme/app_spacing.dart';

class CreateInvoiceFormPage extends StatefulWidget {
  const CreateInvoiceFormPage({super.key});

  @override
  State<CreateInvoiceFormPage> createState() => _CreateInvoiceFormPageState();
}

class _CreateInvoiceFormPageState extends State<CreateInvoiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ProcurementService _procurementService = ProcurementService();
  final SupplierService _supplierService = SupplierService();

  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  int? _selectedSupplierId;
  String _selectedSupplierName = '';
  int? _storeId;
  String _storeName = '';
  int _paymentTypeId = 2;
  DateTime _selectedDate = DateTime.now();
  int _taxes = 0;
  int _discounts = 0;
  final _taxesController = TextEditingController(text: '0');
  final _discountsController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _detailRequests = [];
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _taxesController.dispose();
    _discountsController.dispose();
    _notesController.dispose();
    for (var item in _items) {
      (item['priceCtrl'] as TextEditingController).dispose();
      (item['qtyCtrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final presence = await PresenceService.getUserPresence();
      final today = presence['data']?['today'];
      final storeId = today?['store_id'];
      final storeName = today?['store'] ?? '';

      if (storeId == null) {
        setState(() {
          _errorMessage = 'Anda belum melakukan clock-in.';
          _isLoadingData = false;
        });
        return;
      }

      _storeId = int.tryParse(storeId.toString());
      _storeName = storeName.toString();

      final requests = await _procurementService.getDetailRequests(
        storeId: _storeId!,
        paymentTypeId: _paymentTypeId,
      );
      setState(() {
        _detailRequests = requests;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoadingData = false;
      });
    }
  }

  Future<void> _reloadDetailRequests(int paymentTypeId) async {
    if (_storeId == null) return;
    try {
      final requests = await _procurementService.getDetailRequests(
        storeId: _storeId!,
        paymentTypeId: paymentTypeId,
      );
      setState(() => _detailRequests = requests);
    } catch (_) {}
  }

  void _addItem() {
    setState(() {
      _items.add({
        'detail_request_id': null,
        'productName': null,
        'unitName': null,
        'priceCtrl': TextEditingController(text: '0'),
        'qtyCtrl': TextEditingController(text: '1'),
      });
    });
  }

  void _removeItem(int index) {
    (_items[index]['priceCtrl'] as TextEditingController).dispose();
    (_items[index]['qtyCtrl'] as TextEditingController).dispose();
    setState(() => _items.removeAt(index));
  }

  int _itemSubtotal(Map<String, dynamic> item) {
    final price = int.tryParse((item['priceCtrl'] as TextEditingController).text) ?? 0;
    final qty = int.tryParse((item['qtyCtrl'] as TextEditingController).text) ?? 0;
    return price * qty;
  }

  int get _subtotalPrice {
    int total = 0;
    for (var item in _items) {
      if (item['detail_request_id'] != null) {
        total += _itemSubtotal(item);
      }
    }
    return total;
  }

  int get _totalPrice => _subtotalPrice + _taxes - _discounts;

  Future<void> _pickSupplier() async {
    List<dynamic> suppliers;
    try {
      final list = await _supplierService.getSuppliers();
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

    String query = '';
    final result = await showDialog<Map<String, dynamic>>(
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
    if (result != null) {
      setState(() {
        _selectedSupplierId = result['id'];
        _selectedSupplierName = result['name'];
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih supplier terlebih dahulu.')),
      );
      return;
    }
    if (_items.isEmpty || _items.every((i) => i['detail_request_id'] == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 item produk.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final items = _items.where((i) => i['detail_request_id'] != null).map((i) {
        return {
          'detail_request_id': i['detail_request_id'],
          'quantity_product': int.tryParse((i['qtyCtrl'] as TextEditingController).text) ?? 1,
          'subtotal_invoice': _itemSubtotal(i),
        };
      }).toList();

      await _procurementService.createInvoiceStandalone(
        supplierId: _selectedSupplierId!,
        storeId: _storeId!,
        paymentTypeId: _paymentTypeId,
        date: dateStr,
        items: items,
        taxes: _taxes,
        discounts: _discounts,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice berhasil dibuat.')),
      );
      Navigator.pop(context, true);
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
      body: _isLoadingData
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
                        Text(_errorMessage!, style: TextStyle(color: colorScheme.error)),
                      ],
                    ),
                  ),
                )
              : _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: AppSpacing.paddingMD,
                            children: [
                              Card(
                                child: Padding(
                                  padding: AppSpacing.paddingMD,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Informasi Toko & Supplier',
                                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                      AppSpacing.gapVerticalSM,
                                      Row(
                                        children: [
                                          Icon(Icons.store, size: 20, color: colorScheme.onSurfaceVariant),
                                          AppSpacing.gapHorizontalSM,
                                          Text(_storeName,
                                              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      AppSpacing.gapVerticalSM,
                                      InkWell(
                                        onTap: _pickSupplier,
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'Supplier *',
                                            suffixIcon: Icon(Icons.search),
                                            isDense: true,
                                          ),
                                          child: Text(
                                            _selectedSupplierName.isEmpty
                                                ? 'Pilih supplier'
                                                : _selectedSupplierName,
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: _selectedSupplierName.isEmpty
                                                  ? colorScheme.onSurfaceVariant
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                      AppSpacing.gapVerticalSM,
                                      DropdownButtonFormField<int>(
                                        value: _paymentTypeId,
                                        decoration: const InputDecoration(
                                          labelText: 'Tipe Pembayaran *',
                                          isDense: true,
                                        ),
                                        items: [
                                          const DropdownMenuItem(value: 1, child: Text('Transfer')),
                                          const DropdownMenuItem(value: 2, child: Text('Tunai')),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _paymentTypeId = val);
                                            _reloadDetailRequests(val);
                                          }
                                        },
                                      ),
                                      AppSpacing.gapVerticalSM,
                                      InkWell(
                                        onTap: _pickDate,
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'Tanggal',
                                            prefixIcon: Icon(Icons.calendar_today, size: 20),
                                            isDense: true,
                                          ),
                                          child: Text(
                                            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              AppSpacing.gapVerticalMD,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Item Produk',
                                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                  TextButton.icon(
                                    onPressed: _addItem,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Tambah Item'),
                                  ),
                                ],
                              ),
                              if (_items.isEmpty)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                  child: Center(
                                    child: Text('Belum ada item. Ketuk "Tambah Item" untuk mulai.',
                                        style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant)),
                                  ),
                                ),
                              ..._items.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                final priceCtrl = item['priceCtrl'] as TextEditingController;
                                final qtyCtrl = item['qtyCtrl'] as TextEditingController;

                                return Card(
                                  margin: EdgeInsets.only(bottom: AppSpacing.sectionGap),
                                  child: Padding(
                                    padding: AppSpacing.cardPadding,
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: DropdownButtonFormField<int>(
                                                decoration: const InputDecoration(
                                                  labelText: 'Produk',
                                                  isDense: true,
                                                ),
                                                value: item['detail_request_id'],
                                                items: _detailRequests
                                                    .map<DropdownMenuItem<int>>((dr) => DropdownMenuItem<int>(
                                                          value: dr['id'] is int ? dr['id'] : int.parse(dr['id'].toString()),
                                                          child: Text(
                                                            dr['detail_request_name'] ?? dr['product']?['name'] ?? '',
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ))
                                                    .toList(),
                                                onChanged: (val) {
                                                  final dr = _detailRequests.firstWhere(
                                                    (d) => d['id'] == val,
                                                    orElse: () => <String, dynamic>{},
                                                  );
                                                  setState(() {
                                                    item['detail_request_id'] = val;
                                                    item['productName'] = dr['detail_request_name'] ?? dr['product']?['name'] ?? '';
                                                    item['unitName'] = dr['product']?['unit']?['unit'] ?? '';
                                                  });
                                                },
                                              ),
                                            ),
                                            AppSpacing.gapHorizontalSM,
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline),
                                              color: colorScheme.error,
                                              onPressed: () => _removeItem(idx),
                                            ),
                                          ],
                                        ),
                                        if (item['detail_request_id'] != null) ...[
                                          AppSpacing.gapVerticalSM,
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  controller: qtyCtrl,
                                                  decoration: InputDecoration(
                                                    labelText: 'Jumlah',
                                                    suffixText: item['unitName']?.toString(),
                                                    isDense: true,
                                                  ),
                                                  keyboardType: TextInputType.number,
                                                  onTap: () {
                                                    qtyCtrl.selection = TextSelection(
                                                      baseOffset: 0,
                                                      extentOffset: qtyCtrl.text.length,
                                                    );
                                                  },
                                                  onChanged: (_) => setState(() {}),
                                                ),
                                              ),
                                              AppSpacing.gapHorizontalSM,
                                              Expanded(
                                                child: TextFormField(
                                                  controller: priceCtrl,
                                                  decoration: const InputDecoration(
                                                    labelText: 'Harga',
                                                    prefixText: 'Rp ',
                                                    isDense: true,
                                                  ),
                                                  keyboardType: TextInputType.number,
                                                  onTap: () {
                                                    priceCtrl.selection = TextSelection(
                                                      baseOffset: 0,
                                                      extentOffset: priceCtrl.text.length,
                                                    );
                                                  },
                                                  onChanged: (_) => setState(() {}),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_itemSubtotal(item) > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Align(
                                                alignment: Alignment.centerRight,
                                                child: Text(
                                                  'Subtotal: Rp ${_itemSubtotal(item).toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m.group(1)}.')}',
                                                  style: textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                                                ),
                                              ),
                                            ),
                                        ],
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
                                    children: [
                                      TextFormField(
                                        controller: _taxesController,
                                        decoration: const InputDecoration(
                                          labelText: 'Pajak',
                                          prefixText: 'Rp ',
                                          isDense: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onTap: () {
                                          _taxesController.selection = TextSelection(
                                            baseOffset: 0,
                                            extentOffset: _taxesController.text.length,
                                          );
                                        },
                                        onChanged: (v) => setState(
                                            () => _taxes = int.tryParse(v) ?? 0),
                                      ),
                                      AppSpacing.gapVerticalSM,
                                      TextFormField(
                                        controller: _discountsController,
                                        decoration: const InputDecoration(
                                          labelText: 'Diskon',
                                          prefixText: 'Rp ',
                                          isDense: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onTap: () {
                                          _discountsController.selection = TextSelection(
                                            baseOffset: 0,
                                            extentOffset: _discountsController.text.length,
                                          );
                                        },
                                        onChanged: (v) => setState(
                                            () => _discounts = int.tryParse(v) ?? 0),
                                      ),
                                      const Divider(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Total',
                                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                          Text(
                                            'Rp ${_totalPrice.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m.group(1)}.')}',
                                            style: textTheme.titleMedium?.copyWith(
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
                              AppSpacing.gapVerticalSM,
                              TextFormField(
                                controller: _notesController,
                                decoration: const InputDecoration(
                                  labelText: 'Catatan',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: AppSpacing.paddingMD,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              ),
                              child: Text('Buat Invoice',
                                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
