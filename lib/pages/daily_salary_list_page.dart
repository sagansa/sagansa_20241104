import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/closing_store_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/modern_dropdown.dart';
import 'create_payment_receipt_page.dart';

class DailySalaryListPage extends StatefulWidget {
  const DailySalaryListPage({super.key});

  @override
  State<DailySalaryListPage> createState() => _DailySalaryListPageState();
}

class _DailySalaryListPageState extends State<DailySalaryListPage> {
  final ClosingStoreService _service = ClosingStoreService();
  final ScrollController _scrollController = ScrollController();
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  List<dynamic> _dailySalaries = [];
  int _currentPage = 1;
  bool _hasMore = true;

  // Role & filter states
  bool _isAdmin = false;
  List<dynamic> _employees = [];
  int? _selectedUserId;
  String? _selectedStatus;
  int? _selectedPaymentType;
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;

  // Bulk selection
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  final Map<String, String> _statusOptions = {
    '1': 'Belum Dibayar',
    '2': 'Sudah Dibayar',
    '3': 'Siap Dibayar',
    '4': 'Perbaiki',
  };

  final Map<int, String> _paymentTypeOptions = {
    1: 'Transfer',
    2: 'Tunai',
  };

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
        setState(() {
          _isAdmin = userRoles.contains('admin') || userRoles.contains('super_admin');
        });
      }
    } catch (e) {
      // Ignore
    }
    _loadData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final result = await _service.getDailySalaries(
        page: 1,
        userId: _selectedUserId,
        status: _selectedStatus,
        paymentTypeId: _selectedPaymentType,
        dateFrom: _selectedDateFrom,
        dateTo: _selectedDateTo,
      );
      setState(() {
        _dailySalaries = result['data'];
        _hasMore = _currentPage < (result['meta']['last_page'] ?? 1);
        _isLoading = false;
      });

      // Load employees list for admin filter
      if (_isAdmin && _employees.isEmpty) {
        _loadEmployees();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _service.getEmployeesForDailySalary();
      if (mounted) {
        setState(() {
          _employees = employees;
        });
      }
    } catch (e) {
      // Ignore employee load error
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final result = await _service.getDailySalaries(
        page: _currentPage + 1,
        userId: _selectedUserId,
        status: _selectedStatus,
        paymentTypeId: _selectedPaymentType,
        dateFrom: _selectedDateFrom,
        dateTo: _selectedDateTo,
      );
      setState(() {
        _dailySalaries.addAll(result['data']);
        _currentPage++;
        _hasMore = _currentPage < (result['meta']['last_page'] ?? 1);
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _applyFilters() {
    _loadData();
  }

  void _clearFilters() {
    setState(() {
      _selectedUserId = null;
      _selectedStatus = null;
      _selectedPaymentType = null;
      _selectedDateFrom = null;
      _selectedDateTo = null;
    });
    _loadData();
  }

  String _getDateRangeText() {
    if (_selectedDateFrom == null && _selectedDateTo == null) {
      return 'Semua Tanggal';
    }
    final from = _selectedDateFrom != null
        ? DateFormat('dd/MM/yyyy').format(_selectedDateFrom!)
        : '...';
    final to = _selectedDateTo != null
        ? DateFormat('dd/MM/yyyy').format(_selectedDateTo!)
        : '...';
    return '$from - $to';
  }

  void _showDateRangeDialog() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateFrom != null && _selectedDateTo != null
          ? DateTimeRange(start: _selectedDateFrom!, end: _selectedDateTo!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _selectedDateFrom = picked.start;
        _selectedDateTo = picked.end;
      });
      _applyFilters();
    }
  }

  Future<void> _navigateToPaymentReceipt() async {
    if (_selectedIds.isEmpty) return;

    // Get selected daily salary data
    final selectedSalaries = _dailySalaries
        .where((s) => _selectedIds.contains(s['id']))
        .toList();

    // Get unique employee ID from selected items
    final employeeIds = selectedSalaries
        .map((s) => s['created_by']?['id'])
        .where((id) => id != null)
        .toSet()
        .toList();

    if (employeeIds.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih daily salary dari karyawan yang sama.')),
      );
      return;
    }

    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePaymentReceiptPage(
          dailySalaries:
              selectedSalaries.map((s) => s as Map<String, dynamic>).toList(),
        ),
      ),
    );

    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });

    if (result == true && mounted) {
      await _loadData();
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _dailySalaries.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(_dailySalaries.map((s) => s['id'] as int));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedIds.length} dipilih')
            : const Text('Daily Salary'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isAdmin) ...[
            if (_isSelectionMode) ...[
              IconButton(
                icon: Icon(
                  _selectedIds.length == _dailySalaries.length
                      ? Icons.deselect
                      : Icons.select_all,
                ),
                onPressed: _selectAll,
                tooltip: _selectedIds.length == _dailySalaries.length
                    ? 'Batalkan Semua'
                    : 'Pilih Semua',
              ),
              IconButton(
                icon: const Icon(Icons.payment),
                onPressed: _navigateToPaymentReceipt,
                tooltip: 'Buat Payment Receipt',
              ),
            ] else
              IconButton(
                icon: const Icon(Icons.checklist),
                onPressed: _toggleSelectionMode,
                tooltip: 'Pilih Data',
              ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters for admin only
          if (_isAdmin) _buildFilterSection(),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : _dailySalaries.isEmpty
                        ? _buildEmptyWidget()
                        : _buildListWidget(_dailySalaries),
          ),
        ],
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 20, color: AppColors.info),
              AppSpacing.gapHorizontalSM,
              Text(
                'Filter',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_selectedUserId != null ||
                  _selectedStatus != null ||
                  _selectedPaymentType != null ||
                  _selectedDateFrom != null ||
                  _selectedDateTo != null)
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Hapus Filter'),
                ),
            ],
          ),
          AppSpacing.gapVerticalSM,
          // Row 1: Employee
          ModernDropdown<int?>(
            value: _selectedUserId,
            labelText: 'Karyawan',
            hint: 'Semua Karyawan',
            prefixIcon: const Icon(Icons.person_outline, size: 20),
            items: [null, ..._employees.map((emp) => emp['id'] as int)],
            getLabel: (v) {
              if (v == null) return 'Semua Karyawan';
              final emp = _employees.firstWhere((e) => e['id'] == v, orElse: () => {});
              return emp['name']?.toString() ?? '-';
            },
            onChanged: (value) {
              setState(() => _selectedUserId = value);
              _applyFilters();
            },
          ),
          AppSpacing.gapVerticalSM,
          // Row 2: Status + Payment Type
          Row(
            children: [
              Expanded(
                child: ModernDropdown<String?>(
                  value: _selectedStatus,
                  labelText: 'Status',
                  hint: 'Semua Status',
                  items: [null, ..._statusOptions.keys],
                  getLabel: (v) => v == null ? 'Semua Status' : (_statusOptions[v] ?? v),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _applyFilters();
                  },
                ),
              ),
              AppSpacing.gapHorizontalSM,
              Expanded(
                child: ModernDropdown<int?>(
                  value: _selectedPaymentType,
                  labelText: 'Pembayaran',
                  hint: 'Semua',
                  items: [null, ..._paymentTypeOptions.keys],
                  getLabel: (v) => v == null ? 'Semua Pembayaran' : (_paymentTypeOptions[v] ?? 'Tipe #$v'),
                  onChanged: (value) {
                    setState(() => _selectedPaymentType = value);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalSM,
          // Date Range Button
          InkWell(
            onTap: () => _showDateRangeDialog(),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Filter Tanggal',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusSM,
                ),
                suffixIcon: (_selectedDateFrom != null || _selectedDateTo != null)
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _selectedDateFrom = null;
                            _selectedDateTo = null;
                          });
                          _applyFilters();
                        },
                      )
                    : const Icon(Icons.date_range, size: 18),
              ),
              child: Text(
                _getDateRangeText(),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            AppSpacing.gapVerticalMD,
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            AppSpacing.gapVerticalLG,
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 64, color: colorScheme.outline),
          AppSpacing.gapVerticalMD,
          Text('Belum ada data daily salary.', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildListWidget(List<dynamic> displayList) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ListView.builder(
      controller: _scrollController,
      itemCount: displayList.length + (_hasMore ? 1 : 0),
      padding: AppSpacing.paddingMD,
      itemBuilder: (context, index) {
        if (index == displayList.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final salary = displayList[index];
        final salaryId = salary['id'] as int;
        final employeeName = salary['created_by']?['name'] ?? 'Staff';
        final storeName = salary['store']?['nickname'] ??
            salary['store']?['name'] ??
            '-';
        final shiftStoreName = salary['shift_store']?['name'] ?? '';
        final date = salary['date'] ?? '';
        final amount = double.tryParse(salary['amount'].toString()) ?? 0;
        final status = salary['status'];
        final paymentType = salary['payment_type_id'];

        String statusText;
        Color statusColor;
        if (status == 1 || status == '1') {
          statusText = 'Belum Dibayar';
          statusColor = AppColors.warning;
        } else if (status == 2 || status == '2') {
          statusText = 'Sudah Dibayar';
          statusColor = AppColors.success;
        } else if (status == 3 || status == '3') {
          statusText = 'Siap Dibayar';
          statusColor = AppColors.info;
        } else if (status == 4 || status == '4') {
          statusText = 'Perbaiki';
          statusColor = colorScheme.error;
        } else {
          statusText = 'Status: $status';
          statusColor = AppColors.onSurfaceVariant;
        }

        final String paymentTypeText =
            paymentType == 1 || paymentType == '1' ? 'Transfer' : 'Tunai';

        final isSelected = _selectedIds.contains(salaryId);

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
          color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
          child: InkWell(
            onTap: _isSelectionMode
                ? () => _toggleSelection(salaryId)
                : null,
            borderRadius: AppSpacing.borderRadiusMD,
            child: Padding(
              padding: AppSpacing.paddingMD,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_isSelectionMode)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          employeeName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.borderRadiusSM,
                        ),
                        child: Text(
                          statusText,
                          style: textTheme.labelMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapVerticalSM,
                  Row(
                    children: [
                      Icon(Icons.store, size: 16, color: AppColors.info),
                      AppSpacing.gapHorizontalSM,
                      Text(storeName, style: textTheme.bodySmall),
                      if (shiftStoreName.isNotEmpty) ...[
                        Text(' • ', style: textTheme.bodySmall),
                        Text(shiftStoreName, style: textTheme.bodySmall),
                      ],
                    ],
                  ),
                  AppSpacing.gapVerticalXS,
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: AppColors.info),
                      AppSpacing.gapHorizontalSM,
                      Text(date, style: textTheme.bodySmall),
                    ],
                  ),
                  AppSpacing.gapVerticalXS,
                  Row(
                    children: [
                      Icon(Icons.payment, size: 14, color: AppColors.info),
                      AppSpacing.gapHorizontalSM,
                      Text(paymentTypeText, style: textTheme.bodySmall),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: textTheme.bodyMedium),
                      Text(
                        currencyFormatter.format(amount),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
