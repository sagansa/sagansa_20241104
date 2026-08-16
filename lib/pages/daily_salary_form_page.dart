import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/shift_store_model.dart';
import '../models/store_model.dart';
import '../services/closing_store_service.dart';
import '../services/presence_service.dart';
import '../theme/app_spacing.dart';

/// Form buat/edit daily salary manual (meniru DailySalaryResource admin):
/// create selalu atas nama user login dengan status "belum dibayar";
/// edit hanya untuk record yang belum dibayar. Server menolak duplikat
/// user + tanggal yang sama.
class DailySalaryFormPage extends StatefulWidget {
  final Map<String, dynamic>? dailySalary;

  const DailySalaryFormPage({super.key, this.dailySalary});

  @override
  State<DailySalaryFormPage> createState() => _DailySalaryFormPageState();
}

class _DailySalaryFormPageState extends State<DailySalaryFormPage> {
  final ClosingStoreService _service = ClosingStoreService();
  final PresenceService _presenceService = PresenceService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<Store> _stores = [];
  List<ShiftStore> _shiftStores = [];

  int? _selectedStoreId;
  int? _selectedShiftStoreId;
  DateTime _selectedDate = DateTime.now();
  int? _selectedPaymentTypeId;

  bool get _isEditMode => widget.dailySalary != null;

  static const Map<int, String> _paymentTypeOptions = {
    1: 'Transfer',
    2: 'Tunai',
  };

  @override
  void initState() {
    super.initState();
    _prefillFromRecord();
    _loadOptions();
  }

  void _prefillFromRecord() {
    final record = widget.dailySalary;
    if (record == null) return;

    _selectedStoreId = record['store']?['id'] ?? record['store_id'];
    _selectedShiftStoreId = record['shift_store']?['id'] ?? record['shift_store_id'];
    _selectedPaymentTypeId = record['payment_type_id'] is int
        ? record['payment_type_id'] as int
        : int.tryParse(record['payment_type_id']?.toString() ?? '');
    _amountController.text = (record['amount'] ?? 0).toString();

    final parsedDate = DateTime.tryParse(record['date']?.toString() ?? '');
    if (parsedDate != null) {
      _selectedDate = parsedDate;
    }
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _presenceService.getStores(),
        _presenceService.getShiftStores(),
      ]);
      if (!mounted) return;
      setState(() {
        _stores = results[0] as List<Store>;
        _shiftStores = results[1] as List<ShiftStore>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data form: $e';
      });
    }
  }

  void _onStoreChanged(int? storeId) {
    setState(() => _selectedStoreId = storeId);

    // Saat create, prefill amount dengan default gaji harian toko.
    if (!_isEditMode && storeId != null) {
      final store = _stores.where((s) => s.id == storeId).firstOrNull;
      final defaultAmount = store?.dailySalaryAmount;
      if (defaultAmount != null && defaultAmount.isNotEmpty) {
        _amountController.text = double.parse(defaultAmount).toStringAsFixed(0);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStoreId == null ||
        _selectedShiftStoreId == null ||
        _selectedPaymentTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lengkapi toko, shift, dan metode pembayaran.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final data = <String, dynamic>{
      'store_id': _selectedStoreId,
      'shift_store_id': _selectedShiftStoreId,
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'amount': double.tryParse(_amountController.text) ?? 0,
      'payment_type_id': _selectedPaymentTypeId,
    };

    try {
      if (_isEditMode) {
        await _service.updateDailySalary(
          widget.dailySalary!['id'] as int,
          data,
        );
      } else {
        await _service.createDailySalary(data);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Gaji Harian' : 'Buat Gaji Harian'),
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
                        Text(_errorMessage!,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge),
                        AppSpacing.gapVerticalMD,
                        ElevatedButton(
                          onPressed: _loadOptions,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: AppSpacing.paddingMD,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: _selectedStoreId,
                        decoration: const InputDecoration(
                          labelText: 'Toko',
                          prefixIcon: Icon(Icons.store),
                          border: OutlineInputBorder(),
                        ),
                        items: _stores
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.nickname),
                                ))
                            .toList(),
                        onChanged: _onStoreChanged,
                        validator: (v) =>
                            v == null ? 'Pilih toko terlebih dahulu.' : null,
                      ),
                      AppSpacing.gapVerticalMD,
                      DropdownButtonFormField<int>(
                        initialValue: _selectedShiftStoreId,
                        decoration: const InputDecoration(
                          labelText: 'Shift',
                          prefixIcon: Icon(Icons.schedule),
                          border: OutlineInputBorder(),
                        ),
                        items: _shiftStores
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedShiftStoreId = v),
                        validator: (v) =>
                            v == null ? 'Pilih shift terlebih dahulu.' : null,
                      ),
                      AppSpacing.gapVerticalMD,
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: AppSpacing.borderRadiusMD,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('dd MMMM yyyy').format(_selectedDate),
                          ),
                        ),
                      ),
                      AppSpacing.gapVerticalMD,
                      TextFormField(
                        controller: _amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Gaji',
                          prefixText: 'Rp ',
                          prefixIcon: Icon(Icons.payments),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final amount = double.tryParse(v ?? '');
                          if (v == null || v.isEmpty || amount == null) {
                            return 'Masukkan jumlah gaji yang valid.';
                          }
                          if (amount < 0) {
                            return 'Jumlah gaji tidak boleh negatif.';
                          }
                          return null;
                        },
                      ),
                      AppSpacing.gapVerticalMD,
                      DropdownButtonFormField<int>(
                        initialValue: _selectedPaymentTypeId,
                        decoration: const InputDecoration(
                          labelText: 'Metode Pembayaran',
                          prefixIcon: Icon(Icons.account_balance),
                          border: OutlineInputBorder(),
                        ),
                        items: _paymentTypeOptions.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedPaymentTypeId = v),
                        validator: (v) =>
                            v == null ? 'Pilih metode pembayaran.' : null,
                      ),
                      AppSpacing.gapVerticalLG,
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : Text(_isEditMode
                                ? 'Simpan Perubahan'
                                : 'Buat Gaji Harian'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
