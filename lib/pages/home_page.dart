import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/presence_model.dart';
import 'presence_page.dart';

import 'calendar_page.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/modern_fab.dart';
import '../utils/constants.dart';
import '../controllers/home_controller.dart';
import 'package:provider/provider.dart';
import '../providers/presence_provider.dart';
import '../providers/auth_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late HomeController _controller;
  String userName = '';
  String companyName = 'SAGANSA';
  PresenceModel? todayPresence;
  List<PresenceModel> previousPresences = [];
  final int initialDisplayCount = 7;
  bool isLoading = false;
  final int _selectedIndex = 0;
  bool _hasActiveLeave = false;

  @override
  void initState() {
    super.initState();
    _controller = HomeController(context);
    _loadUserData();
    _initializeData();
  }

  Future<void> _loadUserData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userData = authProvider.userData;

      if (userData != null) {
        setState(() {
          userName = userData['name'] ?? '';
          if (userData['company'] != null) {
            companyName = userData['company']['name'] ?? 'SAGANSA';
          }
        });
      } else {
        // If no user data, try to refresh auth
        await authProvider.refreshAuth();
      }
    } catch (e) {
      // Handle error by refreshing auth
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshAuth();
    }
  }

  Future<void> _initializeData() async {
    try {
      // Load presence data
      await _loadPresenceData();

      // Check active leave
      final hasActiveLeave = await _controller.checkActiveLeave();
      setState(() {
        _hasActiveLeave = hasActiveLeave;
      });
    } catch (e) {
      if (e.toString().contains('User data not found')) {
        _logout();
      }
    }
  }

  Future<void> _loadPresenceData() async {
    setState(() => isLoading = true);
    try {
      final data = await _controller.loadPresenceData();
      final newTodayPresence = data['todayPresence'] != null
          ? PresenceModel.fromJson(data['todayPresence'])
          : null;

      // Update provider
      Provider.of<PresenceProvider>(context, listen: false)
          .setTodayPresence(newTodayPresence);

      setState(() {
        todayPresence = newTodayPresence;
        previousPresences = (data['previousPresences'] as List?)
                ?.map((item) => PresenceModel.fromJson(item))
                .toList() ??
            [];
      });
    } catch (e) {
      print('Error loading presence data: $e'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.logout();

    if (mounted) {
      if (success) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/welcome',
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Tambahkan pull to refresh
  Future<void> _onRefresh() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Reload user data
      await _loadUserData();

      // Reload presence data
      await _loadPresenceData();

      // Check active leave
      final hasActiveLeave = await _controller.checkActiveLeave();
      setState(() {
        _hasActiveLeave = hasActiveLeave;
      });
    } catch (e) {
      print('Error refreshing data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui data')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _doPresence() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey) ?? '';

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final url = todayPresence == null
          ? '${ApiConstants.baseUrl}${ApiConstants.checkIn}'
          : '${ApiConstants.baseUrl}${ApiConstants.checkOut}';

      final Map<String, dynamic> requestBody = todayPresence == null
          ? {
              'store_id': 137,
              'shift_store_id': 1,
              'status': 1,
              'latitude_in': position.latitude.toString(),
              'longitude_in': position.longitude.toString(),
            }
          : {
              'latitude_out': position.latitude.toString(),
              'longitude_out': position.longitude.toString(),
            };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == AppConstants.statusSuccess) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            todayPresence = PresenceModel.fromJson(responseData['data']);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to do presence');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }

    // Reload presence data after check-in/out
    _loadPresenceData();
  }

  Widget _buildPresenceCard(PresenceModel presence) {
    final checkInDateTime = _controller.splitDateTime(presence.checkIn);
    final checkOutDateTime = presence.checkOut != null
        ? _controller.splitDateTime(presence.checkOut!)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Store dan Shift info di tengah
            Text(presence.store,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center),
            Text(presence.shiftStore,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Check In Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Check In',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          )),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: presence
                              .getStatusColor(presence.checkInStatus)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          presence.getStatusText(presence.checkInStatus),
                          style: TextStyle(
                            color:
                                presence.getStatusColor(presence.checkInStatus),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14),
                          const SizedBox(width: 4),
                          Text(checkInDateTime['date']!),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14),
                          const SizedBox(width: 4),
                          Text(checkInDateTime['time']!),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 80,
                  width: 1,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                // Check Out Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Check Out',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          )),
                      const SizedBox(height: 8),
                      Builder(builder: (context) {
                        if (checkOutDateTime != null) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: presence
                                  .getStatusColor(presence.checkOutStatus ?? '')
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              presence
                                  .getStatusText(presence.checkOutStatus ?? ''),
                              style: TextStyle(
                                color: presence.getStatusColor(
                                    presence.checkOutStatus ?? ''),
                                fontSize: 12,
                              ),
                            ),
                          );
                        } else {
                          // Tampilkan status tidak_absen jika checkOutStatus ada
                          String status = presence.checkOutStatus ?? '-';
                          if (status == 'tidak_absen') {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: presence
                                    .getStatusColor('tidak_absen')
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                presence.getStatusText('tidak_absen'),
                                style: TextStyle(
                                  color: presence.getStatusColor('tidak_absen'),
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Text('-',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                )),
                          );
                        }
                      }),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.calendar_today, size: 14),
                          const SizedBox(width: 4),
                          Text(checkOutDateTime?['date'] ?? '-'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.access_time, size: 14),
                          const SizedBox(width: 4),
                          Text(checkOutDateTime?['time'] ?? '-'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToPresencePage() async {
    // Langsung navigasi ke PresencePage
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresencePage(
          isCheckIn: todayPresence == null,
        ),
      ),
    );

    // Refresh data jika ada perubahan
    if (result == true) {
      await _loadPresenceData();
      setState(() {});
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        // Sudah di home, tidak perlu navigasi
        break;
      case 1:
        Navigator.pushNamed(context, '/leave');
        break;
      case 2:
        Navigator.pushNamed(context, '/calendar');
        break;
      case 3:
        Navigator.pushNamed(context, '/salary');
        break;
    }
  }

  Widget _buildUserProfile() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.person, color: Colors.grey[800]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName.isNotEmpty ? userName : 'Loading...',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        companyName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAllPresenceHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CalendarPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Home'),
        actions: [
          if (_hasActiveLeave) // Menampilkan ikon atau pesan jika ada cuti aktif
            IconButton(
              icon: const Icon(Icons.warning, color: Colors.orange),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Anda memiliki cuti yang aktif')),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Tampilkan dialog konfirmasi
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text('Apakah Anda yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      child: const Text('Batal'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: const Text('Logout'),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              // Jika user menekan tombol logout
              if (shouldLogout == true && mounted) {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                final success = await authProvider.logout();

                if (mounted) {
                  if (success) {
                    // Navigation will be handled by AuthWrapper
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/welcome',
                      (route) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authProvider.errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserProfile(),
                const SizedBox(height: 24),
                todayPresence != null
                    ? Column(
                        children: [
                          _buildPresenceCard(todayPresence!),
                          const SizedBox(height: 16),
                        ],
                      )
                    : Column(
                        children: [
                          Card(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fingerprint_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada presensi untuk hari ini',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Silakan lakukan presensi dengan menekan tombol di kanan bawah',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Riwayat Presensi:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: _showAllPresenceHistory,
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                previousPresences.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            previousPresences.length > initialDisplayCount
                                ? initialDisplayCount
                                : previousPresences.length,
                        itemBuilder: (context, index) {
                          return _buildPresenceCard(previousPresences[index]);
                        },
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 200, // Memberikan tinggi tetap
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada riwayat presensi',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
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
      floatingActionButton: todayPresence?.checkOut == null
          ? CustomFAB(
              onPressed: _navigateToPresencePage,
              icon: todayPresence == null
                  ? Icons.fingerprint_outlined // icon untuk checkout
                  : Icons.fingerprint_outlined, // icon untuk checkin
              backgroundColor: todayPresence == null
                  ? Colors.green // warna untuk checkout
                  : Colors.red, // warna untuk checkin
              tooltip: todayPresence == null ? 'Check Out' : 'Check In',
            )
          : null,
      bottomNavigationBar: ModernBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
