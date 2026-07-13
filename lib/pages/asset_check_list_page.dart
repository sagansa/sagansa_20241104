import 'package:flutter/material.dart';
import '../controllers/asset_controller.dart';
import '../models/asset_check_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/modern_bottom_sheet.dart';

/// Riwayat semua pemeriksaan (cross-aset). Tap baris → bottom sheet detail.
class AssetCheckListPage extends StatefulWidget {
  const AssetCheckListPage({super.key, this.assetId});

  final int? assetId;

  @override
  State<AssetCheckListPage> createState() => _AssetCheckListPageState();
}

class _AssetCheckListPageState extends State<AssetCheckListPage> {
  late AssetController _controller;
  List<AssetCheckModel> _checks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AssetController(context);
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data =
          await _controller.loadChecks(assetId: widget.assetId);
      if (!mounted) return;
      setState(() {
        _checks = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _severityColor(int s) {
    switch (s) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.info;
      case 3:
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  void _showDetail(AssetCheckModel c) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    ModernBottomSheet.show(
      context: context,
      title: 'Pemeriksaan ${c.checkDate}',
      child: _buildCheckDetail(c, theme, colorScheme),
    );
  }

  Widget _buildCheckDetail(AssetCheckModel c, ThemeData theme, ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pemeriksa: ${c.checkedByName ?? '-'}',
            style: theme.textTheme.bodyMedium),
        Text('Severity: ${c.severityText}',
            style: theme.textTheme.bodyMedium),
        if (c.latitude != null && c.longitude != null)
          Text('Lokasi: ${c.latitude}, ${c.longitude}',
              style: theme.textTheme.bodySmall),
        if (c.photos.isNotEmpty) ...[
          AppSpacing.gapVerticalSM,
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: c.photos.length,
              separatorBuilder: (_, __) => AppSpacing.gapHorizontalSM,
              itemBuilder: (context, i) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: AppSpacing.borderRadiusSM,
                ),
                child: const Icon(Icons.image),
              ),
            ),
          ),
        ],
        if (c.items.isNotEmpty) ...[
          AppSpacing.gapVerticalSM,
          Text('Checklist:',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          ...c.items.map((it) => Row(
                children: [
                  Icon(
                    it.isOk ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: it.isOk
                        ? AppColors.success
                        : AppColors.error,
                    size: 18,
                  ),
                  AppSpacing.gapHorizontalXS,
                  Expanded(child: Text(it.label)),
                ],
              )),
        ],
        if (c.notes != null && c.notes!.isNotEmpty) ...[
          AppSpacing.gapVerticalSM,
          Text('Catatan: ${c.notes!}',
              style: theme.textTheme.bodyMedium),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pemeriksaan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      SizedBox(height: AppSpacing.sectionGap),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : _checks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history,
                              size: 48,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha:0.5)),
                          AppSpacing.gapVerticalSM,
                          Text('Belum ada riwayat pemeriksaan.',
                              style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: AppSpacing.screenPadding,
                        itemCount: _checks.length,
                        itemBuilder: (context, i) {
                          final c = _checks[i];
                          return Card(
                            margin: EdgeInsets.only(bottom: AppSpacing.itemGap),
                            child: ListTile(
                              onTap: () => _showDetail(c),
                              title: Text(c.checkDate,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${c.checkedByName ?? '-'} • ${c.severityText}',
                                style: theme.textTheme.bodySmall,
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color:
                                      _severityColor(c.severity).withValues(alpha:0.15),
                                  borderRadius: AppSpacing.borderRadiusMD,
                                ),
                                child: Text(
                                  '${c.items.where((e) => !e.isOk).length} not-ok',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: _severityColor(c.severity),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
