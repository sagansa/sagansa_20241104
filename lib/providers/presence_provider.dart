import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/presence_model.dart';
import '../models/shift_store_model.dart';
import '../models/store_model.dart';
import '../services/presence_service.dart';

enum PresenceState { idle, loading, success, error }

class PresenceProvider with ChangeNotifier {
  final PresenceService _service = PresenceService();

  PresenceState _state = PresenceState.idle;
  List<PresenceModel> _presences = [];
  PresenceModel? _todayPresence;
  List<Store> _stores = [];
  List<ShiftStore> _shiftStores = [];
  Position? _currentLocation;
  String? _errorMessage;

  PresenceState get state => _state;
  List<PresenceModel> get presences => _presences;
  PresenceModel? get todayPresence => _todayPresence;
  List<Store> get stores => _stores;
  List<ShiftStore> get shiftStores => _shiftStores;
  Position? get currentLocation => _currentLocation;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == PresenceState.loading;
  bool get hasError => _state == PresenceState.error;

  void setTodayPresence(PresenceModel? presence) {
    _todayPresence = presence;
    notifyListeners();
  }

  Future<void> fetchPresences() async {
    try {
      final response = await _service.getUserPresence();

      final List<dynamic> presencesData = response['data'] is List
          ? response['data'] as List
          : [];

      _presences =
          presencesData.map((json) => PresenceModel.fromJson(json)).toList();

      final todayData = response['today'];
      if (todayData != null && todayData is Map<String, dynamic>) {
        _todayPresence = PresenceModel.fromJson(todayData);
      } else {
        _todayPresence = null;
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadInitialData() async {
    _state = PresenceState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _stores = await _service.getStores();
      _shiftStores = await _service.getShiftStores();
      _state = PresenceState.success;
    } catch (e) {
      _errorMessage = _parseError(e);
      _state = PresenceState.error;
    }

    notifyListeners();
  }

  Future<void> getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi tidak aktif. Mohon aktifkan GPS/Lokasi.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak secara permanen.');
      }

      _currentLocation = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 30),
        ),
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = _parseError(e);
      _state = PresenceState.error;
      notifyListeners();
    }
  }

  bool validateStoreLocation(Position position, Store store) {
    final double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      store.latitude,
      store.longitude,
    );
    return distance <= store.radius;
  }

  /// Submit presence. Returns the raw response data map so the widget
  /// can handle navigation/snackbar based on status and error_code.
  Future<Map<String, dynamic>> submitPresence({
    required bool isCheckIn,
    required Position currentPosition,
    required Store selectedStore,
    required ShiftStore? selectedShiftStore,
    required dynamic imageFile,
    String? dailySalaryAmount,
    String? dailySalaryPaymentTypeId,
  }) async {
    final Map<String, dynamic> presenceData = isCheckIn
        ? {
            'store_id': selectedStore.id.toString(),
            'shift_store_id': selectedShiftStore!.id.toString(),
            'status': '1',
            'latitude_in': currentPosition.latitude.toString(),
            'longitude_in': currentPosition.longitude.toString(),
            'check_in': DateTime.now().toIso8601String(),
          }
        : {
            'latitude_out': currentPosition.latitude.toString(),
            'longitude_out': currentPosition.longitude.toString(),
            'check_out': DateTime.now().toIso8601String(),
            if (dailySalaryAmount != null)
              'daily_salary_amount': dailySalaryAmount,
            if (dailySalaryPaymentTypeId != null)
              'daily_salary_payment_type_id': dailySalaryPaymentTypeId,
          };

    return await _service.uploadImage(imageFile, isCheckIn, presenceData);
  }

  void reset() {
    _state = PresenceState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring('Exception: '.length) : s;
  }
}
