import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/procurement_model.dart';
import '../services/procurement_service.dart';
import '../theme/app_spacing.dart';
import '../utils/procurement_approval.dart';
import '../widgets/add_fab.dart';
import '../widgets/procurement_batch_bottom_bar.dart';
import '../widgets/procurement_entity_card.dart';
import '../widgets/procurement_graph_view.dart';
import '../widgets/procurement_stage_tabs.dart';
import '../widgets/procurement_stats_strip.dart';
import '../widgets/procurement_subfilter_chips.dart';
import 'create_invoice_page.dart';
import 'create_payment_receipt_page.dart';
import 'create_procurement_page.dart';
import 'invoice_detail_page.dart';
import 'payment_receipt_detail_page.dart';
import 'procurement_detail_page.dart';

class ProcurementWorkflowPage extends StatefulWidget {
  const ProcurementWorkflowPage({super.key});

  @override
  State<ProcurementWorkflowPage> createState() => _ProcurementWorkflowPageState();
}

class _ProcurementWorkflowPageState extends State<ProcurementWorkflowPage> {
  final ProcurementService _service = ProcurementService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Stage & sub-filter
  int _activeStage = 0; // 0=Request, 1=Invoice, 2=Payment
  int _subFilterRequest = 0; // 0=Semua, 1=SiapInvoice, 2=SudahJadiInvoice
  int _subFilterInvoice = 0; // 0=Semua, 1=ButuhApproval, 2=SiapDibayar, 3=Lunas
  int _subFilterPayment = 0; // 0=Semua, 1=Tunai, 2=Transfer

  // Search
  bool _searchExpanded = false;
  String _searchQuery = '';

  // Batch
  bool _batchMode = false;
  final Set<int> _selectedRequestIds = {};
  final Set<int> _selectedInvoiceIds = {};

