import 'package:flutter/material.dart';

class CustomFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;

  const CustomFAB({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor = Colors.black,
    this.iconColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      tooltip: tooltip,
      child: Icon(
        icon,
        color: iconColor,
      ),
    );
  }
}
