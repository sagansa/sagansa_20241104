import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/providers/theme_provider.dart';
import 'package:sagansa/widgets/procurement_stats_strip.dart';

void main() {
  group('ProcurementStatsStrip', () {
    testWidgets('render 3 chip metrik dengan label & angka benar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: const Scaffold(
            body: ProcurementStatsStrip(
              pendingApprovalCount: 2,
              siapInvoiceCount: 3,
              siapBayarCount: 1,
            ),
          ),
        ),
      );

      expect(find.textContaining('2'), findsWidgets); // approval count
      expect(find.textContaining('3'), findsWidgets); // siap invoice
      expect(find.textContaining('1'), findsWidgets); // siap bayar
      expect(find.text('approval'), findsOneWidget);
      expect(find.text('siap invoice'), findsOneWidget);
      expect(find.text('siap bayar'), findsOneWidget);
    });

    testWidgets('callback onTap terpanggil saat chip di-tap',
        (WidgetTester tester) async {
      int? tappedIndex;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementStatsStrip(
              pendingApprovalCount: 1,
              siapInvoiceCount: 0,
              siapBayarCount: 0,
              onChipTap: (i) => tappedIndex = i,
            ),
          ),
        ),
      );

      // Tap chip pertama (approval)
      await tester.tap(find.text('approval'));
      await tester.pump();
      expect(tappedIndex, 0);
    });

    testWidgets('count 0 → chip tetap dirender (transparan/disabled style)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: const Scaffold(
            body: ProcurementStatsStrip(
              pendingApprovalCount: 0,
              siapInvoiceCount: 0,
              siapBayarCount: 0,
            ),
          ),
        ),
      );

      // Tetap dirender, count 0
      expect(find.text('approval'), findsOneWidget);
      expect(find.text('siap invoice'), findsOneWidget);
      expect(find.text('siap bayar'), findsOneWidget);
    });
  });
}
