import 'package:flutter_test/flutter_test.dart';
import 'package:zon/core/errors/app_exception.dart';
import 'package:zon/shared/widgets/app_states.dart';

void main() {
  group('errorMessage', () {
    test('uses AppException.message (not the runtime type)', () {
      expect(errorMessage(const NetworkError('offline')), 'offline');
      expect(errorMessage(const AuthError('unauthorized')), 'unauthorized');
    });

    test('falls back to toString for non-AppException errors', () {
      expect(errorMessage('plain string'), 'plain string');
      expect(errorMessage(const FormatException('bad')),
          contains('bad'));
    });
  });
}
