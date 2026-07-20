import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/utils/app_logger.dart';

void main() {
  group('AppLogger.redact', () {
    test('redacts default sensitive keys', () {
      final input = {
        'name': 'sagansa',
        'token': 'abc.def.ghi',
        'password': 'rahasia',
        'access_token': 'xyz',
        'email': 'user@sagansa.id',
      };
      final redacted = AppLogger.redact(input);
      expect(redacted['name'], 'sagansa');
      expect(redacted['token'], '***');
      expect(redacted['password'], '***');
      expect(redacted['access_token'], '***');
      expect(redacted['email'], 'user@sagansa.id');
    });

    test('redacts case-insensitively', () {
      final input = {'Token': 'abc', 'PASSWORD': 'xyz'};
      final redacted = AppLogger.redact(input);
      expect(redacted['Token'], '***');
      expect(redacted['PASSWORD'], '***');
    });

    test('preserves non-sensitive keys', () {
      final input = {'id': 1, 'name': 'X', 'roles': ['admin']};
      final redacted = AppLogger.redact(input);
      expect(redacted, equals(input));
    });

    test('supports custom sensitive keys', () {
      final input = {'pin': '1234', 'cvv': '999'};
      final redacted = AppLogger.redact(input,
          sensitiveKeys: {'pin', 'cvv'});
      expect(redacted['pin'], '***');
      expect(redacted['cvv'], '***');
    });

    test('handles nested map shallowly (does NOT recurse)', () {
      final input = {
        'user': {'token': 'abc', 'name': 'X'}
      };
      final redacted = AppLogger.redact(input);
      expect((redacted['user'] as Map)['token'], 'abc');
    });
  });

  group('AppLogger preview', () {
    test('returns short text unchanged', () {
      expect(AppLogger.preview('hello'), 'hello');
    });

    test('truncates long text', () {
      final long = 'a' * 300;
      final result = AppLogger.preview(long, maxLength: 200);
      expect(result.length, lessThan(300));
      expect(result, contains('300 bytes total'));
    });
  });

  group('AppLogger methods do not throw', () {
    test('debug executes without exception', () {
      expect(() => AppLogger.debug('test message'), returnsNormally);
      expect(() => AppLogger.debug('test', error: Exception('e')), returnsNormally);
    });

    test('info executes without exception', () {
      expect(() => AppLogger.info('test'), returnsNormally);
    });

    test('warning executes without exception', () {
      expect(() => AppLogger.warning('test'), returnsNormally);
      expect(() => AppLogger.warning('test', error: Exception('e')), returnsNormally);
    });

    test('error executes without exception', () {
      expect(
        () => AppLogger.error('test', error: Exception('e'), stack: StackTrace.current),
        returnsNormally,
      );
    });
  });
}
