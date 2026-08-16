import 'package:flutter/material.dart';

import '../models/delivery_address_model.dart';
import '../services/delivery_address_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/error_utils.dart';
import '../utils/snackbar_utils.dart';
import 'delivery_address_form_page.dart';

/// Daftar calon konsumen (DeliveryAddress) milik user sales.
///
/// Tap item → edit. FAB "+" → tambah baru. Hapus via ikon trash dengan
/// konfirmasi. Di-embed di [SalesHomePage] dengan `showAppBar: false`.
class DeliveryAddressListPage extends StatefulWidget {
  /// Set false saat di-embed di [SalesHomePage] agar tidak muncul AppBar
  /// ganda (halaman induk sudah punya AppBar + tab bar).
  final bool showAppBar;

  const DeliveryAddressListPage({super.key, this.showAppBar = true});

  @override
  State<DeliveryAddressListPage> createState() =>
      _DeliveryAddressListPageState();
}

class _DeliveryAddressListPageState extends State<DeliveryAddressListPage> {
  final DeliveryAddressService _service = DeliveryAddressService();

  List<DeliveryAddressModel> _items = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _service.getList();
      if (!mounted) return;
      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorUtils.sanitize(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<DeliveryAddressModel>(
      context,
      MaterialPageRoute(builder: (_) => const DeliveryAddressFormPage()),
    );
    if (created != null) _loadData();
  }

  Future<void> _openEdit(DeliveryAddressModel address) async {
    final updated = await Navigator.push<DeliveryAddressModel>(
      context,
      MaterialPageRoute(
          builder: (_) => DeliveryAddressFormPage(address: address)),
    );
    if (updated != null) _loadData();
  }

  Future<void> _confirmDelete(DeliveryAddressModel address) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Konsumen?'),
        content: Text(
            'Konsumen "${address.displayName}" akan dihapus. Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.delete(address.id);
      if (!mounted) return;
      SnackbarUtils.success(context, 'Konsumen dihapus.');
      _loadData();
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.error(
          context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text('Konsumen')) : null,
      body: _buildBody(theme, colorScheme),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _openCreate,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              AppSpacing.gapVerticalSM,
              FilledButton(
                onPressed: _loadData,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add_alt_outlined,
                  size: 48, color: colorScheme.onSurfaceVariant),
              AppSpacing.gapVerticalSM,
              Text(
                'Belum ada konsumen. Tap + untuk menambahkan.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: AppSpacing.paddingHorizontalMD,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) {
          final a = _items[index];
          return _CustomerTile(
            address: a,
            onTap: () => _openEdit(a),
            onDelete: () => _confirmDelete(a),
          );
        },
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final DeliveryAddressModel address;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _CustomerTile({
    required this.address,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: AppElevation.level1,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: AppSpacing.borderRadiusMD,
                ),
                child: Icon(Icons.person_outline,
                    color: cs.primary, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.displayName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (address.recipientName.isNotEmpty &&
                        address.recipientName != address.name)
                      Text(
                        address.recipientName,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (address.recipientTelpNo.isNotEmpty)
                      Text(
                        address.recipientTelpNo,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (address.address.isNotEmpty)
                      Text(
                        address.address,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (address.subdistrictName != null ||
                        address.cityName != null)
                      Text(
                        [
                          address.subdistrictName,
                          address.districtName,
                          address.cityName,
                          address.provinceName,
                        ]
                            .whereType<String>()
                            .where((s) => s.isNotEmpty)
                            .join(', '),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}