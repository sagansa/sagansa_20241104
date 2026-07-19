import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/widgets/procurement_subfilter_chips.dart';
import 'package:sagansa/providers/theme_provider.dart';

void main() {
  group('ProcurementSubfilterChips', () {
    testWidgets('render chips sesuai opsi yang diberikan',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: const Scaffold(
            body: ProcurementSubfilterChips(
              options: ['Semua', 'Siap Invoice', 'Sudah Jadi Invoice'],
              activeIndex: 0,
              activeColor: Color(0xFFFF9800),
            ),
          ),
        ),
      );

      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Siap Invoice'), findsOneWidget);
      expect(find.text('Sudah Jadi Invoice'), findsOneWidget);
    });

    testWidgets('chip aktif punya style berbeda',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: const Scaffold(
            body: ProcurementSubfilterChips(
              options: ['Semua', 'Active'],
              activeIndex: 1,
              activeColor: Color(0xFF2196F3),
            ),
          ),
        ),
      );

      final activeChip = tester.widget<Container>(
        find.ancestor(of: find.text('Active'), matching: find.byType(Container)).first,
      );
      // Active chip punya decoration color
      expect(activeChip.decoration, isNotNull);
    });

    testWidgets('onTap callback terpanggil dengan index benar',
        (WidgetTester tester) async {
      int? tappedIndex;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementSubfilterChips(
              options: ['A', 'B', 'C'],
              activeIndex: 0,
              activeColor: Colors.blue,
              onChipTap: (i) => tappedIndex = i,
            ),
          ),
        ),
      );

      await tester.tap(find.text('C'));
      await tester.pump();
      expect(tappedIndex, 2);
    });
  });
}
