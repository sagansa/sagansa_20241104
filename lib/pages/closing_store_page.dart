import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/closing_store_service.dart';
import '../services/image_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/add_fab.dart';
import '../widgets/empty_state.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/modern_bottom_sheet.dart';
import '../widgets/modern_dropdown.dart';
import '../widgets/modern_text_form_field.dart';
import '../widgets/status_badge.dart';
import '../widgets/supplier_picker_modal.dart';

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

  bool _isLoading = false;
  String? _errorMessage;

  bool _isCreatingOrEditing = false;
  List<Map<String, dynamic>> _stores = [];
  bool _isListLoading = true;
  String? _listErrorMessage;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  final ScrollController _scrollController = ScrollController();

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
    _loadClosingStores();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _cashForTomorrowController.dispose();
    _totalCashTransferController.dispose();
    _notesController.dispose();
    for (var ctrl in _cashlessControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadClosingStores() async {
    if (!mounted) return;
    setState(() {
      _isListLoading = true;
      _listErrorMessage = null;
      _page = 1;
      _stores = [];
      _hasMore = true;
    });

    try {
      final result = await _service.getClosingStoresPaged(page: _page);
      if (!mounted) return;
      setState(() {
        _stores = result['data'] as List<Map<String, dynamic>>;
        _hasMore = result['has_more'] as bool;
        _isListLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _listErrorMessage = e.toString().replaceAll('Exception: ', '');
        _isListLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final result = await _service.getClosingStoresPaged(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _page++;
        _stores.addAll(result['data'] as List<Map<String, dynamic>>);
        _hasMore = result['has_more'] as bool;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }



  Widget _buildClosingStoreItem(dynamic item) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final dateStr = item['date'] ?? '';
    final storeName = item['store']?['nickname'] ?? 'Toko';
    final shiftName = item['shift_store']?['name'] ?? 'Shift';
    final totalTransfer = double.tryParse((item['total_cash_transfer'] ?? 0).toString()) ?? 0;
    final cashForTomorrow = double.tryParse((item['cash_for_tomorrow'] ?? 0).toString()) ?? 0;
    final creatorName = item['created_by']?['name'] ?? item['created_by_id']?.toString() ?? '-';
    
    String displayDate = dateStr;
    try {
      final parsedDate = DateTime.parse(dateStr);
      displayDate = DateFormat('dd MMMM yyyy', 'id_ID').format(parsedDate);
    } catch (_) {}

    final status = item['status'] ?? 1;
    String statusLabel = 'Belum Diperiksa';
    StatusType statusType = StatusType.warning;

    if (status == 2) {
      statusLabel = 'Disetujui';
      statusType = StatusType.success;
    } else if (status == 3) {
      statusLabel = 'Ditolak';
      statusType = StatusType.error;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: AppSpacing.borderRadiusMD,
        onTap: () {
          _loadSpecificClosingStore(item['id'] as int);
        },
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      storeName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusSM,
                    ),
                    child: Text(
                      shiftName,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapVerticalXS,
              Text(
                displayDate,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Setoran Kas',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(totalTransfer),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Kas Besok',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(cashForTomorrow),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Oleh: $creatorName',
                    style: textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  StatusBadge(
                    label: statusLabel,
                    type: statusType,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isCreatingOrEditing = true;
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

  Future<void> _loadSpecificClosingStore(int id) async {
    setState(() {
      _isCreatingOrEditing = true;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _service.getClosingStore(id);
      final draft = res['closing_store'];
      
      setState(() {
        _closingData = draft;
        _cashlessList = draft['cashlesses'] ?? [];

        // Pre-fill controllers
        _cashForTomorrowController.text = (draft['cash_for_tomorrow'] ?? 0).toString();
        _totalCashTransferController.text = (draft['total_cash_transfer'] ?? 0).toString();
        _notesController.text = draft['notes'] ?? '';

        _cashlessControllers.clear();
        for (var c in _cashlessList) {
          final cid = c['id'] as int;
          _cashlessControllers[cid] = TextEditingController(
            text: (c['bruto_apl'] ?? 0).toString(),
          );
          _cashlessControllers[cid]!.addListener(() {
            setState(() {});
          });
        }

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

        final Map<int, dynamic> fuelMap = {};
        for (var f in res['fuel_services'] ?? []) {
          fuelMap[f['id'] as int] = f;
        }
        _availableFuelServices = fuelMap.values.toList();

        final Map<int, dynamic> salaryMap = {};
        for (var s in res['daily_salaries'] ?? []) {
          salaryMap[s['id'] as int] = s;
        }
        _availableDailySalaries = salaryMap.values.toList();

        final Map<int, dynamic> invoiceMap = {};
        for (var i in res['invoice_purchases'] ?? []) {
          invoiceMap[i['id'] as int] = i;
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

  bool get _isEditable {
    final status = _closingData?['status'];
    if (status != null && status != 1) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.hasAnyRole(['staff'])) {
        return false;
      }
    }
    return true;
  }

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
      setState(() {
        _isCreatingOrEditing = false;
        _isSubmitting = false;
      });
      _loadClosingStores();
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
    final List<Map<String, dynamic>> serviceDetails = [];
    File? selectedImage;

    ModernBottomSheet.show(
      context: context,
      title: 'Tambah Bensin / Servis Baru',
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

          final theme = Theme.of(context);

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
                  // Close button row
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Tutup',
                    ),
                  ),

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
                        Radio<int>(value: 1),
                        const Text('Fuel (Bensin)'),
                        AppSpacing.gapHorizontalLG,
                        Radio<int>(value: 2),
                        const Text('Service (Servis)'),
                      ],
                    ),
                  ),
                  AppSpacing.gapVerticalSM,

                  // Date picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Tanggal: ${DateFormat('dd MMMM yyyy').format(selectedDate)}',
                    ),
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
                  ModernDropdown<int>(
                    labelText: 'Pilih Kendaraan',
                    hint: 'Pilih kendaraan...',
                    isRequired: true,
                    prefixIcon: const Icon(Icons.directions_car_outlined, size: 20),
                    value: selectedVehicleId,
                    items: vehicles.map((v) => v['id'] as int).toList(),
                    getLabel: (val) {
                      final v = vehicles.firstWhere((e) => e['id'] == val, orElse: () => {});
                      return v['no_register']?.toString() ?? '';
                    },
                    getSubtitle: (val) {
                      final v = vehicles.firstWhere((e) => e['id'] == val, orElse: () => {});
                      return v['name']?.toString() ?? '';
                    },
                    onChanged: (val) => setModalState(() => selectedVehicleId = val),
                    validator: (val) => val == null ? 'Pilih kendaraan' : null,
                  ),
                  AppSpacing.gapVerticalSM,

                  // Supplier (searchable dialog)
                  InkWell(
                    onTap: () async {
                      final result = await SupplierPickerModal.show(
                        context: context,
                        suppliers: suppliers,
                        selectedSupplierId: selectedSupplierId,
                      );
                      if (result != null) {
                        setModalState(() => selectedSupplierId = result['id']);
                      }
                    },
                    borderRadius: AppSpacing.borderRadiusXS,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Pilih Supplier (Opsional)',
                        suffixIcon: Icon(Icons.search),
                      ),
                      child: Text(
                        selectedSupplierId != null
                            ? (suppliers.firstWhere(
                                  (s) => s['id'] == selectedSupplierId,
                                  orElse: () => {'name': ''},
                                )['name'] ??
                                '')
                            : '',
                      ),
                    ),
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

                  // Liter Input (Bensin only)
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

                  // Service Details Repeater (Service only)
                  if (selectedType == 2) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rincian Service:',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              serviceDetails.add({
                                'nameController': TextEditingController(),
                                'costController':
                                    TextEditingController(text: '0'),
                              });
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Item'),
                        ),
                      ],
                    ),
                    AppSpacing.gapVerticalSM,
                    ...serviceDetails.map((detail) {
                      final idx = serviceDetails.indexOf(detail);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: detail['nameController']
                                    as TextEditingController,
                                decoration: const InputDecoration(
                                    labelText: 'Nama Item/Part'),
                              ),
                            ),
                            AppSpacing.gapHorizontalSM,
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: detail['costController']
                                    as TextEditingController,
                                decoration:
                                    const InputDecoration(labelText: 'Biaya'),
                                keyboardType: TextInputType.number,
                                onChanged: (_) =>
                                    setModalState(() => updateServiceAmount()),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error),
                              onPressed: () {
                                setModalState(() {
                                  serviceDetails.removeAt(idx);
                                  updateServiceAmount();
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
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
                    readOnly: selectedType == 2,
                    validator: (val) =>
                        (double.tryParse(val ?? '0') ?? 0) <= 0
                            ? 'Masukkan total biaya'
                            : null,
                  ),
                  AppSpacing.gapVerticalSM,

                  // Notes
                  TextFormField(
                    controller: notesController,
                    decoration:
                        const InputDecoration(labelText: 'Catatan / Notes'),
                    maxLines: 2,
                  ),
                  AppSpacing.gapVerticalLG,

                  // Foto Bukti
                  Text('Foto Bukti / Nota *:',
                      style: theme.textTheme.bodyMedium),
                  AppSpacing.gapVerticalXS,
                  Row(
                    children: [
                      if (selectedImage != null) ...[
                        ClipRRect(
                          borderRadius: AppSpacing.borderRadiusSM,
                          child: Image.file(
                            selectedImage!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        AppSpacing.gapHorizontalMD,
                      ],
                      OutlinedButton.icon(
                        onPressed: () async {
                          final File? file =
                              await ImageService.selectAndPickImage(context);
                          if (file != null) {
                            setModalState(() => selectedImage = file);
                          }
                        },
                        icon: const Icon(Icons.add_a_photo),
                        label: Text(
                            selectedImage == null ? 'Unggah Foto *' : 'Ubah Foto'),
                      ),
                      if (selectedImage != null) ...[
                        AppSpacing.gapHorizontalSM,
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () =>
                              setModalState(() => selectedImage = null),
                        ),
                      ],
                    ],
                  ),
                  AppSpacing.gapVerticalLG,

                  // Simpan button (full width)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        if (selectedImage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Foto bukti / nota wajib diunggah!')),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        setState(() => _isLoading = true);
                        try {
                          final payload = {
                            'closing_store_id': _closingData!['id'],
                            'date': selectedDate.toIso8601String().split('T')[0],
                            'fuel_service': selectedType,
                            'vehicle_id': selectedVehicleId,
                            'supplier_id': selectedSupplierId,
                            'payment_type_id': 2, // selalu tunai (cash)
                            'km': double.tryParse(kmController.text) ?? 0,
                            'liter': double.tryParse(literController.text) ?? 0,
                            'amount':
                                double.tryParse(amountController.text) ?? 0,
                            'notes': notesController.text,
                            if (selectedType == 2)
                              'service_details': serviceDetails.map((d) {
                                return {
                                  'name': (d['nameController']
                                          as TextEditingController)
                                      .text,
                                  'price': double.tryParse(
                                          (d['costController']
                                                  as TextEditingController)
                                              .text) ??
                                      0,
                                };
                              }).toList(),
                          };

                          final newFs = await _service.createFuelService(
                              payload,
                              imageFile: selectedImage);
                          setState(() {
                            _isLoading = false;
                            _availableFuelServices.insert(0, newFs);
                            _selectedFuelServiceIds.add(newFs['id'] as int);
                          });
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Gagal menyimpan transaksi bensin/servis: $e')),
                          );
                          setState(() => _isLoading = false);
                        }
                      },
                      child: const Text('Simpan'),
                    ),
                  ),
                  AppSpacing.gapVerticalMD,
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

    if (!_isCreatingOrEditing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Riwayat Tutup Shift'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadClosingStores,
            )
          ],
        ),
        body: _isListLoading
            ? const Center(child: CircularProgressIndicator())
            : _listErrorMessage != null
                ? Center(
                    child: Padding(
                      padding: AppSpacing.paddingLG,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                          AppSpacing.gapVerticalMD,
                          Text(
                            _listErrorMessage!,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge,
                          ),
                          AppSpacing.gapVerticalLG,
                          ElevatedButton(
                            onPressed: _loadClosingStores,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _stores.isEmpty
                    ? const EmptyState(
                        icon: Icons.assignment_turned_in_outlined,
                        title: 'Belum ada laporan tutup shift.',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadClosingStores,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: AppSpacing.paddingMD,
                          itemCount: _stores.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _stores.length) {
                              return const Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return _buildClosingStoreItem(_stores[index]);
                          },
                        ),
                      ),
        floatingActionButton: AddFab(
          onPressed: _loadData,
        ),
        bottomNavigationBar: ModernBottomNav(
          currentIndex: 4,
          onTap: (index) {
            if (index != 4) {
              Navigator.pop(context);
            }
          },
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tutup Shift Toko'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _isCreatingOrEditing = false;
              });
              _loadClosingStores();
            },
          ),
        ),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _isCreatingOrEditing = false;
        });
        _loadClosingStores();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tutup Shift Toko'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _isCreatingOrEditing = false;
              });
              _loadClosingStores();
            },
          ),
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
            if (!_isEditable)
              Container(
                width: double.infinity,
                padding: AppSpacing.paddingMD,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusMD,
                  border: Border.all(color: colorScheme.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: colorScheme.error),
                    AppSpacing.gapHorizontalMD,
                    Expanded(
                      child: Text(
                        'Laporan Closing Store ini telah diperiksa oleh admin dan tidak dapat diedit lagi.',
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Header Card
            Card(
              child: Padding(
                padding: AppSpacing.paddingMD,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.storefront, color: AppColors.info),
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
                      enabled: _isEditable,
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
                      enabled: _isEditable,
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
                          enabled: _isEditable,
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
                  icon: const Icon(Icons.add_circle, color: AppColors.info),
                  onPressed: _isEditable ? _showAddFuelServiceBottomSheet : null,
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
              enabled: _isEditable,
            ),
            AppSpacing.gapVerticalXL,

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isSubmitting || !_isEditable) ? null : _submit,
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
          onChanged: _isEditable ? (bool? val) {
            setState(() {
              if (val == true) {
                _selectedFuelServiceIds.add(id);
              } else {
                _selectedFuelServiceIds.remove(id);
              }
            });
          } : null,
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
          onChanged: _isEditable ? (bool? val) {
            setState(() {
              if (val == true) {
                _selectedDailySalaryIds.add(id);
              } else {
                _selectedDailySalaryIds.remove(id);
              }
            });
          } : null,
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
          onChanged: _isEditable ? (bool? val) {
            setState(() {
              if (val == true) {
                _selectedInvoicePurchaseIds.add(id);
              } else {
                _selectedInvoicePurchaseIds.remove(id);
              }
            });
          } : null,
        );
      }).toList(),
    );
  }
}
