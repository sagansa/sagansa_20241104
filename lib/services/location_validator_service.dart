import 'package:trust_location/trust_location.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:geolocator/geolocator.dart';

class LocationValidatorService {
  Future<bool> validateLocation() async {
    bool isMockLocation = false;

    try {
      // Inisialisasi TrustLocation
      TrustLocation.start(1000);

      // Listen untuk mock location updates
      TrustLocation.onChange.listen((event) {
        isMockLocation = event.isMockLocation ?? false;
      });

      // Cek akurasi lokasi
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Jika terdeteksi mock location, return false
      if (isMockLocation) {
        return false;
      }

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
    } finally {
      // Stop TrustLocation service
      TrustLocation.stop();
    }
  }

  Future<void> showLocationSettings() async {
    final AndroidIntent intent = AndroidIntent(
      action: 'android.settings.LOCATION_SOURCE_SETTINGS',
    );
    await intent.launch();
  }

  // Tambahkan method untuk menyimpan riwayat lokasi
  Future<void> logLocationHistory(Position position) async {
    // Simpan ke local storage atau server
    // Berguna untuk analisis pola lokasi yang mencurigakan
  }
}
