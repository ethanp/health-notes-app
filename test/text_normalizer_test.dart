import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/services/text_normalizer.dart';

void main() {
  group('SymptomNormalizer', () {
    test('should generate consistent keys', () {
      final key1 = SymptomNormalizer.pipeJoinedNormalizedPair('Headache', 'Severe');
      final key2 = SymptomNormalizer.pipeJoinedNormalizedPair('HEADACHE', 'severe');
      final key3 = SymptomNormalizer.pipeJoinedNormalizedPair('  headache  ', '  SEVERE  ');

      expect(key1, equals(key2));
      expect(key2, equals(key3));
      expect(key1, equals('headache|severe'));
    });

    test('should correctly compare symptoms', () {
      expect(
        SymptomNormalizer.areEqual('Headache', 'Severe', 'headache', 'severe'),
        isTrue,
      );
      expect(
        SymptomNormalizer.areEqual(
          '  Headache  ',
          'Severe',
          'HEADACHE',
          'SEVERE',
        ),
        isTrue,
      );
      expect(
        SymptomNormalizer.areEqual('Headache', 'Severe', 'Migraine', 'Mild'),
        isFalse,
      );
    });
  });

  group('CaseInsensitiveAggregator', () {
    test('should aggregate strings case-insensitively', () {
      final items = [
        'Headache',
        'headache',
        'HEADACHE',
        'Migraine',
        'migraine',
      ];
      final result = CaseInsensitiveAggregator.countByCaseInsensitiveDisplay(items);

      expect(result.length, equals(2));
      expect(result['Headache'], equals(3));
      expect(result['Migraine'], equals(2));
    });

    test('should preserve original casing in display names', () {
      final items = ['headache', 'Headache', 'HEADACHE'];
      final result = CaseInsensitiveAggregator.countByCaseInsensitiveDisplay(items);

      expect(result.containsKey('headache'), isTrue);
      expect(result['headache'], equals(3));
    });

    test('should group items by string key case-insensitively', () {
      final items = [
        {'name': 'Headache', 'severity': 5},
        {'name': 'headache', 'severity': 3},
        {'name': 'Migraine', 'severity': 8},
      ];

      final result = CaseInsensitiveAggregator.groupByCaseInsensitiveKey(
        items,
        (item) => item['name'] as String,
      );

      expect(result.length, equals(2));
      expect(result['Headache']?.length, equals(2));
      expect(result['Migraine']?.length, equals(1));
    });
  });
}
