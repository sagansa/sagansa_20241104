import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/providers/theme_provider.dart';
import 'package:sagansa/widgets/procurement_stage_tabs.dart';

void main() {
  group('ProcurementStageTabs', () {
    testWidgets('render 3 tab dengan label & count',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: const Scaffold(
            body: ProcurementStageTabs(
              activeStage: 0,
              requestCount: 12,
              invoiceCount: 8,
              paymentCount: 5,
            ),
          ),
        ),
      );

      expect(find.textContaining('Request'), findsOneWidget);
      expect(find.textContaining('Invoice'), findsOneWidget);
      expect(find.textContaining('Payment'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('tab aktif ditandai (underline sesuai index)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: const Scaffold(
            body: ProcurementStageTabs(
              activeStage: 1, // Invoice
              requestCount: 0,
              invoiceCount: 0,
              paymentCount: 0,
            ),
          ),
        ),
      );

      // Active tab text-nya bold
      final invoiceText = tester.widget<Text>(find.textContaining('Invoice').first);
      expect(invoiceText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('onTap terpanggil dengan index benar',
        (WidgetTester tester) async {
      int? tappedIndex;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementStageTabs(
              activeStage: 0,
              requestCount: 1,
              invoiceCount: 1,
              paymentCount: 1,
              onTabTap: (i) => tappedIndex = i,
            ),
          ),
        ),
      );

      await tester.tap(find.textContaining('Payment'));
      await tester.pump();
      expect(tappedIndex, 2);
    });
  });
}
