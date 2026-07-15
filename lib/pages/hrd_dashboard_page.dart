import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/constants.dart';
import '../controllers/home_controller.dart';
import '../models/presence_model.dart';
import 'home_page.dart';
import 'salary_page.dart';
import 'printer_settings_page.dart';
import 'leave_page.dart';
import 'loan_page.dart';
import 'calendar_page.dart';
import 'daily_salary_list_page.dart';
import '../services/salary_service.dart';

class HRDDashboardPage extends StatefulWidget {
  const HRDDashboardPage({super.key});

  @override
  State<HRDDashboardPage> createState() => _HRDDashboardPageState();
}

class _HRDDashboardPageState extends State<HRDDashboardPage> {
  String userName = '';
  String companyName = 'SAGANSA';
  bool isStorageStaff = false;
  bool hasLoanData = false;

  late HomeController _homeController;
  List<PresenceModel> previousPresences = [];
  PresenceModel? todayPresence;
  bool isLoading = false;

  final ScrollController _scrollController = ScrollController();
  int _maxDisplayed = 7;

  // Filter States
  String _selectedMonth = 'Semua';
  String _selectedStatus = 'Semua';

  final List<String> _months = [
    'Semua',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  final List<String> _statuses = [
    'Semua',
    'Tepat Waktu',
    'Terlambat',
    'Pulang Cepat',
  ];

  @override
  void initState() {
    super.initState();
    _homeController = HomeController(context);
    _loadUserData();
    _loadPresenceHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      final filteredList = _getFilteredPresences();
      if (_maxDisplayed < filteredList.length) {
        setState(() {
          _maxDisplayed = (_maxDisplayed + 10).clamp(0, filteredList.length);
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = json.decode(userString);
        final userRoles = List<String>.from(userData['roles'] ?? []);
        
        bool hasLoan = false;
        try {
          final salaryHistory = await SalaryService().getSalaryHistory();
          hasLoan = salaryHistory.any((item) => item['has_loan'] == true);
        } catch (e) {
          // Ignore
        }

        setState(() {
          userName = userData['name'] ?? '';
          companyName = userData['company']?['name'] ?? 'SAGANSA';
          isStorageStaff = userRoles.contains('storage-staff');
          hasLoanData = hasLoan;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _loadPresenceHistory() async {
    setState(() => isLoading = true);
    try {
      final data = await _homeController.loadPresenceData();
      final previousData = data['previous'] as List? ?? [];
      final todayData = data['today'];

      setState(() {
        todayPresence = todayData != null ? PresenceModel.fromJson(todayData) : null;
        previousPresences = previousData
            .map((item) {
              try {
                return PresenceModel.fromJson(item);
              } catch (e) {
                return null;
              }
            })
            .whereType<PresenceModel>()
            .toList();
      });
    } catch (e) {
      // Ignore
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      await prefs.remove(AppConstants.tokenKey);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  List<PresenceModel> _getFilteredPresences() {
    final allPresences = [
      if (todayPresence != null) todayPresence!,
      ...previousPresences,
    ];

    return allPresences.where((presence) {
      // 1. Month Filter
      if (_selectedMonth != 'Semua') {
        try {
          final dateStr = presence.checkIn.split(' ')[0]; // YYYY-MM-DD
          final monthInt = int.parse(dateStr.split('-')[1]);
          if (_months[monthInt] != _selectedMonth) {
            return false;
          }
        } catch (_) {
          return false;
        }
      }

      // 2. Status Filter
      if (_selectedStatus != 'Semua') {
        final checkInStatus = presence.checkInStatus;
        final checkOutStatus = presence.checkOutStatus;

        if (_selectedStatus == 'Tepat Waktu' && checkInStatus != 'tepat_waktu') {
          return false;
        }
        if (_selectedStatus == 'Terlambat' && checkInStatus != 'terlambat') {
          return false;
        }
        if (_selectedStatus == 'Pulang Cepat' && checkOutStatus != 'pulang_cepat') {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filteredList = _getFilteredPresences();

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => InkWell(
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: SvgPicture.asset(
                'assets/images/logo.svg',
                width: 36,
                fit: BoxFit.contain,
                height: 36,
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName,
              style: theme.textTheme.titleSmall,
            ),
            Text(
              companyName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: AppSpacing.borderRadiusSM,
                    ),
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      width: 48,
                      fit: BoxFit.contain,
                      height: 48,
                    ),
                  ),
                  AppSpacing.gapVerticalSM,
                  Text(
                    userName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    companyName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Beranda'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: const Text('Printer Thermal'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrinterSettingsPage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Bantuan'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementasi halaman bantuan
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: colorScheme.error),
              title: Text('Logout', style: TextStyle(color: colorScheme.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Konfirmasi'),
                    content: const Text('Apakah Anda yakin ingin keluar?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Ya'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await _logout();
                }
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Layanan Personalia (HRD)',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickMenuCard(
                    icon: Icons.wallet_outlined,
                    color: AppColors.success,
                    title: 'Gaji & Slip',
                    isFirst: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SalaryPage()),
                      );
                    },
                  ),
                  _buildQuickMenuCard(
                    icon: Icons.calendar_month_outlined,
                    color: AppColors.primary,
                    title: 'Kalender',
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
                  _buildQuickMenuCard(
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.warning,
                    title: 'Cuti & Izin',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LeavePage()),
                      );
                    },
                  ),
                  if (hasLoanData)
                    _buildQuickMenuCard(
                      icon: Icons.payments_outlined,
                      color: AppColors.info,
                      title: 'Kasbon',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoanPage()),
                        );
                      },
                    ),
                  _buildQuickMenuCard(
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.success,
                    title: 'Daily Salary',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DailySalaryListPage()),
                      );
                    },
                  ),
                ],
              ),
            ),

