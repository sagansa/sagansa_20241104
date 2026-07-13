import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/presence_model.dart';
import '../models/leave_model.dart';
import '../services/leave_service.dart';
import '../widgets/modern_bottom_nav.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/modern_bottom_sheet.dart';

class CalendarPage extends StatefulWidget {
  final List<PresenceModel> presences;

  const CalendarPage({super.key, required this.presences});

  @override
  CalendarPageState createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  late List<Appointment> _appointments;
  List<Leave> _leaves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final leaves = await LeaveService().getLeaves();
      setState(() {
        _leaves = leaves;
        _appointments = _getAppointments();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat data')),
      );
    }
  }

  List<Appointment> _getAppointments() {
    final appointments = <Appointment>[];

    for (final presence in widget.presences) {
      final checkInTime = DateTime.parse(presence.checkIn).toLocal();
      final checkOutTime = presence.checkOut != null
          ? DateTime.parse(presence.checkOut!).toLocal()
          : checkInTime.add(const Duration(hours: 8));

      appointments.add(Appointment(
        startTime: checkInTime,
        endTime: checkOutTime,
        subject: 'Presensi: ${presence.store}',
        notes: presence.shiftStore,
        color: _getStatusColor(presence),
        isAllDay: false,
        resourceIds: ['presence'],
      ));
    }

    for (final leave in _leaves) {
      appointments.add(Appointment(
        startTime: DateTime(leave.fromDate.year, leave.fromDate.month,
            leave.fromDate.day),
        endTime: DateTime(leave.untilDate.year, leave.untilDate.month,
            leave.untilDate.day, 23, 59, 59),
        subject: 'Cuti: ${leave.reasonText}',
        notes: leave.notes ?? '',
        color: _getLeaveStatusColor(leave.status),
        isAllDay: true,
        resourceIds: ['leave'],
      ));
    }

    return appointments;
  }

  Color _getStatusColor(PresenceModel presence) {
    if (presence.checkOutStatus == 'tidak_absen') {
      return AppColors.error;
    } else if (presence.checkInStatus == 'terlambat') {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  Color _getLeaveStatusColor(int status) {
    switch (status) {
      case 1:
        return AppColors.warning.withValues(alpha: 0.7);
      case 2:
        return AppColors.success.withValues(alpha: 0.7);
      case 3:
        return AppColors.error.withValues(alpha: 0.7);
      default:
        return AppColors.onSurfaceVariant.withValues(alpha: 0.7);
    }
  }

  void _onTap(CalendarTapDetails details) {
    if (details.targetElement != CalendarElement.calendarCell) return;
    ModernBottomSheet.show(
      context: context,
      title: _formatDate(details.date!),
      child: _getContentForDate(details.date!),
    );
  }

  Widget _getContentForDate(DateTime date) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_leaves.any((l) =>
        _isSameDay(date, l.fromDate) ||
        _isSameDay(date, l.untilDate) ||
        (date.isAfter(l.fromDate) && date.isBefore(l.untilDate)))) {
      return _buildLeaveDetails(date);
    }

    if (widget.presences.any((p) {
      final checkInTime = DateTime.parse(p.checkIn).toLocal();
      return _isSameDay(date, checkInTime);
    })) {
      return _buildPresenceDetails(date);
    }

    return Center(
      child: Padding(
        padding: AppSpacing.paddingVerticalXL,
        child: Text(
          'Tidak ada data untuk tanggal ini',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildPresenceDetails(DateTime date) {
    final textTheme = Theme.of(context).textTheme;
    try {
      final presence = widget.presences.firstWhere((p) {
        final checkInTime = DateTime.parse(p.checkIn).toLocal();
        return _isSameDay(date, checkInTime);
      });

      return Container(
        width: double.infinity,
        padding: AppSpacing.paddingVerticalSM,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              presence.store,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapVerticalSM,
            Text('Shift: ${presence.shiftStore}'),
            AppSpacing.gapVerticalMD,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check In',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(_formatDateTime(DateTime.parse(presence.checkIn))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: presence
                            .getStatusColor(presence.checkInStatus)
                            .withValues(alpha: 0.2),
                        borderRadius: AppSpacing.borderRadiusXS,
                      ),
                      child: Text(
                        presence.getStatusText(presence.checkInStatus),
                        style: textTheme.bodySmall?.copyWith(
                          color:
                              presence.getStatusColor(presence.checkInStatus),
                        ),
                      ),
                    ),
                  ],
                ),
                if (presence.checkOut != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Check Out',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(_formatDateTime(
                          DateTime.parse(presence.checkOut!))),
                      if (presence.checkOutStatus != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: presence
                                .getStatusColor(presence.checkOutStatus!)
                                .withValues(alpha: 0.2),
                            borderRadius: AppSpacing.borderRadiusXS,
                          ),
                          child: Text(
                            presence.getStatusText(presence.checkOutStatus!),
                            style: textTheme.bodySmall?.copyWith(
                              color: presence
                                  .getStatusColor(presence.checkOutStatus!),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildLeaveDetails(DateTime date) {
    final textTheme = Theme.of(context).textTheme;
    try {
      final leave = _leaves.firstWhere(
        (l) =>
            (date.isAfter(l.fromDate.subtract(const Duration(days: 1))) ||
                _isSameDay(date, l.fromDate)) &&
            (date.isBefore(l.untilDate.add(const Duration(days: 1))) ||
                _isSameDay(date, l.untilDate)),
      );

      return Container(
        width: double.infinity,
        padding: AppSpacing.paddingVerticalSM,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cuti: ${leave.reasonText}',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapVerticalSM,
            Text('Status: ${leave.statusText}'),
            AppSpacing.gapVerticalSM,
            Text(
              'Tanggal: ${_formatDate(leave.fromDate)} - ${_formatDate(leave.untilDate)}',
            ),
            if (leave.notes != null && leave.notes!.isNotEmpty) ...[
              AppSpacing.gapVerticalSM,
              Text('Catatan: ${leave.notes}'),
            ],
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kalender')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
      ),
      body: SfCalendar(
        view: CalendarView.month,
        dataSource: AppointmentDataSource(_appointments),
        onTap: _onTap,
        monthViewSettings: MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
          showAgenda: true,
          agendaViewHeight: 200,
          numberOfWeeksInView: 6,
          agendaStyle: AgendaStyle(
            backgroundColor: colorScheme.surface,
            appointmentTextStyle: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
            dateTextStyle: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
            dayTextStyle: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        timeSlotViewSettings: TimeSlotViewSettings(
          startHour: 0,
          endHour: 24,
          timeFormat: 'HH:mm',
          timeIntervalHeight: 60,
          timeTextStyle: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        showDatePickerButton: true,
        allowViewNavigation: true,
        showNavigationArrow: true,
        todayHighlightColor: colorScheme.primary,
        cellBorderColor: colorScheme.outlineVariant,
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index != 2) {
            Navigator.pop(context);
          }
        },
        presences: widget.presences,
      ),
    );
  }
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].startTime;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].endTime;
  }

  @override
  String getSubject(int index) {
    return appointments![index].subject;
  }

  @override
  Color getColor(int index) {
    return appointments![index].color;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].isAllDay;
  }
}
