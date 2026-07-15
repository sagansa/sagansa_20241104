import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/salary_service.dart';
import 'salary_detail_page.dart';

class SalaryPage extends StatefulWidget {
  const SalaryPage({super.key});

  @override
  State<SalaryPage> createState() => _SalaryPageState();
}

class _SalaryPageState extends State<SalaryPage> {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final ScrollController _scrollController = ScrollController();

  final SalaryService _salaryService = SalaryService();
  List<Map<String, dynamic>> salaryHistory = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Role & filters
  bool _isAdmin = false;
  List<Map<String, dynamic>> _employees = [];
  int? _selectedUserId;
  String? _selectedPeriod; // YYYY-MM, null = semua

  // Pagination (admin)
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUserRole();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = json.decode(userString);
        final userRoles = List<String>.from(userData['roles'] ?? []);
        if (mounted) {
          setState(() {
            _isAdmin = userRoles.contains('admin') ||
                userRoles.contains('super_admin');
          });
        }
      }
    } catch (_) {}
    await _loadData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        _isAdmin) {
      _loadMore();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      List<Map<String, dynamic>> data;
      if (_isAdmin) {
        final result = await _salaryService.getSalaryHistoryAdmin(
          page: 1,
          userId: _selectedUserId,
          period: _selectedPeriod,
        );
        data = (result['data'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        final meta = result['meta'] as Map<String, dynamic>;
        _hasMore = _currentPage < (meta['last_page'] ?? 1);
        // Load employees list for filter (once)
        if (_employees.isEmpty) _loadEmployees();
      } else {
        data = await _salaryService.getSalaryHistory();
      }
      if (!mounted) return;
      setState(() {
        salaryHistory = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat riwayat gaji: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _salaryService.getEmployeesForSalary();
      if (mounted) setState(() => _employees = employees);
    } catch (_) {
      // Abaikan; dropdown tetap "Semua"
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await _salaryService.getSalaryHistoryAdmin(
        page: _currentPage + 1,
        userId: _selectedUserId,
        period: _selectedPeriod,
      );
      final data = (result['data'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final meta = result['meta'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        salaryHistory.addAll(data);
        _currentPage++;
        _hasMore = _currentPage < (meta['last_page'] ?? 1);
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedUserId = null;
      _selectedPeriod = null;
    });
    _loadData();
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'processing':
        return AppColors.info;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Dibayarkan';
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      default:
        return 'Unknown';
    }
  }

  Widget _buildSalaryCard(Map<String, dynamic> salary) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final DateTime periodDate = DateTime.parse(salary['period']);
    final DateTime? paymentDate = salary['paymentDate'] != null
        ? DateTime.parse(salary['paymentDate'])
        : null;
    final String userName = salary['user_name'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SalaryDetailPage(
                salaryId: salary['id'],
                userName: _isAdmin ? userName : null,
              ),
            ),
          );
        },
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Column(
            children: [
              if (_isAdmin && userName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 18, color: colorScheme.primary),
                      AppSpacing.gapHorizontalSM,
                      Expanded(
                        child: Text(
                          userName,
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM yyyy', 'id_ID').format(periodDate),
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: _getStatusColor(salary['status'], colorScheme)
                          .withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusMD,
                    ),
                    child: Text(
                      _getStatusText(salary['status']),
                      style: textTheme.labelMedium?.copyWith(
                        color: _getStatusColor(salary['status'], colorScheme),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sectionGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currencyFormatter.format(salary['amount']),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (paymentDate != null)
                    Text(
                      'Dibayar: ${DateFormat('dd/MM/yyyy').format(paymentDate)}',
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Gaji'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            if (_isAdmin) _buildFilterSection(colorScheme, textTheme),
            if (!_isAdmin)
              Container(
                padding: AppSpacing.paddingMD,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary),
                    AppSpacing.gapHorizontalSM,
                    Expanded(
                      child: Text(
                        'Gaji bulanan dihitung berdasarkan periode cut-off yang dikonfigurasi HRD.',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _buildBody(colorScheme, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  /// Generate list bulan untuk dropdown periode (12 bulan terakhir + "Semua").
  List<DropdownMenuItem<String?>> _buildPeriodItems() {
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('Semua')),
    ];
    final now = DateTime.now();
    final fmt = DateFormat('MMMM yyyy', 'id_ID');
    for (int i = 0; i < 12; i++) {
      final d = DateTime(now.year, now.month - i, 1);
      final value =
          '${d.year}-${d.month.toString().padLeft(2, '0')}'; // YYYY-MM
      items.add(DropdownMenuItem<String?>(value: value, child: Text(fmt.format(d))));
    }
    return items;
  }

  Widget _buildFilterSection(ColorScheme colorScheme, TextTheme textTheme) {
    final theme = Theme.of(context);
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 20, color: colorScheme.primary),
              AppSpacing.gapHorizontalSM,
              Text('Filter',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_selectedUserId != null || _selectedPeriod != null)
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Hapus Filter'),
                ),
            ],
          ),
          AppSpacing.gapVerticalSM,
          DropdownButtonFormField<int?>(
            value: _selectedUserId,
            decoration: InputDecoration(
              labelText: 'Karyawan',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusSM),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Semua')),
              ..._employees.map((emp) => DropdownMenuItem<int?>(
                    value: emp['id'],
                    child: Text(emp['name'] ?? '-',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: (value) {
              setState(() => _selectedUserId = value);
              _loadData();
            },
          ),
          AppSpacing.gapVerticalSM,
          DropdownButtonFormField<String?>(
            value: _selectedPeriod,
            decoration: InputDecoration(
              labelText: 'Periode',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusSM),
            ),
            items: _buildPeriodItems(),
            onChanged: (value) {
              setState(() => _selectedPeriod = value);
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: AppSpacing.paddingLG,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: TextStyle(color: colorScheme.error)),
              AppSpacing.gapVerticalMD,
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (salaryHistory.isEmpty) {
      return Center(
        child: Text('Belum ada riwayat slip gaji bulanan.'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: salaryHistory.length + (_hasMore && _isAdmin ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == salaryHistory.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildSalaryCard(salaryHistory[index]);
      },
    );
  }
}
