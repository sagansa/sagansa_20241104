import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/models/procurement_model.dart';
import 'package:sagansa/widgets/procurement_entity_card.dart';
import 'package:sagansa/providers/theme_provider.dart';

RequestPurchase _makeRequest({
  int id = 45,
  String storeName = 'Toko A',
  String userName = 'Andi',
  String date = '2026-07-19',
  List<DetailRequestItem>? items,
}) {
  return RequestPurchase(
    id: id,
    storeId: 1,
    storeName: storeName,
    date: date,
    userId: 10,
    userName: userName,
    detailRequests: items ?? const [],
  );
}

DetailRequestItem _makeDetailRequest({int id = 1, String status = '1'}) {
  return DetailRequestItem(
    id: id,
    productId: 1,
    quantityPlan: 2,
    status: status,
    productName: 'Beras 5kg',
    unitName: 'pcs',
  );
}

InvoicePurchase _makeInvoice({
  int id = 12,
  int totalPrice = 1200000,
  String paymentStatus = '1',
  int? paymentTypeId = 1,
}) {
  return InvoicePurchase(
    id: id,
    paymentTypeId: paymentTypeId,
    storeId: 1,
    date: '2026-07-19',
    totalPrice: totalPrice,
    createdById: 5,
    paymentStatus: paymentStatus,
    storeName: 'Toko A',
    supplierName: 'Supplier X',
  );
}

void main() {
  group('ProcurementEntityCard - Request mode', () {
    testWidgets('render header REQ + store + user + badge',
        (WidgetTester tester) async {
      final req = _makeRequest(items: [_makeDetailRequest()]);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementEntityCard.requestMode(
              request: req,
              linkedInvoices: const [],
            ),
          ),
        ),
      );

      expect(find.textContaining('REQ #45'), findsOneWidget);
      expect(find.textContaining('Toko A'), findsOneWidget);
      expect(find.textContaining('Andi'), findsOneWidget);
      expect(find.text('Siap Invoice'), findsOneWidget);
    });

    testWidgets('link pill INV dirender jika ada linkedInvoices',
        (WidgetTester tester) async {
      final req = _makeRequest();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementEntityCard.requestMode(
              request: req,
              linkedInvoices: [_makeInvoice(id: 11), _makeInvoice(id: 12)],
              onTapLinkInvoice: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('INV #11'), findsOneWidget);
      expect(find.textContaining('INV #12'), findsOneWidget);
    });

    testWidgets('callback onTapCard terpanggil',
        (WidgetTester tester) async {
      int tapped = 0;
      final req = _makeRequest(items: [_makeDetailRequest()]);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementEntityCard.requestMode(
              request: req,
              linkedInvoices: const [],
              onTapCard: () => tapped++,
            ),
          ),
        ),
      );

      await tester.tap(find.textContaining('REQ #45'));
      await tester.pump();
      expect(tapped, 1);
    });
  });

  group('ProcurementEntityCard - Invoice mode', () {
    testWidgets('render header INV + supplier + amount + badge',
        (WidgetTester tester) async {
      final inv = _makeInvoice();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementEntityCard.invoiceMode(
              invoice: inv,
              linkedRequestIds: const [],
            ),
          ),
        ),
      );

      expect(find.textContaining('INV #12'), findsOneWidget);
      expect(find.textContaining('Supplier X'), findsOneWidget);
      expect(find.textContaining('Siap Dibayar'), findsOneWidget);
    });

    testWidgets('thumbnail dirender jika invoice punya image',
        (WidgetTester tester) async {
      final inv = InvoicePurchase(
        id: 12,
        storeId: 1,
        date: '2026-07-19',
        totalPrice: 1200000,
        createdById: 5,
        paymentStatus: '1',
        storeName: 'Toko A',
        image: 'invoices/inv-12.jpg',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementEntityCard.invoiceMode(
              invoice: inv,
              linkedRequestIds: const [],
            ),
          ),
        ),
      );

      // ListThumbnail dirender (Image.network akan muncul setelah load).
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('tidak ada thumbnail jika invoice tanpa image',
        (WidgetTester tester) async {
      final inv = _makeInvoice(); // image = null
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementEntityCard.invoiceMode(
              invoice: inv,
              linkedRequestIds: const [],
            ),
          ),
        ),
      );

      // Tidak ada widget Image karena thumbnail skip saat imageUrl null.
      expect(find.byType(Image), findsNothing);
    });
  });

  group('ProcurementEntityCard - Payment mode', () {
    testWidgets('render header Kwit + lunas badge + link pill',
        (WidgetTester tester) async {
      final receipt = PaymentReceipt(
        id: 8,
        createdAt: '2026-07-19',
        supplierName: 'Supplier X',
        totalAmount: 2000000,
        invoicePurchases: [_makeInvoice(id: 9), _makeInvoice(id: 10)],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementEntityCard.paymentMode(
              receipt: receipt,
              isTunai: false,
            ),
          ),
        ),
      );

      expect(find.textContaining('Kwit #8'), findsOneWidget);
      expect(find.textContaining('Supplier X'), findsOneWidget);
      expect(find.text('Lunas'), findsOneWidget);
      expect(find.textContaining('2 Invoice Gabungan'), findsOneWidget);
    });

    testWidgets('format Tgl Bayar dari ISO ke dd-MM-yyyy',
        (WidgetTester tester) async {
      final receipt = PaymentReceipt(
        id: 10,
        createdAt: '2026-07-19T14:30:00.000000Z',
        supplierName: 'Supplier Z',
        totalAmount: 750000,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementEntityCard.paymentMode(
              receipt: receipt,
              isTunai: false,
            ),
          ),
        ),
      );

      // ISO 2026-07-19 diformat jadi 19-07-2026.
      expect(find.textContaining('Tgl Bayar: 19-07-2026'), findsOneWidget);
    });
  });

  // Regression: card dengan konten padat (badge + links + actions) tidak
  // boleh overflow. Sebelumnya IntrinsicHeight + sibling accent Container
  // menyebabkan "A RenderFlex overflowed by N pixels on the bottom".
  group('ProcurementEntityCard - Layout regression', () {
    testWidgets('invoice mode dengan links + action tidak overflow',
        (WidgetTester tester) async {
      final inv = _makeInvoice();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: ProcurementEntityCard.invoiceMode(
                invoice: inv,
                linkedRequestIds: const [42, 43],
                onTapBayar: () {},
              ),
            ),
          ),
        ),
      );

      // Verifikasi semua elemen dirender tanpa overflow exception.
      expect(find.textContaining('INV #12'), findsOneWidget);
      expect(find.textContaining('Siap Dibayar'), findsOneWidget);
      expect(find.text('Bayar'), findsOneWidget);
      // Tidak ada exception Flutter yang dilempar ke tester.takeException()
      expect(tester.takeException(), isNull);
    });
  });
}
