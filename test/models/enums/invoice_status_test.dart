import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/models/enums/invoice_status.dart';

void main() {
  group('InvoiceStatus.fromApi', () {
    test('maps known codes', () {
      expect(InvoiceStatus.fromApi('1'), InvoiceStatus.draft);
      expect(InvoiceStatus.fromApi('2'), InvoiceStatus.done);
      expect(InvoiceStatus.fromApi('3'), InvoiceStatus.void_);
    });

    test('null/unknown → unknown', () {
      expect(InvoiceStatus.fromApi(null), InvoiceStatus.unknown);
      expect(InvoiceStatus.fromApi('99'), InvoiceStatus.unknown);
    });
  });

  group('InvoiceStatus predicates', () {
    test('isDraft', () {
      expect(InvoiceStatus.draft.isDraft, true);
      expect(InvoiceStatus.done.isDraft, false);
    });

    test('isDone', () {
      expect(InvoiceStatus.done.isDone, true);
      expect(InvoiceStatus.draft.isDone, false);
    });
  });

  group('InvoiceStatus.toApi', () {
    test('inverse of fromApi', () {
      for (final s in InvoiceStatus.values) {
        if (s == InvoiceStatus.unknown) continue;
        expect(InvoiceStatus.fromApi(s.toApi()), s);
      }
    });
  });
}
