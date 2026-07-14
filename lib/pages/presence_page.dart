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
import '../utils/image_utils.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/hygiene_service.dart';
import '../pages/hygiene_page.dart';

class PresencePage extends StatefulWidget {
  final bool isCheckIn;

  const PresencePage({super.key, required this.isCheckIn});

  @override
  PresencePageState createState() => PresencePageState();
}

class PresencePageState extends State<PresencePage> {
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

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _salaryAmountController = TextEditingController(text: '50000');
  int? _selectedPaymentTypeId = 2; // Default Tunai (2)

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
      if (!mounted) return;
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

        if (nearestStore != null) {
          selectedStore = nearestStore;
          isLocationValid = shortestDistance <= nearestStore.radius;

          if (!widget.isCheckIn) {
            _salaryAmountController.text = nearestStore.dailySalaryAmount;
          }

          String message = isLocationValid
              ? 'Anda berada di area ${nearestStore.nickname} (${shortestDistance.toStringAsFixed(2)} meter)'
              : 'Anda berada di luar area ${nearestStore.nickname}. Jarak: ${shortestDistance.toStringAsFixed(2)} meter';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: isLocationValid ? AppColors.success : AppColors.error,
            ),
          );
        }
      });

      mapController.move(
        LatLng(position.latitude, position.longitude),
        18.0,
      );
    } catch (e) {
      if (!mounted) return;
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
            content: const Text('Waktu checkout hanya diperbolehkan sampai jam 02:00'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _validateAndSubmitPresence() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap ambil foto selfie terlebih dahulu'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      if (widget.isCheckIn) {
        final hygieneService = HygieneService();
        final hasHygiene = await hygieneService.checkTodayStatus(storeId: selectedStore!.id);
        if (!hasHygiene) {
          if (!mounted) return;
          setState(() => isLoading = false);
          
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Laporan Kebersihan Belum Diisi'),
              content: Text(
                'Laporan kebersihan untuk toko ${selectedStore!.nickname} belum diisi hari ini. '
                'Harap isi laporan kebersihan terlebih dahulu sebelum melakukan Check In.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HygienePage(),
                      ),
                    );
                  },
                  child: const Text('Isi Laporan'),
                ),
              ],
            ),
          );
          return;
        }
      }

      await _presenceController.submitPresence(
        isCheckIn: widget.isCheckIn,
        currentPosition: currentPosition!,
        selectedStore: selectedStore!,
        selectedShiftStore: selectedShiftStore,
        imageFile: _imageFile!,
        dailySalaryAmount: widget.isCheckIn ? null : _salaryAmountController.text,
        dailySalaryPaymentTypeId: widget.isCheckIn ? null : _selectedPaymentTypeId.toString(),
        onSuccess: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.error),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _updateMapView() {
    if (selectedStore != null && currentPosition != null) {
      final centerLat =
          (currentPosition!.latitude + selectedStore!.latitude) / 2;
      final centerLng =
          (currentPosition!.longitude + selectedStore!.longitude) / 2;

      final distance = Geolocator.distanceBetween(
        currentPosition!.latitude,
        currentPosition!.longitude,
        selectedStore!.latitude,
        selectedStore!.longitude,
      );

      double zoom = 18.0;
      if (distance > 1000) {
        zoom = 14.0;
      } else if (distance > 500) {
        zoom = 15.0;
      } else if (distance > 200) {
        zoom = 16.0;
      } else if (distance > 100) {
        zoom = 17.0;
      }

      mapController.move(LatLng(centerLat, centerLng), zoom);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 75,
        maxWidth: 1024,
      );

      if (photo != null) {
        final compressed = await ImageUtils.compressImage(photo.path);
        if (mounted) {
          setState(() {
            _imageFile = compressed;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    bool isButtonEnabled = selectedStore != null &&
        currentPosition != null &&
        isLocationValid &&
        _imageFile != null;

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
            icon: const Icon(Icons.my_location),
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
                  padding: AppSpacing.paddingMD,
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: AppSpacing.paddingMD,
                          child: Column(
                            children: [
                              if (_imageFile != null) ...[
                                ClipRRect(
                                  borderRadius: AppSpacing.borderRadiusSM,
                                  child: Image.file(
                                    _imageFile!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                AppSpacing.gapVerticalSM,
                              ],
                              ElevatedButton.icon(
                                onPressed: _takePhoto,
                                icon: const Icon(Icons.camera_alt),
                                label: Text(_imageFile == null
                                    ? 'Ambil Foto Selfie'
                                    : 'Ambil Ulang Foto'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppSpacing.gapVerticalMD,
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
                                    content: Text('Anda berada di luar area toko. Jarak: ${distance.toStringAsFixed(2)} meter'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }

                            _updateMapView();
                          },
                        ),
                        AppSpacing.gapVerticalMD,
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
                        AppSpacing.gapVerticalMD,
                      ],
                      SizedBox(
                        height: 300,
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: mapController,
                              options: MapOptions(
                                initialCenter: LatLng(
                                  currentPosition?.latitude ?? -6.200000,
                                  currentPosition?.longitude ?? 106.816666,
                                ),
                                initialZoom: 15.0,
                              ),
                              children: [
                                // CartoDB Voyager: tile berbasis data OSM dengan
                                // gaya bersih yang mirip Google Maps (jalan oranye,
                                // latar terang, label rapi). Gratis tanpa API key.
                                TileLayer(
                                  urlTemplate:
                                      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                                  userAgentPackageName: 'id.sagansa.presence',
                                ),
                                if (selectedStore != null)
                                  CircleLayer(
                                    circles: [
                                      CircleMarker(
                                        point: LatLng(selectedStore!.latitude,
                                            selectedStore!.longitude),
                                        radius: selectedStore!.radius
                                            .toDouble(),
                                        color: colorScheme.primary.withValues(alpha: 0.2),
                                        borderColor: colorScheme.primary,
                                        borderStrokeWidth: 2,
                                      ),
                                    ],
                                  ),
                                MarkerLayer(
                                  markers: [
                                    if (currentPosition != null)
                                      Marker(
                                        point: LatLng(currentPosition!.latitude,
                                            currentPosition!.longitude),
                                        child: Icon(
                                            Icons.person_pin_circle,
                                            color: colorScheme.error,
                                            size: 40.0),
                                      ),
                                    if (selectedStore != null)
                                      Marker(
                                        point: LatLng(selectedStore!.latitude,
                                            selectedStore!.longitude),
                                        child: Icon(Icons.store,
                                            color: colorScheme.primary, size: 40.0),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            if (isLoadingLocation)
                              Center(
                                child: Container(
                                  padding: AppSpacing.paddingMD,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: AppSpacing.borderRadiusSM,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(),
                                      AppSpacing.gapVerticalSM,
                                      const Text('Mendapatkan lokasi...'),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      AppSpacing.gapVerticalMD,
                      if (selectedStore != null)
                        Card(
                          child: Padding(
                            padding: AppSpacing.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lokasi Toko:',
                                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                AppSpacing.gapVerticalSM,
                                Row(
                                  children: [
                                    Icon(Icons.store, color: colorScheme.onSurfaceVariant),
                                    AppSpacing.gapHorizontalSM,
                                    Expanded(
                                      child: Text(
                                        selectedStore!.nickname,
                                        style: textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                if (currentPosition != null) ...[
                                  AppSpacing.gapVerticalSM,
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          color: colorScheme.onSurfaceVariant),
                                      AppSpacing.gapHorizontalSM,
                                      Text(
                                        'Jarak: ${Geolocator.distanceBetween(
                                          currentPosition!.latitude,
                                          currentPosition!.longitude,
                                          selectedStore!.latitude,
                                          selectedStore!.longitude,
                                        ).toStringAsFixed(2)} meter',
                                        style: textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  AppSpacing.gapVerticalSM,
                                  Row(
                                    children: [
                                      Icon(
                                        isLocationValid
                                            ? Icons.check_circle
                                            : Icons.error,
                                        color: isLocationValid
                                            ? AppColors.success
                                            : colorScheme.error,
                                      ),
                                      AppSpacing.gapHorizontalSM,
                                      Text(
                                        isLocationValid
                                            ? 'Anda berada di area toko'
                                            : 'Anda di luar area toko',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: isLocationValid
                                              ? AppColors.success
                                              : colorScheme.error,
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
              if (!widget.isCheckIn) ...[
                AppSpacing.gapVerticalMD,
                Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Salary',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: AppSpacing.sectionGap),
                        TextField(
                          controller: _salaryAmountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Amount (Rp)',

                            prefixText: 'Rp ',
                          ),
                        ),
                        SizedBox(height: AppSpacing.sectionGap),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedPaymentTypeId,
                          decoration: const InputDecoration(
                            labelText: 'Payment Type',

                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Transfer')),
                            DropdownMenuItem(value: 2, child: Text('Tunai')),
                          ],
                          onChanged: (value) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _selectedPaymentTypeId = value;
                                });
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.onSurface.withValues(alpha: 0.35),
                      spreadRadius: 0,
                      blurRadius: 12,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: AppSpacing.paddingMD,
                child: ModernButton(
                  text: widget.isCheckIn ? 'Check In' : 'Check Out',
                  onPressed: isButtonEnabled ? _validateAndSubmitPresence : null,
                  isLoading: isLoading,
                  backgroundColor: widget.isCheckIn ? null : Colors.redAccent,
                  foregroundColor: widget.isCheckIn ? null : Colors.white,
                ),
              ),
            ],
          ),
        ),
    );
  }
}
