import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/providers/fuel_service_payment_provider.dart';

void main() {
  group('FuelServicePaymentProvider', () {
    test('initial state kosong', () {
      final p = FuelServicePaymentProvider();
      expect(p.selectedFuelServiceIds, isEmpty);
      expect(p.totalAmount, 0);
      expect(p.imageFile, isNull);
      expect(p.notes, isEmpty);
      expect(p.canSubmit, isFalse);
    });

    test('toggle selection menambah/menghapus id', () {
      final p = FuelServicePaymentProvider();
      p.toggleSelection(1, amount: 50000);
      expect(p.selectedFuelServiceIds, [1]);
      expect(p.totalAmount, 50000);
      expect(p.isSelected(1), isTrue);

      p.toggleSelection(1, amount: 50000);
      expect(p.selectedFuelServiceIds, isEmpty);
      expect(p.totalAmount, 0);
      expect(p.isSelected(1), isFalse);
    });

    test('multi-select akumulasi total', () {
      final p = FuelServicePaymentProvider();
      p.toggleSelection(1, amount: 50000);
      p.toggleSelection(2, amount: 30000);
      p.toggleSelection(3, amount: 20000);
      expect(p.selectedCount, 3);
      expect(p.totalAmount, 100000);
    });

    test('canSubmit true jika ada item + image + transferAmount', () {
      final p = FuelServicePaymentProvider();
      p.toggleSelection(1, amount: 50000);
      p.setNotes('Test note');
      // tanpa image, canSubmit tetap true (image opsional)
      expect(p.canSubmit, isTrue);
    });

    test('canSubmit false jika tidak ada item', () {
      final p = FuelServicePaymentProvider();
      p.setNotes('Test');
      expect(p.canSubmit, isFalse);
    });

    test('clearSelection reset state', () {
      final p = FuelServicePaymentProvider();
      p.toggleSelection(1, amount: 50000);
      p.setNotes('note');
      p.clearSelection();
      expect(p.selectedFuelServiceIds, isEmpty);
      expect(p.totalAmount, 0);
      expect(p.notes, isEmpty);
      expect(p.imageFile, isNull);
    });

    test('setNotes update nilai', () {
      final p = FuelServicePaymentProvider();
      p.setNotes('hello world');
      expect(p.notes, 'hello world');
    });
  });
}
