import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/widgets/search_text_field.dart';

void main() {
  group('SearchTextField', () {
    testWidgets('renders prefix search icon + hint text', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTextField(
              controller: controller,
              hintText: 'Cari nomor resi...',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Cari nomor resi...'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('shows clear button when text is not empty', (tester) async {
      final controller = TextEditingController(text: 'RESI-123');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTextField(controller: controller),
          ),
        ),
      );

      // Clear button appears because controller has text.
      expect(find.byIcon(Icons.clear), findsOneWidget);
      controller.dispose();
    });

    testWidgets('does not show clear button when text is empty', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTextField(controller: controller),
          ),
        ),
      );

      expect(find.byIcon(Icons.clear), findsNothing);
      controller.dispose();
    });

    testWidgets('clear button clears controller + calls onCleared',
        (tester) async {
      final controller = TextEditingController(text: 'ABC');
      var clearedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTextField(
              controller: controller,
              onCleared: () => clearedCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(clearedCalled, isTrue);
      controller.dispose();
    });

    testWidgets('renders custom suffix widget when provided', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTextField(
              controller: controller,
              suffixWidget: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.qr_code_scanner),
              ),
            ),
          ),
        ),
      );

      // Custom suffix replaces clear button.
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsNothing);
      controller.dispose();
    });

    testWidgets('uses custom prefix icon when provided', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTextField(
              controller: controller,
              prefixIcon: Icons.person_search,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_search), findsOneWidget);
      expect(find.byIcon(Icons.search), findsNothing);
      controller.dispose();
    });
  });
}
