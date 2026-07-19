import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/widgets/procurement_batch_bottom_bar.dart';
import 'package:sagansa/providers/theme_provider.dart';

void main() {
  group('ProcurementBatchBottomBar', () {
    testWidgets('mode Request: tampilkan count + label Gabung',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementBatchBottomBar.requestMode(
              selectedCount: 3,
              onAction: null,
            ),
          ),
        ),
      );

      expect(find.textContaining('3'), findsWidgets);
      expect(find.text('Gabung jadi 1 Invoice'), findsOneWidget);
    });

    testWidgets('mode Invoice: tampilkan count + total + label Bayar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementBatchBottomBar.invoiceMode(
              selectedCount: 2,
              totalAmount: 2000000,
              onAction: null,
            ),
          ),
        ),
      );

      expect(find.textContaining('2'), findsWidgets);
      expect(find.text('Bayar Sekaligus'), findsOneWidget);
      expect(find.textContaining('2.000.000'), findsOneWidget);
    });

    testWidgets('onAction terpanggil saat tombol di-tap',
        (WidgetTester tester) async {
      int tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementBatchBottomBar.requestMode(
              selectedCount: 1,
              onAction: () => tapped++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Gabung jadi 1 Invoice'));
      await tester.pump();
      expect(tapped, 1);
    });
  });
}
