import 'package:flutter/material.dart';
import '../models/transfer_stock_model.dart';
import '../models/store_model.dart';
import '../services/transfer_stock_service.dart';
import '../services/store_service.dart';
import '../theme/app_spacing.dart';

class CreateTransferStockPage extends StatefulWidget {
  const CreateTransferStockPage({super.key});

  @override
  State<CreateTransferStockPage> createState() =>
      _CreateTransferStockPageState();
}

class _CreateTransferStockPageState extends State<CreateTransferStockPage> {
  final StoreService _storeService = StoreService();
  final TransferStockService _transferStockService = TransferStockService();

  List<StoreModel> _stores = [];
  List<TransferStockProduct> _products = [];
  bool _isLoadingData = true;
  String? _errorMessage;

  StoreModel? _selectedFromStore;
  StoreModel? _selectedToStore;
  DateTime _selectedDate = DateTime.now();
  final List<Map<String, dynamic>> _items = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    for (var item in _items) {
      (item['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final stores = await _storeService.getStores();
      final products = await _transferStockService.getProducts();

      setState(() {
        _stores = stores;
        _products = products;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data awal: $e';
        _isLoadingData = false;
      });
    }
  }

  void _addItem() {
    if (_products.isEmpty) return;

    final controller = TextEditingController(text: '0');
    controller.addListener(() {
      final text = controller.text;
      if (text.startsWith('0') && text.length > 1) {
        controller.text = text.substring(1);
        controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length));
      }
    });

    setState(() {
      _items.add({
        'product_id': null,
        'productName': null,
        'unitName': null,
        'controller': controller,
      });
    });
  }

  void _removeItem(int index) {
    (_items[index]['controller'] as TextEditingController).dispose();
    setState(() {
      _items.removeAt(index);
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Gagal Menyimpan',
            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: Theme.of(ctx).colorScheme.error)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitTransfer() async {
    if (_selectedFromStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih toko asal.')),
      );
      return;
    }
    if (_selectedToStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih toko tujuan.')),
      );
      return;
    }
    if (_selectedFromStore!.id == _selectedToStore!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Toko asal dan tujuan tidak boleh sama.')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 item produk.')),
      );
      return;
    }

    for (var item in _items) {
      if (item['product_id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih produk untuk semua item.')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final itemsApi = _items.map((item) {
        final ctrl = item['controller'] as TextEditingController;
        return {
          'product_id': item['product_id'],
          'quantity': double.tryParse(ctrl.text) ?? 0.0,
        };
      }).toList();

      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      await _transferStockService.createTransferStock(
        fromStoreId: _selectedFromStore!.id,
        toStoreId: _selectedToStore!.id,
        date: dateStr,
        items: itemsApi,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer stok berhasil diajukan.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Stok Baru'),
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
                        Text(_errorMessage!,
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.error)),
                        AppSpacing.gapVerticalMD,
                        ElevatedButton(
                          onPressed: _loadInitialData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: AppSpacing.paddingMD,
                            children: [
                              DropdownButtonFormField<StoreModel>(
                                decoration: const InputDecoration(
                                  labelText: 'Toko Asal',
                                  prefixIcon: Icon(Icons.storefront),
                                ),
                                initialValue: _selectedFromStore,
                                items: _stores
                                    .where((s) =>
                                        _selectedToStore == null ||
                                        s.id != _selectedToStore!.id)
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s.nickname),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() => _selectedFromStore = val);
                                },
                              ),
                              AppSpacing.gapVerticalMD,
                              DropdownButtonFormField<StoreModel>(
                                decoration: const InputDecoration(
                                  labelText: 'Toko Tujuan',
                                  prefixIcon: Icon(Icons.store),
                                ),
                                initialValue: _selectedToStore,
                                items: _stores
                                    .where((s) =>
                                        _selectedFromStore == null ||
                                        s.id != _selectedFromStore!.id)
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s.nickname),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() => _selectedToStore = val);
                                },
                              ),
                              AppSpacing.gapVerticalMD,
                              InkWell(
                                onTap: _pickDate,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Tanggal',
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  child: Text(
                                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ),
                              AppSpacing.gapVerticalLG,
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Item Produk',
                                    style: textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  TextButton.icon(
                                    onPressed: _addItem,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Tambah Item'),
                                  ),
                                ],
                              ),
                              if (_items.isEmpty)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: AppSpacing.lg),
                                  child: Center(
                                    child: Text(
                                      'Belum ada item. Ketuk "Tambah Item" untuk mulai.',
                                      style: textTheme.bodyMedium
                                          ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ..._items.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                return Card(
                                  margin: EdgeInsets.only(
                                      bottom: AppSpacing.sectionGap),
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
                                                initialValue: item['product_id'],
                                                items: _products
                                                    .map((p) =>
                                                        DropdownMenuItem(
                                                          value: p.id,
                                                          child: Text(
                                                              p.name,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis),
                                                        ))
                                                    .toList(),
                                                onChanged: (val) {
                                                  final product =
                                                      _products.firstWhere(
                                                    (p) => p.id == val,
                                                    orElse: () =>
                                                        TransferStockProduct(
                                                            id: 0,
                                                            name: '',
                                                            unitName: ''),
                                                  );
                                                  setState(() {
                                                    item['product_id'] = val;
                                                    item['productName'] =
                                                        product.name;
                                                    item['unitName'] =
                                                        product.unitName;
                                                  });
                                                },
                                              ),
                                            ),
                                            AppSpacing.gapHorizontalSM,
                                            IconButton(
                                              icon: const Icon(Icons
                                                  .remove_circle_outline),
                                              color: colorScheme.error,
                                              onPressed: () =>
                                                  _removeItem(idx),
                                            ),
                                          ],
                                        ),
                                        AppSpacing.gapVerticalSM,
                                        if (item['product_id'] != null)
                                          TextFormField(
                                            controller:
                                                item['controller'],
                                            keyboardType:
                                                TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'Kuantitas',
                                              suffixText:
                                                  item['unitName'],
                                            ),
                                            onTap: () {
                                              final ctrl = item[
                                                      'controller']
                                                  as TextEditingController;
                                              ctrl.selection =
                                                  TextSelection(
                                                      baseOffset: 0,
                                                      extentOffset:
                                                          ctrl.text
                                                              .length);
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        Padding(
                          padding: AppSpacing.paddingMD,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(),
                              onPressed:
                                  _isSubmitting ? null : _submitTransfer,
                              child: Text(
                                'Ajukan Transfer Stok',
                                style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isSubmitting)
                      Container(
                        color: colorScheme.scrim.withValues(alpha: 0.3),
                        child:
                            const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
    );
  }
}
