import 'package:flutter/material.dart';
import '../models/storage_stock_model.dart';
import '../services/storage_stock_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/add_fab.dart';
import 'create_storage_stock_page.dart';
import 'storage_stock_detail_page.dart';

class StorageStockListPage extends StatefulWidget {
  const StorageStockListPage({super.key});

  @override
  State<StorageStockListPage> createState() => _StorageStockListPageState();
}

class _StorageStockListPageState extends State<StorageStockListPage> {
  final StorageStockService _service = StorageStockService();
  List<StorageStockModel> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.getStorageStocks();
      if (!mounted) return;
      setState(() {
        _reports = data;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Stok Gudang')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: AppSpacing.paddingLG,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!, style: TextStyle(color: colorScheme.error)),
                        AppSpacing.gapVerticalMD,
                        ElevatedButton(
                          onPressed: _fetchReports,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _reports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant.withValues(alpha:0.5),
                          ),
                          AppSpacing.gapVerticalMD,
                          Text(
                            'Belum ada riwayat laporan stok gudang.',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchReports,
                      child: ListView.builder(
                        padding: AppSpacing.paddingMD,
                        itemCount: _reports.length,
                        itemBuilder: (context, idx) {
                          final report = _reports[idx];

                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
                            child: InkWell(
                              borderRadius: AppSpacing.borderRadiusLG,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StorageStockDetailPage(reportId: report.id),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: AppSpacing.paddingMD,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          report.storeName,
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary.withValues(alpha:0.1),
                                            borderRadius: AppSpacing.borderRadiusXL,
                                          ),
                                          child: Text(
                                            report.statusText,
                                            style: textTheme.labelSmall?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    AppSpacing.gapVerticalSM,
                                    Text(
                                      'Tanggal: ${report.date}',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    AppSpacing.gapVerticalXS,
                                    Text(
                                      'Dilaporkan oleh: ${report.createdByName}',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant.withValues(alpha:0.8),
                                      ),
                                    ),
                                    const Divider(height: 24),
                                    Text(
                                      '${report.details.length} jenis item terdata',
                                      style: textTheme.bodySmall?.copyWith(
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
              builder: (context) => const CreateStorageStockPage(),
            ),
          );
          if (result == true) {
            _fetchReports();
          }
        },
      ),
    );
  }
}
