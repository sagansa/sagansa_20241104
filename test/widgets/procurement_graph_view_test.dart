import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/models/procurement_model.dart';
import 'package:sagansa/providers/theme_provider.dart';
import 'package:sagansa/widgets/procurement_graph_view.dart';

RequestPurchase _makeRequest({int id = 1, List<DetailRequestItem>? items}) {
  return RequestPurchase(
    id: id,
    storeId: 1,
    storeName: 'Toko A',
    date: '2026-07-19',
    userId: 10,
    userName: 'Andi',
    detailRequests: items ?? [],
  );
}

DetailRequestItem _makeDetailRequest({int id = 1}) {
  return DetailRequestItem(
    id: id,
    productId: 1,
    quantityPlan: 2,
    status: '1',
    productName: 'Beras 5kg',
    unitName: 'pcs',
  );
}

InvoicePurchase _makeInvoice({
  int id = 100,
  int totalPrice = 1000000,
  String paymentStatus = '1',
  List<DetailInvoiceItem>? detailInvoices,
}) {
  return InvoicePurchase(
    id: id,
    paymentTypeId: 1,
    storeId: 1,
    date: '2026-07-19',
    totalPrice: totalPrice,
    createdById: 5,
    paymentStatus: paymentStatus,
    storeName: 'Toko A',
    supplierName: 'Supplier X',
    detailInvoices: detailInvoices ?? const [],
  );
}

DetailInvoiceItem _makeDetailInvoice({
  int id = 200,
  int? detailRequestId,
}) {
  return DetailInvoiceItem(
    id: id,
    invoicePurchaseId: 100,
    detailRequestId: detailRequestId,
    quantityProduct: 2,
    subtotalInvoice: 100000,
    productName: 'Beras 5kg',
    unitName: 'pcs',
  );
}

PaymentReceipt _makeReceipt({
  int id = 300,
  int totalAmount = 2000000,
  List<InvoicePurchase> invoicePurchases = const [],
}) {
  return PaymentReceipt(
    id: id,
    createdAt: '2026-07-19',
    supplierName: 'Supplier X',
    totalAmount: totalAmount,
    invoicePurchases: invoicePurchases,
  );
}

