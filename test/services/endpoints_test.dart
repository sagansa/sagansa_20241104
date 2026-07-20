import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/services/endpoints.dart';

void main() {
  group('Endpoints static const', () {
    test('auth endpoints', () {
      expect(Endpoints.login, 'login');
      expect(Endpoints.logout, 'logout');
      expect(Endpoints.profile, 'profile');
    });

    test('procurement base paths', () {
      expect(Endpoints.procurementProducts, 'procurement/products');
      expect(Endpoints.procurementRequests, 'procurement/requests');
      expect(Endpoints.procurementInvoices, 'procurement/invoices');
    });
  });

  group('Endpoints param methods', () {
    test('procurementRequestDetail injects id', () {
      expect(Endpoints.procurementRequestDetail(42), 'procurement/requests/42');
    });

    test('procurementApproveItem injects itemId', () {
      expect(
        Endpoints.procurementApproveItem(7),
        'procurement/requests/items/7/approve',
      );
    });

    test('procurementRejectItem injects itemId', () {
      expect(
        Endpoints.procurementRejectItem(7),
        'procurement/requests/items/7/reject',
      );
    });

    test('assetDetail injects id', () {
      expect(Endpoints.assetDetail(99), 'assets/99');
    });

    test('supplierDetail injects id', () {
      expect(Endpoints.supplierDetail(3), 'suppliers/3');
    });
  });

  group('Endpoints completeness', () {
    test('all values are non-empty', () {
      const values = [
        Endpoints.login,
        Endpoints.profile,
        Endpoints.procurementProducts,
        Endpoints.assets,
        Endpoints.suppliers,
      ];
      for (final v in values) {
        expect(v.isNotEmpty, true);
      }
    });
  });
}
