import 'package:flutter/material.dart';
import '../../models/procurement_model.dart';
import '../../services/procurement_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/constants.dart';
import '../../utils/format_utils.dart';
import '../../widgets/add_fab.dart';
import '../../widgets/modern_bottom_nav.dart';
import 'invoice_selection_page.dart';
import 'payment_receipt_detail_page.dart';

class PaymentReceiptDashboardPage extends StatefulWidget {
  const PaymentReceiptDashboardPage({super.key});

  @override
  State<PaymentReceiptDashboardPage> createState() =>
      _PaymentReceiptDashboardPageState();
}

class _PaymentReceiptDashboardPageState
    extends State<PaymentReceiptDashboardPage> {
  final ProcurementService _procurementService = ProcurementService();
  final ScrollController _scrollController = ScrollController();

  List<PaymentReceipt> _receipts = [];
  bool _isLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUser();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadUser() async {
    _fetchReceipts();
  }

  Future<void> _fetchReceipts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _receipts = [];
      _hasMore = true;
    });

    try {
      final result = await _procurementService.getPaymentReceipts(page: 1);
      if (!mounted) return;
      setState(() {
        _receipts = result.items;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat payment receipt: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    try {
      final result =
          await _procurementService.getPaymentReceipts(page: _currentPage + 1);
      if (!mounted) return;
      setState(() {
        _receipts.addAll(result.items);
        _hasMore = result.hasMore;
        _currentPage++;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.');
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '${ApiConstants.baseUrl}/media/$path';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Receipt'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: AppSpacing.paddingLG,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!,
                            style: TextStyle(color: colorScheme.error)),
                        AppSpacing.gapVerticalMD,
                        ElevatedButton(
                          onPressed: _fetchReceipts,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _receipts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          AppSpacing.gapVerticalMD,
                          Text(
                            'Belum ada payment receipt.',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchReceipts,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: AppSpacing.paddingMD,
                        itemCount:
                            _receipts.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (context, idx) {
                          if (idx == _receipts.length) {
                            return const Padding(
                              padding: AppSpacing.paddingMD,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              ),
                            );
                          }
                          final receipt = _receipts[idx];
                          final invoiceCount =
                              receipt.invoicePurchases.length;
                          final storeName =
                              receipt.invoicePurchases.isNotEmpty
                                  ? receipt.invoicePurchases.first
                                      .storeName
                                  : (receipt.supplierName ?? 'Invoice');

                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
                            child: InkWell(
                              borderRadius: AppSpacing.borderRadiusLG,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PaymentReceiptDetailPage(
                                            receiptId: receipt.id),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: AppSpacing.paddingMD,
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (receipt.image != null &&
                                        receipt.image!.isNotEmpty)
                                      ClipRRect(
                                        borderRadius:
                                            AppSpacing.borderRadiusSM,
                                        child: Image.network(
                                          _imageUrl(receipt.image),
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _imagePlaceholder(
                                                  colorScheme),
                                          loadingBuilder:
                                              (_, child, progress) {
                                            if (progress == null) {
                                              return child;
                                            }
                                            return Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .surfaceContainerHighest
                                                    .withValues(alpha: 0.3),
                                                borderRadius:
                                                    AppSpacing.borderRadiusSM,
                                              ),
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    else
                                      _imagePlaceholder(colorScheme),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  storeName,
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow
                                                      .ellipsis,
                                                ),
                                              ),
                                              Text(
                                                'Rp ${receipt.transferAmount != 0 ? _formatAmount(receipt.transferAmount) : '0'}',
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color:
                                                      colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                          AppSpacing.gapVerticalSM,
                          Text(
                                            '$invoiceCount invoice • ${receipt.createdAt.substring(0, 10)}',
                                            style: theme
                                                .textTheme.bodySmall
                                                ?.copyWith(
                                              color: colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                          if (receipt.notes != null &&
                                              receipt
                                                  .notes!.isNotEmpty) ...[
                                            AppSpacing.gapVerticalXS,
                                            Text(
                                              FormatUtils.stripHtml(
                                                  receipt.notes!),
                                              style: theme
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.8),
                                                fontStyle:
                                                    FontStyle.italic,
                                              ),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: AddFab(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const InvoiceSelectionPage(),
            ),
          ).then((_) => _fetchReceipts());
        },
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme colorScheme) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: AppSpacing.borderRadiusSM,
      ),
      child: Icon(
        Icons.receipt_long,
        size: 28,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }
}
