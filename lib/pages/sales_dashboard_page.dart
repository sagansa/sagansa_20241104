import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sales_dashboard_model.dart';
import '../services/sales_dashboard_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/format_utils.dart';
import '../widgets/modern_bottom_nav.dart';

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
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
            indicator: BoxDecoration(color: Colors.transparent),
            dividerColor: Colors.transparent,
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
                  _ChannelsTab(key: ValueKey('channels-${_periode.apiValue}'), periode: _periode),
                ],
              ),
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
      ),
    );
  }

  Widget _buildPeriodeRow() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingSM,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
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
            labelStyle: TextStyle(
              color: selected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
            ),
          );
        }).toList(),
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
  int? _compareYear;
  String _metric = 'omzet'; // 'omzet' | 'order' | 'qty'

  @override
  void initState() {
    super.initState();
    _compareYear = DateTime.now().year - 1; // default: tahun lalu
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
      final t = await _service.getTrend(widget.periode,
          compareYear: _compareYear, metric: _metric);
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

  Future<void> _changeCompareYear(int? year) async {
    setState(() => _compareYear = year);
    await _loadTrend();
  }

  Future<void> _changeMetric(String m) async {
    if (m == _metric || _loadingTrend) return;
    setState(() => _metric = m);
    await _loadTrend();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.paddingMD,
      children: [
        _buildKpiRow(),
        AppSpacing.gapVerticalMD,
        _buildCompareChip(),
        AppSpacing.gapVerticalSM,
        _buildChart(),
        AppSpacing.gapVerticalLG,
      ],
    );
  }

  Widget _buildCompareChip() {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        ActionChip(
          label: Text(_compareYear == null
              ? 'Bandingkan: —'
              : 'Bandingkan: $_compareYear'),
          avatar: const Icon(Icons.compare_arrows, size: 16),
          onPressed: _showCompareYearSheet,
          backgroundColor: cs.surfaceContainerHighest,
        ),
      ],
    );
  }

  Future<void> _showCompareYearSheet() async {
    final currentYear = DateTime.now().year;
    final years = List.generate(8, (i) => currentYear - 1 - i); // 2025, 2024, ..., 2018

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: AppSpacing.paddingMD,
                child: const Text('Tahun Pembanding',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: const Text('Tidak ada'),
                      leading: Radio<int?>(
                        value: null,
                        groupValue: _compareYear,
                        onChanged: (v) {
                          Navigator.pop(ctx);
                          _changeCompareYear(v);
                        },
                      ),
                    ),
                    ...years.map((y) => ListTile(
                          title: Text('$y'),
                          leading: Radio<int?>(
                            value: y,
                            groupValue: _compareYear,
                            onChanged: (v) {
                              Navigator.pop(ctx);
                              _changeCompareYear(v);
                            },
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

    final ts = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(s.periodeLabel,
                  style: ts.bodySmall,
                  overflow: TextOverflow.ellipsis),
            ),
            AppSpacing.gapHorizontalXS,
            Flexible(
              child: Text(
                s.prevLabel.isEmpty ? '' : 'vs ${s.prevLabel}',
                style: ts.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        AppSpacing.gapVerticalSM,
        Row(
          children: [
            Expanded(child: _kpiCard('Omzet', s.omzet, s.omzetPrev, isCurrency: true)),
            AppSpacing.gapHorizontalSM,
            Expanded(child: _kpiCard('Order', s.orderCount, s.orderCountPrev)),
            AppSpacing.gapHorizontalSM,
            Expanded(child: _kpiCard('Qty', s.totalQty, s.totalQtyPrev)),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String label, int currentValue, int prevValue,
      {bool isCurrency = false}) {
    final cs = Theme.of(context).colorScheme;
    final valueText = isCurrency
        ? FormatUtils.formatCurrencyCompact(currentValue)
        : FormatUtils.formatNumber(currentValue);
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppSpacing.borderRadiusMD,
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valueText,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: _deltaIndicator(currentValue, prevValue, isCurrency: isCurrency),
          ),
        ],
      ),
    );
  }

  /// Indikator naik/turun/baru/stabil untuk KPI card.
  /// Baris pertama: ikon + persentase. Baris kedua: nilai sebelumnya.
  Widget _deltaIndicator(int current, int prev, {bool isCurrency = false}) {
    final cs = Theme.of(context).colorScheme;
    final prevText = isCurrency
        ? FormatUtils.formatCurrencyCompact(prev)
        : FormatUtils.formatNumber(prev);
    if (prev == 0) {
      // Tidak ada data pembanding → hindari div-by-zero.
      return _pill(Icons.fiber_new, 'Baru', cs.outline);
    }
    final delta = current - prev;
    final pct = (delta.abs() / prev * 100).round();
    final Color color;
    final IconData icon;
    if (delta > 0) {
      color = AppColors.success;
      icon = Icons.arrow_upward;
    } else if (delta < 0) {
      color = AppColors.error;
      icon = Icons.arrow_downward;
    } else {
      color = cs.outline;
      icon = Icons.arrow_forward;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _pill(icon, '$pct%', color),
        const SizedBox(height: 2),
        Text(
          'dari $prevText',
          style: TextStyle(
            fontSize: 9,
            color: AppColors.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _pill(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(text,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      ],
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

    final cs = Theme.of(context).colorScheme;
    final hasCompare = _compareYear != null && _trend.any((p) => p.valuePrev != null);

    final currentSpots = <FlSpot>[];
    double maxY = 0;
    for (var i = 0; i < _trend.length; i++) {
      final v = _trend[i].value.toDouble();
      currentSpots.add(FlSpot(i.toDouble(), v));
      if (v > maxY) maxY = v;
    }

    final prevSpots = <FlSpot>[];
    if (hasCompare) {
      for (var i = 0; i < _trend.length; i++) {
        final v = (_trend[i].valuePrev ?? 0).toDouble();
        prevSpots.add(FlSpot(i.toDouble(), v));
        if (v > maxY) maxY = v;
      }
    }

    final metricColor = _metricColor;
    final lineBars = <LineChartBarData>[
      LineChartBarData(
        spots: currentSpots,
        isCurved: true,
        color: metricColor,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: metricColor.withValues(alpha: 0.15),
        ),
      ),
    ];
    if (hasCompare) {
      lineBars.add(LineChartBarData(
        spots: prevSpots,
        isCurved: true,
        color: cs.outline,
        barWidth: 2,
        dashArray: const [4, 4],
        dotData: const FlDotData(show: false),
      ));
    }

    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppSpacing.borderRadiusMD,
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tren ${_metricLabel(_metric)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 0,
            children: [
              _metricChip('Omzet', 'omzet'),
              _metricChip('Order', 'order'),
              _metricChip('Qty', 'qty'),
            ],
          ),
          if (hasCompare) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.circle, size: 10, color: metricColor),
              const SizedBox(width: 4),
              Text('Periode ini', style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 12),
              Icon(Icons.linear_scale, size: 10, color: cs.outline),
              const SizedBox(width: 4),
              Text('$_compareYear', style: const TextStyle(fontSize: 11)),
            ]),
          ],
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
                        if (hasCompare) {
                          return LineTooltipItem(
                            '${point.label}\n• ${_fmtMetric(point.value)}\n• $_compareYear: ${_fmtMetric(point.valuePrev ?? 0)}',
                            const TextStyle(fontSize: 11),
                          );
                        }
                        return LineTooltipItem(
                          '${point.label}\n${_fmtMetric(point.value)}',
                          const TextStyle(fontSize: 11),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: lineBars,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----- Helper metric (Omzet/Order/Qty) untuk chart -----

  Color get _metricColor {
    final cs = Theme.of(context).colorScheme;
    switch (_metric) {
      case 'order':
        return cs.primary;
      case 'qty':
        return AppColors.success;
      default:
        return cs.secondary; // 'omzet'
    }
  }

  String _metricLabel(String metric) {
    switch (metric) {
      case 'order':
        return 'Order';
      case 'qty':
        return 'Qty';
      default:
        return 'Omzet';
    }
  }

  String _fmtMetric(int v) {
    switch (_metric) {
      case 'omzet':
        return FormatUtils.formatCurrencyCompact(v);
      case 'order':
      case 'qty':
      default:
        return FormatUtils.formatNumber(v);
    }
  }

  Widget _metricChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _metric == value,
      onSelected: _loadingTrend ? null : (_) => _changeMetric(value),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity(horizontal: -3, vertical: -3),
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
        '${FormatUtils.formatCurrencyCompact(item.revenue)}${item.unit != null ? ' · ${item.unit}' : ''}',
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

class _ChannelsTab extends StatefulWidget {
  final SalesPeriode periode;
  const _ChannelsTab({super.key, required this.periode});

  @override
  State<_ChannelsTab> createState() => _ChannelsTabState();
}

class _ChannelsTabState extends State<_ChannelsTab> {
  final SalesDashboardService _service = SalesDashboardService();
  List<SalesChannelItem> _items = [];
  int _totalOmzet = 0;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _service.getChannels(widget.periode);
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _totalOmzet = result.totalOmzet;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _colorFor(String channel) {
    switch (channel) {
      case '3':
        return AppColors.secondary;
      case '1':
        return AppColors.primary;
      case '2':
        return AppColors.onPrimary;
      default:
        return AppColors.onSurfaceVariant;
    }
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
            FilledButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    if (_items.isEmpty || _totalOmzet == 0) {
      return const Center(
        child: Padding(
          padding: AppSpacing.paddingLG,
          child: Text('Belum ada penjualan di periode ini.'),
        ),
      );
    }

    return ListView(
      padding: AppSpacing.paddingMD,
      children: [
        _buildPie(),
        AppSpacing.gapVerticalMD,
        ..._items.map(_buildChannelRow),
      ],
    );
  }

  Widget _buildPie() {
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 60,
          sections: _items
              .where((item) => item.omzet > 0)
              .map((item) {
            return PieChartSectionData(
              value: item.omzet.toDouble(),
              color: _colorFor(item.channel),
              title: '${item.percentage.toStringAsFixed(0)}%',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChannelRow(SalesChannelItem item) {
    return Container(
      padding: AppSpacing.paddingMD,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusSM,
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _colorFor(item.channel),
              borderRadius: AppSpacing.borderRadiusXS,
            ),
          ),
          AppSpacing.gapHorizontalMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.channelLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${item.orderCount} order · ${item.qty} qty',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(FormatUtils.formatCurrencyCompact(item.omzet),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${item.percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
