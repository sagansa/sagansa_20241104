import 'dart:io';
import 'package:flutter/foundation.dart';

/// State untuk flow pembayaran transfer bensin/servis.
///
/// Provider ini menyimpan:
/// - selectedFuelServiceIds: id fuel service yang dipilih user
/// - _amounts: mapping fuel_service_id → amount (untuk compute total)
/// - imageFile: bukti transfer yang di-upload (opsional)
/// - notes: catatan
///
/// UI pakai provider ini via `context.watch<FuelServicePaymentProvider>()`.
/// Saat submit, panggil submit() yang akan call service API.
class FuelServicePaymentProvider extends ChangeNotifier {
  final Set<int> _selectedIds = {};
  final Map<int, int> _amounts = {};
  File? _imageFile;
  String _notes = '';
  bool _isSubmitting = false;

  List<int> get selectedFuelServiceIds => _selectedIds.toList();
  int get selectedCount => _selectedIds.length;
  bool isSelected(int id) => _selectedIds.contains(id);
  int get totalAmount => _amounts.values.fold(0, (sum, a) => sum + a);
  File? get imageFile => _imageFile;
  String get notes => _notes;
  bool get isSubmitting => _isSubmitting;

  /// Bisa submit jika minimal 1 item dipilih (image opsional per spec).
  bool get canSubmit => _selectedIds.isNotEmpty && !_isSubmitting;

  /// Toggle selection untuk satu fuel service. [amount] = nominal fuel service.
  void toggleSelection(int fuelServiceId, {required int amount}) {
    if (_selectedIds.contains(fuelServiceId)) {
      _selectedIds.remove(fuelServiceId);
      _amounts.remove(fuelServiceId);
    } else {
      _selectedIds.add(fuelServiceId);
      _amounts[fuelServiceId] = amount;
    }
    notifyListeners();
  }

  void setImageFile(File? file) {
    _imageFile = file;
    notifyListeners();
  }

  void setNotes(String value) {
    _notes = value;
    notifyListeners();
  }

  void setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  /// Reset semua state ke kondisi awal.
  void clearSelection() {
    _selectedIds.clear();
    _amounts.clear();
    _imageFile = null;
    _notes = '';
    _isSubmitting = false;
    notifyListeners();
  }
}
