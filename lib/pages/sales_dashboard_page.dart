import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sales_dashboard_model.dart';
import '../services/sales_dashboard_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SalesDashboardPage extends StatefulWidget {
  const SalesDashboardPage({super.key});

  @override
  State<SalesDashboardPage> createState() => _SalesDashboardPageState();
}

class _SalesDashboardPageState extends State<SalesDashboardPage> {
  SalesPeriode _periode = SalesPeriode.today;
  bool _accessChecked = false;
  bool _canAccess = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    bool ok = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = json.decode(userString) as Map<String, dynamic>;
        final roles = List<String>.from(userData['roles'] ?? []);
        ok = roles.contains('admin') || roles.contains('super_admin');
      }
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _canAccess = ok;
      _accessChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    if (!_accessChecked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard Penjualan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!_canAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard Penjualan')),
        body: const Center(
          child: Padding(
            padding: AppSpacing.paddingLG,
            child: Text('Anda tidak punya akses ke fitur ini.'),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Penjualan'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Ringkasan'),
              Tab(text: 'Produk'),
              Tab(text: 'Channel'),
            ],
            labelColor: cs.onSurface,
            indicatorColor: AppColors.primary,
          ),
        ),
        body: Column(
          children: [
            _buildPeriodeRow(),
            Expanded(
              child: TabBarView(
                children: [
                  _SummaryTab(key: ValueKey('summary-${_periode.apiValue}'), periode: _periode),
                  _ProductsTab(key: ValueKey('products-${_periode.apiValue}'), periode: _periode),
                  _PlaceholderTab(text: 'Channel — diisi di Task 14'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodeRow() {
    return Container(
      padding: AppSpacing.paddingSM,
      color: AppColors.surfaceVariant,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: SalesPeriode.values.map((p) {
          final selected = p == _periode;
          return ChoiceChip(
            label: Text(p.label),
            selected: selected,
            onSelected: (_) {
              setState(() => _periode = p);
            },
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: selected ? AppColors.onPrimary : AppColors.onSurface,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String text;
  const _PlaceholderTab({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

class _SummaryTab extends StatefulWidget {
  final SalesPeriode periode;
  const _SummaryTab({super.key, required this.periode});

  @override
  State<_SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<_SummaryTab> {
  final SalesDashboardService _service = SalesDashboardService();
  SalesSummary? _summary;
  List<SalesTrendPoint> _trend = [];
  bool _loadingSummary = false;
  bool _loadingTrend = false;
  String? _errorSummary;
  String? _errorTrend;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadTrend();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loadingSummary = true;
      _errorSummary = null;
    });
    try {
      final s = await _service.getSummary(widget.periode);
      if (!mounted) return;
      setState(() {
        _summary = s;
        _loadingSummary = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorSummary = e.toString().replaceFirst('Exception: ', '');
        _loadingSummary = false;
      });
    }
  }

  Future<void> _loadTrend() async {
    setState(() {
      _loadingTrend = true;
      _errorTrend = null;
    });
    try {
      final t = await _service.getTrend(widget.periode);
      if (!mounted) return;
      setState(() {
        _trend = t;
        _loadingTrend = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorTrend = e.toString().replaceFirst('Exception: ', '');
        _loadingTrend = false;
      });
    }
  }

  String _fmtRupiah(int value) {
    if (value >= 1000000000) return 'Rp ${(value / 1000000000).toStringAsFixed(1)}M';
    if (value >= 1000000) return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
    if (value >= 1000) return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    return 'Rp $value';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.paddingMD,
      children: [
        _buildKpiRow(),
        AppSpacing.gapVerticalMD,
        _buildChart(),
        AppSpacing.gapVerticalLG,
      ],
    );
  }

  Widget _buildKpiRow() {
    if (_loadingSummary) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorSummary != null) {
      return _retryCard(_errorSummary!, _loadSummary);
    }
    final s = _summary;
    if (s == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.periodeLabel, style: Theme.of(context).textTheme.bodySmall),
        AppSpacing.gapVerticalSM,
        Row(
          children: [
            Expanded(child: _kpiCard('Omzet', _fmtRupiah(s.omzet))),
            AppSpacing.gapHorizontalSM,
            Expanded(child: _kpiCard('Order', '${s.orderCount}')),
            AppSpacing.gapHorizontalSM,
            Expanded(child: _kpiCard('Qty', '${s.totalQty}')),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String label, String value) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMD,
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_loadingTrend) {
      return const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator()));
    }
    if (_errorTrend != null) {
      return SizedBox(height: 200, child: _retryCard(_errorTrend!, _loadTrend));
    }
    if (_trend.isEmpty) {
      return const SizedBox(
          height: 200, child: Center(child: Text('Tidak ada data trend.')));
    }

    final spots = <FlSpot>[];
    double maxY = 0;
    for (var i = 0; i < _trend.length; i++) {
      final v = _trend[i].omzet.toDouble();
      spots.add(FlSpot(i.toDouble(), v));
      if (v > maxY) maxY = v;
    }

    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMD,
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tren Omzet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY == 0 ? 1 : maxY * 1.1,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((ts) {
                        final idx = ts.spotIndex;
                        final point = _trend[idx];
                        return LineTooltipItem(
                          '${point.label}\n${_fmtRupiah(point.omzet)}',
                          const TextStyle(fontSize: 11),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.secondary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.secondary.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _retryCard(String msg, VoidCallback onRetry) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          children: [
            Text(msg, textAlign: TextAlign.center),
            AppSpacing.gapVerticalSM,
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}

class _ProductsTab extends StatefulWidget {
  final SalesPeriode periode;
  const _ProductsTab({super.key, required this.periode});

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  final SalesDashboardService _service = SalesDashboardService();
  List<SalesProductItem> _items = [];
  SalesProductMeta? _meta;
  ProductSort _sort = ProductSort.qty;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  final int _perPage = 50;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      _page = 1;
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final page = reset ? 1 : _page + 1;
      final result = await _service.getProducts(
        widget.periode,
        page: page,
        perPage: _perPage,
        sort: _sort,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items = result.items;
        } else {
          _items = [..._items, ...result.items];
          _page = page;
        }
        _meta = result.meta;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  String _fmtRupiah(int value) {
    if (value >= 1000000) return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
    if (value >= 1000) return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    return 'Rp $value';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            AppSpacing.gapVerticalMD,
            FilledButton(
              onPressed: () => _load(reset: true),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSortToggle(),
        Expanded(
          child: _items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: AppSpacing.paddingLG,
                    child: Text('Tidak ada produk terjual di periode ini.'),
                  ),
                )
              : ListView.builder(
                  itemCount: _items.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == _items.length) return _buildLoadMoreRow();
                    return _buildItemTile(_items[i], i);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSortToggle() {
    return Padding(
      padding: AppSpacing.paddingSM,
      child: Row(
        children: [
          const Text('Urutkan: ', style: TextStyle(fontSize: 12)),
          ChoiceChip(
            label: const Text('Qty ↓'),
            selected: _sort == ProductSort.qty,
            onSelected: (_) {
              setState(() => _sort = ProductSort.qty);
              _load(reset: true);
            },
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: const Text('Omzet ↓'),
            selected: _sort == ProductSort.revenue,
            onSelected: (_) {
              setState(() => _sort = ProductSort.revenue);
              _load(reset: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(SalesProductItem item, int index) {
    final isTop3 = index < 3;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isTop3 ? AppColors.secondary : AppColors.surfaceVariant,
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: isTop3 ? Colors.white : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(item.productName ?? 'Produk #${item.productId}'),
      subtitle: Text(
        '${_fmtRupiah(item.revenue)}${item.unit != null ? ' · ${item.unit}' : ''}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLoadMoreRow() {
    if (_meta == null || !_meta!.hasMore) return const SizedBox.shrink();
    return Padding(
      padding: AppSpacing.paddingMD,
      child: FilledButton.tonal(
        onPressed: _isLoadingMore ? null : () => _load(reset: false),
        child: _isLoadingMore
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text('Muat lebih banyak (${_meta!.currentPage + 1}/${_meta!.lastPage})'),
      ),
    );
  }
}
