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

      // Jika akurasi terlalu rendah (>50 meter), lokasi mungkin tidak valid
      if (position.accuracy > 50) {
        return false;
      }

      // Cek kecepatan perubahan lokasi
      Position lastPosition = position;
      await Future.delayed(Duration(seconds: 2));
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Hitung kecepatan perpindahan (dalam m/s)
      double distance = Geolocator.distanceBetween(
        lastPosition.latitude,
        lastPosition.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );
      double speed = distance / 2; // waktu 2 detik

      // Jika kecepatan terlalu tinggi (>100 m/s), mungkin fake
      if (speed > 100) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error validating location: $e');
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
