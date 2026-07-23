import 'package:flutter/material.dart';

/// Sliver list dengan infinite scroll generik.
///
/// Melakukan attach [ScrollController] listener yang trigger [onLoadMore]
/// ketika user scroll mendekati bottom (default 200px sebelum edge).
/// Render loading footer otomatis saat [hasMore] == true.
///
/// Dipakai di dalam [PagedBodyView] atau langsung di `CustomScrollView`.
///
/// Contoh:
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverToBoxAdapter(child: searchBar),
///     PagedSliverList<MyItem>(
///       items: items,
///       itemBuilder: (ctx, i) => MyItemCard(items[i]),
///       hasMore: hasMore,
///       onLoadMore: () => provider.loadMore(),
///     ),
///   ],
/// )
/// ```
class PagedSliverList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, int) itemBuilder;

  /// Apakah masih ada halaman berikutnya. Jika true, footer loading muncul.
  final bool hasMore;

  /// Dipanggil saat user scroll mendekati bottom.
  final Future<void> Function() onLoadMore;

  /// ScrollController eksternal (e.g., dari parent). Jika null, buat sendiri.
  final ScrollController? controller;

  /// Jarak dari bottom (dalam pixel) yang trigger onLoadMore. Default 200.
  final double loadMoreThreshold;

  /// Builder custom untuk loading footer. Default: CircularProgressIndicator.
  final Widget Function(BuildContext)? loadingMoreBuilder;

  const PagedSliverList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.hasMore,
    required this.onLoadMore,
    this.controller,
    this.loadMoreThreshold = 200,
    this.loadingMoreBuilder,
  });

  @override
  State<PagedSliverList<T>> createState() => _PagedSliverListState<T>();
}

class _PagedSliverListState<T> extends State<PagedSliverList<T>> {
  ScrollController? _internalController;
  bool _isLoadingMore = false;

  ScrollController get _effectiveController =>
      widget.controller ?? (_internalController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _effectiveController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant PagedSliverList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onScroll);
      _effectiveController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onScroll);
    _internalController?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !widget.hasMore) return;

    final position = _effectiveController.position;
    if (position.pixels >= position.maxScrollExtent - widget.loadMoreThreshold) {
      _triggerLoadMore();
    }
  }

  Future<void> _triggerLoadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      await widget.onLoadMore();
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, index) {
          // Footer loading di index terakhir jika hasMore.
          if (index == widget.items.length) {
            return widget.loadingMoreBuilder?.call(ctx) ??
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
          }
          return widget.itemBuilder(ctx, index);
        },
        childCount: widget.items.length + (widget.hasMore ? 1 : 0),
      ),
    );
  }
}
