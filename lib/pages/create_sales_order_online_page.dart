import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/sales_order_online_model.dart';
import '../models/store_model.dart';
import '../services/sales_order_service.dart';
import '../services/store_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/image_utils.dart';
import '../widgets/glass_container.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_dropdown.dart';

class CreateSalesOrderOnlinePage extends StatefulWidget {
  const CreateSalesOrderOnlinePage({super.key});

  @override
  State<CreateSalesOrderOnlinePage> createState() =>
      _CreateSalesOrderOnlinePageState();
}

class _CreateSalesOrderOnlinePageState
    extends State<CreateSalesOrderOnlinePage> {
  final StoreService _storeService = StoreService();
  final SalesOrderService _salesOrderService = SalesOrderService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _receiptNoController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<StoreModel> _stores = [];
  List<SalesOrderOnlineProduct> _products = [];
  List<OnlineShopProvider> _providers = [];
  List<DeliveryServiceOption> _deliveryServices = [];

  StoreModel? _selectedStore;
  OnlineShopProvider? _selectedProvider;
  DeliveryServiceOption? _selectedDeliveryService;
  DateTime _selectedDate = DateTime.now();
  File? _imageResi;
  Uint8List? _imageResiBytes;

  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  /// Baris item: setiap map berisi produk terpilih, controller quantity, dan
  /// controller unit price. Subtotal dihitung dinamis.
  final List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _receiptNoController.dispose();
    for (final item in _items) {
      (item['qtyController'] as TextEditingController).dispose();
      (item['priceController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _storeService.getStores(),
        _salesOrderService.getOnlineProducts(),
        _salesOrderService.getOnlineShopProviders(),
        _salesOrderService.getDeliveryServices(),
      ]);

      if (!mounted) return;
      setState(() {
        _stores = results[0] as List<StoreModel>;
        _products = results[1] as List<SalesOrderOnlineProduct>;
        _providers = results[2] as List<OnlineShopProvider>;
        _deliveryServices = results[3] as List<DeliveryServiceOption>;
        _isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoadingData = false;
      });
    }
  }

  void _addItem() {
    setState(() {
      _items.add({
        'product': null as SalesOrderOnlineProduct?,
        'qtyController': TextEditingController(text: '1'),
        'priceController': TextEditingController(text: '0'),
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      final item = _items.removeAt(index);
      (item['qtyController'] as TextEditingController).dispose();
      (item['priceController'] as TextEditingController).dispose();
    });
  }

  int get _totalPrice {
    var total = 0;
    for (final item in _items) {
      final qty = int.tryParse(
              (item['qtyController'] as TextEditingController).text) ??
          0;
      final price = int.tryParse(
              (item['priceController'] as TextEditingController).text) ??
          0;
      total += qty * price;
    }
    return total;
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.ltr,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    try {
      final photo = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1024,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        if (kIsWeb) {
          if (mounted) {
            setState(() => _imageResiBytes = bytes);
          }
        } else {
          final compressed = await ImageUtils.compressImage(photo.path);
          if (mounted) {
            setState(() => _imageResi = compressed);
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: cs.error,
        ),
      );
    }
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const _BarcodeScannerPage()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _receiptNoController.text = result);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStore == null ||
        _selectedProvider == null ||
        _selectedDeliveryService == null) {
      _showError('Lengkapi semua field wajib (toko, provider, delivery service).');
      return;
    }
    if (_items.isEmpty) {
      _showError('Tambahkan minimal 1 item produk.');
      return;
    }

    // Validasi setiap item punya produk terpilih.
    for (final item in _items) {
      if (item['product'] == null) {
        _showError('Setiap item harus memilih produk.');
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final items = _items.map((item) {
        final product = item['product'] as SalesOrderOnlineProduct;
        final qty = int.tryParse(
                (item['qtyController'] as TextEditingController).text) ??
            1;
        final price = int.tryParse(
                (item['priceController'] as TextEditingController).text) ??
            0;
        return SalesOrderItemRequest(
          productId: product.id,
          quantity: qty,
          unitPrice: price,
        );
      }).toList();

      await _salesOrderService.createOnlineOrder(
        selectedStore: _selectedStore!,
        deliveryDate:
            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        onlineShopProviderId: _selectedProvider!.id,
        deliveryServiceId: _selectedDeliveryService!.id,
        receiptNo: _receiptNoController.text.trim(),
        items: items,
        imagePayment: kIsWeb ? null : _imageResi,
        imagePaymentBytes: kIsWeb ? _imageResiBytes : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sales order online berhasil dibuat.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Gagal',
            style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
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

  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m.group(1)}.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Sales Order Online')),
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
                            style: TextStyle(color: colorScheme.error),
                            textAlign: TextAlign.center),
                        AppSpacing.gapVerticalMD,
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoadingData = true;
                              _errorMessage = null;
                            });
                            _loadInitialData();
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    behavior: HitTestBehavior.translucent,
                    child: ListView(
                    padding: AppSpacing.paddingMD,
                    children: [
                      // === Header fields ===
                      Card(
                        child: Padding(
                          padding: AppSpacing.paddingMD,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Informasi Order',
                                  style: textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              AppSpacing.gapVerticalMD,
                               ModernDropdown<StoreModel>(
                                 labelText: 'Toko',
                                 hint: 'Pilih toko...',
                                 isRequired: true,
                                 prefixIcon: const Icon(Icons.storefront, size: 20),
                                 value: _selectedStore,
                                 items: _stores,
                                 getLabel: (s) => s.nickname,
                                 onChanged: (v) =>
                                     setState(() => _selectedStore = v),
                                 validator: (v) =>
                                     v == null ? 'Pilih toko' : null,
                               ),
                               AppSpacing.gapVerticalSM,
                               ModernDropdown<OnlineShopProvider>(
                                 labelText: 'Online Shop Provider',
                                 hint: 'Pilih provider...',
                                 isRequired: true,
                                 prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 20),
                                 value: _selectedProvider,
                                 items: _providers,
                                 getLabel: (p) => p.name,
                                 onChanged: (v) =>
                                     setState(() => _selectedProvider = v),
                                 validator: (v) =>
                                     v == null ? 'Pilih provider' : null,
                               ),
                               AppSpacing.gapVerticalSM,
                               ModernDropdown<DeliveryServiceOption>(
                                 labelText: 'Delivery Service',
                                 hint: 'Pilih kurir...',
                                 isRequired: true,
                                 prefixIcon: const Icon(Icons.local_shipping_outlined, size: 20),
                                 value: _selectedDeliveryService,
                                 items: _deliveryServices,
                                 getLabel: (d) => d.name,
                                 onChanged: (v) =>
                                     setState(() => _selectedDeliveryService = v),
                                 validator: (v) =>
                                     v == null ? 'Pilih delivery service' : null,
                               ),
                              AppSpacing.gapVerticalSM,
                              InkWell(
                                onTap: _pickDate,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Tanggal Pengiriman *',
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  child: Text(
                                    '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                  ),
                                ),
                              ),
                              AppSpacing.gapVerticalSM,
                              TextFormField(
                                controller: _receiptNoController,
                                decoration: InputDecoration(
                                  labelText: 'Nomor Resi *',
                                  prefixIcon: const Icon(Icons.receipt_outlined),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.qr_code_scanner),
                                    tooltip: 'Scan Barcode / QR',
                                    onPressed: _scanBarcode,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Nomor resi wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              AppSpacing.gapVerticalSM,
                              // Image resi
                              if (_imageResi != null || _imageResiBytes != null) ...[
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: AppSpacing.borderRadiusMD,
                                      child: kIsWeb
                                          ? Image.memory(_imageResiBytes!,
                                              height: 180,
                                              width: double.infinity,
                                              fit: BoxFit.cover)
                                          : Image.file(_imageResi!,
                                              height: 180,
                                              width: double.infinity,
                                              fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.success,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle,
                                                color: Colors.white, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Siap diunggah',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                AppSpacing.gapVerticalSM,
                              ],
                              OutlinedButton.icon(
                                onPressed: _pickImage,
                                icon: Icon(
                                  (_imageResi == null && _imageResiBytes == null)
                                      ? Icons.add_a_photo
                                      : Icons.edit,
                                  size: 18,
                                ),
                                label: Text(
                                    (_imageResi == null && _imageResiBytes == null)
                                        ? 'Unggah Foto Resi (Opsional)'
                                        : 'Ganti Foto Resi'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppSpacing.gapVerticalMD,

                      // === Items ===
                      Card(
                        child: Padding(
                          padding: AppSpacing.paddingMD,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Detail Item',
                                      style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle),
                                    color: colorScheme.primary,
                                    onPressed: _addItem,
                                  ),
                                ],
                              ),
                              ..._items.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                return _buildItemRow(idx, item, theme);
                              }),
                              if (_items.isEmpty)
                                Padding(
                                  padding: AppSpacing.paddingVerticalMD,
                                  child: Center(
                                    child: Text(
                                      'Belum ada item. Tap + untuk menambah.',
                                      style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                ),
                              const Divider(height: 32),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total',
                                      style: textTheme.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  StatefulBuilder(
                                    builder: (context, setInner) {
                                      // Re-render total saat items berubah.
                                      return Text(
                                        'Rp ${_formatCurrency(_totalPrice)}',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppSpacing.gapVerticalMD,
                    ],
                    ),
                  ),
                ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return GlassContainer.bottomBar(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm + 4, AppSpacing.md, AppSpacing.lg),
      child: SafeArea(
        child: ModernButton(
          text: 'Simpan Sales Order',
          onPressed: _isSubmitting ? null : _submit,
          isLoading: _isSubmitting,
        ),
      ),
    );
  }

  Widget _buildItemRow(int idx, Map<String, dynamic> item, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final product = item['product'] as SalesOrderOnlineProduct?;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ModernDropdown<SalesOrderOnlineProduct>(
                  labelText: 'Produk',
                  hint: 'Pilih produk...',
                  value: product,
                  items: _products,
                  getLabel: (p) => p.name,
                  getSubtitle: (p) => p.unit,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        item['product'] = v;
                        item['product_id'] = v.id;
                      });
                    }
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
          AppSpacing.gapVerticalSM,
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: item['qtyController'] as TextEditingController,
                  keyboardType: TextInputType.number,
                  onTap: () {
                    final ctrl = item['qtyController'] as TextEditingController;
                    ctrl.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: ctrl.text.length,
                    );
                  },
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    isDense: true,
                    suffixText: product?.unit,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              AppSpacing.gapHorizontalSM,
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: item['priceController'] as TextEditingController,
                  keyboardType: TextInputType.number,
                  onTap: () {
                    final ctrl = item['priceController'] as TextEditingController;
                    ctrl.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: ctrl.text.length,
                    );
                  },
                  decoration: const InputDecoration(
                    labelText: 'Harga Satuan',
                    isDense: true,
                    prefixText: 'Rp ',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Subtotal: Rp ${_formatCurrency((_itemSubtotal(item)))}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  int _itemSubtotal(Map<String, dynamic> item) {
    final qty = int.tryParse(
            (item['qtyController'] as TextEditingController).text) ??
        0;
    final price = int.tryParse(
            (item['priceController'] as TextEditingController).text) ??
        0;
    return qty * price;
  }
}

class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage();

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode != null && barcode.rawValue != null) {
      _hasScanned = true;
      Navigator.pop(context, barcode.rawValue);
    }
  }

  Future<void> _scanFromGallery() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo == null) return;
      final controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
      final result = await controller.analyzeImage(photo.path);
      await controller.dispose();
      final barcode = result?.barcodes.firstOrNull;
      if (barcode != null && barcode.rawValue != null) {
        if (mounted) Navigator.pop(context, barcode.rawValue);
      } else {
        if (mounted) {
          final cs = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tidak ditemukan barcode/QR pada gambar.', style: TextStyle(color: Colors.white)),
              backgroundColor: cs.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses gambar: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: cs.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Resi / Barcode / QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Ambil dari Galeri',
            onPressed: _scanFromGallery,
          ),
          ValueListenableBuilder(
            valueListenable: _controller!,
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
                onPressed: () => _controller!.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 280,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.surface, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              'Arahkan kamera ke QR code atau Barcode resi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.surface.withValues(alpha: 0.8),
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
