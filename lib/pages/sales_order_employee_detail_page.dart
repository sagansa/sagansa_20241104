import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sales_order_employee_model.dart';
import '../services/sales_order_employee_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/format_utils.dart';
import '../utils/snackbar_utils.dart';
import 'sales_order_employee_form_page.dart';

/// Detail penjualan employee.
///
/// - Role admin/super_admin: tombol "Ubah Status" (bottom sheet 1..4), tombol "Hapus".
/// - Role sales pemilik (canEdit=true & !isLocked): tombol "Edit" & "Hapus".
class SalesOrderEmployeeDetailPage extends StatefulWidget {
  final int orderId;
  final bool canEdit; // true untuk sales; admin tidak create/edit via mobile

  const SalesOrderEmployeeDetailPage({
    super.key,
    required this.orderId,
    required this.canEdit,
  });

  @override
  State<SalesOrderEmployeeDetailPage> createState() =>
      _SalesOrderEmployeeDetailPageState();
}

class _SalesOrderEmployeeDetailPageState
    extends State<SalesOrderEmployeeDetailPage> {
  final SalesOrderEmployeeService _service = SalesOrderEmployeeService();
  SalesOrderEmployeeModel? _order;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  /// True jika ada mutasi yang mempengaruhi list (status / edit / hapus).
  /// Dikirim balik ke list page lewat Navigator.pop(true) agar list di-refresh.
  bool _dirty = false;

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRoles();
    _loadOrder();
  }

  Future<void> _loadRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      final userData = json.decode(userString);
      final roles = List<String>.from(userData['roles'] ?? []);
      if (mounted) {
        setState(() {
          _isAdmin = roles.contains('admin') || roles.contains('super_admin');
        });
      }
    }
  }

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final o = await _service.getDetail(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = o;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// Sales hanya boleh edit/hapus jika pemilik & belum valid. Admin selalu boleh hapus.
  bool get _canEdit =>
      widget.canEdit && _order != null && !_order!.isLocked;
  bool get _canDelete => _isAdmin || _canEdit;

  Future<void> _openEdit() async {
    if (_order == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) =>
              SalesOrderEmployeeFormPage(order: _order)),
    );
    if (result == true) {
      _dirty = true;
      _loadOrder();
    }
  }

  Future<void> _confirmDelete() async {
    if (_order == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Penjualan?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await _service.delete(_order!.id);
      if (!mounted) return;
      SnackbarUtils.success(context, 'Penjualan dihapus.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openStatusSheet() async {
    if (_order == null) return;
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) {
        final options = [
          (1, 'Belum Diperiksa', AppColors.onSurfaceVariant),
          (2, 'Valid', AppColors.success),
          (3, 'Tidak Valid', AppColors.error),
          (4, 'Periksa Ulang', AppColors.warning),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: AppSpacing.paddingMD,
                child: Text('Status Pembayaran',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Divider(height: 1),
              ...options.map((o) {
                return RadioListTile<int>(
                  value: o.$1,
                  groupValue: _order!.paymentStatus,
                  title: Text(o.$2),
                  onChanged: (_) => Navigator.pop(ctx, o.$1),
                  activeColor: o.$3,
                  // tandai pilihan saat ini via value/groupValue
                  controlAffinity: ListTileControlAffinity.trailing,
                );
              }),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == _order!.paymentStatus) return;

    setState(() => _busy = true);
    try {
      final updated = await _service.updatePaymentStatus(_order!.id, selected);
      if (!mounted) return;
      setState(() {
        _order = updated;
        _dirty = true;
      });
      SnackbarUtils.success(context, 'Status pembayaran diperbarui.');
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      // Saat user tekan back, kirim _dirty agar list tahu perlu refresh.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context, _dirty);
      },
      child: Scaffold(
      appBar: AppBar(title: const Text('Detail Penjualan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBody(message: _error!, onRetry: _loadOrder)
              : _order == null
                  ? const Center(child: Text('Data tidak ditemukan.'))
                  : RefreshIndicator(
                      onRefresh: _loadOrder,
                      child: ListView(
                        padding: AppSpacing.paddingMD,
                        children: [
                          _buildHeader(context),
                          AppSpacing.gapVerticalMD,
                          _buildInfoCard(context),
                          AppSpacing.gapVerticalMD,
                          _buildItemsCard(context),
                          AppSpacing.gapVerticalMD,
                          _buildImageCard(context),
                          AppSpacing.gapVerticalLG,
                          _buildActions(context),
                        ],
                      ),
                    ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final o = _order!;
    final color = _statusColor(cs);
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.deliveryAddressName ?? o.storeName ?? '-',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  if (o.orderedByName != null) ...[
                    const SizedBox(height: 2),
                    Text('oleh ${o.orderedByName}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: AppSpacing.borderRadiusSM,
              ),
              child: Text(
                o.paymentStatusLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final o = _order!;
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          children: [
            _infoRow(context, 'Toko', o.storeName ?? '-'),
            _divider(),
            _infoRow(
                context,
                'Tanggal',
                o.deliveryDate != null
                    ? FormatUtils.formatDate(o.deliveryDate!)
                    : '-'),
            _divider(),
            _infoRow(context, 'Rekening Tujuan',
                o.transferToAccountName ?? '-'),
            _divider(),
            _infoRow(context, 'Alamat Pengiriman',
                o.deliveryAddressName ?? '-'),
            if (o.notes != null && o.notes!.isNotEmpty) ...[
              _divider(),
              _infoRow(context, 'Catatan', o.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context) {
    final o = _order!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item Penjualan',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.gapVerticalSM,
            ...o.items.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${i.productName}${i.productUnit != null ? ' (${i.productUnit})' : ''}',
                                style: theme.textTheme.bodyMedium),
                            Text(
                                '${i.quantity} × ${FormatUtils.formatCurrency(i.unitPrice)}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Text(FormatUtils.formatCurrency(i.subtotalPrice),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(FormatUtils.formatCurrency(o.totalPrice),
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(BuildContext context) {
    final o = _order!;
    final theme = Theme.of(context);
    if (o.imagePaymentUrl == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bukti Transfer',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.gapVerticalSM,
            ClipRRect(
              borderRadius: AppSpacing.borderRadiusMD,
              child: Image.network(
                o.imagePaymentUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                      child: Icon(Icons.image_not_supported_outlined)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final children = <Widget>[];
    if (_isAdmin) {
      children.add(
        FilledButton.tonalIcon(
          onPressed: _busy ? null : _openStatusSheet,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Ubah Status'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      );
    }
    if (_canEdit) {
      if (children.isNotEmpty) children.add(AppSpacing.gapVerticalSM);
      children.add(
        FilledButton.icon(
          onPressed: _busy ? null : _openEdit,
          icon: const Icon(Icons.edit),
          label: const Text('Edit Penjualan'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      );
    }
    if (_canDelete) {
      if (children.isNotEmpty) children.add(AppSpacing.gapVerticalSM);
      children.add(
        OutlinedButton.icon(
          onPressed: _busy ? null : _confirmDelete,
          icon: _busy
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.delete_outline, color: AppColors.error),
          label: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      );
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(children: children);
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Divider(height: 1),
      );

  Color _statusColor(ColorScheme cs) {
    switch (_order!.paymentStatus) {
      case 2:
        return AppColors.success;
      case 3:
        return AppColors.error;
      case 4:
        return AppColors.warning;
      default:
        return cs.onSurfaceVariant;
    }
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            AppSpacing.gapVerticalSM,
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
