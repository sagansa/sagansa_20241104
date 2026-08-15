import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/sales_order_employee_model.dart';
import '../models/store_model.dart';
import '../services/image_upload_service.dart';
import '../services/sales_order_employee_service.dart';
import '../services/store_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/format_utils.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_dropdown.dart';
import '../widgets/safe_bottom_bar.dart';

/// Form create/update penjualan employee (role sales).
///
/// [order] null → mode create. [order] tidak null → mode edit (hanya untuk
/// order milik sendiri yang belum valid / belum locked).
class SalesOrderEmployeeFormPage extends StatefulWidget {
  final SalesOrderEmployeeModel? order;
  const SalesOrderEmployeeFormPage({super.key, this.order});

  @override
  State<SalesOrderEmployeeFormPage> createState() =>
      _SalesOrderEmployeeFormPageState();
}

class _FormItem {
  int? productId;
  String? productName;
  String? unit;
  int quantity;
  int unitPrice;
  _FormItem(
      {this.productId,
      this.productName,
      this.unit,
      this.quantity = 1,
      this.unitPrice = 0});
}

class _SalesOrderEmployeeFormPageState
    extends State<SalesOrderEmployeeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final SalesOrderEmployeeService _service = SalesOrderEmployeeService();
  final StoreService _storeService = StoreService();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  // Master data
  List<StoreModel> _stores = [];
  List<Map<String, dynamic>> _transferAccounts = [];
  List<Map<String, dynamic>> _deliveryAddresses = [];
  List<Map<String, dynamic>> _products = [];

  // Form state
  StoreModel? _store;
  DateTime? _deliveryDate;
  Map<String, dynamic>? _transferAccount;
  Map<String, dynamic>? _deliveryAddress;
  final List<_FormItem> _items = [];
  String? _imagePath; // path lokal untuk preview
  String? _uploadedImagePath; // path yang dikirim ke backend
  final _notesController = TextEditingController();

  bool get _isEdit => widget.order != null;

  @override
  void initState() {
    super.initState();
    _loadSupportingData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSupportingData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getSupportingData(),
        _storeService.getStores(),
      ]);
      final data = results[0] as Map<String, dynamic>;
      final stores = results[1] as List<StoreModel>;
      if (!mounted) return;

      setState(() {
        _transferAccounts = (data['transfer_to_accounts'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        _deliveryAddresses = (data['delivery_addresses'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        _products = (data['products'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        _stores = stores;

        // Prefill untuk edit mode
        if (_isEdit) _prefillFromOrder();

        // Default store: kalau create, ambil store pertama
        _store ??= _stores.isNotEmpty ? _stores.first : null;
        _transferAccount ??=
            _transferAccounts.isNotEmpty ? _transferAccounts.first : null;
        _deliveryAddress ??=
            _deliveryAddresses.isNotEmpty ? _deliveryAddresses.first : null;
        _deliveryDate ??= DateTime.now();

        if (_items.isEmpty) _items.add(_FormItem());
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _prefillFromOrder() {
    final o = widget.order!;
    _store = _stores.where((s) => s.id == o.storeId).firstOrNull;
    _deliveryDate = o.deliveryDate;
    _transferAccount = _transferAccounts
        .where((e) => e['id'] == o.transferToAccountId)
        .firstOrNull;
    _deliveryAddress = _deliveryAddresses
        .where((e) => e['id'] == o.deliveryAddressId)
        .firstOrNull;
    _uploadedImagePath = o.imagePayment;
    _notesController.text = o.notes ?? '';
    _items
      ..clear()
      ..addAll(o.items.map((i) => _FormItem(
            productId: i.productId,
            productName: i.productName,
            unit: i.productUnit,
            quantity: i.quantity,
            unitPrice: i.unitPrice,
          )));
  }

  int get _total =>
      _items.fold(0, (sum, i) => sum + (i.quantity * i.unitPrice));

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _imagePath = picked.path);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _deliveryDate = picked);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    // Validasi tambahan: minimal 1 item dengan product terisi.
    final validItems = _items.where((i) => i.productId != null).toList();
    if (validItems.isEmpty) {
      SnackbarUtils.warning(context, 'Tambahkan minimal 1 produk.');
      return;
    }
    if (_store == null ||
        _deliveryDate == null ||
        _transferAccount == null ||
        _deliveryAddress == null) {
      SnackbarUtils.warning(context, 'Lengkapi semua field wajib.');
      return;
    }

    setState(() => _saving = true);

    try {
      // Upload image bila ada yang baru dipilih.
      String? imagePath = _uploadedImagePath;
      if (_imagePath != null) {
        final uploaded = await ImageUploadService.upload(
          File(_imagePath!),
          directory: 'images/Employee',
        );
        if (uploaded == null) {
          throw Exception('Gagal upload bukti transfer.');
        }
        imagePath = uploaded;
      }

      final itemsPayload = validItems
          .map((i) => {
                'product_id': i.productId,
                'quantity': i.quantity,
                'unit_price': i.unitPrice,
              })
          .toList();

      if (_isEdit) {
        await _service.update(
          widget.order!.id,
          storeId: _store!.id,
          deliveryDate: _fmt(_deliveryDate!),
          deliveryAddressId: _deliveryAddress!['id'] as int,
          transferToAccountId: _transferAccount!['id'] as int,
          imagePayment: imagePath,
          clearImage: imagePath == null,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          items: itemsPayload,
        );
      } else {
        await _service.create(
          storeId: _store!.id,
          deliveryDate: _fmt(_deliveryDate!),
          deliveryAddressId: _deliveryAddress!['id'] as int,
          transferToAccountId: _transferAccount!['id'] as int,
          imagePayment: imagePath,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          items: itemsPayload,
        );
      }

      if (!mounted) return;
      SnackbarUtils.success(
          context, _isEdit ? 'Penjualan diperbarui.' : 'Penjualan dibuat.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.error(
          context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Penjualan' : 'Penjualan Baru'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadSupportingData)
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md + context.systemBottomInset,
                    ),
                    children: [
                      _buildStoreField(theme),
                      AppSpacing.gapVerticalMD,
                      _buildDateField(theme),
                      AppSpacing.gapVerticalMD,
                      _buildDropdownField(
                        theme: theme,
                        label: 'Alamat Pengiriman',
                        value: _deliveryAddress,
                        items: _deliveryAddresses,
                        onChanged: (v) => setState(() => _deliveryAddress = v),
                      ),
                      AppSpacing.gapVerticalMD,
                      _buildDropdownField(
                        theme: theme,
                        label: 'Rekening Tujuan Transfer',
                        value: _transferAccount,
                        items: _transferAccounts,
                        onChanged: (v) => setState(() => _transferAccount = v),
                      ),
                      AppSpacing.gapVerticalMD,
                      _buildItemsSection(theme),
                      AppSpacing.gapVerticalMD,
                      _buildImageSection(theme),
                      AppSpacing.gapVerticalMD,
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      AppSpacing.gapVerticalLG,
                      ModernButton(
                        text: _isEdit ? 'Simpan Perubahan' : 'Simpan',
                        onPressed: _saving ? null : _save,
                        isLoading: _saving,
                        icon: Icons.save_outlined,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStoreField(ThemeData theme) {
    return ModernDropdown<StoreModel>(
      value: _store,
      labelText: 'Toko',
      hint: 'Pilih toko...',
      isRequired: true,
      prefixIcon: const Icon(Icons.storefront, size: 20),
      items: _stores,
      getLabel: (s) => s.nickname,
      onChanged: (v) => setState(() => _store = v),
    );
  }

  Widget _buildDateField(ThemeData theme) {
    final text =
        _deliveryDate == null ? '' : FormatUtils.formatDate(_deliveryDate!);
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tanggal Pengiriman *',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(text.isEmpty ? 'Pilih tanggal' : text),
      ),
    );
  }

  Widget _buildDropdownField({
    required ThemeData theme,
    required String label,
    required Map<String, dynamic>? value,
    required List<Map<String, dynamic>> items,
    required ValueChanged<Map<String, dynamic>?> onChanged,
  }) {
    return ModernDropdown<Map<String, dynamic>>(
      value: value,
      labelText: label,
      hint: 'Pilih $label...',
      isRequired: true,
      items: items,
      getLabel: (e) => e['name']?.toString() ?? '-',
      onChanged: onChanged,
    );
  }

  Widget _buildItemsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Produk',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(
              'Total: ${FormatUtils.formatCurrency(_total)}',
              style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.success, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        AppSpacing.gapVerticalSM,
        ..._items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ItemRow(
              item: item,
              products: _products,
              onChanged: (newItem) => setState(() => _items[i] = newItem),
              onRemove: _items.length > 1
                  ? () => setState(() => _items.removeAt(i))
                  : null,
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _items.add(_FormItem())),
            icon: const Icon(Icons.add),
            label: const Text('Tambah produk'),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    final hasImage = _imagePath != null || _uploadedImagePath != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bukti Transfer (opsional)',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        AppSpacing.gapVerticalSM,
        if (hasImage)
          Stack(
            children: [
              ClipRRect(
                borderRadius: AppSpacing.borderRadiusMD,
                child: _imagePath != null
                    ? Image.file(File(_imagePath!),
                        height: 160, width: double.infinity, fit: BoxFit.cover)
                    : Image.network(
                        '$_uploadedImagePath',
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton.filled(
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                            _imagePath = null;
                            _uploadedImagePath = null;
                          }),
                  icon: const Icon(Icons.close, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                ),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: _saving ? null : _pickImage,
            icon: const Icon(Icons.upload_outlined),
            label: const Text('Pilih Gambar'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final _FormItem item;
  final List<Map<String, dynamic>> products;
  final ValueChanged<_FormItem> onChanged;
  final VoidCallback? onRemove;
  const _ItemRow({
    required this.item,
    required this.products,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final qtyCtrl = TextEditingController(text: '${item.quantity}');
    final priceCtrl = TextEditingController(text: '${item.unitPrice}');
    return Card(
      child: Padding(
        padding: AppSpacing.paddingSM,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ModernDropdown<int>(
                    value: item.productId,
                    labelText: 'Produk',
                    hint: 'Pilih produk...',
                    items: products.map((p) => p['id'] as int).toList(),
                    getLabel: (v) {
                      final p = products.firstWhere((e) => e['id'] == v,
                          orElse: () => {});
                      return '${p['name'] ?? ''} (${p['unit'] ?? ''})';
                    },
                    getSubtitle: (v) {
                      final p = products.firstWhere((e) => e['id'] == v,
                          orElse: () => {});
                      return 'Rp ${p['price'] ?? 0}';
                    },
                    onChanged: (v) {
                      if (v == null) return;
                      final p = products.firstWhere((e) => e['id'] == v);
                      onChanged(_FormItem(
                        productId: v,
                        productName: p['name']?.toString(),
                        unit: p['unit']?.toString(),
                        quantity: item.quantity,
                        unitPrice: item.unitPrice,
                      ));
                    },
                  ),
                ),
                if (onRemove != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline, size: 20),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: qtyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 0;
                      onChanged(_FormItem(
                        productId: item.productId,
                        productName: item.productName,
                        unit: item.unit,
                        quantity: n,
                        unitPrice: item.unitPrice,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Harga Satuan',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 0;
                      onChanged(_FormItem(
                        productId: item.productId,
                        productName: item.productName,
                        unit: item.unit,
                        quantity: item.quantity,
                        unitPrice: n,
                      ));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            AppSpacing.gapVerticalSM,
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
