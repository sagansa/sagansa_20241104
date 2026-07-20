import 'package:flutter/material.dart';

import '../models/presence_model.dart';
import '../services/presence_service.dart';
import '../services/salary_service.dart';
import '../widgets/dashboard_scaffold.dart';
import 'calendar_page.dart';
import 'daily_salary_list_page.dart';
import 'leave_page.dart';
import 'loan_page.dart';
import 'presence_monthly_page.dart';
import 'salary_page.dart';

class HRDDashboardPage extends StatefulWidget {
  const HRDDashboardPage({super.key});

  @override
  State<HRDDashboardPage> createState() => _HRDDashboardPageState();
}

class _HRDDashboardPageState extends State<HRDDashboardPage> {
  bool hasLoanData = false;

  List<PresenceModel> previousPresences = [];
  PresenceModel? todayPresence;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLoanAvailability();
    _loadPresenceHistory();
  }

  Future<void> _loadLoanAvailability() async {
    try {
      final salaryHistory = await SalaryService().getSalaryHistory();
      if (mounted) {
        setState(() {
          hasLoanData = salaryHistory.any((item) => item['has_loan'] == true);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPresenceHistory() async {
    setState(() => isLoading = true);
    try {
      final data = await PresenceService().getUserPresence();
      final previousData = data['previous'] as List? ?? [];
      final todayData = data['today'];

      if (mounted) {
        setState(() {
          todayPresence =
              todayData != null ? PresenceModel.fromJson(todayData) : null;
          previousPresences = previousData
              .map((item) {
                try {
                  return PresenceModel.fromJson(item);
                } catch (_) {
                  return null;
                }
              })
              .whereType<PresenceModel>()
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      currentIndex: 1,
      title: 'Layanan Personalia (HRD)',
      subtitle: 'Kelola gaji, presensi, cuti, dan kasbon karyawan.',
      menuItems: [
        DashboardMenuItem(
          icon: Icons.wallet_outlined,
          title: 'Gaji & Slip',
          subtitle: 'Informasi slip gaji bulanan Anda.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SalaryPage()),
            );
          },
        ),
        DashboardMenuItem(
          icon: Icons.calendar_month_outlined,
          title: 'Kalender',
          subtitle: 'Jadwal dan riwayat kehadiran kerja.',
          onTap: () {
            final allPresences = [
              if (todayPresence != null) todayPresence!,
              ...previousPresences,
            ];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CalendarPage(presences: allPresences),
              ),
            );
          },
        ),
        DashboardMenuItem(
          icon: Icons.receipt_long_outlined,
          title: 'Cuti & Izin',
          subtitle: 'Ajukan cuti atau izin ketidakhadiran.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LeavePage()),
            );
          },
        ),
        DashboardMenuItem(
          icon: Icons.fact_check_outlined,
          title: 'Rekap Presensi',
          subtitle: 'Ringkasan kehadiran kerja bulanan.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PresenceMonthlyPage(),
              ),
            );
          },
        ),
        DashboardMenuItem(
          icon: Icons.payments_outlined,
          title: 'Kasbon',
          subtitle: 'Ajukan atau lihat kasbon karyawan.',
          visible: hasLoanData,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoanPage()),
            );
          },
        ),
        DashboardMenuItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Daily Salary',
          subtitle: 'Detail dan rekapitulasi gaji harian.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const DailySalaryListPage()),
            );
          },
        ),
      ],
    );
  }
}
