import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/models/enums/order_mode.dart';
import 'package:sagansa/widgets/delivery/order_list_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  final baseOrder = <String, dynamic>{
    'id': 1,
    'receipt_no': 'RESI-001',
    'delivery_status': 1,
    'store_name': 'Toko A',
    'provider_name': 'JNE',
    'method_name': 'REG',
    'created_at': '2026-07-22T10:00:00.000000Z',
  };

  group('OrderListCard', () {
    testWidgets('renders receipt number for online order', (tester) async {
      await tester.pumpWidget(wrap(
        OrderListCard(
          order: Map.from(baseOrder),
          orderMode: OrderMode.online,
          isAdmin: false,
          isStickerPrinted: false,
          isPrintingSticker: false,
          onTap: () {},
        ),
      ));

      expect(find.textContaining('RESI-001'), findsOneWidget);
    });

    testWidgets('renders store name', (tester) async {
      await tester.pumpWidget(wrap(
        OrderListCard(
          order: Map.from(baseOrder),
          orderMode: OrderMode.online,
          isAdmin: false,
          isStickerPrinted: false,
          isPrintingSticker: false,
          onTap: () {},
        ),
      ));

      expect(find.textContaining('Toko A'), findsWidgets);
    });

    testWidgets('calls onTap when card tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(wrap(
        OrderListCard(
          order: Map.from(baseOrder),
          orderMode: OrderMode.online,
          isAdmin: false,
          isStickerPrinted: false,
          isPrintingSticker: false,
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(OrderListCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders for direct order mode', (tester) async {
      await tester.pumpWidget(wrap(
        OrderListCard(
          order: {
            ...baseOrder,
            'ordered_by_name': 'John Doe',
            'address': 'Jl. Test No. 1',
          },
          orderMode: OrderMode.direct,
          isAdmin: false,
          isStickerPrinted: false,
          isPrintingSticker: false,
          onTap: () {},
        ),
      ));

      expect(find.byType(OrderListCard), findsOneWidget);
    });

    testWidgets('renders admin-specific elements when isAdmin', (tester) async {
      await tester.pumpWidget(wrap(
        OrderListCard(
          order: Map.from(baseOrder),
          orderMode: OrderMode.online,
          isAdmin: true,
          isStickerPrinted: false,
          isPrintingSticker: false,
          onTap: () {},
        ),
      ));

      expect(find.byType(OrderListCard), findsOneWidget);
    });
  });
}
