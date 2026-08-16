import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/widgets/add_fab.dart';

void main() {
  group('AddFab', () {
    testWidgets('keeps bottom padding at 8 despite system bottom inset',
        (tester) async {
      // Simulasikan home indicator iOS (34pt logical -> physical px).
      tester.view.devicePixelRatio = 3.0;
      tester.view.viewPadding = FakeViewPadding(bottom: 34 * 3);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: AddFab(onPressed: () {}),
          ),
        ),
      );

      final fabPadding = (tester.widget<Padding>(
        find
            .ancestor(
              of: find.byType(FloatingActionButton),
              matching: find.byType(Padding),
            )
            .first,
      ).padding) as EdgeInsets;

      expect(fabPadding.bottom, 8);
      expect(fabPadding.right, 8);
    });
  });
}