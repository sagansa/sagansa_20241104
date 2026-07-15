import 'package:flutter/material.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmText = 'Ya',
  String cancelText = 'Batal',
  bool isDestructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: isDestructive ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
          ),
          child: Text(
            confirmText,
            style: TextStyle(
              fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<bool> showConfirmExitDialog(BuildContext context) async {
  return showConfirmDialog(
    context,
    title: 'Konfirmasi',
    content: 'Apakah Anda yakin ingin keluar?',
    confirmText: 'Keluar',
  );
}

Future<void> showErrorDialog(BuildContext context, String message) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Gagal'),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}
