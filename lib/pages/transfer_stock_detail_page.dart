import 'package:flutter/material.dart';
import '../models/transfer_stock_model.dart';
import '../services/transfer_stock_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class TransferStockDetailPage extends StatefulWidget {
  final int transferId;

  const TransferStockDetailPage({super.key, required this.transferId});

  @override
  State<TransferStockDetailPage> createState() =>
      _TransferStockDetailPageState();
}

class _TransferStockDetailPageState extends State<TransferStockDetailPage> {
  final TransferStockService _service = TransferStockService();
  TransferStockModel? _transfer;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await _service.getTransferStock(widget.transferId);
      if (!mounted) return;
      setState(() {
        _transfer = data;
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
        title: const Text('Detail Transfer Stok'),
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
                          onPressed: _fetchDetail,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _transfer == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md +
                            MediaQuery.of(context).padding.bottom,
                      ),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${_transfer!.fromStoreName} → ${_transfer!.toStoreName}',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      AppSpacing.gapHorizontalSM,
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(
                                                  _transfer!.status)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              AppSpacing.borderRadiusXL,
                                        ),
                                        child: Text(
                                          _transfer!.statusText,
                                          style: TextStyle(
                                            color:
                                                _statusColor(_transfer!.status),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  AppSpacing.gapVerticalSM,
                                  _buildInfoRow(
                                      'Tanggal', _transfer!.date, theme),
                                  AppSpacing.gapVerticalSM,
                                  _buildInfoRow('Toko Asal',
                                      _transfer!.fromStoreName, theme),
                                  AppSpacing.gapVerticalSM,
                                  _buildInfoRow('Toko Tujuan',
                                      _transfer!.toStoreName, theme),
                                  AppSpacing.gapVerticalSM,
                                  _buildInfoRow(
                                      'Dikirim oleh',
                                      _transfer!.sentByName,
                                      theme),
                                  if (_transfer!.receivedByName != null) ...[
                                    AppSpacing.gapVerticalSM,
                                    _buildInfoRow(
                                        'Diterima oleh',
                                        _transfer!.receivedByName!,
                                        theme),
                                  ],
                                  if (_transfer!.notes != null &&
                                      _transfer!.notes!.isNotEmpty) ...[
                                    AppSpacing.gapVerticalSM,
                                    _buildInfoRow(
                                        'Catatan', _transfer!.notes!, theme),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          AppSpacing.gapVerticalLG,
                          Text(
                            'Item Transfer:',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.gapVerticalSM,
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _transfer!.details.length,
                            itemBuilder: (context, idx) {
                              final item = _transfer!.details[idx];
                              return Card(
                                 margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: ListTile(
                                  title: Text(
                                    item.productName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  trailing: Text(
                                    '${item.quantity.toStringAsFixed(0)} ${item.unitName}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
