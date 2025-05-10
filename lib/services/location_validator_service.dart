import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

class LocationValidatorService {
  static const platform = MethodChannel('com.example.app/location');

  Future<bool> validateLocation() async {
    try {
      // Cek akurasi lokasi
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Cek permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      // Cek apakah permission diblokir permanen
      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // Dapatkan posisi saat ini
      Position position = await Geolocator.getCurrentPosition();

      // Return false jika lokasi palsu terdeteksi
      return !position.isMocked;
    } catch (e) {
      return false;
    }
  }

  Future<void> showLocationSettings() async {
    try {
      await platform.invokeMethod('openLocationSettings');
    } on PlatformException catch (e) {
      print("Failed to open location settings: '${e.message}'.");
    }
  }

  Future<void> logLocationHistory(Position position) async {
    // Simpan ke local storage atau server
    // Berguna untuk analisis pola lokasi yang mencurigakan
  }
}
