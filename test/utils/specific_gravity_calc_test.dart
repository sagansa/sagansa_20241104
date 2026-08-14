import 'package:flutter_test/flutter_test.dart';

import 'package:sagansa/utils/specific_gravity_calc.dart';

void main() {
  group('calculateSpecificGravity', () {
    test('906.5 -> 17.2235 kg & 223.5 g', () {
      final result = calculateSpecificGravity(906.5);

      expect(result.totalKg, 17.2235);
      expect(result.totalKgFormatted, '17.2235');

      expect(result.additionalGram, 223.5);
      expect(result.additionalGramFormatted, '223.5');
    });

    test('906.0 -> 17.2140 kg & 214.0 g', () {
      final result = calculateSpecificGravity(906.0);

      expect(result.totalKg, 17.2140);
      expect(result.totalKgFormatted, '17.2140');

      expect(result.additionalGram, 214.0);
      expect(result.additionalGramFormatted, '214.0');
    });

    test('format string exact (4dp / 1dp)', () {
      final result = calculateSpecificGravity(906.5);
      expect(result.totalKgFormatted, matches(RegExp(r'^\d+\.\d{4}$')));
      expect(
        result.additionalGramFormatted,
        matches(RegExp(r'^\d+\.\d{1}$')),
      );
    });
  });
}
