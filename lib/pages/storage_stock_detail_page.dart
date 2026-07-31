import 'package:flutter/material.dart';
import '../models/storage_stock_model.dart';
import '../services/storage_stock_service.dart';
import '../theme/app_spacing.dart';

class StorageStockDetailPage extends StatefulWidget {
  final int reportId;

  const StorageStockDetailPage({super.key, required this.reportId});

  @override
  State<StorageStockDetailPage> createState() => _StorageStockDetailPageState();
}

class _StorageStockDetailPageState extends State<StorageStockDetailPage> {
  final StorageStockService _service = StorageStockService();
  StorageStockModel? _report;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await _service.getStorageStock(widget.reportId);
      if (!mounted) return;
      setState(() {
        _report = data;
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
      appBar: AppBar(title: const Text('Detail Stok Gudang')),
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
                          onPressed: _fetchDetail,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _report == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: AppSpacing.paddingMD,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            child: Padding(
                              padding: AppSpacing.paddingMD,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _report!.storeName,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary.withValues(alpha:0.1),
                                            borderRadius: AppSpacing.borderRadiusXL,
                                          ),
                                          child: Text(
                                            _report!.statusText,
                                            overflow: TextOverflow.ellipsis,
                                            style: textTheme.labelMedium?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  AppSpacing.gapVerticalSM,
                                  _buildInfoRow('Tanggal', _report!.date, theme),
                                  AppSpacing.gapVerticalSM,
                                  _buildInfoRow('Dilaporkan oleh', _report!.createdByName, theme),
                                ],
                              ),
                            ),
                          ),
                          AppSpacing.gapVerticalLG,
                          Text(
                            'Item Stok Opname:',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.gapVerticalSM,
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _report!.details.length,
                            itemBuilder: (context, idx) {
                              final item = _report!.details[idx];
                              return Card(
                                 margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: ListTile(
                                  title: Text(
                                    item.productName,
                                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  trailing: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 130),
                                    child: Text(
                                      '${item.quantity.toStringAsFixed(0)} ${item.unitName}',
                                      textAlign: TextAlign.end,
                                      softWrap: true,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
