import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/procurement_model.dart';
import '../services/closing_store_service.dart';
import '../services/image_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class CreatePaymentReceiptPage extends StatefulWidget {
  final List<InvoicePurchase>? invoices;
  final List<dynamic>? dailySalaries;
  const CreatePaymentReceiptPage({super.key, this.invoices, this.dailySalaries});

  @override
  State<CreatePaymentReceiptPage> createState() => _CreatePaymentReceiptPageState();
}

class _CreatePaymentReceiptPageState extends State<CreatePaymentReceiptPage> {
  final ClosingStoreService _service = ClosingStoreService();
  final _formKey = GlobalKey<FormState>();
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Payment type: 1 = FuelService, 2 = DailySalary
  int _paymentFor = 1;

  // Fuel Service states
  List<dynamic> _fuelServiceUsers = [];
  List<dynamic> _fuelServices = [];
  int? _selectedFuelServiceUserId;
  final Set<int> _selectedFuelServiceIds = {};

  // Daily Salary states
  List<dynamic> _employees = [];
  List<dynamic> _dailySalaries = [];
  int? _selectedEmployeeId;
  final Set<int> _selectedDailySalaryIds = {};

  // Invoice states (for backward compatibility)
  List<InvoicePurchase> _invoices = [];
  int? _selectedSupplierId;

