import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/providers/theme_provider.dart';
import 'package:sagansa/widgets/list_thumbnail.dart';

void main() {
  group('ListThumbnail Widget Tests', () {
    testWidgets('renders placeholder icon when imageUrl is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: const Scaffold(
            body: ListThumbnail(
              imageUrl: null,
              placeholderIcon: Icons.local_gas_station,
            ),
          ),
        ),
      );

      // Placeholder container dirender (kotak 56x56)
      expect(find.byType(ListThumbnail), findsOneWidget);
      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
      // Tidak ada Image bila tidak ada imageUrl
      expect(find.byType(Image), findsNothing);
      // Tidak ada GestureDetector bila onTap null
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('renders Image.network when imageUrl is provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: const Scaffold(
            body: ListThumbnail(
              imageUrl: 'https://example.com/img.jpg',
            ),
          ),
        ),
      );

      expect(find.byType(ListThumbnail), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      // Placeholder icon default (receipt_long) TIDAK boleh muncul
      // saat imageUrl valid (sedang loading → loading box, bukan icon placeholder)
    });

    testWidgets('wraps with GestureDetector when onTap is provided',
        (WidgetTester tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ListThumbnail(
              placeholderIcon: Icons.receipt_long,
              onTap: () => tapCount++,
            ),
          ),
        ),
      );

      // GestureDetector ada bila onTap disediakan
      expect(find.byType(GestureDetector), findsOneWidget);

      // Tap thumbnail → callback terpanggil
      await tester.tap(find.byType(ListThumbnail));
      await tester.pump();
      expect(tapCount, 1);
    });

    testWidgets('uses default placeholder icon Icons.receipt_long',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: const Scaffold(
            body: ListThumbnail(), // imageUrl null, pakai default icon
          ),
        ),
      );

      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
    });
  });
}
