import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calendar_model.dart';
import '../services/calendar_service.dart';
import '../widgets/modern_bottom_nav.dart';
import '../utils/constants.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late CalendarService _calendarService;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarModel? _calendarData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    _calendarService = CalendarService(token: token);
    await _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    try {
      final calendarData = await _calendarService.getCalendarData();
      if (mounted) {
        setState(() {
          _calendarData = calendarData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal memuat data kalender: ${e.toString()}')),
        );
      }
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    if (_calendarData == null) return [];

    try {
      return _calendarData!.data.events.where((event) {
        final eventDate = DateTime.parse(event.date);
        return isSameDay(eventDate, day);
      }).toList();
    } catch (e) {
      print('Error getting events for day: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Presensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadCalendarData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _calendarData == null
              ? const Center(child: Text('Tidak ada data kalender'))
              : Column(
                  children: [
                    TableCalendar(
                      firstDay:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      eventLoader: _getEventsForDay,
                      calendarStyle: const CalendarStyle(
                        markersMaxCount: 1,
                        markerDecoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _selectedDay == null
                          ? const Center(
                              child: Text('Pilih tanggal untuk melihat detail'))
                          : _buildEventList(),
                    ),
                  ],
                ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 3,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildEventList() {
    final eventsForDay = _getEventsForDay(_selectedDay!);

    if (eventsForDay.isEmpty) {
      return const Center(child: Text('Tidak ada presensi pada tanggal ini'));
    }

    return ListView.builder(
      itemCount: eventsForDay.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final event = eventsForDay[index];
        return Card(
          child: ListTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getStatusColor(event.color),
                shape: BoxShape.circle,
              ),
            ),
            title: Text('Toko: ${event.store}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shift: ${event.shift}'),
                Text('Check In: ${event.checkIn}'),
                if (event.checkOut != null)
                  Text('Check Out: ${event.checkOut}'),
                Text('Status: ${_getStatusText(event.status)}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
        return 'Hadir';
      case 'terlambat':
        return 'Terlambat';
      case 'belum_checkout':
        return 'Belum Checkout';
      default:
        return status;
    }
  }
}
