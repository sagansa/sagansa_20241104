import 'package:flutter/material.dart';

import 'error_utils.dart';

/// Snackbar dengan teks selalu putih agar kontras di light & dark mode,
/// baik pada background sukses (hijau) maupun error (merah).
class SnackbarUtils {
  static void show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message, backgroundColor: const Color(0xFF4CAF50));
  }

  static void error(BuildContext context, dynamic message) {
    show(
      context,
      ErrorUtils.sanitize(message),
      backgroundColor: const Color(0xFFB71C1C),
    );
  }

  static void warning(BuildContext context, String message) {
    show(context, message, backgroundColor: const Color(0xFFFF9800));
  }
}
