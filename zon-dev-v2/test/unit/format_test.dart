import 'package:flutter_test/flutter_test.dart';
import 'package:zon/shared/utils/format.dart';

void main() {
  group('compactCount', () {
    test('values under 1000 are plain', () {
      expect(compactCount(0), '0');
      expect(compactCount(42), '42');
      expect(compactCount(999), '999');
    });

    test('thousands', () {
      expect(compactCount(1000), '1k');
      expect(compactCount(1200), '1.2k');
      expect(compactCount(15000), '15k');
      expect(compactCount(12345), '12.3k');
    });

    test('millions', () {
      expect(compactCount(1000000), '1.0M');
      expect(compactCount(2500000), '2.5M');
    });
  });
}
