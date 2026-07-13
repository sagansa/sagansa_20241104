import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/closing_store_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/modern_bottom_sheet.dart';
import '../widgets/modern_text_form_field.dart';

class ClosingStorePage extends StatefulWidget {
  const ClosingStorePage({super.key});

  @override
  State<ClosingStorePage> createState() => _ClosingStorePageState();
}

class _ClosingStorePageState extends State<ClosingStorePage> {
  final ClosingStoreService _service = ClosingStoreService();
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  String? _errorMessage;

  // Active Draft Data
  Map<String, dynamic>? _closingData;
  List<dynamic> _cashlessList = [];

  // Available unpaid transactions for checkboxes
  List<dynamic> _availableFuelServices = [];
  List<dynamic> _availableDailySalaries = [];
  List<dynamic> _availableInvoicePurchases = [];

  // Selected IDs
  final Set<int> _selectedFuelServiceIds = {};
  final Set<int> _selectedDailySalaryIds = {};
  final Set<int> _selectedInvoicePurchaseIds = {};

  // Controllers
  final TextEditingController _cashForTomorrowController = TextEditingController(text: '0');
  final TextEditingController _totalCashTransferController = TextEditingController(text: '0');
  final TextEditingController _notesController = TextEditingController();
  final Map<int, TextEditingController> _cashlessControllers = {};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _cashForTomorrowController.dispose();
    _totalCashTransferController.dispose();
    _notesController.dispose();
    for (var ctrl in _cashlessControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Get active draft
      final draft = await _service.getActiveDraft();
      
      // 2. Get unpaid transactions
      final unpaid = await _service.getUnpaidTransactions();

      setState(() {
        _closingData = draft;
        _cashlessList = draft['cashlesses'] ?? [];

        // Pre-fill controllers
        _cashForTomorrowController.text = (draft['cash_for_tomorrow'] ?? 0).toString();
        _totalCashTransferController.text = (draft['total_cash_transfer'] ?? 0).toString();
        _notesController.text = draft['notes'] ?? '';

        for (var c in _cashlessList) {
          final id = c['id'] as int;
          _cashlessControllers[id] = TextEditingController(
            text: (c['bruto_apl'] ?? 0).toString(),
          );
          // Add listener to rebuild/recalculate on change
          _cashlessControllers[id]!.addListener(() {
            setState(() {});
          });
        }

        // Set selected IDs based on draft
        _selectedFuelServiceIds.clear();
        if (draft['fuel_services'] != null) {
          for (var f in draft['fuel_services']) {
            _selectedFuelServiceIds.add(f['id'] as int);
          }
        }

        _selectedDailySalaryIds.clear();
        if (draft['daily_salaries'] != null) {
          for (var s in draft['daily_salaries']) {
            _selectedDailySalaryIds.add(s['id'] as int);
          }
        }

        _selectedInvoicePurchaseIds.clear();
        if (draft['invoice_purchases'] != null) {
          for (var i in draft['invoice_purchases']) {
            _selectedInvoicePurchaseIds.add(i['id'] as int);
          }
        }

        // Load available lists (and merge currently selected ones to make sure they are in the list)
        final Map<int, dynamic> fuelMap = {};
        for (var f in unpaid['fuel_services'] ?? []) {
          fuelMap[f['id'] as int] = f;
        }
        if (draft['fuel_services'] != null) {
          for (var f in draft['fuel_services']) {
            fuelMap[f['id'] as int] = f;
          }
        }
        _availableFuelServices = fuelMap.values.toList();

        final Map<int, dynamic> salaryMap = {};
        for (var s in unpaid['daily_salaries'] ?? []) {
          salaryMap[s['id'] as int] = s;
        }
        if (draft['daily_salaries'] != null) {
          for (var s in draft['daily_salaries']) {
            salaryMap[s['id'] as int] = s;
          }
        }
        _availableDailySalaries = salaryMap.values.toList();

        final Map<int, dynamic> invoiceMap = {};
        for (var i in unpaid['invoice_purchases'] ?? []) {
          invoiceMap[i['id'] as int] = i;
        }
        if (draft['invoice_purchases'] != null) {
          for (var i in draft['invoice_purchases']) {
            invoiceMap[i['id'] as int] = i;
          }
        }
        _availableInvoicePurchases = invoiceMap.values.toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Calculations
  double get _cashFromYesterday => double.tryParse((_closingData?['cash_from_yesterday'] ?? 0).toString()) ?? 0;
  double get _cashForTomorrow => double.tryParse(_cashForTomorrowController.text) ?? 0;
  double get _totalCashTransfer => double.tryParse(_totalCashTransferController.text) ?? 0;

  double get _totalCashless {
    double total = 0;
    for (var ctrl in _cashlessControllers.values) {
      total += double.tryParse(ctrl.text) ?? 0;
    }
    return total;
  }

  double get _spendingTotalCash {
    double total = 0;
    for (var f in _availableFuelServices) {
      if (_selectedFuelServiceIds.contains(f['id'])) {
        total += double.tryParse(f['amount'].toString()) ?? 0;
      }
    }
    for (var s in _availableDailySalaries) {
      if (_selectedDailySalaryIds.contains(s['id'])) {
        total += double.tryParse(s['amount'].toString()) ?? 0;
      }
    }
    for (var i in _availableInvoicePurchases) {
      if (_selectedInvoicePurchaseIds.contains(i['id'])) {
        total += double.tryParse(i['amount'].toString()) ?? 0;
      }
    }
    return total;
  }

  double get _totalCash {
    return _cashForTomorrow - _cashFromYesterday + _spendingTotalCash + _totalCashTransfer;
  }

  double get _totalOmzet {
    return _totalCash + _totalCashless;
  }

  Future<void> _submit() async {
    if (_closingData == null) return;

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'id': _closingData!['id'],
        'cash_for_tomorrow': _cashForTomorrow,
        'total_cash_transfer': _totalCashTransfer,
        'notes': _notesController.text,
        'cashlesses': _cashlessList.map((c) {
          final id = c['id'] as int;
          return {
            'id': id,
            'bruto_apl': double.tryParse(_cashlessControllers[id]?.text ?? '0') ?? 0,
          };
        }).toList(),
        'fuel_service_ids': _selectedFuelServiceIds.toList(),
        'daily_salary_ids': _selectedDailySalaryIds.toList(),
        'invoice_purchase_ids': _selectedInvoicePurchaseIds.toList(),
      };

      await _service.saveClosingStore(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan Closing Store berhasil disimpan.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Gagal Menyimpan', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: Theme.of(ctx).colorScheme.error)),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showAddFuelServiceBottomSheet() async {
    if (_closingData == null) return;
    
    setState(() => _isLoading = true);
    List<dynamic> vehicles = [];
    List<dynamic> suppliers = [];
    try {
      vehicles = await _service.getVehicles();
      suppliers = await _service.getSuppliers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data kendaraan/supplier: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }

    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();
    int selectedType = 1; // 1 = Fuel, 2 = Service
    int? selectedVehicleId;
    int? selectedSupplierId;
    final kmController = TextEditingController(text: '0');
    final literController = TextEditingController(text: '0');
    final amountController = TextEditingController(text: '0');
    final notesController = TextEditingController();

    // Service details list
    final List<Map<String, dynamic>> serviceDetails = [];

    ModernBottomSheet.show(
      context: context,
      title: 'Tambah Fuel / Service Baru',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          void updateServiceAmount() {
            if (selectedType == 2) {
              double total = 0;
              for (var detail in serviceDetails) {
                total += double.tryParse(detail['costController'].text) ?? 0;
              }
              amountController.text = total.toStringAsFixed(0);
            }
          }

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
                      
                      // Type Radio
                      RadioGroup<int>(
                        groupValue: selectedType,
                        onChanged: (val) {
                          setModalState(() {
                            selectedType = val!;
                            if (val == 1) {
                              amountController.text = '0';
                            } else {
                              updateServiceAmount();
                            }
                          });
                        },
                        child: Row(
                          children: [
                            Radio<int>(
                              value: 1,
                            ),
                            const Text('Fuel (Bensin)'),
                            AppSpacing.gapHorizontalLG,
                            Radio<int>(
                              value: 2,
                            ),
                            const Text('Service (Servis)'),
                          ],
                        ),
                      ),
                      AppSpacing.gapVerticalSM,

                      // Date picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Tanggal: ${DateFormat('dd MMMM yyyy').format(selectedDate)}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                      ),
                      AppSpacing.gapVerticalSM,

                      // Vehicle Dropdown
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Pilih Kendaraan *',
                        ),
                        initialValue: selectedVehicleId,
                        items: vehicles.map((v) {
                          return DropdownMenuItem<int>(
                            value: v['id'] as int,
                            child: Text(v['no_register'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedVehicleId = val),
                        validator: (val) => val == null ? 'Pilih kendaraan' : null,
                      ),
                      AppSpacing.gapVerticalSM,

                      // Supplier Dropdown
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Pilih Supplier (Opsional)',
                        ),
                        initialValue: selectedSupplierId,
                        items: suppliers.map((s) {
                          return DropdownMenuItem<int>(
                            value: s['id'] as int,
                            child: Text(s['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedSupplierId = val),
                      ),
                      AppSpacing.gapVerticalSM,

                      // KM Input
                      TextFormField(
                        controller: kmController,
                        decoration: const InputDecoration(
                          labelText: 'KM Kendaraan',
                          suffixText: 'km',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      AppSpacing.gapVerticalSM,

                      // Liter Input (Bensin Only)
                      if (selectedType == 1) ...[
                        TextFormField(
                          controller: literController,
                          decoration: const InputDecoration(
                            labelText: 'Jumlah Liter',
                            suffixText: 'liter',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        AppSpacing.gapVerticalSM,
                      ],

                      // Service Details Repeater (Service Only)
                      if (selectedType == 2) ...[
                        Text(
                          'Rincian Service:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        AppSpacing.gapVerticalSM,
                        ...serviceDetails.map((detail) {
                          final idx = serviceDetails.indexOf(detail);
                          return Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.sm),
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
                                    onChanged: (val) => setModalState(() => updateServiceAmount()),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                                  onPressed: () {
                                    setModalState(() {
                                      serviceDetails.removeAt(idx);
                                      updateServiceAmount();
                                    });
                                  },
                                )
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              serviceDetails.add({
                                'nameController': TextEditingController(),
                                'costController': TextEditingController(text: '0'),
                              });
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Item Service'),
                        ),
                        AppSpacing.gapVerticalSM,
                      ],

                      // Amount Input
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Total Biaya (Amount) *',
                          prefixText: 'Rp ',
                        ),
                        keyboardType: TextInputType.number,
                        readOnly: selectedType == 2, // Read-only if service
                        validator: (val) => (double.tryParse(val ?? '0') ?? 0) <= 0 ? 'Masukkan total biaya' : null,
                      ),
                      AppSpacing.gapVerticalSM,

                      // Notes Input
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan / Notes',
                        ),
                        maxLines: 2,
                      ),
                      AppSpacing.gapVerticalLG,

                      // Actions Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          AppSpacing.gapHorizontalSM,
                          ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                Navigator.pop(context); // Close bottom sheet
                                setState(() => _isLoading = true);
                                try {
                                  final payload = {
                                    'closing_store_id': _closingData!['id'],
                                    'date': selectedDate.toIso8601String().split('T')[0],
                                    'fuel_service': selectedType,
                                    'vehicle_id': selectedVehicleId,
                                    'supplier_id': selectedSupplierId,
                                    'km': double.tryParse(kmController.text) ?? 0,
                                    'liter': double.tryParse(literController.text) ?? 0,
                                    'amount': double.tryParse(amountController.text) ?? 0,
                                    'notes': notesController.text,
                                    if (selectedType == 2)
                                      'service_details': serviceDetails.map((d) {
                                        return {
                                          'name': (d['nameController'] as TextEditingController).text,
                                          'price': double.tryParse((d['costController'] as TextEditingController).text) ?? 0,
                                        };
                                      }).toList(),
                                  };

                                  final newFs = await _service.createFuelService(payload);
                                   
                                  // Refresh lists
                                  await _loadData();
                                   
                                  // Automatically check/select this new transaction
                                  setState(() {
                                    _selectedFuelServiceIds.add(newFs['id'] as int);
                                  });
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal menyimpan transaksi bensin/servis: $e')),
                                  );
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                            child: const Text('Simpan'),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tutup Shift Toko')),
        body: Center(
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
                  onPressed: _loadData,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final storeName = _closingData?['store']?['nickname'] ?? 'Toko';
    final shiftName = _closingData?['shift_store']?['name'] ?? 'Shift';
    final closingDate = _closingData?['date'] ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutup Shift Toko'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: AppSpacing.paddingMD,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.storefront, color: colorScheme.primary),
                    ),
                    AppSpacing.gapHorizontalMD,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$shiftName | $closingDate',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalMD,

            // Cash Info Section
            Text(
              'Aliran Kas Laci Kasir (Cash)',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapVerticalSM,
            Card(
              child: Padding(
                padding: AppSpacing.paddingMD,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Saldo Kas Awal (Kemarin)'),
                      trailing: Text(
                        currencyFormatter.format(_cashFromYesterday),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _cashForTomorrowController,
                      decoration: const InputDecoration(
                        labelText: 'Kas Untuk Besok *',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => setState(() {}),
                    ),
                    SizedBox(height: AppSpacing.sectionGap),
                    TextFormField(
                      controller: _totalCashTransferController,
                      decoration: const InputDecoration(
                        labelText: 'Total Setoran Cash (Bank Transfer) *',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalMD,

            // Cashless List Section
            if (_cashlessList.isNotEmpty) ...[
              Text(
                'Laporan EDC / Cashless',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapVerticalSM,
              Card(
                child: Padding(
                  padding: AppSpacing.paddingMD,
                  child: Column(
                    children: _cashlessList.map((c) {
                      final id = c['id'] as int;
                      final providerName = c['account_cashless']?['cashless_provider']?['name'] ?? 'Provider';
                      final storeCashlessName = c['account_cashless']?['store_cashless']?['name'] ?? '';
                      return Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm + AppSpacing.xs),
                        child: TextFormField(
                          controller: _cashlessControllers[id],
                          decoration: InputDecoration(
                            labelText: '$providerName | $storeCashlessName',
                            prefixText: 'Rp ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              AppSpacing.gapVerticalMD,
            ],

            // Spending Lists
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pengeluaran Bensin & Servis (Cash)',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: _showAddFuelServiceBottomSheet,
                ),
              ],
            ),
            AppSpacing.gapVerticalSM,
            _buildFuelServicesList(colorScheme),
            AppSpacing.gapVerticalMD,

            Text(
              'Pengeluaran Gaji Harian (Cash)',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapVerticalSM,
            _buildDailySalariesList(colorScheme),
            AppSpacing.gapVerticalMD,

            Text(
              'Pengeluaran Invoice & Bon (Cash)',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapVerticalSM,
            _buildInvoicePurchasesList(colorScheme),
            AppSpacing.gapVerticalLG,

            // Calculator Summary Card
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: AppSpacing.paddingMD,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Shift',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sectionGap),
                    _buildSummaryRow(
                      'Total Pengeluaran Laci (Cash)', 
                      currencyFormatter.format(_spendingTotalCash),
                      colorScheme,
                    ),
                    _buildSummaryRow(
                      'Total Cashless/EDC', 
                      currencyFormatter.format(_totalCashless),
                      colorScheme,
                    ),
                    _buildSummaryRow(
                      'Total Cash Fisik Laci', 
                      currencyFormatter.format(_totalCash),
                      colorScheme,
                      isBold: true,
                    ),
                    const Divider(),
                    _buildSummaryRow(
                      'Total Omzet Toko Hari Ini', 
                      currencyFormatter.format(_totalOmzet),
                      colorScheme,
                      isBold: true,
                      large: true,
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalLG,

            // Notes Section
            ModernTextFormField(
              labelText: 'Catatan Closing',
              controller: _notesController,
              maxLines: 3,
            ),
            AppSpacing.gapVerticalXL,

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting 
                  ? CircularProgressIndicator(color: colorScheme.onPrimary)
                  : Text(
                      'Simpan & Selesaikan Shift',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
              ),
            ),
            AppSpacing.gapVerticalXL,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ColorScheme colorScheme, {bool isBold = false, bool large = false}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (large ? textTheme.bodyLarge : textTheme.bodyMedium)?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          Text(
            value,
            style: (large ? textTheme.titleMedium : textTheme.bodyMedium)?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelServicesList(ColorScheme colorScheme) {
    if (_availableFuelServices.isEmpty) {
      return const Text('Tidak ada pengeluaran bensin/servis cash.');
    }
    return Column(
      children: _availableFuelServices.map((f) {
        final id = f['id'] as int;
        final isChecked = _selectedFuelServiceIds.contains(id);
        final date = f['date'] ?? '';
        final amount = double.tryParse(f['amount'].toString()) ?? 0;
        final typeStr = f['fuel_service'] == 1 ? 'Fuel' : 'Service';
        final vehicleNo = f['vehicle']?['no_register'] ?? '';
        
        return CheckboxListTile(
          title: Text('$typeStr | $vehicleNo'),
          subtitle: Text('$date | ${currencyFormatter.format(amount)}'),
          value: isChecked,
          onChanged: (bool? val) {
            setState(() {
              if (val == true) {
                _selectedFuelServiceIds.add(id);
              } else {
                _selectedFuelServiceIds.remove(id);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildDailySalariesList(ColorScheme colorScheme) {
    if (_availableDailySalaries.isEmpty) {
      return const Text('Tidak ada pengeluaran gaji harian cash.');
    }
    return Column(
      children: _availableDailySalaries.map((s) {
        final id = s['id'] as int;
        final isChecked = _selectedDailySalaryIds.contains(id);
        final date = s['date'] ?? '';
        final amount = double.tryParse(s['amount'].toString()) ?? 0;
        final employeeName = s['user']?['name'] ?? 'Pegawai';
        
        return CheckboxListTile(
          title: Text(employeeName),
          subtitle: Text('$date | ${currencyFormatter.format(amount)}'),
          value: isChecked,
          onChanged: (bool? val) {
            setState(() {
              if (val == true) {
                _selectedDailySalaryIds.add(id);
              } else {
                _selectedDailySalaryIds.remove(id);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildInvoicePurchasesList(ColorScheme colorScheme) {
    if (_availableInvoicePurchases.isEmpty) {
      return const Text('Tidak ada pengeluaran invoice/bon cash.');
    }
    return Column(
      children: _availableInvoicePurchases.map((i) {
        final id = i['id'] as int;
        final isChecked = _selectedInvoicePurchaseIds.contains(id);
        final date = i['date'] ?? '';
        final amount = double.tryParse(i['amount'].toString()) ?? 0;
        final invoiceNo = i['no_invoice'] ?? '';
        
        return CheckboxListTile(
          title: Text('Invoice #$invoiceNo'),
          subtitle: Text('$date | ${currencyFormatter.format(amount)}'),
          value: isChecked,
          onChanged: (bool? val) {
            setState(() {
              if (val == true) {
                _selectedInvoicePurchaseIds.add(id);
              } else {
                _selectedInvoicePurchaseIds.remove(id);
              }
            });
          },
        );
      }).toList(),
    );
  }
}