void main() {
  group('ProcurementGraphView - Mapping correctness', () {
    testWidgets('orphan invoice (tanpa parent request) ditampilkan',
        (WidgetTester tester) async {
      // Invoice tanpa detail_request → tidak terhubung ke request manapun.
      final orphanInv = _makeInvoice(id: 99, detailInvoices: const []);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementGraphView(
              requests: const [],
              invoices: [orphanInv],
              receipts: const [],
              requestToInvoices: const {},
              invoiceToReceipt: const {},
            ),
          ),
        ),
      );

      // Orphan invoice HARUS dirender.
      expect(find.textContaining('INV #99'), findsOneWidget);
    });

    testWidgets('1 request → 1 invoice → 1 receipt (happy path)',
        (WidgetTester tester) async {
      final req = _makeRequest(id: 1, items: [_makeDetailRequest(id: 10)]);
      final inv = _makeInvoice(
        id: 100,
        detailInvoices: [_makeDetailInvoice(id: 200, detailRequestId: 10)],
      );
      final rec = _makeReceipt(id: 300, invoicePurchases: [inv]);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementGraphView(
              requests: [req],
              invoices: [inv],
              receipts: [rec],
              requestToInvoices: {1: [inv]},
              invoiceToReceipt: {100: rec},
            ),
          ),
        ),
      );

      expect(find.textContaining('REQ #1'), findsOneWidget);
      expect(find.textContaining('INV #100'), findsOneWidget);
      expect(find.textContaining('KWT #300'), findsOneWidget);
    });

    testWidgets('2 request → 1 invoice (merge) → badge xN di invoice',
        (WidgetTester tester) async {
      final req1 = _makeRequest(id: 1, items: [_makeDetailRequest(id: 10)]);
      final req2 = _makeRequest(id: 2, items: [_makeDetailRequest(id: 11)]);
      final inv = _makeInvoice(
        id: 100,
        detailInvoices: [
          _makeDetailInvoice(id: 200, detailRequestId: 10),
          _makeDetailInvoice(id: 201, detailRequestId: 11),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementGraphView(
              requests: [req1, req2],
              invoices: [inv],
              receipts: const [],
              requestToInvoices: {1: [inv], 2: [inv]},
              invoiceToReceipt: const {},
            ),
          ),
        ),
      );

      // Badge x2 muncul di invoice karena 2 request digabung.
      expect(find.text('x2'), findsWidgets);
    });

    testWidgets('1 receipt membayar 2 invoice → badge gabung di receipt',
        (WidgetTester tester) async {
      final req = _makeRequest(id: 1, items: [_makeDetailRequest(id: 10)]);
      final inv1 = _makeInvoice(
        id: 100,
        detailInvoices: [_makeDetailInvoice(id: 200, detailRequestId: 10)],
      );
      final inv2 = _makeInvoice(
        id: 101,
        detailInvoices: [_makeDetailInvoice(id: 201, detailRequestId: 10)],
      );
      // 1 receipt untuk 2 invoice.
      final rec = _makeReceipt(id: 300, invoicePurchases: [inv1, inv2]);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementGraphView(
              requests: [req],
              invoices: [inv1, inv2],
              receipts: [rec],
              requestToInvoices: {1: [inv1, inv2]},
              invoiceToReceipt: {100: rec, 101: rec},
            ),
          ),
        ),
      );

      // Receipt punya badge "gabung" karena 2 invoice digabung jadi 1 payment.
      expect(find.textContaining('gabung'), findsWidgets);
    });
  });

  group('ProcurementGraphView - Callbacks', () {
    testWidgets('tap request node memanggil onTapRequest',
        (WidgetTester tester) async {
      RequestPurchase? tapped;
      final req = _makeRequest(id: 1, items: [_makeDetailRequest()]);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementGraphView(
              requests: [req],
              invoices: const [],
              receipts: const [],
              requestToInvoices: const {},
              invoiceToReceipt: const {},
              onTapRequest: (r) => tapped = r,
            ),
          ),
        ),
      );

      await tester.tap(find.textContaining('REQ #1'));
      await tester.pump();
      expect(tapped?.id, 1);
    });

    testWidgets('tap invoice node memanggil onTapInvoice',
        (WidgetTester tester) async {
      InvoicePurchase? tapped;
      final req = _makeRequest(id: 1, items: [_makeDetailRequest(id: 10)]);
      final inv = _makeInvoice(
        id: 100,
        detailInvoices: [_makeDetailInvoice(detailRequestId: 10)],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementGraphView(
              requests: [req],
              invoices: [inv],
              receipts: const [],
              requestToInvoices: {1: [inv]},
              invoiceToReceipt: const {},
              onTapInvoice: (i) => tapped = i,
            ),
          ),
        ),
      );

      await tester.tap(find.textContaining('INV #100'));
      await tester.pump();
      expect(tapped?.id, 100);
    });
  });

  group('ProcurementGraphView - Edge cases', () {
    testWidgets('empty state: tidak ada data → tampilkan pesan',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: const Scaffold(
            body: ProcurementGraphView(
              requests: [],
              invoices: [],
              receipts: [],
              requestToInvoices: {},
              invoiceToReceipt: {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Tidak ada data'), findsOneWidget);
    });

    testWidgets('request tanpa invoice → tampilkan "belum di-invoice"',
        (WidgetTester tester) async {
      final req = _makeRequest(id: 1, items: [_makeDetailRequest()]);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme,
          home: Scaffold(
            body: ProcurementGraphView(
              requests: [req],
              invoices: const [],
              receipts: const [],
              requestToInvoices: const {},
              invoiceToReceipt: const {},
            ),
          ),
        ),
      );

      expect(find.textContaining('belum di-invoice'), findsOneWidget);
    });
  });
}