  // Data
  List<RequestPurchase> _requests = [];
  List<InvoicePurchase> _allInvoices = [];
  List<PaymentReceipt> _allReceipts = [];
  Map<int, List<InvoicePurchase>> _requestToInvoices = {};
  Map<int, PaymentReceipt> _invoiceToReceipt = {};
  Map<int, List<int>> _invoiceToRequestIds = {};

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _errorMessage;

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = json.decode(userString);
        final roles = List<String>.from(userData['roles'] ?? []);
        if (mounted) {
          setState(() => _isAdmin = roles.contains('admin') || roles.contains('super_admin'));
        }
      }
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore && _hasMore && _activeStage == 0) {
      _loadMore();
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _page = 1;
      _requests = [];
      _allInvoices = [];
      _allReceipts = [];
      _requestToInvoices = {};
      _invoiceToReceipt = {};
      _invoiceToRequestIds = {};
      _selectedRequestIds.clear();
      _selectedInvoiceIds.clear();
      _hasMore = true;
    });

    try {
      final requestResult = await _service.getRequestsPaged(page: _page, perPage: 30);
      final requests = requestResult['data'] as List<RequestPurchase>;

      List<InvoicePurchase> invoices = [];
      List<PaymentReceipt> receipts = [];
      try {
        invoices = (await _service.getInvoices(perPage: 100)).items;
      } catch (_) {}
      try {
        receipts = (await _service.getPaymentReceipts(perPage: 100)).items;
      } catch (_) {}

      // Build requestToInvoices (with dedup)
      final reqToInv = <int, List<InvoicePurchase>>{};
      for (var inv in invoices) {
        for (var detailItem in inv.detailInvoices) {
          if (detailItem.detailRequestId != null) {
            for (var req in requests) {
              if (req.detailRequests.any((dr) => dr.id == detailItem.detailRequestId)) {
                reqToInv.putIfAbsent(req.id, () => []).add(inv);
                break;
              }
            }
          }
        }
      }
      reqToInv.forEach((reqId, list) {
        final unique = <int, InvoicePurchase>{};
        for (var i in list) {
          unique[i.id] = i;
        }
        reqToInv[reqId] = unique.values.toList();
      });

      // Build invoiceToReceipt
      final invToRec = <int, PaymentReceipt>{};
      for (var rec in receipts) {
        for (var inv in rec.invoicePurchases) {
          invToRec[inv.id] = rec;
        }
      }

      // Build invoiceToRequestIds (inverse of reqToInv)
      final invToReqIds = <int, List<int>>{};
      reqToInv.forEach((reqId, invs) {
        for (var inv in invs) {
          invToReqIds.putIfAbsent(inv.id, () => []).add(reqId);
        }
      });

      if (!mounted) return;
      setState(() {
        _requests = requests;
        _allInvoices = invoices;
        _allReceipts = receipts;
        _requestToInvoices = reqToInv;
        _invoiceToReceipt = invToRec;
        _invoiceToRequestIds = invToReqIds;
        _hasMore = requestResult['has_more'] as bool;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final result = await _service.getRequestsPaged(page: nextPage, perPage: 30);
      final newRequests = result['data'] as List<RequestPurchase>;
      if (!mounted) return;
      setState(() {
        _page = nextPage;
        _requests.addAll(newRequests);
        _hasMore = result['has_more'] as bool;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // ============ Helpers (computed) ============

  bool _hasPendingItems(InvoicePurchase inv) {
    return hasPendingApprovalItems(
      invoicePaymentTypeId: inv.paymentTypeId,
      itemStatuses: inv.detailInvoices.map((d) => d.status).toList(),
    );
  }

  int _pendingItemCount(InvoicePurchase inv) {
    return pendingItemCount(inv.detailInvoices.map((d) => d.status).toList());
  }

  int get _countPendingApproval =>
      _allInvoices.where((inv) => _hasPendingItems(inv)).length;

  int get _countSiapInvoice =>
      _requests.where((r) => r.detailRequests.isNotEmpty && !_requestToInvoices.containsKey(r.id)).length;

  int get _countSiapBayar =>
      _allInvoices.where((inv) => inv.paymentStatus != '2' && !_hasPendingItems(inv)).length;

  // ============ Filtering ============

  List<RequestPurchase> get _filteredRequests {
    var list = _requests.where((r) => r.detailRequests.isNotEmpty).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) =>
          r.id.toString().contains(q) ||
          r.storeName.toLowerCase().contains(q) ||
          r.userName.toLowerCase().contains(q)).toList();
    }
    switch (_subFilterRequest) {
      case 1:
        return list.where((r) => !_requestToInvoices.containsKey(r.id)).toList();
      case 2:
        return list.where((r) => _requestToInvoices.containsKey(r.id)).toList();
      default:
        return list;
    }
  }

  List<InvoicePurchase> get _filteredInvoices {
    var list = _allInvoices;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((i) =>
          i.id.toString().contains(q) ||
          i.storeName.toLowerCase().contains(q) ||
          (i.supplierName ?? '').toLowerCase().contains(q)).toList();
    }
    // Sort: pending approval di atas
    list = List.from(list)
      ..sort((a, b) {
        final aP = _hasPendingItems(a) ? 0 : 1;
        final bP = _hasPendingItems(b) ? 0 : 1;
        return aP.compareTo(bP);
      });
    switch (_subFilterInvoice) {
      case 1:
        return list.where((i) => _hasPendingItems(i)).toList();
      case 2:
        return list.where((i) => i.paymentStatus != '2' && !_hasPendingItems(i)).toList();
      case 3:
        return list.where((i) => i.paymentStatus == '2').toList();
      default:
        return list;
    }
  }

  List<PaymentReceipt> get _filteredReceipts {
    var list = _allReceipts;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) =>
          r.id.toString().contains(q) ||
          (r.supplierName ?? '').toLowerCase().contains(q)).toList();
    }
    switch (_subFilterPayment) {
      case 1:
        return list.where((r) => r.paymentFor == '2').toList(); // tunai
      case 2:
        return list.where((r) => r.paymentFor == '1').toList(); // transfer (asumsi)
      default:
        return list;
    }
  }

  int get _batchPaymentTotal {
    int total = 0;
    for (var id in _selectedInvoiceIds) {
      final inv = _allInvoices.firstWhere(
        (i) => i.id == id,
        orElse: () => InvoicePurchase(
          id: 0,
          storeId: 0,
          date: '',
          createdById: 0,
          storeName: '',
        ),
      );
      total += inv.totalPrice;
    }
    return total;
  }

  // ============ Build ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procurement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _searchExpanded = !_searchExpanded),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) async {
              if (val == 'graph') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _GraphPage(
                      requests: _requests,
                      invoices: _allInvoices,
                      receipts: _allReceipts,
                      requestToInvoices: _requestToInvoices,
                      invoiceToReceipt: _invoiceToReceipt,
                    ),
                  ),
                );
                _fetchData();
              } else if (val == 'refresh') {
                _fetchData();
              } else if (val == 'batch') {
                setState(() {
                  _batchMode = !_batchMode;
                  _selectedRequestIds.clear();
                  _selectedInvoiceIds.clear();
                });
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'graph', child: Text('🌳 Grafik Many-to-Many')),
              const PopupMenuItem(value: 'refresh', child: Text('🔄 Refresh')),
              PopupMenuItem(
                value: 'batch',
                child: Text(_batchMode ? '☑️ Exit Mode Batch' : '☑️ Mode Batch'),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_searchExpanded ? 110 : 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Cari No Request/Invoice/Toko...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ProcurementStatsStrip(
                pendingApprovalCount: _countPendingApproval,
                siapInvoiceCount: _countSiapInvoice,
                siapBayarCount: _countSiapBayar,
                onChipTap: (i) {
                  if (i == 0) {
                    setState(() {
                      _activeStage = 1;
                      _subFilterInvoice = 1;
                    });
                  } else if (i == 1) {
                    setState(() {
                      _activeStage = 0;
                      _subFilterRequest = 1;
                    });
                  } else {
                    setState(() {
                      _activeStage = 1;
                      _subFilterInvoice = 2;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      AppSpacing.gapVerticalMD,
                      ElevatedButton(
                        onPressed: _fetchData,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: Column(
                    children: [
                      ProcurementStageTabs(
                        activeStage: _activeStage,
                        requestCount: _filteredRequests.length,
                        invoiceCount: _filteredInvoices.length,
                        paymentCount: _filteredReceipts.length,
                        onTabTap: (i) => setState(() {
                          _activeStage = i;
                          _selectedRequestIds.clear();
                          _selectedInvoiceIds.clear();
                        }),
                      ),
                      _buildSubFilter(),
                      Expanded(child: _buildActiveList()),
                    ],
                  ),
                ),
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButton: AddFab(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateProcurementPage()),
          );
          if (created == true) _fetchData();
        },
      ),
    );
  }

  Widget _buildSubFilter() {
    if (_activeStage == 0) {
      return ProcurementSubfilterChips(
        options: const ['Semua', 'Siap Invoice', 'Sudah Jadi Invoice'],
        activeIndex: _subFilterRequest,
        activeColor: const Color(0xFFFF9800),
        onChipTap: (i) => setState(() => _subFilterRequest = i),
      );
    } else if (_activeStage == 1) {
      final options = _isAdmin
          ? const ['Semua', '⚠️ Butuh Approval', 'Siap Dibayar', 'Lunas']
          : const ['Semua', 'Siap Dibayar', 'Lunas'];
      final activeIdx = _isAdmin
          ? _subFilterInvoice
          : (_subFilterInvoice > 0 ? _subFilterInvoice - 1 : 0);
      return ProcurementSubfilterChips(
        options: options,
        activeIndex: activeIdx.clamp(0, options.length - 1),
        activeColor: const Color(0xFF2196F3),
        onChipTap: (i) => setState(() {
          _subFilterInvoice = _isAdmin ? i : (i == 0 ? 0 : i + 1);
        }),
      );
    } else {
      return ProcurementSubfilterChips(
        options: const ['Semua', 'Tunai', 'Transfer'],
        activeIndex: _subFilterPayment,
        activeColor: const Color(0xFF9C27B0),
        onChipTap: (i) => setState(() => _subFilterPayment = i),
      );
    }
  }

  Widget _buildActiveList() {
    if (_activeStage == 0) return _buildRequestList();
    if (_activeStage == 1) return _buildInvoiceList();
    return _buildReceiptList();
  }

  Widget _buildRequestList() {
    final list = _filteredRequests;
    if (list.isEmpty) return _buildEmpty('Tidak ada request', Icons.shopping_bag_outlined);
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.paddingMD,
      itemCount: list.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == list.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final req = list[i];
        final linked = _requestToInvoices[req.id] ?? [];
        final isSel = _selectedRequestIds.contains(req.id);
        return ProcurementEntityCard.requestMode(
          request: req,
          linkedInvoices: linked,
          isSelected: isSel,
          showCheckbox: _batchMode,
          checkboxValue: isSel,
          onCheckboxChanged: (v) => setState(() {
            if (v) {
              _selectedRequestIds.add(req.id);
            } else {
              _selectedRequestIds.remove(req.id);
            }
          }),
          onTapCard: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProcurementDetailPage(requestId: req.id),
              ),
            );
            _fetchData();
          },
          onTapCreateInvoice: () async {
            final created = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => CreateInvoicePage(requestId: req.id, requestIds: [req.id]),
              ),
            );
            if (created == true) _fetchData();
          },
          onTapLinkInvoice: (inv) async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InvoiceDetailPage(invoiceId: inv.id),
              ),
            );
            _fetchData();
          },
        );
      },
    );
  }

  Widget _buildInvoiceList() {
    final list = _filteredInvoices;
    if (list.isEmpty) return _buildEmpty('Tidak ada invoice', Icons.receipt_long_outlined);
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.paddingMD,
      itemCount: list.length,
      itemBuilder: (_, i) {
        final inv = list[i];
        final reqIds = _invoiceToRequestIds[inv.id] ?? [];
        final pendingCount = _pendingItemCount(inv);
        final isSel = _selectedInvoiceIds.contains(inv.id);
        final canBayar = inv.paymentStatus != '2' && pendingCount == 0;
        return ProcurementEntityCard.invoiceMode(
          invoice: inv,
          linkedRequestIds: reqIds,
          pendingApprovalItemCount: pendingCount,
          isAdmin: _isAdmin,
          showCheckbox: _batchMode && canBayar,
          checkboxValue: isSel,
          onCheckboxChanged: (v) => setState(() {
            if (v) {
              _selectedInvoiceIds.add(inv.id);
            } else {
              _selectedInvoiceIds.remove(inv.id);
            }
          }),
          onTapCard: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InvoiceDetailPage(invoiceId: inv.id),
              ),
            );
            _fetchData();
          },
          onTapBayar: canBayar
              ? () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatePaymentReceiptPage(invoices: [inv]),
                    ),
                  );
                  if (created == true) _fetchData();
                }
              : null,
          onTapReviewApprove: pendingCount > 0
              ? () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InvoiceDetailPage(invoiceId: inv.id),
                    ),
                  );
                  _fetchData();
                }
              : null,
        );
      },
    );
  }

  Widget _buildReceiptList() {
    final list = _filteredReceipts;
    if (list.isEmpty) return _buildEmpty('Tidak ada payment receipt', Icons.payment_outlined);
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.paddingMD,
      itemCount: list.length,
      itemBuilder: (_, i) {
        final rec = list[i];
        // Asumsi: paymentFor == '2' = tunai, '1' = transfer, '3' = other
        final isTunai = rec.paymentFor == '2';
        return ProcurementEntityCard.paymentMode(
          receipt: rec,
          isTunai: isTunai,
          onTapCard: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentReceiptDetailPage(receiptId: rec.id),
              ),
            );
            _fetchData();
          },
        );
      },
    );
  }

  Widget _buildEmpty(String text, IconData icon) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 54,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                AppSpacing.gapVerticalMD,
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomBar() {
    if (_batchMode && _activeStage == 0 && _selectedRequestIds.isNotEmpty) {
      return ProcurementBatchBottomBar.requestMode(
        selectedCount: _selectedRequestIds.length,
        onClear: () => setState(() {
          _selectedRequestIds.clear();
        }),
        onAction: () async {
          final ids = _selectedRequestIds.toList();
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => CreateInvoicePage(requestId: ids.first, requestIds: ids),
            ),
          );
          if (created == true) {
            setState(() {
              _selectedRequestIds.clear();
              _batchMode = false;
            });
            _fetchData();
          }
        },
      );
    }
    if (_batchMode && _activeStage == 1 && _selectedInvoiceIds.isNotEmpty) {
      return ProcurementBatchBottomBar.invoiceMode(
        selectedCount: _selectedInvoiceIds.length,
        totalAmount: _batchPaymentTotal,
        onClear: () => setState(() {
          _selectedInvoiceIds.clear();
        }),
        onAction: () async {
          final selected = _allInvoices
              .where((i) => _selectedInvoiceIds.contains(i.id))
              .toList();
          if (selected.isEmpty) return;
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => CreatePaymentReceiptPage(invoices: selected),
            ),
          );
          if (created == true) {
            setState(() {
              _selectedInvoiceIds.clear();
              _batchMode = false;
            });
            _fetchData();
          }
        },
      );
    }
    return null;
  }
}

/// Wrapper page untuk GraphView (dipanggil dari menu ⋮).
class _GraphPage extends StatelessWidget {
  final List<RequestPurchase> requests;
  final List<InvoicePurchase> invoices;
  final List<PaymentReceipt> receipts;
  final Map<int, List<InvoicePurchase>> requestToInvoices;
  final Map<int, PaymentReceipt> invoiceToReceipt;

  const _GraphPage({
    required this.requests,
    required this.invoices,
    required this.receipts,
    required this.requestToInvoices,
    required this.invoiceToReceipt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grafik Many-to-Many')),
      body: ProcurementGraphView(
        requests: requests,
        invoices: invoices,
        receipts: receipts,
        requestToInvoices: requestToInvoices,
        invoiceToReceipt: invoiceToReceipt,
        onTapRequest: (r) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProcurementDetailPage(requestId: r.id),
          ),
        ),
        onTapInvoice: (i) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailPage(invoiceId: i.id),
          ),
        ),
        onTapReceipt: (r) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentReceiptDetailPage(receiptId: r.id),
          ),
        ),
      ),
    );
  }
}