  // Common states
  final _transferAmountController = TextEditingController();
  final _notesController = TextEditingController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    if (widget.invoices != null && widget.invoices!.isNotEmpty) {
      _invoices = widget.invoices!;
      _paymentFor = 3; // InvoicePurchase
      _selectedSupplierId = _invoices.first.supplierId;
      final totalAmount = _invoices.fold<int>(0, (sum, inv) => sum + inv.totalPrice);
      _transferAmountController.text = totalAmount.toString();
      _isLoadingData = false;
    } else if (widget.dailySalaries != null && widget.dailySalaries!.isNotEmpty) {
      _paymentFor = 2; // DailySalary
      _dailySalaries = widget.dailySalaries!;
      _selectedDailySalaryIds.addAll(_dailySalaries.map((s) => s['id'] as int));
      _selectedEmployeeId = _dailySalaries.first['created_by']?['id'];
      _updateTotalAmount();
      _isLoadingData = false;
    } else {
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _transferAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.getUsersForFuelServicePayment(),
        _service.getEmployeesForDailySalary(),
      ]);

      if (!mounted) return;
      setState(() {
        _fuelServiceUsers = results[0];
        _employees = results[1];
        _isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingData = false;
      });
    }
  }

  Future<void> _loadFuelServices(int userId) async {
    try {
      final services = await _service.getFuelServicesForPayment(createdById: userId);
      if (!mounted) return;
      setState(() {
        _fuelServices = services;
        _selectedFuelServiceIds.clear();
        _transferAmountController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data bensin/servis: $e')),
      );
    }
  }

  Future<void> _loadDailySalaries(int userId) async {
    try {
      final salaries = await _service.getDailySalariesForPayment(userId: userId);
      if (!mounted) return;
      setState(() {
        _dailySalaries = salaries;
        _selectedDailySalaryIds.clear();
        _transferAmountController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data daily salary: $e')),
      );
    }
  }

  void _updateTotalAmount() {
    int total = 0;
    if (_paymentFor == 1) {
      for (final service in _fuelServices) {
        if (_selectedFuelServiceIds.contains(service['id'])) {
          total += int.tryParse(service['amount'].toString()) ?? 0;
        }
      }
    } else {
      for (final salary in _dailySalaries) {
        if (_selectedDailySalaryIds.contains(salary['id'])) {
          total += int.tryParse(salary['amount'].toString()) ?? 0;
        }
      }
    }
    _transferAmountController.text = total.toString();
  }

  Future<void> _pickImage() async {
    try {
      final photo = await ImageService.selectAndPickImage(context);
      if (photo != null && mounted) {
        setState(() => _selectedImage = photo);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_paymentFor == 1 && _selectedFuelServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 item bensin/servis.')),
      );
      return;
    }

    if (_paymentFor == 2 && _selectedDailySalaryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 item daily salary.')),
      );
      return;
    }

    final transferAmount = int.tryParse(_transferAmountController.text) ?? 0;
    if (transferAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah transfer harus lebih dari 0.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final data = <String, dynamic>{
        'payment_for': _paymentFor,
        'transfer_amount': transferAmount,
      };

      if (_paymentFor == 1) {
        data['fuel_service_created_by'] = _selectedFuelServiceUserId;
        data['fuelServices'] = _selectedFuelServiceIds.toList();
      } else if (_paymentFor == 2) {
        data['user_id'] = _selectedEmployeeId;
        data['dailySalaries'] = _selectedDailySalaryIds.toList();
      } else if (_paymentFor == 3) {
        data['supplier_id'] = _selectedSupplierId;
        data['invoicePurchases'] = _invoices.map((inv) => inv.id).toList();
      }

      if (_notesController.text.isNotEmpty) {
        data['notes'] = _notesController.text;
      }

      await _service.createPaymentReceipt(data, imageFile: _selectedImage);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment receipt berhasil dibuat.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(color: Colors.white)),
          backgroundColor: cs.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Payment Receipt')),
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
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: AppSpacing.paddingMD,
                    children: [
                      // Payment Type Selection
                      Card(
                        child: Padding(
                          padding: AppSpacing.paddingMD,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Jenis Pembayaran',
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              AppSpacing.gapVerticalSM,
                              SegmentedButton<int>(
                                segments: const [
                                  ButtonSegment(value: 1, label: Text('Bensin & Servis'), icon: Icon(Icons.local_gas_station)),
                                  ButtonSegment(value: 2, label: Text('Daily Salary'), icon: Icon(Icons.account_balance_wallet)),
                                  ButtonSegment(value: 3, label: Text('Invoice'), icon: Icon(Icons.receipt_long)),
                                ],
                                selected: {_paymentFor},
                                onSelectionChanged: widget.invoices != null
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _paymentFor = value.first;
                                          _selectedFuelServiceUserId = null;
                                          _selectedEmployeeId = null;
                                          _fuelServices = [];
                                          _dailySalaries = [];
                                          _selectedFuelServiceIds.clear();
                                          _selectedDailySalaryIds.clear();
                                          _transferAmountController.clear();
                                        });
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppSpacing.gapVerticalMD,

                      // Fuel Service Section
                      if (_paymentFor == 1) ...[
                        Card(
                          child: Padding(
                            padding: AppSpacing.paddingMD,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pilih Created By',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                AppSpacing.gapVerticalSM,
                                DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Created By *',
                                    isDense: true,
                                  ),
                                  value: _selectedFuelServiceUserId,
                                  items: _fuelServiceUsers.map((user) {
                                    return DropdownMenuItem<int>(
                                      value: user['id'],
                                      child: Text(user['name'] ?? '-'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedFuelServiceUserId = value);
                                    if (value != null) _loadFuelServices(value);
                                  },
                                  validator: (v) => v == null ? 'Pilih created by' : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        AppSpacing.gapVerticalMD,

                        if (_fuelServices.isNotEmpty) ...[
                          Card(
                            child: Padding(
                              padding: AppSpacing.paddingMD,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Pilih Item',
                                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            if (_selectedFuelServiceIds.length == _fuelServices.length) {
                                              _selectedFuelServiceIds.clear();
                                            } else {
                                              _selectedFuelServiceIds.addAll(
                                                  _fuelServices.map((s) => s['id'] as int));
                                            }
                                          });
                                          _updateTotalAmount();
                                        },
                                        child: Text(
                                          _selectedFuelServiceIds.length == _fuelServices.length
                                              ? 'Batal Pilih Semua'
                                              : 'Pilih Semua',
                                        ),
                                      ),
                                    ],
                                  ),
                                  AppSpacing.gapVerticalSM,
                                  ...(_fuelServices.map((service) {
                                    final id = service['id'] as int;
                                    final amount = double.tryParse(service['amount'].toString()) ?? 0;
                                    final isSelected = _selectedFuelServiceIds.contains(id);
                                    return CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text('Item #$id'),
                                      subtitle: Text(currencyFormatter.format(amount)),
                                      value: isSelected,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedFuelServiceIds.add(id);
                                          } else {
                                            _selectedFuelServiceIds.remove(id);
                                          }
                                        });
                                        _updateTotalAmount();
                                      },
                                    );
                                  })),
                                ],
                              ),
                            ),
                          ),
                          AppSpacing.gapVerticalMD,
                        ],
                      ],

                      // Daily Salary Section
                      if (_paymentFor == 2) ...[
                        Card(
                          child: Padding(
                            padding: AppSpacing.paddingMD,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pilih Karyawan',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                AppSpacing.gapVerticalSM,
                                DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Karyawan *',
                                    isDense: true,
                                  ),
                                  value: _selectedEmployeeId,
                                  items: _employees.map((emp) {
                                    return DropdownMenuItem<int>(
                                      value: emp['id'],
                                      child: Text(emp['name'] ?? '-'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedEmployeeId = value);
                                    if (value != null) _loadDailySalaries(value);
                                  },
                                  validator: (v) => v == null ? 'Pilih karyawan' : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        AppSpacing.gapVerticalMD,

                        if (_dailySalaries.isNotEmpty) ...[
                          Card(
                            child: Padding(
                              padding: AppSpacing.paddingMD,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Pilih Item',
                                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            if (_selectedDailySalaryIds.length == _dailySalaries.length) {
                                              _selectedDailySalaryIds.clear();
                                            } else {
                                              _selectedDailySalaryIds.addAll(
                                                  _dailySalaries.map((s) => s['id'] as int));
                                            }
                                          });
                                          _updateTotalAmount();
                                        },
                                        child: Text(
                                          _selectedDailySalaryIds.length == _dailySalaries.length
                                              ? 'Batal Pilih Semua'
                                              : 'Pilih Semua',
                                        ),
                                      ),
                                    ],
                                  ),
                                  AppSpacing.gapVerticalSM,
                                  ...(_dailySalaries.map((salary) {
                                    final id = salary['id'] as int;
                                    final amount = double.tryParse(salary['amount'].toString()) ?? 0;
                                    final date = salary['date'] ?? '';
                                    final isSelected = _selectedDailySalaryIds.contains(id);
                                    return CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text('Salary #$id'),
                                      subtitle: Text('$date - ${currencyFormatter.format(amount)}'),
                                      value: isSelected,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedDailySalaryIds.add(id);
                                          } else {
                                            _selectedDailySalaryIds.remove(id);
                                          }
                                        });
                                        _updateTotalAmount();
                                      },
                                    );
                                  })),
                                ],
                              ),
                            ),
                          ),
                          AppSpacing.gapVerticalMD,
                        ],
                      ],

                      // Invoice Section
                      if (_paymentFor == 3 && _invoices.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: AppSpacing.paddingMD,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Invoice Terpilih',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                AppSpacing.gapVerticalSM,
                                ...(_invoices.map((inv) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Invoice #${inv.id}',
                                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                              Text(inv.supplierName ?? '-',
                                                  style: theme.textTheme.bodySmall),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          currencyFormatter.format(inv.totalPrice),
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })),
                              ],
                            ),
                          ),
                        ),
                        AppSpacing.gapVerticalMD,
                      ],

                      // Payment Details
                      Card(
                        child: Padding(
                          padding: AppSpacing.paddingMD,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Detail Pembayaran',
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              AppSpacing.gapVerticalSM,
                              TextFormField(
                                controller: _transferAmountController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Total Pembayaran',
                                  prefixText: 'Rp ',
                                  isDense: true,
                                ),
                              ),
                              AppSpacing.gapVerticalSM,
                              TextFormField(
                                controller: _notesController,
                                decoration: const InputDecoration(
                                  labelText: 'Catatan',
                                  isDense: true,
                                ),
                                maxLines: 2,
                              ),
                              AppSpacing.gapVerticalSM,
                              // Image preview
                              if (_selectedImage != null) ...[
                                ClipRRect(
                                  borderRadius: AppSpacing.borderRadiusMD,
                                  child: kIsWeb
                                      ? Image.network(
                                          _selectedImage!.path,
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          _selectedImage!,
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                AppSpacing.gapVerticalSM,
                              ],
                              OutlinedButton.icon(
                                onPressed: _pickImage,
                                icon: Icon(
                                  _selectedImage == null ? Icons.add_a_photo : Icons.edit,
                                  size: 18,
                                ),
                                label: Text(
                                  _selectedImage == null ? 'Unggah Bukti (Opsional)' : 'Ganti Foto',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppSpacing.gapVerticalMD,

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Buat Payment Receipt'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
