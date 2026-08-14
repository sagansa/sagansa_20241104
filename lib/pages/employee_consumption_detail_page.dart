import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/employee_consumption_model.dart';
import '../providers/auth_provider.dart';
import '../services/employee_consumption_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/modern_button.dart';
import '../widgets/status_badge.dart';
import 'create_employee_consumption_page.dart';

class EmployeeConsumptionDetailPage extends StatefulWidget {
  final int consumptionId;

  const EmployeeConsumptionDetailPage(
      {super.key, required this.consumptionId});

  @override
  State<EmployeeConsumptionDetailPage> createState() =>
      _EmployeeConsumptionDetailPageState();
}

class _EmployeeConsumptionDetailPageState
    extends State<EmployeeConsumptionDetailPage> {
  final EmployeeConsumptionService _service = EmployeeConsumptionService();
  EmployeeConsumptionModel? _item;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAdmin = false;
  bool _canManage = false;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _isAdmin = auth.isAdmin;
    _canManage =
        auth.hasAnyRole(['admin', 'super_admin', 'supervisor', 'staff']);
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await _service.getEmployeeConsumption(widget.consumptionId);
      if (!mounted) return;
      setState(() {
        _item = data;
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

  void _openEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => CreateEmployeeConsumptionPage(consumption: _item)),
    );
    if (result == true) _fetchDetail();
  }

  Future<void> _updateStatus(int status, String label) async {
    final isValid = status == 2;
    final confirmed = await showConfirmDialog(
      context,
      title: isValid ? 'Set Status Valid?' : 'Set Status Perbaiki?',
      content: isValid
          ? 'Sisa stok karyawan akan ditandai VALID dan terkunci dari perubahan.'
          : 'Sisa stok karyawan akan ditandai DIPERBAIKI.',
      confirmText: isValid ? 'Valid' : 'Perbaiki',
    );
    if (!confirmed) return;

    setState(() => _isUpdatingStatus = true);
    try {
      await _service.updateStatus(widget.consumptionId, status);
      if (!mounted) return;
      showSuccessSnackBar(
        context,
        'Status sisa stok karyawan diubah ke "$label".',
      );
      _fetchDetail();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  StatusType _statusType(int status) {
    switch (status) {
      case 2:
        return StatusType.success;
      case 3:
        return StatusType.neutral;
      case 4:
        return StatusType.error;
      default:
        return StatusType.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Sisa Stok Karyawan'),
        actions: [
          if (_canManage && _item != null && _item!.status != 2)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: _openEdit,
              tooltip: 'Edit',
            ),
        ],
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
                          onPressed: _fetchDetail,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _item == null
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
                          Container(
                            padding: AppSpacing.paddingMD,
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: AppSpacing.borderRadiusLG,
                              border: Border.all(
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _item!.storeName,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge(
                                      label: _item!.statusText,
                                      type: _statusType(_item!.status),
                                      size: BadgeSize.medium,
                                    ),
                                  ],
                                ),
                                AppSpacing.gapVerticalSM,
                                _buildInfoRow(
                                    'Tanggal', _formatDate(_item!.date), theme),
                                AppSpacing.gapVerticalSM,
                                _buildInfoRow('Dilaporkan oleh',
                                    _item!.createdByName, theme),
                                AppSpacing.gapVerticalSM,
                                _buildInfoRow('Jumlah item',
                                    '${_item!.details.length} jenis', theme),
                              ],
                            ),
                          ),
                          if (_isAdmin) ...[
                            AppSpacing.gapVerticalLG,
                            Text(
                              'Aksi Admin:',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppSpacing.gapVerticalSM,
                            Row(
                              children: [
                                Expanded(
                                  child: ModernButton(
                                    text: 'Set Valid',
                                    icon: Icons.verified_rounded,
                                    variant: ModernButtonVariant.outlined,
                                    onPressed: _isUpdatingStatus
                                        ? null
                                        : () => _updateStatus(2, 'Valid'),
                                  ),
                                ),
                                AppSpacing.gapHorizontalMD,
                                Expanded(
                                  child: ModernButton(
                                    text: 'Set Perbaiki',
                                    icon: Icons.build_rounded,
                                    variant: ModernButtonVariant.outlined,
                                    onPressed: _isUpdatingStatus
                                        ? null
                                        : () => _updateStatus(3, 'Diperbaiki'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          AppSpacing.gapVerticalLG,
                          Text(
                            'Item Sisa Stok:',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.gapVerticalSM,
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _item!.details.length,
                            itemBuilder: (context, idx) {
                              final item = _item!.details[idx];
                              return Container(
                                margin:
                                    const EdgeInsets.only(bottom: AppSpacing.sm),
                                padding: AppSpacing.paddingSM,
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: AppSpacing.borderRadiusMD,
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    item.productName,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 130),
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

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
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