import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory_anomaly_model.dart';
import '../models/store_model.dart';
import '../services/inventory_anomaly_service.dart';
import '../services/store_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class InventoryAnomalyPage extends StatefulWidget {
  const InventoryAnomalyPage({super.key});

  @override
  State<InventoryAnomalyPage> createState() => _InventoryAnomalyPageState();
}

class _InventoryAnomalyPageState extends State<InventoryAnomalyPage> {
  final InventoryAnomalyService _service = InventoryAnomalyService();
  final StoreService _storeService = StoreService();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  InventoryAnomalyResponse? _response;

  DateTime _dateFrom = DateTime.now().subtract(const Duration(days: 1));
  DateTime _dateTo = DateTime.now().subtract(const Duration(days: 1));

  List<StoreModel> _allStores = [];
  List<int>? _selectedStoreIds; // null = semua

  int _page = 1;
  final int _perPage = 50;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadStores();
    await _fetchComparison();
  }

  Future<void> _loadStores() async {
    try {
      _allStores = await _storeService.getStores();
    } catch (_) {
      // silent; store filter optional
    }
  }

  Future<void> _fetchComparison({bool loadMore = false}) async {
    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _error = null;
      }
    });

    try {
      final newPage = loadMore ? _page + 1 : 1;
      final res = await _service.getComparison(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        storeIds: _selectedStoreIds,
        page: newPage,
        perPage: _perPage,
      );

      setState(() {
        if (loadMore && _response != null) {
          _response = InventoryAnomalyResponse(
            period: res.period,
            summary: res.summary,
            items: [..._response!.items, ...res.items],
            meta: res.meta,
          );
          _page = newPage;
        } else {
          _response = res;
          _page = 1;
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<bool> _canAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final roles = prefs.getStringList('roles') ?? [];
    return roles.contains('admin') || roles.contains('super_admin');
  }

  String _fmt(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')} ${_monthShort(d.month)} ${d.year}";

  String _monthShort(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ][m];

  String get _dateLabel {
    if (_dateFrom == _dateTo) return _fmt(_dateFrom);
    return "${_fmt(_dateFrom)} – ${_fmt(_dateTo)}";
  }

  String get _storeLabel {
    if (_selectedStoreIds == null || _selectedStoreIds!.isEmpty) {
      return 'Semua store';
    }
    if (_selectedStoreIds!.length == 1) {
      final s = _allStores
          .where((st) => st.id == _selectedStoreIds!.first)
          .toList();
      return s.isEmpty ? '1 store' : s.first.nickname;
    }
    return '${_selectedStoreIds!.length} store';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perbandingan Penjualan vs Stok')),
      body: FutureBuilder<bool>(
        future: _canAccess(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!(snap.data ?? false)) {
            return const Center(
              child: Padding(
                padding: AppSpacing.paddingLG,
                child: Text('Anda tidak punya akses ke fitur ini.'),
              ),
            );
          }
          return _buildBody();
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _response == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _response == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            AppSpacing.gapVerticalMD,
            FilledButton(
              onPressed: () => _fetchComparison(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }
    final resp = _response;
    if (resp == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () => _fetchComparison(),
      child: ListView(
        children: [
          AppSpacing.gapVerticalSM,
          _buildFilterRow(),
          AppSpacing.gapVerticalMD,
          _buildSummaryRow(resp.summary),
          AppSpacing.gapVerticalMD,
          ...resp.items.map(_buildItemTile),
          if (resp.meta.hasMore)
            Padding(
              padding: AppSpacing.paddingMD,
              child: FilledButton.tonal(
                onPressed: _isLoadingMore ? null : () => _fetchComparison(loadMore: true),
                child: _isLoadingMore
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Muat lebih banyak'),
              ),
            ),
          if (resp.items.isEmpty)
            const Padding(
              padding: AppSpacing.paddingLG,
              child: Text(
                'Tidak ada data untuk periode ini.',
                textAlign: TextAlign.center,
              ),
            ),
          AppSpacing.gapVerticalLG,
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: AppSpacing.paddingSM,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ActionChip(
            label: Text(_dateLabel),
            avatar: const Icon(Icons.calendar_today, size: 16),
            onPressed: _showDateFilterSheet,
          ),
          ActionChip(
            label: Text(_storeLabel),
            avatar: const Icon(Icons.store, size: 16),
            onPressed: _showStoreFilterSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(InventoryAnomalySummary s) {
    Widget chip(String label, int value, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppSpacing.borderRadiusSM,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 16)),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      );
    }

    return Padding(
      padding: AppSpacing.paddingSM,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          chip('Cocok', s.matchCount, const Color(0xFF2E7D32)),
          chip('Selisih', s.mismatchCount, const Color(0xFFC62828)),
          chip('No SO', s.noSoDataCount, const Color(0xFF616161)),
          chip('No Stok', s.noStockDataCount, const Color(0xFFF9A825)),
          chip('Total', s.productsCompared, AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildItemTile(InventoryAnomalyItem it) {
    final outLabel = it.stockOut != null ? '${it.stockOut}' : '-';
    final deltaLabel = it.delta == null
        ? '-'
        : (it.delta! == 0 ? '0' : (it.delta! > 0 ? '+${it.delta}' : '${it.delta}'));
    final unitSuffix = (it.unit != null && it.unit!.isNotEmpty) ? ' (${it.unit})' : '';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: it.status.color.withValues(alpha: 0.15),
        child: Icon(Icons.circle, color: it.status.color, size: 14),
      ),
      title: Text(it.productName ?? 'Produk #${it.productId}'),
      subtitle: Text(
        '${it.soldQty} terjual • $outLabel keluar • Δ $deltaLabel$unitSuffix',
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: it.status.color.withValues(alpha: 0.1),
          borderRadius: AppSpacing.borderRadiusSM,
        ),
        child: Text(
          it.status.label,
          style: TextStyle(color: it.status.color, fontSize: 11),
        ),
      ),
    );
  }

  Future<void> _showDateFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Hari ini'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _dateFrom = DateTime.now();
                    _dateTo = DateTime.now();
                  });
                  _fetchComparison();
                },
              ),
              ListTile(
                title: const Text('Kemarin (default)'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    final y = DateTime.now().subtract(const Duration(days: 1));
                    _dateFrom = y;
                    _dateTo = y;
                  });
                  _fetchComparison();
                },
              ),
              ListTile(
                title: const Text('Pilih tanggal'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dateFrom,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _dateFrom = picked;
                      _dateTo = picked;
                    });
                    _fetchComparison();
                  }
                },
              ),
              ListTile(
                title: const Text('Range tanggal'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                    initialDateRange: DateTimeRange(start: _dateFrom, end: _dateTo),
                  );
                  if (picked != null) {
                    setState(() {
                      _dateFrom = picked.start;
                      _dateTo = picked.end;
                    });
                    _fetchComparison();
                  }
                },
              ),
              AppSpacing.gapVerticalSM,
            ],
          ),
        );
      },
    );
  }

  Future<void> _showStoreFilterSheet() async {
    final all = _selectedStoreIds == null;
    final checks = {
      for (final s in _allStores) s.id: all ? true : _selectedStoreIds!.contains(s.id),
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: AppSpacing.paddingMD,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pilih Store',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            setSheet(() {
                              final allChecked = checks.values.every((v) => v);
                              for (final k in checks.keys) {
                                checks[k] = !allChecked;
                              }
                            });
                          },
                          child: const Text('Toggle Semua'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: _allStores.map((s) {
                        return CheckboxListTile(
                          value: checks[s.id] ?? false,
                          title: Text(s.nickname),
                          onChanged: (v) {
                            setSheet(() {
                              checks[s.id] = v ?? false;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: AppSpacing.paddingMD,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final selected = checks.entries
                            .where((e) => e.value)
                            .map((e) => e.key)
                            .toList();
                        setState(() {
                          _selectedStoreIds =
                              selected.length == _allStores.length ? null : selected;
                        });
                        _fetchComparison();
                      },
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
