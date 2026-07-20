import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/models/enums/procurement_item_status.dart';

void main() {
  group('ProcurementItemStatus.fromApi', () {
    test('maps known codes', () {
      expect(ProcurementItemStatus.fromApi('1'),
          ProcurementItemStatus.pending);
      expect(ProcurementItemStatus.fromApi('2'), ProcurementItemStatus.done);
      expect(ProcurementItemStatus.fromApi('3'), ProcurementItemStatus.rejected);
      expect(ProcurementItemStatus.fromApi('4'),
          ProcurementItemStatus.partiallyApproved);
    });

    test('null → unknown', () {
      expect(ProcurementItemStatus.fromApi(null),
          ProcurementItemStatus.unknown);
    });

    test('unknown code → unknown', () {
      expect(ProcurementItemStatus.fromApi('99'),
          ProcurementItemStatus.unknown);
      expect(ProcurementItemStatus.fromApi(''),
          ProcurementItemStatus.unknown);
    });
  });

  group('ProcurementItemStatus.toApi', () {
    test('inverse of fromApi', () {
      for (final status in ProcurementItemStatus.values) {
        if (status == ProcurementItemStatus.unknown) continue;
        final code = status.toApi();
        expect(ProcurementItemStatus.fromApi(code), status);
      }
    });
  });

  group('ProcurementItemStatus predicates', () {
    test('isPending', () {
      expect(ProcurementItemStatus.pending.isPending, true);
      expect(ProcurementItemStatus.done.isPending, false);
    });

    test('isApproved (done OR partiallyApproved)', () {
      expect(ProcurementItemStatus.done.isApproved, true);
      expect(ProcurementItemStatus.partiallyApproved.isApproved, true);
      expect(ProcurementItemStatus.pending.isApproved, false);
      expect(ProcurementItemStatus.rejected.isApproved, false);
    });

    test('isRejected', () {
      expect(ProcurementItemStatus.rejected.isRejected, true);
      expect(ProcurementItemStatus.done.isRejected, false);
    });
  });

  group('ProcurementItemStatus.displayLabel', () {
    test('human-readable Indonesian labels', () {
      expect(ProcurementItemStatus.pending.displayLabel, 'Pending Approval');
      expect(ProcurementItemStatus.done.displayLabel, 'Done');
      expect(ProcurementItemStatus.rejected.displayLabel, 'Rejected');
      expect(ProcurementItemStatus.partiallyApproved.displayLabel,
          'Partially Approved');
      expect(ProcurementItemStatus.unknown.displayLabel, 'Unknown');
    });
  });
}
