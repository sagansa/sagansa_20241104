import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/utility_usage_model.dart';
import '../services/utility_usage_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/add_fab.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state.dart';
import '../widgets/modern_bottom_nav.dart';
import 'utility_usage_detail_page.dart';
import 'utility_usage_form_page.dart';

class UtilityUsageListPage extends StatefulWidget {
  const UtilityUsageListPage({super.key});

  @override
  State<UtilityUsageListPage> createState() => _UtilityUsageListPageState();
}

class _UtilityUsageListPageState extends State<UtilityUsageListPage> {
  final UtilityUsageService _service = UtilityUsageService();
  final ScrollController _scrollController = ScrollController();

  List<UtilityUsageModel> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  bool _hasLoaded = false;
  bool _canManage = false;
  String? _errorMessage;

  // Filters - hierarchical: Store -> Category -> Utility
  int? _selectedStoreId;
  int? _selectedCategory;
  int? _selectedUtilityId;
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _utilities = [];

  // Helper getters for hierarchical filtering
  List<Map<String, dynamic>> get _filteredUtilities {
    if (_selectedStoreId == null && _selectedCategory == null) {
      return _utilities;
    }
    return _utilities.where((u) {
      final matchStore = _selectedStoreId == null || u['store_id'] == _selectedStoreId;
      final matchCategory = _selectedCategory == null || u['category'] == _selectedCategory;
      return matchStore && matchCategory;
    }).toList();
  }

  // Fixed, manual category options (independent of store)
  List<Map<String, dynamic>> get _filteredCategories => const [
        {'id': 1, 'label': 'Listrik'},
        {'id': 2, 'label': 'Air'},
        {'id': 3, 'label': 'Internet'},
      ];

  bool get _hasActiveFilters => _selectedStoreId != null || _selectedCategory != null || _selectedUtilityId != null;

  @override
  void initState() {
    super.initState();
    _canManage = context.read<AuthProvider>().hasAnyRole(['admin', 'super_admin', 'supervisor', 'staff']);
    _loadFilterData();
    _fetch();
    _scrollController.addListener(_onScroll);
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
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final result = await _service.getUtilityUsagesPaged(
        page: _page + 1,
        storeId: _selectedStoreId,
        category: _selectedCategory,
        utilityId: _selectedUtilityId,
      );
      if (!mounted) return;
      setState(() {
        _page++;
        _items.addAll(result['data'] as List<UtilityUsageModel>);
        _hasMore = result['has_more'] as bool;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadFilterData() async {
    try {
      final results = await Future.wait([
        _service.getStores(),
        _service.getUtilities(),
      ]);
      if (!mounted) return;
      setState(() {
        _stores = results[0];
        _utilities = results[1];
      });
    } catch (_) {}
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _page = 1;
      _items = [];
      _hasMore = true;
    });
    try {
      final result = await _service.getUtilityUsagesPaged(
        page: _page,
        storeId: _selectedStoreId,
        category: _selectedCategory,
        utilityId: _selectedUtilityId,
      );
      if (!mounted) return;
      setState(() {
        _items = result['data'] as List<UtilityUsageModel>;
        _hasMore = result['has_more'] as bool;
        _isLoading = false;
        _hasLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _hasLoaded = true;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStoreId = null;
      _selectedCategory = null;
      _selectedUtilityId = null;
    });
    _fetch();
  }

  StatusType _statusType(int status) {
    switch (status) {
      case 2:
        return StatusType.success;
      case 3:
        return StatusType.neutral;
      case 4:
        return StatusType.error;
      default:
        return StatusType.warning;
    }
  }

  void _openDetail(UtilityUsageModel item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => UtilityUsageDetailPage(usageId: item.id)),
    );
    if (result == true) _fetch();
  }

