import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/widgets/filter_chip_row.dart';
import 'package:sagansa/widgets/section_card.dart';

void main() {
  group('FilterChipRow', () {
    testWidgets('renders all options as ChoiceChips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterChipRow<String>(
              options: const ['Semua', 'Pending', 'Lunas'],
              selected: null,
              onSelected: (_) {},
              getLabel: (s) => s,
            ),
          ),
        ),
      );

      expect(find.byType(ChoiceChip), findsNWidgets(3));
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Lunas'), findsOneWidget);
    });

    testWidgets('marks selected option as selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterChipRow<String>(
              options: const ['A', 'B', 'C'],
              selected: 'B',
              onSelected: (_) {},
              getLabel: (s) => s,
            ),
          ),
        ),
      );

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final bChip = chips.elementAt(1);
      expect(bChip.selected, isTrue);
    });

    testWidgets('calls onSelected with option when chip tapped', (tester) async {
      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterChipRow<String>(
              options: const ['A', 'B'],
              selected: null,
              onSelected: (val) => result = val,
              getLabel: (s) => s,
            ),
          ),
        ),
      );

      await tester.tap(find.text('B'));
      await tester.pump();

      expect(result, 'B');
    });

    testWidgets('calls onSelected with null when selected chip tapped again',
        (tester) async {
      String? result = 'initial';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterChipRow<String>(
              options: const ['A'],
              selected: 'A',
              onSelected: (val) => result = val,
              getLabel: (s) => s,
            ),
          ),
        ),
      );

      await tester.tap(find.text('A'));
      await tester.pump();

      expect(result, isNull);
    });

    testWidgets('uses Wrap when scrollable false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterChipRow<String>(
              options: const ['A', 'B'],
              selected: null,
              onSelected: (_) {},
              getLabel: (s) => s,
              scrollable: false,
            ),
          ),
        ),
      );

      expect(find.byType(Wrap), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
    });
  });

  group('SectionCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionCard(
              child: const Text('Body content'),
            ),
          ),
        ),
      );

      expect(find.text('Body content'), findsOneWidget);
    });

    testWidgets('renders title when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionCard(
              title: 'Transaction Details',
              child: const SizedBox(),
            ),
          ),
        ),
      );

      expect(find.text('Transaction Details'), findsOneWidget);
    });

    testWidgets('renders icon header when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionCard(
              title: 'Test',
              icon: Icons.person,
              child: const SizedBox(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders actions when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionCard(
              title: 'Test',
              actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.edit))],
              child: const SizedBox(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionCard(
              onTap: () => tapped = true,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not render header divider when no title/icon',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionCard(
              child: const Text('No header'),
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsNothing);
    });
  });
}
