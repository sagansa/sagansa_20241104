import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/asset_controller.dart';
import '../models/store_model.dart';
import '../services/store_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/modern_bottom_sheet.dart';

/// Buat instance aset dari produk yang sudah ditandai sebagai aset
/// (product-driven). Memastikan konsistensi nama/kode/kategori antar toko:
/// user hanya memilih produk dari katalog (yang sudah di-flag is_asset oleh
/// admin), lalu memilih toko & qty.
///
/// Alur: pilih toko -> pilih produk (modal) -> qty -> submit.
class AssetFromProductPage extends StatefulWidget {
  const AssetFromProductPage({super.key, this.initialStoreId});

  final int? initialStoreId;

  @override
  State<AssetFromProductPage> createState() => _AssetFromProductPageState();
}

class _AssetFromProductPageState extends State<AssetFromProductPage> {
  late AssetController _controller;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAdmin = false;
  String? _errorMessage;

  List<StoreModel> _stores = [];
  List<Map<String, dynamic>> _assetProducts = [];
  StoreModel? _selectedStore;

  final _qtyCtrl = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _controller = AssetController(context);
    _load();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Baca role user.
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = json.decode(userString);
        final roles = List<String>.from(userData['roles'] ?? []);
        _isAdmin = roles.contains('admin');
      }

      final storeService = StoreService();
      final presenceStoreId = await _controller.loadCurrentStoreId();
      final results = await Future.wait<dynamic>([
        storeService.getStores(),
        _controller.loadAssetProducts(),
      ]);
      if (!mounted) return;
      final stores = results[0] as List<StoreModel>;
      final products = results[1] as List<Map<String, dynamic>>;

      // Staff: kunci ke presence store (tidak boleh pilih lain).
      // Admin: bebas pilih (default store pertama).
      StoreModel? initial;
      if (!_isAdmin) {
        initial = stores.where((s) => s.id == presenceStoreId).firstOrNull;
      } else {
        initial = widget.initialStoreId != null
            ? stores.where((s) => s.id == widget.initialStoreId).firstOrNull
            : (stores.isNotEmpty ? stores.first : null);
      }

      setState(() {
        _stores = stores;
        _assetProducts = products;
        _selectedStore = initial;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Future<void> _pickProduct() async {
    if (_assetProducts.isEmpty) {
      _showError('Belum ada produk yang ditandai sebagai aset. '
          'Minta admin menandai produk di panel admin dahulu.');
      return;
    }
    final queryCtrl = TextEditingController();
    final picked = await ModernBottomSheet.show<Map<String, dynamic>>(
      context: context,
      title: 'Pilih Produk Aset',
      padding: EdgeInsets.zero,
      child: StatefulBuilder(builder: (context, setS) {
        final theme = Theme.of(context);
        List<Map<String, dynamic>> filtered = _assetProducts;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: AppSpacing.paddingHorizontalMD,
              child: TextField(
                controller: queryCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                onChanged: (v) {
                  setS(() {
                    filtered = _assetProducts
                        .where((p) => (p['name'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(v.toLowerCase()))
                        .toList();
                  });
                },
              ),
            ),
            AppSpacing.gapVerticalSM,
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final p = filtered[i];
                  final cat = p['asset_category'];
                  final catName = cat is Map ? cat['name'] : '-';
                  return ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(p['name'] ?? '-',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${p['sku'] ?? ''} • $catName'
                          .trim(),
                      style: theme.textTheme.bodySmall,
                    ),
                    onTap: () => Navigator.pop(context, p),
                  );
                },
              ),
            ),
            AppSpacing.gapVerticalSM,
          ],
        );
      }),
    );
    queryCtrl.dispose();
    if (picked != null && mounted) {
      setState(() => _selectedProduct = picked);
    }
  }

  Map<String, dynamic>? _selectedProduct;

  Future<void> _submit() async {
    if (_selectedStore == null) {
      _showError('Pilih toko terlebih dahulu.');
      return;
    }
    if (_selectedProduct == null) {
      _showError('Pilih produk terlebih dahulu.');
      return;
    }
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty < 1) {
      _showError('Qty minimal 1.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _controller.createFromProduct(
        productId: _selectedProduct!['id'] as int,
        storeId: _selectedStore!.id,
        qty: qty,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$qty aset berhasil dibuat dari '
            '"${_selectedProduct!['name']}".')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Aset dari Produk'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      SizedBox(height: AppSpacing.sectionGap),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : SafeArea(
                  child: ListView(
                    padding: AppSpacing.screenPadding,
                    children: [
                      // Store dropdown.
                      // Staff: dikunci ke presence store (read-only).
                      // Admin: bebas pilih store manapun.
                      DropdownButtonFormField<StoreModel>(
                        initialValue: _selectedStore,
                        decoration: InputDecoration(
                          labelText: 'Toko *',
                          helperText: !_isAdmin
                              ? (_selectedStore == null
                                  ? 'Anda belum check-in hari ini. Lakukan presence dahulu.'
                                  : 'Terkunci ke store presence Anda.')
                              : null,
                        ),
                        items: _stores
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.nickname.isNotEmpty
                                      ? s.nickname
                                      : 'Store #${s.id}'),
                                ))
                            .toList(),
                        onChanged: _isAdmin
                            ? (v) => setState(() => _selectedStore = v)
                            : null, // disabled for staff
                      ),
                      SizedBox(height: AppSpacing.sectionGap),

                      // Product picker tile.
                        InkWell(
                        onTap: _pickProduct,
                        borderRadius: AppSpacing.borderRadiusMD,
                        child: Container(
                          padding: AppSpacing.cardPadding,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha:0.5),
                            borderRadius: AppSpacing.borderRadiusMD,
                            border: Border.all(
                                color: colorScheme.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  color: colorScheme.primary),
                              SizedBox(width: AppSpacing.rowGap),
                              Expanded(
                                child: _selectedProduct == null
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Pilih Produk Aset *',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                          Text(
                                            _assetProducts.isEmpty
                                                ? 'Belum ada produk ditandai sebagai aset'
                                                : 'Tap untuk memilih dari ${_assetProducts.length} produk',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedProduct!['name'] ?? '-',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                          Text(
                                            '${_selectedProduct!['sku'] ?? '-'} • '
                                            '${(_selectedProduct!['asset_category'] is Map ? _selectedProduct!['asset_category']['name'] : '-')}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  color: colorScheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sectionGap),

                      // Qty.
                        TextFormField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Unit *',
                          helperText: 'Akan dibuatkan N instance aset '
                              '(nama/kode/kategori otomatis dari produk).',
                        ),
                      ),
                      AppSpacing.gapVerticalLG,

                      FilledButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.add_circle_outline_rounded),
                        label: Text(_isSaving
                            ? 'Menyimpan...'
                            : 'Buat Aset'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
