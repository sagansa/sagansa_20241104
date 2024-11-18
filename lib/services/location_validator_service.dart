import 'package:geolocator/geolocator.dart';

class LocationValidatorService {
  bool _isMockLocation = false;
  Stream<Position>? _positionStream;

  Future<void> startListening() async {
    // Request permission
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      return;
    }

    // Start listening to location updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );

    _positionStream?.listen((Position position) {
      // Check if location is mocked
      _isMockLocation = position.isMocked;
    });
  }

  void stopListening() {
    _positionStream = null;
  }

  bool isMockLocationOn() {
    return _isMockLocation;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<bool> validateLocation() async {
    try {
      // Cek apakah layanan lokasi aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

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
    await Geolocator.openLocationSettings();
  }
}
