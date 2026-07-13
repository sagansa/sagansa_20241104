import 'package:flutter/material.dart';
import '../controllers/asset_controller.dart';
import '../models/asset_issue_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'asset_detail_page.dart';

/// Daftar issue (default: open) + aksi tutup issue.
class AssetIssuePage extends StatefulWidget {
  const AssetIssuePage({super.key});

  @override
  State<AssetIssuePage> createState() => _AssetIssuePageState();
}

class _AssetIssuePageState extends State<AssetIssuePage> {
  late AssetController _controller;
  List<AssetIssueModel> _issues = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _statusFilter = 1; // default open

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
      final data = await _controller.loadIssues(status: _statusFilter);
      if (!mounted) return;
      setState(() {
        _issues = data;
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

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Aset'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + AppSpacing.xs, vertical: AppSpacing.xs),
            child: Row(
              children: [
                _FilterTab(
                    label: 'Open',
                    selected: _statusFilter == 1,
                    colorScheme: colorScheme,
                    onTap: () {
                      setState(() => _statusFilter = 1);
                      _load();
                    }),
                AppSpacing.gapHorizontalSM,
                _FilterTab(
                    label: 'Closed',
                    selected: _statusFilter == 2,
                    colorScheme: colorScheme,
                    onTap: () {
                      setState(() => _statusFilter = 2);
                      _load();
                    }),
              ],
            ),
          ),
        ),
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
              : _issues.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.task_alt_rounded,
                              size: 48,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha:0.5)),
                          AppSpacing.gapVerticalSM,
                          Text(
                            _statusFilter == 1
                                ? 'Tidak ada issue terbuka.'
                                : 'Tidak ada issue yang sudah closed.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: AppSpacing.screenPadding,
                        itemCount: _issues.length,
                        itemBuilder: (context, i) {
                          final issue = _issues[i];
                          return Card(
                            margin: EdgeInsets.only(bottom: AppSpacing.itemGap),
                            child: ListTile(
                              onTap: () {
                                if (issue.assetId != 0) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AssetDetailPage(
                                          assetId: issue.assetId),
                                    ),
                                  );
                                }
                              },
                              title: Text(
                                issue.assetName ?? 'Aset #${issue.assetId}',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    issue.description ??
                                        'Tidak ada deskripsi',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  AppSpacing.gapVerticalXS,
                                  Text(
                                    issue.isOpen
                                        ? 'Dilaporkan: ${issue.createdAt ?? '-'}'
                                        : 'Ditutup: ${issue.resolvedAt ?? '-'}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              trailing: issue.isOpen
                                  ? TextButton(
                                      onPressed: () async {
                                        try {
                                          await _controller.closeIssue(issue.id);
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content:
                                                    Text('Issue ditutup.')),
                                          );
                                          _load();
                                        } catch (e) {
                                          _showError(e
                                              .toString()
                                              .replaceFirst(
                                                  'Exception: ', ''));
                                        }
                                      },
                                      child: const Text('Tutup'),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                      decoration: BoxDecoration(
                                        color: AppColors.success
                                            .withValues(alpha:0.15),
                                        borderRadius:
                                            AppSpacing.borderRadiusMD,
                                      ),
                                      child: Text(
                                        'Closed',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: AppColors.success,
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

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusXL,
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color:
                selected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
