import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/presence_model.dart';
import '../../../providers/home_dashboard_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Section presensi user (clock in / clock out) di dashboard staff.
///
/// Subscribe ke [HomeDashboardProvider.presence.todayPresence] via
/// `context.select`. Tombol clock in/out memanggil [onNavigateToPresence]
/// yang dibawa dari parent.
class HomePresenceSection extends StatelessWidget {
  /// Callback saat tombol clock in/out ditekan (navigasi ke PresencePage).
  final VoidCallback onNavigateToPresence;

  const HomePresenceSection({super.key, required this.onNavigateToPresence});

  @override
  Widget build(BuildContext context) {
    final todayPresence = context.select<HomeDashboardProvider, PresenceModel?>(
        (p) => p.presence.todayPresence);

    if (todayPresence != null) {
      if (todayPresence.checkOut != null) {
        // Bila hari ini sudah clock out maka tidak menampilkan apapun.
        return const SizedBox.shrink();
      }
      return _PresenceCard(
        presence: todayPresence,
        onClockOut: onNavigateToPresence,
      );
    }

    return _EmptyPresenceCard(onClockIn: onNavigateToPresence);
  }
}

class _PresenceCard extends StatelessWidget {
  final PresenceModel presence;
  final VoidCallback onClockOut;

  const _PresenceCard({required this.presence, required this.onClockOut});

  Map<String, String> _splitDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    return {
      'date':
          '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}',
      'time':
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final checkInDateTime = _splitDateTime(presence.checkIn);
    final checkOutDateTime = presence.checkOut != null
        ? _splitDateTime(presence.checkOut!)
        : null;

    return Card(
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          children: [
            Text(
              presence.store,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              presence.shiftStore,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVerticalMD,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check In',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.gapVerticalSM,
                      _StatusBadge(
                        color: presence.getStatusColor(presence.checkInStatus),
                        text: presence.getStatusText(presence.checkInStatus),
                      ),
                      AppSpacing.gapVerticalSM,
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: colorScheme.onSurfaceVariant),
                          AppSpacing.gapHorizontalXS,
                          Text(
                            checkInDateTime['date']!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: colorScheme.onSurfaceVariant),
                          AppSpacing.gapHorizontalXS,
                          Text(
                            checkInDateTime['time']!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 80,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Check Out',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.gapVerticalSM,
                      if (presence.checkOut != null) ...[
                        _StatusBadge(
                          color:
                              presence.getStatusColor(presence.checkOutStatus),
                          text: presence.getStatusText(presence.checkOutStatus),
                        ),
                        AppSpacing.gapVerticalSM,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              checkOutDateTime!['date']!,
                              style: theme.textTheme.bodySmall,
                            ),
                            AppSpacing.gapHorizontalXS,
                            Icon(Icons.calendar_today,
                                size: 14,
                                color: colorScheme.onSurfaceVariant),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              checkOutDateTime['time']!,
                              style: theme.textTheme.bodySmall,
                            ),
                            AppSpacing.gapHorizontalXS,
                            Icon(Icons.access_time,
                                size: 14,
                                color: colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ] else ...[
                        _StatusBadge(
                          color: AppColors.warning,
                          text: 'Belum',
                        ),
                        AppSpacing.gapVerticalSM,
                        Text(
                          'Belum Absen Pulang',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
            if (presence.checkOut == null) ...[
              AppSpacing.gapVerticalMD,
              ElevatedButton.icon(
                onPressed: onClockOut,
                icon: Icon(Icons.logout, color: AppColors.onError),
                label: const Text(
                  'CLOCK OUT / ABSEN KELUAR',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.onError,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyPresenceCard extends StatelessWidget {
  final VoidCallback onClockIn;
  const _EmptyPresenceCard({required this.onClockIn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Container(
        padding: AppSpacing.paddingXL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fingerprint_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            AppSpacing.gapVerticalMD,
            Text(
              'Belum ada presensi untuk hari ini',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapVerticalSM,
            Text(
              'Silakan lakukan presensi masuk terlebih dahulu.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            AppSpacing.gapVerticalLG,
            ElevatedButton.icon(
              onPressed: onClockIn,
              icon: Icon(Icons.login, color: AppColors.onSuccess),
              label: const Text(
                'CLOCK IN / ABSEN MASUK',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.onSuccess,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Color color;
  final String text;
  const _StatusBadge({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusSM,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
