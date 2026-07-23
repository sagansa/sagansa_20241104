import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/closing_store_service.dart';
import '../services/fuel_service_service.dart';
import '../services/image_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/modern_dropdown.dart';
import '../widgets/supplier_picker_modal.dart';

class FuelServiceFormPage extends StatefulWidget {
  const FuelServiceFormPage({super.key});

  @override
  State<FuelServiceFormPage> createState() => _FuelServiceFormPageState();
}

class _FuelServiceFormPageState extends State<FuelServiceFormPage> {
  final ClosingStoreService _lookupService = ClosingStoreService();
  final FuelServiceService _service = FuelServiceService();
  final _formKey = GlobalKey<FormState>();

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<dynamic> _vehicles = [];
  List<dynamic> _suppliers = [];

  // Form states
  DateTime _selectedDate = DateTime.now();
  int _selectedType = 1; // 1 = Fuel, 2 = Service
  int? _selectedVehicleId;
  double? _vehicleLastKm; // KM terakhir kendaraan terpilih (untuk validasi).
  int? _selectedSupplierId;
  int _selectedPaymentType = 2; // 2 = Tunai, 1 = Transfer
  
  final _kmController = TextEditingController(text: '0');
  final _literController = TextEditingController(text: '0');
  final _amountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  final List<Map<String, dynamic>> _serviceServiceDetails = [];
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _kmController.dispose();
    _literController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (var detail in _serviceServiceDetails) {
      (detail['nameController'] as TextEditingController).dispose();
      (detail['costController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      final vehiclesData = await _lookupService.getVehicles();
      final suppliersData = await _lookupService.getSuppliers();
      setState(() {
        _vehicles = vehiclesData;
        _suppliers = suppliersData;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingData = false;
      });
    }
  }

  void _updateServiceAmount() {
    if (_selectedType == 2) {
      double total = 0;
      for (var detail in _serviceServiceDetails) {
        total += double.tryParse((detail['costController'] as TextEditingController).text) ?? 0;
      }
      _amountController.text = total.toStringAsFixed(0);
    }
  }

  Future<int?> _showSupplierSearchDialog(BuildContext ctx, List<dynamic> suppliers) {
    return showDialog<int>(
      context: ctx,
      builder: (dialogCtx) {
        String query = '';
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final filtered = suppliers.where((s) {
              if (query.isEmpty) return true;
              return (s['name'] ?? '').toString().toLowerCase().contains(query.toLowerCase());
            }).toList();

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 80),
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
                              onTap: () => Navigator.pop(dialogCtx, filtered[i]['id']),
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
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto bukti / nota wajib diunggah!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'date': _selectedDate.toIso8601String().split('T')[0],
        'fuel_service': _selectedType,
        'vehicle_id': _selectedVehicleId,
        'supplier_id': _selectedSupplierId,
        'payment_type_id': _selectedPaymentType,
        'km': double.tryParse(_kmController.text) ?? 0,
        'liter': double.tryParse(_literController.text) ?? 0,
        'amount': double.tryParse(_amountController.text) ?? 0,
        'notes': _notesController.text,
        if (_selectedType == 2)
          'service_details': _serviceServiceDetails.map((d) {
            return {
              'name': (d['nameController'] as TextEditingController).text,
              'price': double.tryParse((d['costController'] as TextEditingController).text) ?? 0,
            };
          }).toList(),
      };

      await _service.createFuelService(payload, imageFile: _selectedImage);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi bensin/servis berhasil disimpan.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan transaksi bensin/servis: $e')),
        );
      }
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Bensin / Servis'),
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
                        const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                        AppSpacing.gapVerticalMD,
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge,
                        ),
                        AppSpacing.gapVerticalLG,
                        ElevatedButton(
                          onPressed: _loadFormData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: AppSpacing.paddingMD,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type Radio Group
                        Text('Tipe Pengeluaran:', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        AppSpacing.gapVerticalXS,
                        RadioGroup<int>(
                          groupValue: _selectedType,
                          onChanged: (val) {
                            setState(() {
                              _selectedType = val!;
                              if (val == 1) {
                                _amountController.text = '0';
                              } else {
                                _updateServiceAmount();
                              }
                            });
                          },
                          child: Row(
                            children: [
                              Radio<int>(
                                value: 1,
                              ),
                              const Text('Fuel (Bensin)'),
                              const SizedBox(width: AppSpacing.lg),
                              Radio<int>(
                                value: 2,
                              ),
                              const Text('Service (Servis)'),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),

                        // Date picker
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Tanggal: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),

                        // Vehicle Dropdown
                        ModernDropdown<int>(
                          labelText: 'Pilih Kendaraan',
                          hint: 'Pilih kendaraan...',
                          isRequired: true,
                          prefixIcon: const Icon(Icons.directions_car_outlined, size: 20),
                          value: _selectedVehicleId,
                          items: _vehicles.map((v) => v['id'] as int).toList(),
                          getLabel: (val) {
                            final v = _vehicles.firstWhere((e) => e['id'] == val, orElse: () => {});
                            return v['no_register']?.toString() ?? '';
                          },
                          getSubtitle: (val) {
                            final v = _vehicles.firstWhere((e) => e['id'] == val, orElse: () => {});
                            return v['name']?.toString() ?? '';
                          },
                          onChanged: (val) => setState(() {
                            _selectedVehicleId = val;
                            // Set last_km dari kendaraan terpilih untuk validasi KM.
                            final v = _vehicles.firstWhere(
                              (e) => e['id'] == val,
                              orElse: () => {},
                            );
                            final lastKm = v['last_km'];
                            _vehicleLastKm = lastKm is num
                                ? lastKm.toDouble()
                                : double.tryParse(lastKm?.toString() ?? '');
                            // Pre-fill KM dengan last_km bila kosong/0.
                            if ((_kmController.text.isEmpty ||
                                    (double.tryParse(_kmController.text) ?? 0) <= 0) &&
                                _vehicleLastKm != null) {
                              _kmController.text =
                                  _vehicleLastKm!.toStringAsFixed(0);
                            }
                          }),
                          validator: (val) => val == null ? 'Pilih kendaraan' : null,
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),

                        // Supplier Dropdown (searchable)
                        InkWell(
                          onTap: () async {
                            final res = await SupplierPickerModal.show(
                              context: context,
                              suppliers: _suppliers,
                              selectedSupplierId: _selectedSupplierId,
                            );
                            if (res != null) {
                              setState(() => _selectedSupplierId = res['id']);
                            }
                          },
                          borderRadius: AppSpacing.borderRadiusXS,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Pilih Supplier (Opsional)',
                              suffixIcon: Icon(Icons.search),
                            ),
                            child: Text(
                              _selectedSupplierId != null
                                  ? (_suppliers.firstWhere(
                                      (s) => s['id'] == _selectedSupplierId,
                                      orElse: () => {'name': ''},
                                    )['name'] ?? '')
                                  : '',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),

                        // Payment Type
                        Text('Tipe Pembayaran:', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        AppSpacing.gapVerticalXS,
                        RadioGroup<int>(
                          groupValue: _selectedPaymentType,
                          onChanged: (val) => setState(() => _selectedPaymentType = val!),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: 2,
                              ),
                              const Text('Tunai'),
                              AppSpacing.gapHorizontalMD,
                              Radio<int>(
                                value: 1,
                              ),
                              const Text('Transfer'),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),

                        // KM Input
                        TextFormField(
                          controller: _kmController,
                          decoration: InputDecoration(
                            labelText: 'KM Kendaraan *',
                            suffixText: 'km',
                            helperText: _vehicleLastKm != null
                                ? 'KM terakhir tercatat: ${_vehicleLastKm!.toStringAsFixed(0)} km'
                                : null,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            final km = double.tryParse(val ?? '') ?? 0;
                            if (km <= 0) {
                              return 'KM harus lebih besar dari 0';
                            }
                            if (_vehicleLastKm != null && km < _vehicleLastKm!) {
                              return 'KM tidak boleh lebih kecil dari km terakhir '
                                  '(${_vehicleLastKm!.toStringAsFixed(0)} km)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),

                        // Liter Input (Bensin Only)
                        if (_selectedType == 1) ...[
                          TextFormField(
                            controller: _literController,
                            decoration: const InputDecoration(
                              labelText: 'Jumlah Liter',
                              suffixText: 'liter',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: AppSpacing.sectionGap),
                        ],

                        // Service Details Repeater (Service Only)
                        if (_selectedType == 2) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Rincian Service:',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _serviceServiceDetails.add({
                                      'nameController': TextEditingController(),
                                      'costController': TextEditingController(text: '0'),
                                    });
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Tambah Item'),
                              ),
                            ],
                          ),
                          AppSpacing.gapVerticalSM,
                          ..._serviceServiceDetails.map((detail) {
                            final idx = _serviceServiceDetails.indexOf(detail);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: detail['nameController'] as TextEditingController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nama Item/Part',
                                      ),
                                    ),
                                  ),
                                  AppSpacing.gapHorizontalSM,
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: detail['costController'] as TextEditingController,
                                      decoration: const InputDecoration(
                                        labelText: 'Biaya',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) => setState(() => _updateServiceAmount()),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                                    onPressed: () {
                                      setState(() {
                                        _serviceServiceDetails.removeAt(idx);
                                        _updateServiceAmount();
                                      });
                                    },
                                  )
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: AppSpacing.sectionGap),
                        ],

                        // Amount Input
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Total Biaya (Amount) *',
                            prefixText: 'Rp ',
                          ),
                          keyboardType: TextInputType.number,
                          readOnly: _selectedType == 2,
                          validator: (val) => (double.tryParse(val ?? '0') ?? 0) <= 0 ? 'Masukkan total biaya' : null,
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),

                        // Notes Input
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Catatan / Notes',
                          ),
                          maxLines: 2,
                        ),
                        AppSpacing.gapVerticalLG,

                        // Foto Bukti
                        Text('Foto Bukti / Nota *:', style: theme.textTheme.bodyMedium),
                        AppSpacing.gapVerticalXS,
                        Row(
                          children: [
                            if (_selectedImage != null) ...[
                              ClipRRect(
                                borderRadius: AppSpacing.borderRadiusSM,
                                child: Image.file(
                                  _selectedImage!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              AppSpacing.gapHorizontalMD,
                            ],
                            OutlinedButton.icon(
                              onPressed: () async {
                                final File? file = await ImageService.selectAndPickImage(context);
                                if (file != null) {
                                  setState(() {
                                    _selectedImage = file;
                                  });
                                }
                              },
                              icon: const Icon(Icons.add_a_photo),
                              label: Text(_selectedImage == null ? 'Unggah Foto *' : 'Ubah Foto'),
                            ),
                            if (_selectedImage != null) ...[
                              AppSpacing.gapHorizontalSM,
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                        AppSpacing.gapVerticalXL,
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm + 4, AppSpacing.md, AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Simpan Transaksi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