            AppSpacing.gapVerticalLG,
            const Divider(),
            AppSpacing.gapVerticalMD,

            // Presence History Section with Filters
            Text(
              'Riwayat Presensi Lengkap',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Filter Bar UI
            Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + AppSpacing.xs, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: AppSpacing.borderRadiusMD,
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedMonth,
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              isExpanded: true,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              items: _months.map((String month) {
                                return DropdownMenuItem<String>(
                                  value: month,
                                  child: Text(month),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedMonth = val;
                                    _maxDisplayed = 7;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: colorScheme.outlineVariant,
                          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + AppSpacing.xs),
                        ),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStatus,
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              isExpanded: true,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              items: _statuses.map((String status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedStatus = val;
                                    _maxDisplayed = 7;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapVerticalMD,

            // Filtered List or Loading
            isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : filteredList.isNotEmpty
                    ? Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredList.length > _maxDisplayed
                                ? _maxDisplayed
                                : filteredList.length,
                            itemBuilder: (context, index) {
                              return _buildPresenceCard(filteredList[index]);
                            },
                          ),
                          if (filteredList.length > _maxDisplayed)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_outlined,
                                size: 48,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              AppSpacing.gapVerticalMD,
                              Text(
                                'Tidak ada riwayat presensi yang cocok',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
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
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 1,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildQuickMenuCard({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    bool isFirst = false,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 105,
      child: Card(
        margin: EdgeInsets.only(
          left: isFirst ? AppSpacing.sm : 0,
          right: AppSpacing.sm,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusMD,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sectionGap, horizontal: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: AppSpacing.paddingSM,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusSM,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ), 
                AppSpacing.gapVerticalSM,
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresenceCard(PresenceModel presence) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final checkInDateTime = _homeController.splitDateTime(presence.checkIn);
    final checkOutDateTime = presence.checkOut != null
        ? _homeController.splitDateTime(presence.checkOut!)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          children: [
            Text(
              presence.store,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              presence.shiftStore,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVerticalMD,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check In',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.gapVerticalSM,
                      _buildStatusBadge(
                        presence.getStatusColor(presence.checkInStatus),
                        presence.getStatusText(presence.checkInStatus),
                      ),
                      AppSpacing.gapVerticalSM,
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
                          AppSpacing.gapHorizontalXS,
                          Text(
                            checkInDateTime['date']!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: colorScheme.onSurfaceVariant),
                          AppSpacing.gapHorizontalXS,
                          Text(
                            checkInDateTime['time']!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 80,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Check Out',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.gapVerticalSM,
                      if (presence.checkOut != null) ...[
                        _buildStatusBadge(
                          presence.getStatusColor(presence.checkOutStatus),
                          presence.getStatusText(presence.checkOutStatus),
                        ),
                        AppSpacing.gapVerticalSM,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              checkOutDateTime!['date']!,
                              style: theme.textTheme.bodySmall,
                            ),
                            AppSpacing.gapHorizontalXS,
                            Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              checkOutDateTime['time']!,
                              style: theme.textTheme.bodySmall,
                            ),
                            AppSpacing.gapHorizontalXS,
                            Icon(Icons.access_time, size: 14, color: colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ] else ...[
                        _buildStatusBadge(
                          AppColors.warning,
                          'Belum',
                        ),
                        AppSpacing.gapVerticalSM,
                        Text(
                          'Belum Absen Pulang',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ]
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

  Widget _buildStatusBadge(Color color, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusSM,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
