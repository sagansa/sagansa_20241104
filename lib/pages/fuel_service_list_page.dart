import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/closing_store_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/add_fab.dart';
import '../widgets/modern_bottom_sheet.dart';

class FuelServiceListPage extends StatefulWidget {
  const FuelServiceListPage({super.key});

  @override
  State<FuelServiceListPage> createState() => _FuelServiceListPageState();
}

class _FuelServiceListPageState extends State<FuelServiceListPage> {
  final ClosingStoreService _service = ClosingStoreService();
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _fuelServices = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getFuelServices();
      setState(() {
        _fuelServices = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showAddFuelServiceBottomSheet() async {
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
    int selectedPaymentType = 2; // 2 = Tunai, 1 = Transfer
    final kmController = TextEditingController(text: '0');
    final literController = TextEditingController(text: '0');
    final amountController = TextEditingController(text: '0');
    final notesController = TextEditingController();

    // Service details list
    final List<Map<String, dynamic>> serviceDetails = [];

    ModernBottomSheet.show(
      context: context,
      title: 'Tambah Bensin / Servis Baru',
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
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

          return Form(
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
                const SizedBox(height: AppSpacing.sectionGap),

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
                const SizedBox(height: AppSpacing.sectionGap),

                // Supplier Dropdown (searchable)
                InkWell(
                  onTap: () async {
                    final result = await _showSupplierSearchDialog(context, suppliers);
                    if (result != null) {
                      setModalState(() => selectedSupplierId = result);
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
                            )['name'] ?? '')
                          : '',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // Payment Type
                Text('Tipe Pembayaran:', style: theme.textTheme.bodyMedium),
                AppSpacing.gapVerticalXS,
                RadioGroup<int>(
                  groupValue: selectedPaymentType,
                  onChanged: (val) => setModalState(() => selectedPaymentType = val!),
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
                  controller: kmController,
                  decoration: const InputDecoration(
                    labelText: 'KM Kendaraan',
                    suffixText: 'km',

                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.sectionGap),

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
                  const SizedBox(height: AppSpacing.sectionGap),
                ],

                // Service Details Repeater (Service Only)
                if (selectedType == 2) ...[
                  Text(
                    'Rincian Service:',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
                  const SizedBox(height: AppSpacing.sectionGap),
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
                  validator: (val) => (double.tryParse(val ?? '0') ?? 0) <= 0 ? 'Masukkan total biaya' : null,
                ),
                const SizedBox(height: AppSpacing.sectionGap),

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
                          Navigator.pop(context);
                          setState(() => _isLoading = true);
                          try {
                            final payload = {
                              'date': selectedDate.toIso8601String().split('T')[0],
                              'fuel_service': selectedType,
                              'vehicle_id': selectedVehicleId,
                              'supplier_id': selectedSupplierId,
                              'payment_type_id': selectedPaymentType,
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

                            await _service.createFuelService(payload);
                             
                            await _loadData();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bensin & Servis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: AppSpacing.paddingLG,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: colorScheme.error),
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
                )
              : _fuelServices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_gas_station_outlined, size: 64, color: colorScheme.outline),
                          AppSpacing.gapVerticalMD,
                          Text('Belum ada riwayat bensin atau servis.', style: textTheme.bodyLarge),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _fuelServices.length,
                      padding: AppSpacing.paddingMD,
                      itemBuilder: (context, index) {
                        final fs = _fuelServices[index];
                        final type = fs['fuel_service'] == 1 ? 'Fuel' : 'Service';
                        final isFuel = fs['fuel_service'] == 1;
                        final amount = double.tryParse(fs['amount'].toString()) ?? 0;
                        final date = fs['date'] ?? '';
                        final vehicleNo = fs['vehicle']?['no_register'] ?? 'Kendaraan';
                        final km = fs['km'] ?? 0;
                        final creatorName = fs['created_by']?['name'] ?? 'Staff';
                        final statusStr = fs['status'] == 2 ? 'Lunas / Terhubung' : 'Pending';
                        final isPaid = fs['status'] == 2;

                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
                          child: Padding(
                            padding: AppSpacing.paddingMD,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                      decoration: BoxDecoration(
                                        color: (isFuel ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                                        borderRadius: AppSpacing.borderRadiusSM,
                                      ),
                                      child: Text(
                                        type,
                                        style: textTheme.labelMedium?.copyWith(
                                          color: isFuel ? AppColors.success : AppColors.warning,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      currencyFormatter.format(amount),
                                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                AppSpacing.gapVerticalSM,
                                Text(
                                  '$vehicleNo (KM: $km)',
                                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                AppSpacing.gapVerticalXS,
                                Text(
                                  'Tanggal: $date | Oleh: $creatorName',
                                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                ),
                                AppSpacing.gapVerticalSM,
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      statusStr,
                                      style: textTheme.labelMedium?.copyWith(
                                        color: isPaid ? AppColors.success : colorScheme.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (fs['notes'] != null) ...[
                                      (() {
                                        final stripped = _stripHtmlTags(fs['notes'].toString());
                                        if (stripped.isNotEmpty) {
                                          return Text(
                                            stripped,
                                            style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      })(),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: AddFab(
        onPressed: _showAddFuelServiceBottomSheet,
      ),
    );
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

String _stripHtmlTags(String htmlText) {
  RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
  return htmlText.replaceAll(exp, '').trim();
}
