import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import '../models/store_model.dart';
import '../models/shift_store_model.dart';
import '../services/presence_service.dart';

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
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      timeLimit: const Duration(seconds: 30),
      forceAndroidLocationManager: true,
    );

    return position;
  }

  bool validateStoreLocation(Position position, StoreModel store) {
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
    required StoreModel selectedStore,
    ShiftStoreModel? selectedShiftStore,
    required File imageFile,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final now = DateTime.now();
      final formattedDateTime = "${now.year}-"
          "${now.month.toString().padLeft(2, '0')}-"
          "${now.day.toString().padLeft(2, '0')} "
          "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')}";

      print('Formatted DateTime: $formattedDateTime');

      final Map<String, dynamic> presenceData = isCheckIn
          ? {
              'store_id': selectedStore.id.toString(),
              'shift_store_id': selectedShiftStore!.id.toString(),
              'status': "1",
              'latitude_in': currentPosition.latitude.toString(),
              'longitude_in': currentPosition.longitude.toString(),
              'check_in': formattedDateTime,
            }
          : {
              'latitude_out': currentPosition.latitude.toString(),
              'longitude_out': currentPosition.longitude.toString(),
              'check_out': formattedDateTime,
            };

      print('Sending presence data: $presenceData');

      await PresenceService.submitPresence(presenceData, isCheckIn, imageFile);
      onSuccess();
    } catch (e) {
      print('Error in submitPresence controller: $e');
      onError(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
