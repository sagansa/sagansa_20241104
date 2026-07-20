import 'package:flutter/foundation.dart';
import '../services/leave_service.dart';

enum LeaveState { idle, loading, success, error }

class LeaveProvider extends ChangeNotifier {
  final LeaveService _service = LeaveService();

  LeaveState _state = LeaveState.idle;
  String? _errorMessage;

  LeaveState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == LeaveState.loading;
  bool get hasError => _state == LeaveState.error;

  Future<bool> submitLeave({
    required int reason,
    required DateTime fromDate,
    required DateTime untilDate,
    String? notes,
  }) async {
    _state = LeaveState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.submitLeave(
        reason: reason,
        fromDate: fromDate,
        untilDate: untilDate,
        notes: notes,
      );
      _state = LeaveState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _state = LeaveState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLeave({
    required int leaveId,
    required String reason,
    required DateTime fromDate,
    required DateTime untilDate,
    required String notes,
  }) async {
    _state = LeaveState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateLeave(leaveId, reason, fromDate, untilDate, notes);
      _state = LeaveState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _state = LeaveState.error;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _state = LeaveState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring('Exception: '.length) : s;
  }
}
