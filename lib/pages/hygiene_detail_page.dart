import 'package:flutter/material.dart';
import '../models/hygiene_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/format_utils.dart';

/// Detail dari sebuah laporan kebersihan: info toko/tanggal/status +
/// daftar tiap ruangan beserta foto, kondisi, dan catatan.
///
/// Menerima [HygieneModel] yang sudah dimuat dari list (backend `index()`
/// sudah eager-load rooms + store + created/approved by), jadi tidak perlu
/// fetch ulang.
class HygieneDetailPage extends StatelessWidget {
  final HygieneModel hygiene;

  const HygieneDetailPage({super.key, required this.hygiene});

  String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.success;
      case 3:
        return AppColors.error;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  Color _conditionColor(int? condition) {
    switch (condition) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.error;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dirtyCount = hygiene.rooms
        .where((r) => r.condition == 3 || r.condition == 2)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kebersihan')),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              child: Padding(
                padding: AppSpacing.paddingMD,
                child: Column(
                  children: [
                    _buildInfoRow(
                        'Toko', hygiene.storeName ?? '-', theme),
                    const Divider(height: 20),
                    _buildInfoRow('Tanggal', _formatDate(hygiene.createdAt), theme),
                    const Divider(height: 20),
                    _buildInfoRow(
                        'Dilaporkan oleh', hygiene.createdByName ?? '-', theme),
                    if (hygiene.approvedByName != null) ...[
                      const Divider(height: 20),
                      _buildInfoRow(
                          'Disetujui oleh', hygiene.approvedByName!, theme),
                    ],
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: _statusColor(hygiene.status)
                                .withValues(alpha: 0.1),
                            borderRadius: AppSpacing.borderRadiusXL,
                          ),
                          child: Text(
                            hygiene.statusLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _statusColor(hygiene.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (hygiene.notes != null && hygiene.notes!.isNotEmpty) ...[
              AppSpacing.gapVerticalMD,
              Card(
                child: Padding(
                  padding: AppSpacing.paddingMD,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catatan',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      AppSpacing.gapVerticalSM,
                      Text(
                        FormatUtils.stripHtml(hygiene.notes!),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            AppSpacing.gapVerticalLG,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Ruangan',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (dirtyCount > 0)
                  Text(
                    '$dirtyCount perlu perhatian',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            AppSpacing.gapVerticalSM,
            if (hygiene.rooms.isEmpty)
              Center(
                child: Padding(
                  padding: AppSpacing.paddingLG,
                  child: Text(
                    'Tidak ada data ruangan.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              )
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.itemGap,
                crossAxisSpacing: AppSpacing.itemGap,
                childAspectRatio: 0.72,
                children: hygiene.rooms.map((room) {
                  final imageUrl = room.imageUrl;
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Penanda status di pojok atas gambar.
                        Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 1.4,
                              child: imageUrl != null
                                  ? GestureDetector(
                                      onTap: () =>
                                          _showImage(context, imageUrl),
                                      child: Image.network(
                                        imageUrl,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                          color: colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.3),
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        loadingBuilder: (_, child, progress) {
                                          if (progress == null) return child;
                                          return Container(
                                            color: colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.3),
                                            child: const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _conditionColor(room.condition)
                                      .withValues(alpha: 0.9),
                                  borderRadius: AppSpacing.borderRadiusMD,
                                ),
                                child: Text(
                                  room.conditionLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: AppSpacing.paddingSM,
                          child: Text(
                            room.roomName ?? 'Ruangan',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (room.notes != null && room.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm),
                            child: Text(
                              room.notes!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showImage(BuildContext context, String url) {
    final colorScheme = Theme.of(context).colorScheme;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.87),
            iconTheme: IconThemeData(color: colorScheme.surface),
            title: Text('Foto Ruangan',
                style: TextStyle(color: colorScheme.surface)),
          ),
          body: Container(
            color: Colors.black,
            child: Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.broken_image,
                    color: colorScheme.surface.withValues(alpha: 0.54),
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
