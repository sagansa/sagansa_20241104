import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/utils/procurement_approval.dart';

void main() {
  group('hasPendingApprovalItems', () {
    test('true jika ada item dengan status Process (1)', () {
      expect(hasPendingApprovalItems(['1', '2', '4']), isTrue);
    });

    test('false jika semua item sudah approved/done', () {
      expect(hasPendingApprovalItems(['2', '4']), isFalse);
    });

    test('false jika ada item rejected (3) saja tanpa pending', () {
      expect(hasPendingApprovalItems(['3']), isFalse);
    });

    test('false jika list kosong', () {
      expect(hasPendingApprovalItems([]), isFalse);
    });

    test('false jika semua item null', () {
      expect(hasPendingApprovalItems([null, null]), isFalse);
    });
  });

  group('pendingItemCount', () {
    test('hitung jumlah item dengan status Process (1)', () {
      expect(pendingItemCount(['1', '1', '2', '4']), 2);
    });

    test('0 jika tidak ada pending', () {
      expect(pendingItemCount(['2', '3', '4']), 0);
    });

    test('0 jika list kosong', () {
      expect(pendingItemCount([]), 0);
    });

    test('0 jika semua item null', () {
      expect(pendingItemCount([null, null]), 0);
    });
  });

  group('kPendingApprovalStatus', () {
    test('konstan = "1" (backend Process status)', () {
      expect(kPendingApprovalStatus, '1');
    });
  });
}
