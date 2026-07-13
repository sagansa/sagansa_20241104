import 'package:flutter/material.dart';
import '../models/transfer_stock_model.dart';
import '../services/transfer_stock_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/add_fab.dart';
import 'create_transfer_stock_page.dart';
import 'transfer_stock_detail_page.dart';

class TransferStockListPage extends StatefulWidget {
  const TransferStockListPage({super.key});

  @override
  State<TransferStockListPage> createState() => _TransferStockListPageState();
}

class _TransferStockListPageState extends State<TransferStockListPage> {
  final TransferStockService _service = TransferStockService();
  List<TransferStockModel> _transfers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTransfers();
  }

  Future<void> _fetchTransfers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.getTransferStocks();
      if (!mounted) return;
      setState(() {
        _transfers = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.success;
      case 3:
        return AppColors.onSurfaceVariant;
      case 4:
        return AppColors.error;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Stok'),
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
                        Icon(Icons.error_outline_rounded,
                            size: 48, color: colorScheme.error),
                        AppSpacing.gapVerticalMD,
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                        AppSpacing.gapVerticalMD,
                        ElevatedButton(
                          onPressed: _fetchTransfers,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _transfers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 48,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          AppSpacing.gapVerticalMD,
                          Text(
                            'Belum ada riwayat transfer stok.',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchTransfers,
                      child: ListView.builder(
                        padding: AppSpacing.paddingMD,
                        itemCount: _transfers.length,
                        itemBuilder: (context, idx) {
                          final transfer = _transfers[idx];

                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
                            child: InkWell(
                              borderRadius: AppSpacing.borderRadiusLG,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TransferStockDetailPage(
                                            transferId: transfer.id),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: AppSpacing.paddingMD,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${transfer.fromStoreName} → ${transfer.toStoreName}',
                                            style: theme
                                                .textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        AppSpacing.gapHorizontalSM,
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _statusColor(
                                                    transfer.status)
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                AppSpacing.borderRadiusXL,
                                          ),
                                          child: Text(
                                            transfer.statusText,
                                            style: TextStyle(
                                              color: _statusColor(
                                                  transfer.status),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    AppSpacing.gapVerticalSM,
                                    Text(
                                      'Tanggal: ${transfer.date}',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                    AppSpacing.gapVerticalXS,
                    Text(
                                      'Dikirim oleh: ${transfer.sentByName}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const Divider(height: 24),
                                    Text(
                                      '${transfer.details.length} jenis item',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
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
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTransferStockPage(),
            ),
          );
          if (result == true) {
            _fetchTransfers();
          }
        },
      ),
    );
  }
}
