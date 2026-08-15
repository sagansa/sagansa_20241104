import 'package:flutter/material.dart';

import '../widgets/safe_bottom_bar.dart';

class AddFab extends StatelessWidget {
  final VoidCallback onPressed;

  const AddFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: context.systemBottomInset + 8,
        right: 8,
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
