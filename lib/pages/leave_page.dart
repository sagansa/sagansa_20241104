import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leave_model.dart';
import '../services/leave_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/modern_fab.dart';
import 'leave_form_page.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  LeavePageState createState() => LeavePageState();
}

class LeavePageState extends State<LeavePage> {
  final LeaveService _leaveService = LeaveService();
  final ScrollController _scrollController = ScrollController();
  List<LeaveModel> _leaves = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isAdmin = false;
  String? _errorMessage;
  int _page = 1;
  bool _hasMore = true;
  String? _selectedStatus;

  final Map<String, String> _statusOptions = {
    '1': 'Pending',
    '2': 'Disetujui',
    '3': 'Ditolak',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUserRole();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      final userData = json.decode(userString);
      final roles = List<String>.from(userData['roles'] ?? []);
      setState(() {
        _isAdmin = roles.contains('admin') || roles.contains('super_admin');
      });
    }
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _page = 1;
      _hasMore = true;
    });

    try {
      if (_isAdmin) {
        final result = await _leaveService.getAdminLeaves(
          page: 1,
          status: _selectedStatus,
        );
        setState(() {
          _leaves = (result['data'] as List)
              .map((e) => LeaveModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _hasMore = _page < (result['meta']['last_page'] ?? 1);
          _isLoading = false;
        });
      } else {
        final result = await _leaveService.getLeavesPaged(page: _page);
        setState(() {
          _leaves = result['data'] as List<LeaveModel>;
          _hasMore = result['has_more'] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    setState(() => _isLoadingMore = true);

    try {
      if (_isAdmin) {
        final result = await _leaveService.getAdminLeaves(
          page: _page + 1,
          status: _selectedStatus,
        );
        setState(() {
          _leaves.addAll((result['data'] as List)
              .map((e) => LeaveModel.fromJson(e as Map<String, dynamic>))
              .toList());
          _page++;
          _hasMore = _page < (result['meta']['last_page'] ?? 1);
        });
      } else {
        final result = await _leaveService.getLeavesPaged(page: _page + 1);
        setState(() {
          _leaves.addAll(result['data'] as List<LeaveModel>);
          _page++;
          _hasMore = result['has_more'] as bool;
        });
      }
    } catch (_) {
      // ignore pagination errors, allow retry on next scroll
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Color _getStatusColor(dynamic status) {
    final s = status is int ? status : int.tryParse(status.toString()) ?? 0;
    switch (s) {
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.success;
      case 3:
        return AppColors.error;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  String _getStatusText(dynamic status) {
    final s = status is int ? status : int.tryParse(status.toString()) ?? 0;
    switch (s) {
      case 1:
        return 'Pending';
      case 2:
        return 'Disetujui';
      case 3:
        return 'Ditolak';
      default:
        return 'Unknown';
    }
  }

  String _getReasonText(dynamic reason) {
    final r = reason is int ? reason : int.tryParse(reason.toString()) ?? 0;
    switch (r) {
      case 1:
        return 'Cuti';
      case 2:
        return 'Izin';
      case 3:
        return 'Sakit';
      case 4:
        return 'Lainnya';
      default:
        return 'Lainnya';
    }
  }

  Future<void> _approveLeave(LeaveModel leave) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setujui Cuti'),
        content: Text('Setujui cuti dari ${leave.createdBy.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);
      await _leaveService.approveLeave(leave.id);
      await _loadLeaves();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuti berhasil disetujui'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(color: Colors.white)),
            backgroundColor: cs.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectLeave(LeaveModel leave) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Cuti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tolak cuti dari ${leave.createdBy.name}?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);
      await _leaveService.rejectLeave(
        leave.id,
        rejectNote: notesController.text.isNotEmpty ? notesController.text : null,
      );
      await _loadLeaves();
      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cuti berhasil ditolak', style: TextStyle(color: Colors.white)),
            backgroundColor: cs.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(color: Colors.white)),
            backgroundColor: cs.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuti & Izin'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaves,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter for admin
          if (_isAdmin) _buildFilterSection(),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : _leaves.isEmpty
                        ? _buildEmptyWidget()
                        : _buildListWidget(),
          ),
        ],
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index != 1) {
            Navigator.pop(context);
          }
        },
      ),
      floatingActionButton: CustomFAB(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LeaveFormPage()),
          );
          if (result == true) {
            _loadLeaves();
          }
        },
        icon: Icons.event_busy,
        tooltip: 'Tambah Cuti',
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
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 20, color: colorScheme.primary),
          AppSpacing.gapHorizontalSM,
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusSM,
                ),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Semua'),
                ),
                ..._statusOptions.entries.map((entry) =>
                    DropdownMenuItem<String?>(
                      value: entry.key,
                      child: Text(entry.value),
                    )),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
                _loadLeaves();
              },
            ),
          ),
          if (_selectedStatus != null) ...[
            AppSpacing.gapHorizontalSM,
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                setState(() => _selectedStatus = null);
                _loadLeaves();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    final colorScheme = Theme.of(context).colorScheme;

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
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            AppSpacing.gapVerticalLG,
            ElevatedButton(
              onPressed: _loadLeaves,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: colorScheme.outline),
          AppSpacing.gapVerticalMD,
          Text('Belum ada data cuti.', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildListWidget() {
    return RefreshIndicator(
      onRefresh: _loadLeaves,
      child: ListView.builder(
        controller: _scrollController,
        padding: AppSpacing.paddingMD,
        itemCount: _leaves.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _leaves.length) {
            return _isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }
          final leave = _leaves[index];
          return _buildLeaveCard(leave);
        },
      ),
    );
  }

  String _formatDate(dynamic dateOrStr) {
    if (dateOrStr == null) return '-';
    DateTime date;
    if (dateOrStr is DateTime) {
      date = dateOrStr;
    } else {
      final str = dateOrStr.toString();
      if (str.isEmpty) return '-';
      try {
        date = DateTime.parse(str);
      } catch (_) {
        return str;
      }
    }
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  Widget _buildLeaveCard(LeaveModel leave) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final employeeName = leave.createdBy.name;
    final status = leave.status;
    final fromDate = _formatDate(leave.fromDate);
    final untilDate = _formatDate(leave.untilDate);
    final reason = leave.reason;
    final notes = leave.notes;
    final isPending = status == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_isAdmin)
                  Expanded(
                    child: Text(
                      employeeName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      _getReasonText(reason),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusLG,
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalSM,
            if (_isAdmin) ...[
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: colorScheme.onSurfaceVariant),
                  AppSpacing.gapHorizontalSM,
                  Text(
                    _getReasonText(reason),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              AppSpacing.gapVerticalXS,
            ],
            Row(
              children: [
                Icon(Icons.date_range, size: 16, color: colorScheme.onSurfaceVariant),
                AppSpacing.gapHorizontalSM,
                Expanded(
                  child: Text(
                    '$fromDate - $untilDate',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (notes != null && notes.toString().isNotEmpty) ...[
              AppSpacing.gapVerticalSM,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 16, color: colorScheme.onSurfaceVariant),
                  AppSpacing.gapHorizontalSM,
                  Expanded(
                    child: Text(
                      notes.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // Admin actions for pending leaves
            if (_isAdmin && isPending) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectLeave(leave),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                    ),
                  ),
                  AppSpacing.gapHorizontalSM,
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _approveLeave(leave),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Setujui'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
