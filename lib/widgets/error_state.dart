import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'empty_state.dart';

/// Error state dengan retry button. Turunan pola [EmptyState].
///
/// Digunakan ketika request API gagal — menampilkan icon error (merah),
/// pesan error, dan tombol "Coba Lagi" untuk retry.
///
/// Contoh pemakaian:
/// ```dart
/// ErrorState(
///   message: 'Gagal memuat data',
///   onRetry: _loadData,
/// )
/// ```
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      iconColor: AppColors.error,
      title: message,
      action: onRetry != null
          ? ElevatedButton(
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            )
          : null,
    );
  }
}
