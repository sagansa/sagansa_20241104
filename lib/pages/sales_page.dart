import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/enums/order_mode.dart';
import '../models/sales_order_employee_model.dart';
import '../providers/delivery_provider.dart';
import '../providers/printer_provider.dart';
import '../services/sales_order_employee_service.dart';
import '../theme/app_spacing.dart';
import '../utils/error_utils.dart';
import '../utils/format_utils.dart';
import '../widgets/delivery/order_list_view.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/paged_body_view.dart';
import 'create_sales_order_online_page.dart';
import 'sales_order_employee_detail_page.dart';
import 'sales_order_employee_form_page.dart';

/// Halaman Penjualan terpadu — 3 tab: Online, Employee, Direct.
///
/// Menggantikan dialog pilih tipe penjualan di TransactionDashboardPage
/// — user cukup tap tab untuk ganti tipe, tanpa bolak-balik ke menu utama.
class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Penjualan'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: cs.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: cs.primary,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurfaceVariant,
              tabs: const [
                Tab(text: 'Online'),
                Tab(text: 'Employee'),
                Tab(text: 'Direct'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OnlineTabContent(),
          const _EmployeeTabContent(),
          _DirectTabContent(),
        ],
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) Navigator.pop(context);
        },
      ),
    );
  }
}

/// Tab Online — delivery list scoped to online orders.
class _OnlineTabContent extends StatefulWidget {
  @override
  State<_OnlineTabContent> createState() => _OnlineTabContentState();
}

class _OnlineTabContentState extends State<_OnlineTabContent> {
  late DeliveryProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = DeliveryProvider(orderMode: OrderMode.online)..initialize();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  void _openCreateOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateSalesOrderOnlinePage(),
      ),
    ).then((_) => _provider.loadInitialOrders());
  }

  Future<void> _scanBarcode() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _ScannerPlaceholder()),
    );
    if (scannedCode != null && scannedCode.isNotEmpty) {
      _provider.receiptController.text = scannedCode;
      _provider.searchOrder().catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: ChangeNotifierProvider(
        create: (_) => PrinterProvider(),
        child: Stack(
          children: [
            OrderListView(
              orderMode: OrderMode.online,
              onScanBarcode: _scanBarcode,
            ),
            if (_provider.listState.isAdmin)
              Positioned(
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: FloatingActionButton(
                  onPressed: _openCreateOrder,
                  child: const Icon(Icons.add),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tab Direct — delivery list scoped to direct orders.
class _DirectTabContent extends StatefulWidget {
  @override
  State<_DirectTabContent> createState() => _DirectTabContentState();
}

class _DirectTabContentState extends State<_DirectTabContent> {
  late DeliveryProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = DeliveryProvider(orderMode: OrderMode.direct)..initialize();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: ChangeNotifierProvider(
        create: (_) => PrinterProvider(),
        child: Stack(
          children: [
            OrderListView(
              orderMode: OrderMode.direct,
              onScanBarcode: () {},
            ),
            if (_provider.listState.isAdmin)
              Positioned(
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: FloatingActionButton(
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tab Employee — daftar penjualan employee (tanpa Scaffold sendiri).
class _EmployeeTabContent extends StatefulWidget {
  const _EmployeeTabContent();

  @override
  State<_EmployeeTabContent> createState() => _EmployeeTabContentState();
}

class _EmployeeTabContentState extends State<_EmployeeTabContent> {
  final SalesOrderEmployeeService _service = SalesOrderEmployeeService();
  final ScrollController _scrollController = ScrollController();

  List<SalesOrderEmployeeModel> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasNext = false;
  int _page = 1;
  String? _error;

  bool _isSales = false;

  int? _selectedSalesId;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      final roles = List<String>.from(json.decode(userString)['roles'] ?? []);
      if (mounted) {
        setState(() {
          _isSales = roles.contains('sales');
        });
      }
    }
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 1;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final (list, hasNext) = await _service.getList(
        salesId: _selectedSalesId,
        page: _page,
      );
      if (!mounted) return;

      setState(() {
        _items = reset ? list : [..._items, ...list];
        _hasNext = hasNext;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorUtils.sanitize(e);
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasNext || _isLoadingMore) return;
    _page += 1;
    await _load(reset: false);
  }

  void _openCreate() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SalesOrderEmployeeFormPage()),
    );
    if (result == true) _load();
  }

  void _openDetail(SalesOrderEmployeeModel order) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SalesOrderEmployeeDetailPage(
          orderId: order.id,
          canEdit: _isSales,
        ),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        PagedBodyView<SalesOrderEmployeeModel>(
          controller: _scrollController,
          isLoading: _isLoading,
          error: _error,
          items: _items,
          hasMore: _hasNext,
          onRefresh: () => _load(),
          onLoadMore: _loadMore,
          emptyIcon: Icons.receipt_long_outlined,
          emptyTitle: 'Belum ada penjualan employee.',
          emptySubtitle: _isSales ? 'Tap + untuk membuat pesanan baru.' : null,
          itemBuilder: (context, index) {
            final o = _items[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                onTap: () => _openDetail(o),
                title: Text(
                  o.storeName ?? 'Customer',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${o.orderedByName ?? '-'} · ${o.deliveryDate != null ? FormatUtils.formatDate(o.deliveryDate!) : '-'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Text(
                  FormatUtils.formatCurrency(o.totalPrice),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: cs.primary,
                  ),
                ),
              ),
            );
          },
        ),
        if (_isSales)
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: FloatingActionButton(
              onPressed: _isLoading ? null : _openCreate,
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }
}

/// Placeholder — actual barcode scanner page integration.
class _ScannerPlaceholder extends StatelessWidget {
  const _ScannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR/Barcode')),
      body: const Center(child: Text('Scanner page')),
    );
  }
}
