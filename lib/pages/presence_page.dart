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

class PresencePage extends StatefulWidget {
  final bool isCheckIn;

  const PresencePage({Key? key, required this.isCheckIn}) : super(key: key);

  @override
  _PresencePageState createState() => _PresencePageState();
}

class _PresencePageState extends State<PresencePage> {
  List<Store> stores = [];
  List<ShiftStore> shiftStores = [];
  Store? selectedStore;
  ShiftStore? selectedShiftStore;
  bool isLoading = false;
  Position? currentPosition;
  MapController mapController = MapController();
  bool isLoadingLocation = false;
  bool isLocationValid = false;
  bool isTimeValid = true;
  late PresenceController _presenceController;

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
        Store? nearestStore;
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

  void _handlePresence() async {
    if (!widget.isCheckIn && !isTimeValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Tidak dapat melakukan checkout di luar waktu yang ditentukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    await _presenceController.submitPresence(
      isCheckIn: widget.isCheckIn,
      currentPosition: currentPosition!,
      selectedStore: selectedStore!,
      selectedShiftStore: selectedShiftStore,
      onSuccess: () {
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

    setState(() => isLoading = false);
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
                        ModernDropdown<Store>(
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
                          ModernDropdown<ShiftStore>(
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
                onPressed: isButtonEnabled ? _handlePresence : null,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
