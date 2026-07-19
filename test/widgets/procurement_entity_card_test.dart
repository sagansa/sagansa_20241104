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
              pendingApprovalItemCount: 0,
            ),
          ),
        ),
      );

      expect(find.textContaining('INV #12'), findsOneWidget);
      expect(find.textContaining('Supplier X'), findsOneWidget);
      expect(find.textContaining('Siap Dibayar'), findsOneWidget);
    });

    testWidgets('badge pending muncul jika ada item pending',
        (WidgetTester tester) async {
      final inv = _makeInvoice();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementEntityCard.invoiceMode(
              invoice: inv,
              linkedRequestIds: const [],
              pendingApprovalItemCount: 2,
              onTapReviewApprove: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('2 item butuh approval'), findsOneWidget);
      expect(find.text('Review & Approve'), findsOneWidget);
    });

    testWidgets('button Bayar disabled jika ada item pending',
        (WidgetTester tester) async {
      final inv = _makeInvoice();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementEntityCard.invoiceMode(
              invoice: inv,
              linkedRequestIds: const [],
              pendingApprovalItemCount: 1,
              onTapBayar: () {},
            ),
          ),
        ),
      );

      // Tidak ada tombol Bayar (disabled = tidak dirender)
      expect(find.text('Bayar'), findsNothing);
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

    testWidgets('badge Tunai muncul jika isTunai true',
        (WidgetTester tester) async {
      final receipt = PaymentReceipt(
        id: 9,
        createdAt: '2026-07-19',
        supplierName: 'Supplier Y',
        totalAmount: 500000,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementEntityCard.paymentMode(
              receipt: receipt,
              isTunai: true,
            ),
          ),
        ),
      );

      expect(find.textContaining('perlu reconcile'), findsOneWidget);
    });
  });

  // Regression: card dengan konten padat (badge + links + actions) tidak
  // boleh overflow. Sebelumnya IntrinsicHeight + sibling accent Container
  // menyebabkan "A RenderFlex overflowed by N pixels on the bottom".
  group('ProcurementEntityCard - Layout regression', () {
    testWidgets('invoice mode dengan pending + tunai tidak overflow',
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
                pendingApprovalItemCount: 2,
                isAdmin: true,
                onTapReviewApprove: () {},
              ),
            ),
          ),
        ),
      );

      // Verifikasi semua elemen dirender tanpa overflow exception.
      expect(find.textContaining('INV #12'), findsOneWidget);
      expect(find.textContaining('2 item butuh approval'), findsOneWidget);
      expect(find.text('Review & Approve'), findsOneWidget);
      // Tidak ada exception Flutter yang dilempar ke tester.takeException()
      expect(tester.takeException(), isNull);
    });
  });
}
