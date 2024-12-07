import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/store_model.dart';
import '../models/shift_store_model.dart';
import '../pages/home_page.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_dropdown.dart';
import '../controllers/presence_controller.dart';
import '../services/location_validator_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PresencePage extends StatefulWidget {
  final bool isCheckIn;

  const PresencePage({Key? key, required this.isCheckIn}) : super(key: key);

  @override
  _PresencePageState createState() => _PresencePageState();
}

class _PresencePageState extends State<PresencePage> {
  List<StoreModel> stores = [];
  List<ShiftStoreModel> shiftStores = [];
  StoreModel? selectedStore;
  ShiftStoreModel? selectedShiftStore;
  bool isLoading = false;
  Position? currentPosition;
  MapController mapController = MapController();
  bool isLoadingLocation = false;
  bool isLocationValid = false;
  bool isTimeValid = true;
  late PresenceController _presenceController;
  final LocationValidatorService _locationValidator =
      LocationValidatorService();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _presenceController = PresenceController(context);
    _loadData();
    _validateCheckoutTime();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final data = await _presenceController.loadInitialData();
      setState(() {
        stores = data['stores'];
        shiftStores = data['shiftStores'];
      });
      _getCurrentLocation();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingLocation = true);
    try {
      final position = await _presenceController.getCurrentLocation();
      setState(() {
        currentPosition = position;

        // Cari toko terdekat
        StoreModel? nearestStore;
        double shortestDistance = double.infinity;

        for (var store in stores) {
          double distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            store.latitude,
            store.longitude,
          );

          if (distance < shortestDistance) {
            shortestDistance = distance;
            nearestStore = store;
          }
        }

        // Update selected store dan validasi lokasi
        if (nearestStore != null) {
          selectedStore = nearestStore;
          isLocationValid = shortestDistance <= nearestStore.radius;

          // Tampilkan snackbar dengan informasi jarak
          String message = isLocationValid
              ? 'Anda berada di area ${nearestStore.nickname} (${shortestDistance.toStringAsFixed(2)} meter)'
              : 'Anda berada di luar area ${nearestStore.nickname}. Jarak: ${shortestDistance.toStringAsFixed(2)} meter';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: isLocationValid ? Colors.green : Colors.red,
            ),
          );
        }
      });

      // Pindahkan map ke posisi saat ini
      mapController.move(
        LatLng(position.latitude, position.longitude),
        18.0,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoadingLocation = false);
    }
  }

  void _validateCheckoutTime() {
    if (!widget.isCheckIn) {
      final now = DateTime.now();
      final currentHour = now.hour;
      setState(() {
        isTimeValid = currentHour <= 23 || currentHour <= 2;
      });

      if (!isTimeValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Waktu checkout hanya diperbolehkan sampai jam 02:00'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (photo != null) {
        final File originalFile = File(photo.path);
        final img.Image? originalImage = img.decodeImage(
          await originalFile.readAsBytes(),
        );

        if (originalImage != null) {
          final img.Image resizedImage = img.copyResize(
            originalImage,
            width: 800,
            height: 800,
            interpolation: img.Interpolation.linear,
          );

          final Directory tempDir = await getTemporaryDirectory();
          final String targetPath =
              '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
          final File targetFile = File(targetPath);

          await targetFile.writeAsBytes(
            img.encodeJpg(resizedImage, quality: 85),
          );

          setState(() {
            _imageFile = targetFile;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: ${e.toString()}')),
      );
    }
  }

  Future<void> _validateAndSubmitPresence() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silakan ambil foto terlebih dahulu')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final isLocationValid = await _locationValidator.validateLocation();

      if (!isLocationValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Lokasi tidak valid atau terdeteksi penggunaan fake GPS'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Pengaturan',
              textColor: Colors.white,
              onPressed: () => _locationValidator.showLocationSettings(),
            ),
          ),
        );
        return;
      }

      await _presenceController.submitPresence(
        isCheckIn: widget.isCheckIn,
        currentPosition: currentPosition!,
        selectedStore: selectedStore!,
        selectedShiftStore: selectedShiftStore,
        imageFile: _imageFile!,
        onSuccess: () async {
          // Simpan data store ke SharedPreferences saat check-in berhasil
          if (widget.isCheckIn && selectedStore != null) {
            try {
              final prefs = await SharedPreferences.getInstance();
              final storeData = {
                'store': {
                  'id': selectedStore!.id,
                  'name': selectedStore!.nickname,
                }
              };

              print('Saving store data to SharedPreferences:');
              print(jsonEncode(storeData));

              await prefs.setString('store', jsonEncode(storeData));

              // Verifikasi data tersimpan
              final savedData = prefs.getString('store');
              print('Verified saved store data:');
              print(savedData);
            } catch (e) {
              print('Error saving store data: $e');
            }
          }

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
          );
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        },
      );
    } catch (e) {
      print('Error in validateAndSubmitPresence: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isButtonEnabled =
        selectedStore != null && currentPosition != null && isLocationValid;

    if (widget.isCheckIn) {
      isButtonEnabled = isButtonEnabled && selectedShiftStore != null;
    } else {
      isButtonEnabled = isButtonEnabled && isTimeValid;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCheckIn ? 'Check In' : 'Check Out'),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (widget.isCheckIn) ...[
                        ModernDropdown<StoreModel>(
                          value: selectedStore,
                          hint: 'Pilih Toko',
                          items: stores,
                          getLabel: (store) => store.nickname,
                          onChanged: (value) async {
                            setState(() {
                              selectedStore = value;
                              isLocationValid = false;
                            });

                            if (value != null && currentPosition != null) {
                              double distance = Geolocator.distanceBetween(
                                currentPosition!.latitude,
                                currentPosition!.longitude,
                                value.latitude,
                                value.longitude,
                              );

                              setState(() {
                                isLocationValid = distance <= value.radius;
                              });

                              if (!isLocationValid) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Anda berada di luar area toko. Jarak: ${distance.toStringAsFixed(2)} meter'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        SizedBox(height: 16),
                        if (isLocationValid)
                          ModernDropdown<ShiftStoreModel>(
                            value: selectedShiftStore,
                            hint: 'Pilih Shift',
                            items: shiftStores,
                            getLabel: (shift) => shift.name,
                            onChanged: (value) {
                              setState(() {
                                selectedShiftStore = value;
                              });
                            },
                          ),
                        SizedBox(height: 16),
                      ],
                      Container(
                        height: 300,
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: mapController,
                              options: MapOptions(
                                center: currentPosition != null
                                    ? LatLng(currentPosition!.latitude,
                                        currentPosition!.longitude)
                                    : LatLng(-6.200000, 106.816666),
                                zoom: 15.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  subdomains: ['a', 'b', 'c'],
                                ),
                                MarkerLayer(
                                  markers: currentPosition != null
                                      ? [
                                          Marker(
                                            width: 40.0,
                                            height: 40.0,
                                            point: LatLng(
                                                currentPosition!.latitude,
                                                currentPosition!.longitude),
                                            builder: (ctx) => Icon(
                                                Icons.location_on,
                                                color: Colors.red,
                                                size: 40.0),
                                          ),
                                        ]
                                      : [],
                                ),
                              ],
                            ),
                            if (isLoadingLocation)
                              Center(
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 8),
                                      Text('Mendapatkan lokasi...'),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      if (selectedStore != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lokasi Toko:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.store, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        selectedStore!.nickname,
                                        style: TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                                if (currentPosition != null) ...[
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          color: Colors.grey),
                                      SizedBox(width: 8),
                                      Text(
                                        'Jarak: ${Geolocator.distanceBetween(
                                          currentPosition!.latitude,
                                          currentPosition!.longitude,
                                          selectedStore!.latitude,
                                          selectedStore!.longitude,
                                        ).toStringAsFixed(2)} meter',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        isLocationValid
                                            ? Icons.check_circle
                                            : Icons.error,
                                        color: isLocationValid
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        isLocationValid
                                            ? 'Anda berada di area toko'
                                            : 'Anda di luar area toko',
                                        style: TextStyle(
                                          color: isLocationValid
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Text(
                                widget.isCheckIn
                                    ? 'Foto Check In'
                                    : 'Foto Check Out',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 12),
                              if (_imageFile != null)
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(_imageFile!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.camera_alt,
                                      size: 50, color: Colors.grey),
                                ),
                              SizedBox(height: 12),
                              ModernButton(
                                text: _imageFile == null
                                    ? 'Ambil Foto'
                                    : 'Ambil Ulang',
                                onPressed: _takePhoto,
                                icon: Icons.camera_alt,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              padding: EdgeInsets.all(16),
              child: ModernButton(
                text: widget.isCheckIn ? 'Check In' : 'Check Out',
                onPressed: isButtonEnabled ? _validateAndSubmitPresence : null,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
