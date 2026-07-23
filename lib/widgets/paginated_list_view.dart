import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, int) itemBuilder;
  final bool hasMore;
  final Future<void> Function() onLoadMore;
  final Widget Function(BuildContext)? loadingMoreBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final double loadMoreThreshold;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.hasMore,
    required this.onLoadMore,
    this.loadingMoreBuilder,
    this.controller,
    this.padding,
    this.loadMoreThreshold = 200,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  late ScrollController _controller;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
    if (widget.controller == null) {
      _controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.removeListener(_onScroll);
      _controller.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    if (_controller.position.pixels >=
            _controller.position.maxScrollExtent - widget.loadMoreThreshold &&
        !_isLoadingMore &&
        widget.hasMore) {
      setState(() => _isLoadingMore = true);
      widget.onLoadMore().then((_) {
        if (mounted) setState(() => _isLoadingMore = false);
      }).catchError((_) {
        if (mounted) setState(() => _isLoadingMore = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      padding: widget.padding ?? AppSpacing.paddingMD,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.items.length) {
          if (widget.loadingMoreBuilder != null) {
            return widget.loadingMoreBuilder!(context);
          }
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.itemBuilder(context, index);
      },
    );
  }
}
