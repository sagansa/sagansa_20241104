import 'package:flutter/material.dart';

/// AppBar action untuk search toggle.
/// Tap → toggle inline search bar di body.
class SearchAppBarAction extends StatelessWidget {
  final bool isSearchActive;
  final VoidCallback onTap;

  const SearchAppBarAction({
    super.key,
    required this.isSearchActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isSearchActive ? Icons.search_off : Icons.search),
      tooltip: isSearchActive ? 'Tutup Pencarian' : 'Cari',
      onPressed: onTap,
    );
  }
}
