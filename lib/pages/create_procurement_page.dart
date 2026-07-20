import 'package:flutter/material.dart';
import '../../models/procurement_model.dart';
import '../../models/store_model.dart';
import '../../services/procurement_service.dart';
import '../../services/store_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../widgets/modern_bottom_sheet.dart';
import '../widgets/modern_dropdown.dart';

class CreateProcurementPage extends StatefulWidget {
  const CreateProcurementPage({super.key});

  @override
  State<CreateProcurementPage> createState() => _CreateProcurementPageState();
}

class _CreateProcurementPageState extends State<CreateProcurementPage> {
  final StoreService _storeService = StoreService();
  final ProcurementService _procurementService = ProcurementService();

  List<StoreModel> _stores = [];
  List<ProcurementProduct> _products = [];
  bool _isLoadingData = true;
  String? _errorMessage;

  StoreModel? _selectedStore;
  final List<Map<String, dynamic>> _selectedItems = []; // Contains product_id, productName, unitName, quantity_plan
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final stores = await _storeService.getStores();
      final products = await _procurementService.getProducts();
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

  void _showAddItemBottomSheet() {
    int? selectedPaymentType = 1;
    ProcurementProduct? selectedProduct;
    final qtyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    ModernBottomSheet.show(
      context: context,
      title: 'Tambah Item Request',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      // Product (searchable)
                      InkWell(
                        onTap: () async {
                          final result = await _showProductSearchDialog();
                          if (result != null) {
                            setModalState(() {
                              selectedProduct = result;
                              selectedPaymentType = result.paymentTypeId ?? 1;
                            });
                          }
                        },
                        borderRadius: AppSpacing.borderRadiusXS,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Pilih Produk',
                            suffixIcon: Icon(Icons.search),
                          ),
                          child: Text(
                            selectedProduct != null
                                ? selectedProduct!.name
                                : '',
                          ),
                        ),
                      ),
                      AppSpacing.gapVerticalMD,
                      ModernDropdown<int>(
                        labelText: 'Rencana Pembayaran',
                        hint: 'Pilih pembayaran...',
                        value: selectedPaymentType,
                        items: const [1, 2],
                        getLabel: (val) => val == 1 ? 'Transfer' : 'Tunai / Cash',
                        onChanged: (val) {
                          setModalState(() {
                            selectedPaymentType = val;
                          });
                        },
                        validator: (val) => val == null ? 'Pilih rencana pembayaran' : null,
                      ),
                      AppSpacing.gapVerticalMD,
                      TextFormField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Jumlah / Quantity',
                          suffixText: selectedProduct?.unitName ?? '',
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Jumlah wajib diisi';
                          final num = double.tryParse(val);
                          if (num == null || num <= 0) return 'Jumlah harus lebih besar dari 0';
                          return null;
                        },
                      ),
                      AppSpacing.gapVerticalLG,
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate() && selectedProduct != null) {
                              final duplicateIndex = _selectedItems.indexWhere((item) => 
                                item['product_id'] == selectedProduct!.id && 
                                item['payment_type_id'] == selectedPaymentType
                              );
                               
                              setState(() {
                                if (duplicateIndex != -1) {
                                  _selectedItems[duplicateIndex]['quantity_plan'] += double.parse(qtyController.text);
                                } else {
                                  _selectedItems.add({
                                    'product_id': selectedProduct!.id,
                                    'productName': selectedProduct!.name,
                                    'unitName': selectedProduct!.unitName,
                                    'quantity_plan': double.parse(qtyController.text),
                                    'payment_type_id': selectedPaymentType,
                                  });
                                }
                              });
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Tambah ke List'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
  }

  Future<void> _submitRequest() async {
    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih toko terlebih dahulu.')),
      );
      return;
    }

    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 item belanja.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final List<Map<String, dynamic>> itemsApi = _selectedItems.map((item) {
        return {
          'product_id': item['product_id'],
          'quantity_plan': item['quantity_plan'],
          'payment_type_id': item['payment_type_id'],
        };
      }).toList();

      await _procurementService.createRequest(_selectedStore!.id, itemsApi);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request Purchase berhasil dibuat.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat request: $e')),
      );
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
        title: const Text('Buat Request Baru'),
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
                    Padding(
                      padding: AppSpacing.paddingMD,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ModernDropdown<StoreModel>(
                            labelText: 'Pilih Toko / Outlet',
                            hint: 'Pilih outlet...',
                            prefixIcon: const Icon(Icons.storefront, size: 20),
                            value: _selectedStore,
                            items: _stores,
                            getLabel: (s) => s.nickname,
                            getSubtitle: (s) => '',
                            onChanged: (s) {
                              setState(() {
                                _selectedStore = s;
                              });
                            },
                          ),
                          AppSpacing.gapVerticalLG,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Daftar Item Request',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _showAddItemBottomSheet,
                                icon: const Icon(Icons.add),
                                label: const Text('Tambah Item'),
                              ),
                            ],
                          ),
                          AppSpacing.gapVerticalSM,
                          Expanded(
                            child: _selectedItems.isEmpty
                                ? Center(
                                    child: Text(
                                      'Belum ada item belanja ditambahkan.',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _selectedItems.length,
                                    itemBuilder: (context, idx) {
                                      final item = _selectedItems[idx];
                                      return Card(
                                        margin: EdgeInsets.only(bottom: AppSpacing.sm),
                                        child: ListTile(
                                          title: Text(
                                            item['productName'],
                                            style: textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            item['payment_type_id'] == 2 ? 'Rencana: Tunai' : 'Rencana: Transfer',
                                            style: textTheme.bodySmall?.copyWith(
                                              color: item['payment_type_id'] == 2 ? AppColors.warning : AppColors.success,
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${item['quantity_plan'].toStringAsFixed(0)} ${item['unitName']}',
                                                style: textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                              AppSpacing.gapHorizontalSM,
                                              IconButton(
                                                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedItems.removeAt(idx);
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          AppSpacing.gapVerticalMD,
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(),
                              onPressed: _isSubmitting ? null : _submitRequest,
                              child: Text(
                                'Kirim Request Belanja',
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Future<ProcurementProduct?> _showProductSearchDialog() async {
    String query = '';
    return showDialog<ProcurementProduct>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = _products.where((p) {
              if (query.isEmpty) return true;
              return p.name.toLowerCase().contains(query.toLowerCase());
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
                        hintText: 'Cari produk...',
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
                        ? const Center(child: Text('Tidak ada produk'))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) => ListTile(
                              title: Text(filtered[i].name),
                              subtitle: Text('Satuan: ${filtered[i].unitName}'),
                              onTap: () => Navigator.pop(ctx, filtered[i]),
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
}
