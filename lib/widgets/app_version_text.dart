import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_spacing.dart';

/// Menampilkan versi aplikasi sesuai [pubspec.yaml] (`version: 1.2.1+6`).
///
/// Membaca data dari [PackageInfo.fromPlatform] (otomatis sinkron dengan
/// pubspec.yaml saat build), sehingga tidak perlu hard-code angka versi.
/// Format tampilan: `v1.2.1 (build 6)`.
class AppVersionText extends StatefulWidget {
  const AppVersionText({super.key});

  @override
  State<AppVersionText> createState() => _AppVersionTextState();
}

class _AppVersionTextState extends State<AppVersionText> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _info = info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final version = _info?.version;
    final buildNumber = _info?.buildNumber;

    final label = (version == null || version.isEmpty)
        ? 'v-'
        : 'v$version${(buildNumber == null || buildNumber.isEmpty) ? '' : ' (build $buildNumber)'}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
