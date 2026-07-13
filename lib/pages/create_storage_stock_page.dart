import 'package:flutter/material.dart';
import '../models/storage_stock_model.dart';
import '../models/store_model.dart';
import '../services/storage_stock_service.dart';
import '../services/store_service.dart';
import '../theme/app_spacing.dart';

class CreateStorageStockPage extends StatefulWidget {
  const CreateStorageStockPage({super.key});

  @override
  State<CreateStorageStockPage> createState() => _CreateStorageStockPageState();
}

class _CreateStorageStockPageState extends State<CreateStorageStockPage> {
  final StoreService _storeService = StoreService();
  final StorageStockService _storageStockService = StorageStockService();

  List<StoreModel> _stores = [];
  List<StorageStockProduct> _products = [];
  bool _isLoadingData = true;
  String? _errorMessage;

  StoreModel? _selectedStore;
  final List<Map<String, dynamic>> _items = []; // Contains product_id, productName, unitName, controller
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
      final products = await _storageStockService.getProducts();
      
      setState(() {
        _stores = stores;
        _products = products;
        
        // Auto-populate all products by default (lazy load equivalent for mobile)
        _items.clear();
        for (var p in _products) {
          final controller = TextEditingController(text: '0');
          // Select all when focused
          controller.addListener(() {
            final text = controller.text;
            if (text.startsWith('0') && text.length > 1) {
               controller.text = text.substring(1);
               controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
            }
          });
          
          _items.add({
            'product_id': p.id,
            'productName': p.name,
            'unitName': p.unitName,
            'controller': controller,
          });
        }
        
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data awal: $e';
        _isLoadingData = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Gagal Menyimpan', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: Theme.of(ctx).colorScheme.error)),
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

  Future<void> _submitReport() async {
    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih gudang terlebih dahulu.')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada item produk.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final List<Map<String, dynamic>> itemsApi = _items.map((item) {
        final ctrl = item['controller'] as TextEditingController;
        return {
          'product_id': item['product_id'],
          'quantity': double.tryParse(ctrl.text) ?? 0.0,
        };
      }).toList();

      await _storageStockService.createStorageStock(_selectedStore!.id, itemsApi);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan Stok Sisa berhasil disimpan.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      // Show dialog for specific backend validations (e.g. time < 21:00 or duplicated)
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
        title: const Text('Stock Opname Baru'),
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
                        Text(_errorMessage!, style: textTheme.bodyLarge?.copyWith(color: colorScheme.error)),
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
                        Padding(
                          padding: AppSpacing.paddingMD,
                          child: DropdownButtonFormField<StoreModel>(
                            decoration: const InputDecoration(
                              labelText: 'Pilih Gudang / Outlet',
                              prefixIcon: Icon(Icons.storefront),
                            ),
                            initialValue: _selectedStore,
                            items: _stores.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(s.nickname),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedStore = val;
                              });
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          width: double.infinity,
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          child: Text(
                            'Isi kuantitas stok aktual saat ini',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: AppSpacing.paddingMD,
                            itemCount: _items.length,
                            itemBuilder: (context, idx) {
                              final item = _items[idx];
                              return Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.md),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        item['productName'],
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    AppSpacing.gapHorizontalSM,
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        controller: item['controller'],
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(

                                          suffixText: item['unitName'],
                                        ),
                                        onTap: () {
                                          final ctrl = item['controller'] as TextEditingController;
                                          ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: AppSpacing.paddingMD,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(),
                              onPressed: _isSubmitting ? null : _submitReport,
                              child: Text(
                                'Simpan Stock Opname',
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isSubmitting)
                      Container(
                        color: colorScheme.scrim.withValues(alpha: 0.3),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
    );
  }
}
