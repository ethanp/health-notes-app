import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/services/text_normalizer.dart';

void main() {
  group('CaseInsensitiveNormalizer', () {
    final normalizer = CaseInsensitiveNormalizer();

    test('should normalize text to lowercase and trim', () {
      expect(normalizer.normalize('  Hello World  '), equals('hello world'));
      expect(normalizer.normalize('UPPER'), equals('upper'));
      expect(normalizer.normalize('Mixed Case'), equals('mixed case'));
    });

    test('should correctly compare equality', () {
      expect(normalizer.areEqual('Hello', 'hello'), isTrue);
      expect(normalizer.areEqual('  Hello  ', 'hello'), isTrue);
      expect(normalizer.areEqual('WORLD', 'world'), isTrue);
      expect(normalizer.areEqual('Hello', 'goodbye'), isFalse);
    });

    test('should correctly check contains', () {
      expect(normalizer.contains('Hello World', 'hello'), isTrue);
      expect(normalizer.contains('Hello World', 'WORLD'), isTrue);
      expect(normalizer.contains('Hello World', 'xyz'), isFalse);
      expect(normalizer.contains('  Test  ', 'test'), isTrue);
    });
  });

  group('SymptomNormalizer', () {
    test('should generate consistent keys', () {
      final key1 = SymptomNormalizer.generateKey('Headache', 'Severe');
      final key2 = SymptomNormalizer.generateKey('HEADACHE', 'severe');
      final key3 = SymptomNormalizer.generateKey('  headache  ', '  SEVERE  ');

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

    test('should match search queries', () {
      expect(
        SymptomNormalizer.matchesSearch(
          'Headache',
          'Severe',
          'Very painful',
          'head',
        ),
        isTrue,
      );
      expect(
        SymptomNormalizer.matchesSearch(
          'Headache',
          'Severe',
          'Very painful',
          'SEVERE',
        ),
        isTrue,
      );
      expect(
        SymptomNormalizer.matchesSearch(
          'Headache',
          'Severe',
          'Very painful',
          'painful',
        ),
        isTrue,
      );
      expect(
        SymptomNormalizer.matchesSearch(
          'Headache',
          'Severe',
          'Very painful',
          'xyz',
        ),
        isFalse,
      );
    });

    test('should handle empty search query', () {
      expect(
        SymptomNormalizer.matchesSearch('Headache', 'Severe', 'Notes', ''),
        isTrue,
      );
      expect(
        SymptomNormalizer.matchesSearch('Headache', 'Severe', 'Notes', '   '),
        isTrue,
      );
    });
  });

  group('MetricNameNormalizer', () {
    test('should normalize metric names', () {
      expect(MetricNameNormalizer.normalize('  Mood  '), equals('mood'));
      expect(MetricNameNormalizer.normalize('ENERGY'), equals('energy'));
      expect(
        MetricNameNormalizer.normalize('Sleep Quality'),
        equals('sleep quality'),
      );
    });

    test('should correctly compare metric names', () {
      expect(MetricNameNormalizer.areEqual('Mood', 'mood'), isTrue);
      expect(MetricNameNormalizer.areEqual('  ENERGY  ', 'energy'), isTrue);
      expect(MetricNameNormalizer.areEqual('Sleep', 'Mood'), isFalse);
    });

    test('should validate metric names', () {
      expect(MetricNameNormalizer.isValidName('Mood'), isTrue);
      expect(MetricNameNormalizer.isValidName('  Energy  '), isTrue);
      expect(MetricNameNormalizer.isValidName(''), isFalse);
      expect(MetricNameNormalizer.isValidName('   '), isFalse);
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
      final result = CaseInsensitiveAggregator.aggregateStrings(items);

      expect(result.length, equals(2));
      expect(result['Headache'], equals(3));
      expect(result['Migraine'], equals(2));
    });

    test('should preserve original casing in display names', () {
      final items = ['headache', 'Headache', 'HEADACHE'];
      final result = CaseInsensitiveAggregator.aggregateStrings(items);

      expect(result.containsKey('headache'), isTrue);
      expect(result['headache'], equals(3));
    });

    test('should group items by string key case-insensitively', () {
      final items = [
        {'name': 'Headache', 'severity': 5},
        {'name': 'headache', 'severity': 3},
        {'name': 'Migraine', 'severity': 8},
      ];

      final result = CaseInsensitiveAggregator.groupByString(
        items,
        (item) => item['name'] as String,
      );

      expect(result.length, equals(2));
      expect(result['Headache']?.length, equals(2));
      expect(result['Migraine']?.length, equals(1));
    });
  });
}
