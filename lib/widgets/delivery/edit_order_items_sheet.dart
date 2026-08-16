import 'package:flutter/material.dart';

import '../../models/sales_order_online_model.dart';
import '../../providers/delivery_provider.dart';
import '../../services/sales_order_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/modern_dropdown.dart';

/// Bottom sheet untuk admin mengubah rincian produk sebuah order:
/// ganti produk, jumlah, harga satuan, tambah/hapus item. Menggantikan
/// pesan lama "hubungi admin backend untuk mengubah jenis produk".
class EditOrderItemsSheet extends StatefulWidget {
  final Map<String, dynamic> order;
  final DeliveryProvider provider;

  const EditOrderItemsSheet({
    super.key,
    required this.order,
    required this.provider,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> order,
    required DeliveryProvider provider,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditOrderItemsSheet(order: order, provider: provider),
    );
  }

  @override
  State<EditOrderItemsSheet> createState() => _EditOrderItemsSheetState();
}

class _EditOrderItemsSheetState extends State<EditOrderItemsSheet> {
  final SalesOrderService _salesOrderService = SalesOrderService();

  List<SalesOrderOnlineProduct> _products = [];
  final List<_EditItemState> _items = [];
  bool _isLoadingProducts = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _seedFromOrder();
    _loadProducts();
  }

  void _seedFromOrder() {
    final items = widget.order['items'];
    if (items is List) {
      for (final raw in items) {
        if (raw is Map<String, dynamic>) {
          _items.add(_EditItemState(
            productId: raw['product_id'] as int?,
            qtyController: TextEditingController(
              text: _toText(raw['quantity'], fallback: '1'),
            ),
            priceController: TextEditingController(
              text: _toText(raw['unit_price']),
            ),
          ));
        }
      }
    }
    if (_items.isEmpty) {
      _addItem();
    }
  }

  static String _toText(dynamic value, {String fallback = '0'}) {
    if (value == null) return fallback;
    final parsed = int.tryParse(value.toString());
    if (parsed == null) {
      final parsedDouble = double.tryParse(value.toString());
      return parsedDouble == null
          ? fallback
          : parsedDouble.round().toString();
    }
    return parsed.toString();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _loadError = null;
    });
    try {
      final products = await _salesOrderService.getOnlineProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProducts = false;
        _loadError = 'Gagal memuat daftar produk: $e';
      });
    }
  }

  void _addItem() {
    setState(() {
      _items.add(_EditItemState(
        productId: null,
        qtyController: TextEditingController(text: '1'),
        priceController: TextEditingController(text: '0'),
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  int get _total {
    int total = 0;
    for (final item in _items) {
      total += item.subtotal;
    }
    return total;
  }

  Future<void> _save() async {
    if (_items.isEmpty) {
      _showSnack('Minimal harus ada 1 item.');
      return;
    }
    for (final item in _items) {
      if (item.productId == null) {
        _showSnack('Ada item yang belum dipilih produknya.');
        return;
      }
      if (item.quantity < 1) {
        _showSnack('Jumlah minimal 1.');
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      await widget.provider.updateOrderItems([
        for (final item in _items)
          {
            'product_id': item.productId,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
          },
      ]);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rincian produk berhasil diperbarui.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Padding(
            padding: AppSpacing.paddingMD,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_outlined,
                        color: colorScheme.primary, size: 20),
                    AppSpacing.gapHorizontalSM,
                    Expanded(
                      child: Text(
                        'Ubah Rincian Produk • Order #${widget.order['id']}',
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (_isLoadingProducts)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_loadError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text(_loadError!,
                            style: textTheme.bodySmall
                                ?.copyWith(color: colorScheme.error)),
                        AppSpacing.gapVerticalSM,
                        OutlinedButton.icon(
                          onPressed: _loadProducts,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _items.length,
                      itemBuilder: (context, index) =>
                          _buildItemCard(context, index),
                    ),
                  ),
                if (!_isLoadingProducts && _loadError == null) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        'Rp ${_total.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m.group(1)}.')}',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapVerticalSM,
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _addItem,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah Item'),
                        ),
                      ),
                      AppSpacing.gapHorizontalMD,
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, int index) {
    final item = _items[index];
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Item ${index + 1}',
                    style: textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_items.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 20, color: colorScheme.error),
                    onPressed: () => _removeItem(index),
                    tooltip: 'Hapus item',
                  ),
              ],
            ),
            ModernDropdown<int>(
              value: item.productId,
              hint: 'Pilih produk',
              labelText: 'Produk',
              items: [for (final p in _products) p.id],
              getLabel: (id) => _products
                  .firstWhere(
                    (p) => p.id == id,
                    orElse: () => SalesOrderOnlineProduct(
                        id: id, name: 'Produk #$id', unit: ''),
                  )
                  .name,
              searchable: true,
              isRequired: true,
              onChanged: (value) =>
                  setState(() => item.productId = value),
            ),
            AppSpacing.gapVerticalMD,
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: item.qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                AppSpacing.gapHorizontalMD,
                Expanded(
                  child: TextField(
                    controller: item.priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Harga Satuan',
                      prefixText: 'Rp ',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalSM,
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Subtotal: Rp ${item.subtotal.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m.group(1)}.')}',
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditItemState {
  int? productId;
  final TextEditingController qtyController;
  final TextEditingController priceController;

  _EditItemState({
    required this.productId,
    required this.qtyController,
    required this.priceController,
  });

  int get quantity => int.tryParse(qtyController.text) ?? 0;
  int get unitPrice => int.tryParse(priceController.text) ?? 0;
  int get subtotal => quantity * unitPrice;

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
  }
}
