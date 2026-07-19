import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/utils/procurement_approval.dart';

void main() {
  group('needsCashDeviationApproval', () {
    test('rule 1: invoice transfer + product transfer = auto-approved', () {
      expect(needsCashDeviationApproval(
        invoicePaymentTypeId: 1, // transfer
        productPaymentTypeId: 1, // transfer
      ), isFalse);
    });

    test('rule 1: invoice transfer + product tunai = auto-approved (bypass)', () {
      expect(needsCashDeviationApproval(
        invoicePaymentTypeId: 1, // transfer
        productPaymentTypeId: 2, // tunai
      ), isFalse);
    });

    test('rule 2: invoice tunai + product tunai = auto-approved', () {
      expect(needsCashDeviationApproval(
        invoicePaymentTypeId: 2, // tunai
        productPaymentTypeId: 2, // tunai
      ), isFalse);
    });

    test('rule 3: invoice tunai + product transfer = CASH DEVIATION (pending)', () {
      expect(needsCashDeviationApproval(
        invoicePaymentTypeId: 2, // tunai
        productPaymentTypeId: 1, // transfer
      ), isTrue);
    });

    test('null invoice payment type → tidak butuh approval (defensive)', () {
      expect(needsCashDeviationApproval(
        invoicePaymentTypeId: null,
        productPaymentTypeId: 1,
      ), isFalse);
    });

    test('null product payment type → tidak butuh approval (defensive)', () {
      expect(needsCashDeviationApproval(
        invoicePaymentTypeId: 2,
        productPaymentTypeId: null,
      ), isFalse);
    });
  });

  group('hasPendingApprovalItems', () {
    test('true jika ada item dengan status pending', () {
      expect(hasPendingApprovalItems(invoicePaymentTypeId: 2, itemStatuses: ['approved', 'pending_approval', 'approved']), isTrue);
    });

    test('false jika semua item approved', () {
      expect(hasPendingApprovalItems(invoicePaymentTypeId: 2, itemStatuses: ['approved', 'approved']), isFalse);
    });

    test('false jika list kosong', () {
      expect(hasPendingApprovalItems(invoicePaymentTypeId: 2, itemStatuses: []), isFalse);
    });
  });

  group('pendingItemCount', () {
    test('hitung jumlah item pending', () {
      expect(pendingItemCount(['approved', 'pending_approval', 'pending_approval']), 2);
    });

    test('0 jika tidak ada pending', () {
      expect(pendingItemCount(['approved', 'rejected']), 0);
    });
  });
}