  void _openForm({UtilityUsageModel? item}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UtilityUsageFormPage(usage: item)),
    );
    if (result == true) _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemakaian Utility'),
        actions: [
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              onPressed: _clearFilters,
              tooltip: 'Hapus Filter',
            ),
        ],
      ),
      floatingActionButton: _canManage
          ? AddFab(onPressed: () => _openForm())
          : null,
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 2, // Ops tab
        onTap: (index) {},
      ),
      body: Column(
        children: [
          _buildFilters(colorScheme, textTheme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildError()
                    : !_hasLoaded
                        ? const Center(child: CircularProgressIndicator())
                        : _items.isEmpty
                            ? _buildEmpty(colorScheme)
                            : _buildList(colorScheme, textTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Store dropdown
          DropdownButtonFormField<int>(
            value: _selectedStoreId,
            isExpanded: true,
            hint: Row(
              children: [
                Icon(Icons.store_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text('Semua Toko', overflow: TextOverflow.ellipsis)),
              ],
            ),
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            items: _stores.map((s) {
              final sid = s['id'] is int ? s['id'] : int.tryParse(s['id']?.toString() ?? '');
              return DropdownMenuItem<int>(
                value: sid,
                child: Text(s['nickname']?.toString() ?? 'Toko #${s['id']}', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedStoreId = val;
                // Reset dependent filters
                if (val != null && _selectedCategory != null) {
                  final validCats = _filteredCategories.map((c) => c['id'] as int).toList();
                  if (!validCats.contains(_selectedCategory)) _selectedCategory = null;
                }
                if (val != null && _selectedUtilityId != null) {
                  final validUtils = _filteredUtilities.map((u) => u['id'] is int ? u['id'] : int.tryParse(u['id']?.toString() ?? '')).whereType<int>().toList();
                  if (!validUtils.contains(_selectedUtilityId)) _selectedUtilityId = null;
                }
              });
              _fetch();
            },
          ),
          const SizedBox(height: 10),

          // Row 2: Category dropdown (dependent on Store)
          DropdownButtonFormField<int>(
            value: _selectedCategory,
            isExpanded: true,
            hint: Row(
              children: [
                Icon(Icons.category_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text('Semua Jenis', overflow: TextOverflow.ellipsis)),
              ],
            ),
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            items: _filteredCategories.map((c) {
              return DropdownMenuItem<int>(
                value: c['id'] as int,
                child: Text(c['label'] as String, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedCategory = val;
                if (val != null && _selectedUtilityId != null) {
                  final validUtils = _filteredUtilities.map((u) => u['id'] is int ? u['id'] : int.tryParse(u['id']?.toString() ?? '')).whereType<int>().toList();
                  if (!validUtils.contains(_selectedUtilityId)) _selectedUtilityId = null;
                }
              });
              _fetch();
            },
          ),
          const SizedBox(height: 10),

          // Row 3: Utility dropdown (dependent on Store & Category)
          DropdownButtonFormField<int>(
            value: _selectedUtilityId,
            isExpanded: true,
            hint: Row(
              children: [
                Icon(Icons.electrical_services_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text('Semua Utility', overflow: TextOverflow.ellipsis)),
              ],
            ),
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            items: _filteredUtilities.map((u) {
              final uid = u['id'] is int ? u['id'] : int.tryParse(u['id']?.toString() ?? '');
              return DropdownMenuItem<int>(
                value: uid,
                child: Text(
                  u['utility_name']?.toString() ?? 'Utility #${u['id']}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (_selectedStoreId == null && _selectedCategory == null)
                ? null
                : (val) {
                    setState(() => _selectedUtilityId = val);
                    _fetch();
                  },
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (_selectedStoreId != null)
                  _buildFilterChip(
                    'Toko: ${_stores.where((s) => s['id'] == _selectedStoreId).firstOrNull?['nickname'] ?? ''}',
                    () => setState(() {
                      _selectedStoreId = null;
                      _selectedCategory = null;
                      _selectedUtilityId = null;
                    }),
                    colorScheme,
                  ),
                if (_selectedCategory != null)
                  _buildFilterChip(
                    'Jenis: ${_categoryLabel(_selectedCategory!)}',
                    () => setState(() {
                      _selectedCategory = null;
                      _selectedUtilityId = null;
                    }),
                    colorScheme,
                  ),
                if (_selectedUtilityId != null)
                  _buildFilterChip(
                    'Utility: ${_utilities.where((u) => u['id'] == _selectedUtilityId).firstOrNull?['utility_name'] ?? ''}',
                    () => setState(() => _selectedUtilityId = null),
                    colorScheme,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete, ColorScheme colorScheme) {
    return InputChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onDeleted: onDelete,
      deleteIconColor: colorScheme.onSurfaceVariant,
      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      labelStyle: TextStyle(color: colorScheme.primary, fontSize: 12),
      deleteIcon: const Icon(Icons.close, size: 16),
      visualDensity: VisualDensity.compact,
    );
  }

  String _categoryLabel(int category) {
    switch (category) {
      case 1:
        return 'Listrik';
      case 2:
        return 'Air';
      case 3:
        return 'Internet';
      default:
        return 'Unknown';
    }
  }

  Widget _buildList(ColorScheme colorScheme, TextTheme textTheme) {
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, idx) {
          if (idx == _items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildCard(_items[idx], colorScheme, textTheme);
        },
      ),
    );
  }

  Widget _buildCard(
      UtilityUsageModel item, ColorScheme colorScheme, TextTheme textTheme) {
    final statusType = _statusType(item.status);
    final resultText = item.unitName != null
        ? '${_formatNumber(item.result)} ${item.unitName}'
        : _formatNumber(item.result);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLG,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: AppSpacing.borderRadiusLG,
        onTap: () => _openDetail(item),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.borderRadiusSM,
                  color: colorScheme.primaryContainer,
                ),
                child: Icon(
                  Icons.electrical_services_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.utilityDisplayName,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatusBadge(
                          label: item.statusText,
                          type: statusType,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(Icons.speed_rounded,
                            size: 13,
                            color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          resultText,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.createdAt != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(Icons.calendar_today_rounded,
                              size: 13,
                              color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              _formatDate(item.createdAt!),
                              style: textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (item.storeNickname != null) ...[
                      Row(
                        children: [
                          Icon(Icons.store_rounded,
                              size: 11,
                              color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            item.storeNickname!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(String value) {
    try {
      final num = double.parse(value);
      if (num == num.roundToDouble()) {
        return num.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
      }
      return num.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
    } catch (_) {
      return value;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildError() {
    return EmptyState(
      icon: Icons.error_outline_rounded,
      title: _errorMessage!,
      subtitle: 'Terjadi kesalahan saat memuat data',
      action: ElevatedButton.icon(
        onPressed: _fetch,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Coba Lagi'),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    return EmptyState(
      icon: Icons.electrical_services_rounded,
      title: 'Belum ada data pemakaian utility.',
    );
  }
}