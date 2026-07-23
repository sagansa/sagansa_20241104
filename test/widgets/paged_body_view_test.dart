import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/widgets/paged_body_view.dart';

void main() {
  Widget buildScaffold(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('PagedBodyView', () {
    testWidgets('shows spinner on initial loading (items empty)', (tester) async {
      await tester.pumpWidget(buildScaffold(
        PagedBodyView<String>(
          isLoading: true,
          error: null,
          items: const [],
          itemBuilder: (_, __) => const SizedBox(),
          onRefresh: () async {},
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows ErrorState when error and items empty', (tester) async {
      await tester.pumpWidget(buildScaffold(
        PagedBodyView<String>(
          isLoading: false,
          error: 'Gagal memuat',
          items: const [],
          itemBuilder: (_, __) => const SizedBox(),
          onRefresh: () async {},
        ),
      ));

      expect(find.text('Gagal memuat'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('shows EmptyState when items empty and not loading',
        (tester) async {
      await tester.pumpWidget(buildScaffold(
        PagedBodyView<String>(
          isLoading: false,
          error: null,
          items: const [],
          itemBuilder: (_, __) => const SizedBox(),
          onRefresh: () async {},
          emptyIcon: Icons.inbox,
          emptyTitle: 'Tidak ada data',
        ),
      ));

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('Tidak ada data'), findsOneWidget);
    });

    testWidgets('shows data list when items present', (tester) async {
      await tester.pumpWidget(buildScaffold(
        PagedBodyView<String>(
          isLoading: false,
          error: null,
          items: const ['A', 'B', 'C'],
          itemBuilder: (ctx, i) => Text('item-$i'),
          onRefresh: () async {},
        ),
      ));

      expect(find.text('item-0'), findsOneWidget);
      expect(find.text('item-1'), findsOneWidget);
      expect(find.text('item-2'), findsOneWidget);
    });

    testWidgets('shows loading footer when hasMore is true', (tester) async {
      await tester.pumpWidget(buildScaffold(
        SizedBox(
          height: 400,
          child: PagedBodyView<String>(
            isLoading: false,
            error: null,
            items: const ['A'],
            itemBuilder: (ctx, i) => const SizedBox(
              height: 200,
              child: Text('item'),
            ),
            onRefresh: () async {},
            hasMore: true,
            onLoadMore: () async {},
          ),
        ),
      ));

      // Footer loading indicator appears after the data items.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not show footer when hasMore is false', (tester) async {
      await tester.pumpWidget(buildScaffold(
        SizedBox(
          height: 400,
          child: PagedBodyView<String>(
            isLoading: false,
            error: null,
            items: const ['A'],
            itemBuilder: (ctx, i) => const SizedBox(
              height: 200,
              child: Text('item'),
            ),
            onRefresh: () async {},
            hasMore: false,
          ),
        ),
      ));

      // No loading indicator (footer) when no more pages.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders sliverHeader above list', (tester) async {
      await tester.pumpWidget(buildScaffold(
        SizedBox(
          height: 600,
          child: PagedBodyView<String>(
            isLoading: false,
            error: null,
            items: const ['A', 'B'],
            itemBuilder: (ctx, i) => const SizedBox(
              height: 100,
              child: Text('item'),
            ),
            onRefresh: () async {},
            sliverHeader: const SliverToBoxAdapter(
              child: Text('HEADER'),
            ),
          ),
        ),
      ));

      expect(find.text('HEADER'), findsOneWidget);
      expect(find.text('item'), findsNWidgets(2));
    });
  });
}
