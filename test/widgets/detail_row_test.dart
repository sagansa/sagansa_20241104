import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/widgets/detail_row.dart';

void main() {
  group('DetailRow', () {
    testWidgets('renders label + value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailRow(label: 'Store', value: 'Toko A'),
          ),
        ),
      );

      expect(find.text('Store'), findsOneWidget);
      expect(find.text('Toko A'), findsOneWidget);
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailRow(
              label: 'Status',
              value: 'Active',
              trailing: const Icon(Icons.check),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('does not render trailing when null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailRow(label: 'L', value: 'V'),
          ),
        ),
      );

      // Only 2 Text widgets (label + value), no trailing.
      expect(find.byType(Icon), findsNothing);
    });
  });

  group('IconDetailRow', () {
    testWidgets('renders icon + label + value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconDetailRow(
              icon: Icons.person,
              label: 'Name',
              value: 'John Doe',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('shows copy icon when onTap provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconDetailRow(
              icon: Icons.phone,
              label: 'Phone',
              value: '081234',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('does not show copy icon when onTap null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconDetailRow(
              icon: Icons.phone,
              label: 'Phone',
              value: '081234',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.copy), findsNothing);
    });

    testWidgets('shows divider by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconDetailRow(
              icon: Icons.phone,
              label: 'P',
              value: 'V',
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('hides divider when showDivider false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconDetailRow(
              icon: Icons.phone,
              label: 'P',
              value: 'V',
              showDivider: false,
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconDetailRow(
              icon: Icons.phone,
              label: 'P',
              value: 'V',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
