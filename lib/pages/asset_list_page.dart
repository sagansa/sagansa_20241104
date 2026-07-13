import 'package:flutter/material.dart';
import '../controllers/asset_controller.dart';
import '../models/asset_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'asset_detail_page.dart';

/// Daftar semua aset dengan search & filter status/due.
class AssetListPage extends StatefulWidget {
  const AssetListPage({super.key, this.initialDue});

  /// Bila diisi ('today'/'overdue'/'week'), halaman langsung memfilter itu.
  final String? initialDue;

  @override
  State<AssetListPage> createState() => _AssetListPageState();
}

class _AssetListPageState extends State<AssetListPage> {
  late AssetController _controller;
  List<AssetModel> _assets = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _dueFilter;
  int? _statusFilter; // 1=aktif, 2=dipelihara, 3=non-aktif

  @override
  void initState() {
    super.initState();
    _controller = AssetController(context);
    _dueFilter = widget.initialDue;
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _controller.loadAssets(
        due: _dueFilter,
        status: _statusFilter,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _assets = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Debounce sederhana untuk pencarian.
  void _onSearchChanged(String v) {
    _searchQuery = v;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_searchQuery == v) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_dueFilter == 'today'
            ? 'Tugas Check Hari Ini'
            : _dueFilter == 'overdue'
                ? 'Aset Terlambat'
                : 'Daftar Aset'),
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari nama / kode aset...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _onSearchChanged,
                ),
                AppSpacing.gapVerticalSM,
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'Semua',
                        selected: _dueFilter == null,
                        colorScheme: colorScheme,
                        onTap: () {
                          setState(() => _dueFilter = null);
                          _load();
                        },
                      ),
                      _FilterChip(
                        label: 'Hari Ini',
                        selected: _dueFilter == 'today',
                        colorScheme: colorScheme,
                        onTap: () {
                          setState(() => _dueFilter = 'today');
                          _load();
                        },
                      ),
                      _FilterChip(
                        label: 'Terlambat',
                        selected: _dueFilter == 'overdue',
                        colorScheme: colorScheme,
                        onTap: () {
                          setState(() => _dueFilter = 'overdue');
                          _load();
                        },
                      ),
                      _FilterChip(
                        label: 'Minggu Ini',
                        selected: _dueFilter == 'week',
                        colorScheme: colorScheme,
                        onTap: () {
                          setState(() => _dueFilter = 'week');
                          _load();
                        },
                      ),
                      _FilterChip(
                        label: 'Aktif',
                        selected: _statusFilter == 1,
                        colorScheme: colorScheme,
                        onTap: () {
                          setState(() => _statusFilter =
                              _statusFilter == 1 ? null : 1);
                          _load();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!,
                                textAlign: TextAlign.center),
                            SizedBox(height: AppSpacing.sectionGap),
                            ElevatedButton(
                                onPressed: _load, child: const Text('Coba Lagi')),
                          ],
                        ),
                      )
                    : _assets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha:0.5)),
                                AppSpacing.gapVerticalSM,
                                Text('Tidak ada aset.',
                                    style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: AppSpacing.screenPadding,
                              itemCount: _assets.length,
                              itemBuilder: (context, i) {
                                final a = _assets[i];
                                return _AssetRow(
                                  asset: a,
                                  theme: theme,
                                  colorScheme: colorScheme,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AssetDetailPage(assetId: a.id),
                                      ),
                                    );
                                    _load();
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: colorScheme.primary,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha:0.5),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXL,
        ),
        checkmarkColor: colorScheme.primary,
        showCheckmark: false,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.asset,
    required this.theme,
    required this.colorScheme,
    required this.onTap,
  });

  final AssetModel asset;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  Color _dueColor() {
    switch (asset.dueStatus) {
      case 'overdue':
        return AppColors.error;
      case 'today':
        return AppColors.warning;
      case 'upcoming':
        return AppColors.info;
      default:
        return AppColors.success;
    }
  }

  String _dueLabel() {
    switch (asset.dueStatus) {
      case 'overdue':
        return 'Terlambat';
      case 'today':
        return 'Hari Ini';
      case 'upcoming':
        return 'Segera';
      default:
        return 'OK';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.itemGap),
      child: ListTile(
        onTap: onTap,
        contentPadding: AppSpacing.listItemPadding,
        leading: CircleAvatar(
          backgroundColor: _dueColor().withValues(alpha:0.15),
          child: Icon(Icons.inventory_2, color: _dueColor(), size: 20),
        ),
        title: Text(
          asset.name,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${asset.code} • ${asset.assetCategoryName ?? '-'}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: _dueColor().withValues(alpha:0.15),
            borderRadius: AppSpacing.borderRadiusMD,
          ),
          child: Text(
            _dueLabel(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: _dueColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
