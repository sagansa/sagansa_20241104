import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/utility_model.dart';
import '../services/utility_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/filter_app_bar_action.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/status_badge.dart';

class UtilityListPage extends StatefulWidget {
  const UtilityListPage({super.key});

  @override
  State<UtilityListPage> createState() => _UtilityListPageState();
}

class _UtilityListPageState extends State<UtilityListPage> {
  final UtilityService _service = UtilityService();

  List<UtilityModel> _items = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  // Filters
  int? _selectedStoreId;
  int? _selectedCategory;
  List<Map<String, dynamic>> _stores = [];

  List<Map<String, dynamic>> get _filteredCategories => const [
        {'id': 1, 'label': 'Listrik'},
        {'id': 2, 'label': 'Air'},
        {'id': 3, 'label': 'Internet'},
      ];

  bool get _hasActiveFilters =>
      _selectedStoreId != null || _selectedCategory != null;

  int get _activeFilterCount {
    int count = 0;
    if (_selectedStoreId != null) count++;
    if (_selectedCategory != null) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _loadStores();
    _fetch();
  }

  Future<void> _loadStores() async {
    try {
      final stores = await _service.getStores();
      if (!mounted) return;
      setState(() => _stores = stores);
    } catch (_) {}
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final items = await _service.getUtilities(storeId: _selectedStoreId);
      if (!mounted) return;
      setState(() {
        _items = items;
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

  List<UtilityModel> get _filteredItems {
    if (_selectedCategory == null) return _items;
    return _items
        .where((u) => u.category == _selectedCategory)
        .toList();
  }

  void _clearFilters() {
    setState(() {
      _selectedStoreId = null;
      _selectedCategory = null;
    });
    _fetch();
  }

  void _openFilterSheet() {
    FilterBottomSheet.show(
      context,
      title: 'Filter Utility',
      fields: [
        DropdownFilterField<int>(
          label: 'Toko',
          value: _selectedStoreId,
          options: _stores
              .map((s) => (
                    s['id'] is int
                        ? s['id'] as int
                        : int.parse(s['id'].toString()),
                    s['nickname']?.toString() ?? 'Toko #${s['id']}',
                  ))
              .toList(),
        ),
        DropdownFilterField<int>(
          label: 'Jenis Utility',
          value: _selectedCategory,
          options: _filteredCategories
              .map((c) => (c['id'] as int, c['label'] as String))
              .toList(),
        ),
      ],
      onApply: (values) {
        setState(() {
          _selectedStoreId = values['Toko'] as int?;
          _selectedCategory = values['Jenis Utility'] as int?;
        });
        _fetch();
      },
      onReset: () {
        _clearFilters();
      },
    );
  }

  void _copyNumber(String? number) {
    if (number == null || number.isEmpty) return;
    Clipboard.setData(ClipboardData(text: number));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nomor "$number" disalin ke clipboard.')),
    );
  }

  StatusType _statusType(int? status) {
    return status == 1 ? StatusType.success : StatusType.neutral;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utility'),
        actions: [
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              onPressed: _clearFilters,
              tooltip: 'Hapus Filter',
            ),
          FilterAppBarAction(
            activeCount: _activeFilterCount,
            onTap: _openFilterSheet,
          ),
        ],
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 2, // Ops tab
        onTap: (index) {},
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildError()
                    : !_hasLoaded
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredItems.isEmpty
                            ? _buildEmpty()
                            : _buildList(colorScheme, textTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildList(ColorScheme colorScheme, TextTheme textTheme) {
    final items = _filteredItems;
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: items.length,
        itemBuilder: (context, idx) => _buildCard(
          items[idx],
          colorScheme,
          textTheme,
        ),
      ),
    );
  }

  Widget _buildCard(
      UtilityModel item, ColorScheme colorScheme, TextTheme textTheme) {
    final statusType = _statusType(item.status);
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
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _copyNumber(item.number),
                    child: Row(
                      children: [
                        Icon(Icons.numbers_rounded,
                            size: 16, color: colorScheme.primary),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            item.number ?? '-',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(Icons.copy_rounded,
                            size: 14, color: colorScheme.onSurfaceVariant),
                      ],
                    ),
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
            Text(
              item.displayName,
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (item.storeNickname != null)
                  _Chip(
                    icon: Icons.store_rounded,
                    label: item.storeNickname!,
                  ),
                if (item.utilityProviderName != null)
                  _Chip(
                    icon: Icons.cable_rounded,
                    label: item.utilityProviderName!,
                  ),
                if (item.unit != null)
                  _Chip(
                    icon: Icons.straighten_rounded,
                    label: item.unit!,
                  ),
                _Chip(
                  label: item.categoryLabel,
                  color: colorScheme.primaryContainer,
                  textColor: colorScheme.primary,
                ),
                if (item.prePost != null)
                  _Chip(
                    label: item.prePostLabel,
                    color: AppColors.info.withValues(alpha: 0.12),
                    textColor: AppColors.info,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            AppSpacing.gapVerticalMD,
            Text(_errorMessage!, textAlign: TextAlign.center),
            AppSpacing.gapVerticalMD,
            ElevatedButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.electrical_services_rounded, size: 48),
            AppSpacing.gapVerticalMD,
            Text('Belum ada data utility.'),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color? color;
  final Color? textColor;

  const _Chip({
    this.icon,
    required this.label,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.borderRadiusSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor ?? colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor ?? colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
