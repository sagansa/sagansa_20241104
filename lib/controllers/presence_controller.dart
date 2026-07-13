import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../pages/readiness_page.dart';
import '../pages/hygiene_page.dart';
import '../models/store_model.dart';
import '../models/shift_store_model.dart';
import '../services/presence_service.dart';
import '../theme/app_colors.dart';
import 'dart:io';

class PresenceController {
  final BuildContext context;

  PresenceController(this.context);

  Future<Map<String, dynamic>> loadInitialData() async {
    try {
      final stores = await PresenceService.getStores();
      final shiftStores = await PresenceService.getShiftStores();
      return {
        'stores': stores,
        'shiftStores': shiftStores,
      };
    } catch (e) {
      throw Exception('Gagal memuat data: $e');
    }
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
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

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 30),
      ),
    );

    return position;
  }

  bool validateStoreLocation(Position position, Store store) {
    double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      store.latitude,
      store.longitude,
    );
    return distance <= store.radius;
  }

  Future<void> submitPresence({
    required bool isCheckIn,
    required Position currentPosition,
    required Store selectedStore,
    required ShiftStore? selectedShiftStore,
    required File imageFile,
    String? dailySalaryAmount,
    String? dailySalaryPaymentTypeId,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final Map<String, dynamic> presenceData = isCheckIn
          ? {
              'store_id': selectedStore.id.toString(),
              'shift_store_id': selectedShiftStore!.id.toString(),
              'status': "1",
              'latitude_in': currentPosition.latitude.toString(),
              'longitude_in': currentPosition.longitude.toString(),
              'check_in': DateTime.now().toIso8601String(),
            }
          : {
              'latitude_out': currentPosition.latitude.toString(),
              'longitude_out': currentPosition.longitude.toString(),
              'check_out': DateTime.now().toIso8601String(),
              if (dailySalaryAmount != null) 'daily_salary_amount': dailySalaryAmount,
              if (dailySalaryPaymentTypeId != null) 'daily_salary_payment_type_id': dailySalaryPaymentTypeId,
            };

      final responseData =
          await PresenceService.uploadImage(imageFile, isCheckIn, presenceData);

      if (!context.mounted) return;

      if (responseData['status'] == 'success') {
        final message = isCheckIn
            ? 'Check-in berhasil\nStatus: ${responseData['data']['check_in_status']}'
            : 'Check-out berhasil\nStatus: ${responseData['data']['check_out_status']}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
          ),
        );

        onSuccess();
      } else {
        if (responseData['error_code'] == 'READINESS_REQUIRED') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Wajib mengisi form Kesiapan Diri'),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 4),
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReadinessPage()),
          );
          onError(responseData['message'] ?? 'Kesiapan Diri diperlukan');
        } else if (responseData['error_code'] == 'HYGIENE_REQUIRED') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Wajib mengisi form Kebersihan Toko'),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 4),
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HygienePage()),
          );
          onError(responseData['message'] ?? 'Kebersihan Toko diperlukan');
        } else {
          onError(responseData['message'] ?? 'Gagal melakukan presensi');
        }
      }
    } catch (e) {
      const errorMessage = 'Gagal mengirim data presensi';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
        ),
      );
      onError(errorMessage);
    }
  }
}
