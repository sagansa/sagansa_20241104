import 'package:flutter/material.dart';

import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/modern_dropdown.dart';
import 'admin_profile_detail_page.dart';

class AdminProfileListPage extends StatefulWidget {
  const AdminProfileListPage({super.key});

  @override
  State<AdminProfileListPage> createState() => _AdminProfileListPageState();
}

class _AdminProfileListPageState extends State<AdminProfileListPage> {
  final UserService _userService = UserService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _statusFilter;

  int _currentPage = 1;
  int _lastPage = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadData({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
      });
    }
    try {
      final result = await _userService.getAdminProfiles(
        page: _currentPage,
        status: _statusFilter,
      );
      if (!mounted) return;
      final data = List<Map<String, dynamic>>.from(result['data']);
      final pagination = result['pagination'] as Map<String, dynamic>;
      setState(() {
        if (reset) {
          _items = data;
        } else {
          _items.addAll(data);
        }
        _lastPage = pagination['last_page'] ?? 1;
        _hasMore = _currentPage < _lastPage;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _loadData();
  }

  Color _statusColor(String? status, ColorScheme cs) {
    switch (status) {
      case 'submitted':
        return AppColors.info;
      case 'accepted':
        return AppColors.success;
      case 'reviewed':
        return AppColors.warning;
      case 'rejected':
        return cs.error;
      default:
        return cs.outline;
    }
  }

  String _statusText(String? status) {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'accepted':
        return 'Diterima';
      case 'reviewed':
        return 'Direview';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Draft';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(reset: true),
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: AppSpacing.paddingMD,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: ModernDropdown<String?>(
              value: _statusFilter,
              labelText: 'Filter Status',
              hint: 'Semua Status',
              prefixIcon: const Icon(Icons.filter_alt_outlined, size: 20),
              items: const [null, 'draft', 'submitted', 'accepted', 'reviewed', 'rejected'],
              getLabel: (v) {
                switch (v) {
                  case 'draft': return 'Draft';
                  case 'submitted': return 'Submitted';
                  case 'accepted': return 'Diterima';
                  case 'reviewed': return 'Direview';
                  case 'rejected': return 'Ditolak';
                  default: return 'Semua Status';
                }
              },
              onChanged: (v) {
                setState(() => _statusFilter = v);
                _loadData(reset: true);
              },
            ),
          ),
          Expanded(
            child: _buildBody(colorScheme, textTheme),
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
                onPressed: () => _loadData(reset: true),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Belum ada data profil.'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: AppSpacing.paddingMD,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final item = _items[index];
        final bool locked = item['locked'] == true;
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AdminProfileDetailPage(profileId: item['id']),
                ),
              ).then((_) => _loadData(reset: true));
            },
            child: Padding(
              padding: AppSpacing.paddingMD,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name']?.toString() ?? '-',
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        AppSpacing.gapVerticalXS,
                        Text(
                          item['email']?.toString() ?? '-',
                          style: textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: _statusColor(item['status'], colorScheme)
                          .withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusMD,
                    ),
                    child: Text(
                      _statusText(item['status']),
                      style: textTheme.labelMedium?.copyWith(
                        color: _statusColor(item['status'], colorScheme),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  AppSpacing.gapHorizontalSM,
                  Icon(
                    locked ? Icons.lock : Icons.lock_open,
                    size: 18,
                    color: locked
                        ? colorScheme.error
                        : AppColors.info,
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
