import 'package:flutter/material.dart';

import '../models/employee_consumption_model.dart';
import '../models/store_model.dart';
import '../services/employee_consumption_service.dart';
import '../services/store_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/glass_container.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_dropdown.dart';

class CreateEmployeeConsumptionPage extends StatefulWidget {
  final EmployeeConsumptionModel? consumption;

  const CreateEmployeeConsumptionPage({super.key, this.consumption});

  @override
  State<CreateEmployeeConsumptionPage> createState() =>
      _CreateEmployeeConsumptionPageState();
}

class _CreateEmployeeConsumptionPageState
    extends State<CreateEmployeeConsumptionPage> {
  final StoreService _storeService = StoreService();
  final EmployeeConsumptionService _service = EmployeeConsumptionService();

  List<StoreModel> _stores = [];
  bool _isLoadingData = true;
  String? _errorMessage;

  StoreModel? _selectedStore;
  DateTime? _selectedDate;
  final List<Map<String, dynamic>> _items = [];
  bool _isSubmitting = false;

  bool get isEditing => widget.consumption != null;

  bool get _isLocked =>
      isEditing && widget.consumption!.status == 2; // Valid tidak bisa diubah

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
      final products = await _service.getProducts();

      final editing = widget.consumption;
      if (editing != null) {
        _selectedStore =
            stores.where((s) => s.id == editing.storeId).firstOrNull;
        _selectedDate = DateTime.tryParse(editing.date);
      }

      _items.clear();
      for (var p in products) {
        final existing = editing?.details
            .where((d) => d.productId == p.id)
            .firstOrNull;
        final controller = TextEditingController(
          text: existing != null ? _qtyText(existing.quantity) : '0',
        );
        _items.add({
          'product_id': p.id,
          'productName': p.name,
          'unitName': p.unitName,
          'controller': controller,
        });
      }

      setState(() {
        _stores = stores;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data awal: $e';
        _isLoadingData = false;
      });
    }
  }

  String _qtyText(double qty) {
    final clean = qty.toStringAsFixed(0);
    return qty == qty.truncateToDouble() ? clean : qty.toString();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Gagal Menyimpan',
            style: Theme.of(ctx)
                .textTheme
                .titleMedium
                ?.copyWith(color: Theme.of(ctx).colorScheme.error)),
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
    final now = DateTime.now();
    final initial = _selectedDate ?? now;
    final clamped = initial.isAfter(now) ? now : initial;
    final date = await showDatePicker(
      context: context,
      initialDate: clamped,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _submitReport() async {
    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih toko terlebih dahulu.')),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal wajib diisi.')),
      );
      return;
    }

    final validItems = _items.where((item) {
      final ctrl = item['controller'] as TextEditingController;
      return (double.tryParse(ctrl.text) ?? 0) > 0;
    }).toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi minimal satu item dengan jumlah > 0.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final itemsApi = validItems.map((item) {
        final ctrl = item['controller'] as TextEditingController;
        return {
          'product_id': item['product_id'],
          'quantity': double.tryParse(ctrl.text) ?? 0.0,
        };
      }).toList();

      final dateStr =
          '${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

      if (isEditing) {
        await _service.updateEmployeeConsumption(
          widget.consumption!.id,
          _selectedStore!.id,
          dateStr,
          itemsApi,
        );
      } else {
        await _service.createEmployeeConsumption(
          _selectedStore!.id,
          dateStr,
          itemsApi,
        );
      }

      if (!mounted) return;
      showSuccessSnackBar(
        context,
        isEditing
            ? 'Sisa stok karyawan berhasil diperbarui.'
            : 'Sisa stok karyawan berhasil disimpan.',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      if (message.contains('valid') || message.contains('tidak dapat diubah')) {
        _showErrorDialog(message);
      } else {
        showErrorSnackBar(context, message);
      }
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
        title:
            Text(isEditing ? 'Edit Sisa Stok Karyawan' : 'Sisa Stok Karyawan Baru'),
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
                            style: textTheme.bodyLarge
                                ?.copyWith(color: colorScheme.error)),
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
                        if (_isLocked)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            color: AppColors.warning.withValues(alpha: 0.15),
                            child: Row(
                              children: [
                                Icon(Icons.lock_outline,
                                    size: 18, color: AppColors.warning),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Data berstatus Valid dan tidak dapat diubah.',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView(
                            padding: AppSpacing.paddingMD,
                            children: [
                              ModernDropdown<StoreModel>(
                                labelText: 'Pilih Toko',
                                hint: 'Pilih toko...',
                                prefixIcon: const Icon(Icons.storefront,
                                    size: 20),
                                value: _selectedStore,
                                items: _stores,
                                enabled: !_isLocked,
                                getLabel: (s) => s.nickname,
                                getSubtitle: (s) => '',
                                onChanged: (val) {
                                  setState(() {
                                    _selectedStore = val;
                                  });
                                },
                              ),
                              AppSpacing.gapVerticalMD,
                              _buildDateField(colorScheme),
                              AppSpacing.gapVerticalMD,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                width: double.infinity,
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                child: Text(
                                  'Isi sisa stok yang belum terjual',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              AppSpacing.gapVerticalSM,
                              ..._items.map((item) {
                                return Padding(
                                  padding:
                                      EdgeInsets.only(bottom: AppSpacing.md),
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
                                          controller:
                                              item['controller'],
                                          keyboardType: TextInputType.number,
                                          enabled: !_isLocked,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            suffixText: item['unitName'],
                                          ),
                                          onTap: () {
                                            final ctrl = item['controller']
                                                as TextEditingController;
                                            ctrl.selection = TextSelection(
                                                baseOffset: 0,
                                                extentOffset: ctrl.text.length);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
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
      bottomNavigationBar: _isLocked
          ? null
          : SafeArea(
              child: GlassContainer.bottomBar(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm + 4, AppSpacing.md, AppSpacing.lg),
                child: ModernButton(
                  text: isEditing ? 'Simpan Perubahan' : 'Simpan Sisa Stok',
                  icon: isEditing
                      ? Icons.save_rounded
                      : Icons.add_circle_rounded,
                  onPressed: _isSubmitting ? null : _submitReport,
                  isLoading: _isSubmitting,
                ),
              ),
            ),
    );
  }

  Widget _buildDateField(ColorScheme colorScheme) {
    return InkWell(
      onTap: _isLocked ? null : _pickDate,
      borderRadius: AppSpacing.borderRadiusSM,
      child: InputDecorator(
        isEmpty: _selectedDate == null,
        decoration: InputDecoration(
          labelText: 'Tanggal *',
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(
          _selectedDate == null
              ? 'Pilih tanggal...'
              : '${_selectedDate!.day.toString().padLeft(2, '0')} ${_monthName(_selectedDate!.month)} ${_selectedDate!.year}',
          style: TextStyle(
            color: _selectedDate == null
                ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return months[month - 1];
  }
}