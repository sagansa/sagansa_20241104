import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/utils/constants.dart';

void main() {
  group('ApiConstants.resolveClosingStoreUrl', () {
    test('production URL: api.sagansa.id → www.sagansa.id', () {
      final result = ApiConstants.resolveClosingStoreUrl(
        'https://api.sagansa.id',
      );
      expect(
        result,
        'https://www.sagansa.id/admin/transaction/closings/panel/closing-stores',
      );
    });

    test('localhost:8001 → localhost:8000', () {
      final result = ApiConstants.resolveClosingStoreUrl(
        'http://localhost:8001',
      );
      expect(
        result,
        'http://localhost:8000/admin/transaction/closings/panel/closing-stores',
      );
    });

    test('127.0.0.1:8001 → 127.0.0.1:8000', () {
      final result = ApiConstants.resolveClosingStoreUrl(
        'http://127.0.0.1:8001',
      );
      expect(
        result,
        'http://127.0.0.1:8000/admin/transaction/closings/panel/closing-stores',
      );
    });

    test('192.168.x.x:8001 → 192.168.x.x:8000', () {
      final result = ApiConstants.resolveClosingStoreUrl(
        'http://192.168.0.142:8001',
      );
      expect(
        result,
        'http://192.168.0.142:8000/admin/transaction/closings/panel/closing-stores',
      );
    });

    test('non-api subdomain di production tetap diawali www', () {
      final result = ApiConstants.resolveClosingStoreUrl(
        'https://api.staging.sagansa.id',
      );
      expect(
        result,
        'https://www.staging.sagansa.id/admin/transaction/closings/panel/closing-stores',
      );
    });

    test('HTTPS production tanpa port eksplisit', () {
      final result = ApiConstants.resolveClosingStoreUrl(
        'https://api.sagansa.id:443',
      );
      expect(
        result,
        'https://www.sagansa.id/admin/transaction/closings/panel/closing-stores',
      );
    });
  });
}
