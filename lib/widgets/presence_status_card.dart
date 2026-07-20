import 'package:flutter/material.dart';
import '../services/presence_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class PresenceStatusCard extends StatelessWidget {
  const PresenceStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final now = DateTime.now();
    final sixAM = DateTime(now.year, now.month, now.day, 6, 0);
    final isAfterSixAM = now.isAfter(sixAM);

    return Card(
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: FutureBuilder<Map<String, dynamic>>(
          future: PresenceService().getUserPresence(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Gagal memuat status presensi',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Text(
                  'Tidak ada data presensi',
                  style: textTheme.bodyMedium,
                ),
              );
            }

            final today = snapshot.data!['today'];
            final hasCheckIn = today != null && today['check_in'] != null;

            if (!isAfterSixAM && !hasCheckIn) {
              return Center(
                child: Text(
                  'Status presensi akan tersedia mulai jam 06:00',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (isAfterSixAM && !hasCheckIn) {
              return Center(
                child: Text(
                  'Belum ada presensi untuk hari ini',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Presensi Hari Ini',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.gapVerticalMD,
                _buildStatusRow(
                  context,
                  'Check In',
                  today['check_in'] ?? '-',
                  today['check_in_status'],
                ),
                AppSpacing.gapVerticalSM,
                _buildStatusRow(
                  context,
                  'Check Out',
                  today['check_out'] ?? '-',
                  today['check_out_status'],
                ),
                if (today['late_minutes'] != null) ...[
                  AppSpacing.gapVerticalSM,
                  Text(
                    'Keterlambatan: ${today['late_minutes'].toString()} menit',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    BuildContext context,
    String label,
    String time,
    String? status,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    Color statusColor;
    if (status == 'tepat_waktu') {
      statusColor = AppColors.success;
    } else if (status == 'terlambat') {
      statusColor = colorScheme.error;
    } else {
      statusColor = AppColors.info;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium),
        Row(
          children: [
            Text(time, style: textTheme.bodyMedium),
            if (status != null) ...[
              AppSpacing.gapHorizontalSM,
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusMD,
                ),
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
