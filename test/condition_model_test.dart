import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/condition.dart';

void main() {
  group('Condition', () {
    test('JSON serialization roundtrip', () {
      final now = DateTime.now();
      final condition = Condition(
        id: 'c1',
        userId: 'u1',
        name: 'Migraine',
        startDate: now,
        endDate: null,
        status: ConditionStatus.active,
        colorValue: 0xFFE57373,
        iconCodePoint: 0xf36e,
        notes: 'Test notes',
        createdAt: now,
        updatedAt: now,
      );

      final json = condition.toJson();
      final from = Condition.fromJson(json);
      
      expect(from.id, condition.id);
      expect(from.userId, condition.userId);
      expect(from.name, condition.name);
      expect(from.status, condition.status);
      expect(from.colorValue, condition.colorValue);
      expect(from.iconCodePoint, condition.iconCodePoint);
      expect(from.notes, condition.notes);
    });

    test('JSON serialization with resolved status', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 5);
      final condition = Condition(
        id: 'c2',
        userId: 'u1',
        name: 'Cold',
        startDate: start,
        endDate: end,
        status: ConditionStatus.resolved,
        createdAt: start,
        updatedAt: end,
      );

      final json = condition.toJson();
      final from = Condition.fromJson(json);
      
      expect(from.status, ConditionStatus.resolved);
      expect(from.endDate, isNotNull);
    });

    test('isActive returns true for active conditions', () {
      final condition = Condition(
        id: 'c1',
        userId: 'u1',
        name: 'Test',
        startDate: DateTime.now(),
        status: ConditionStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(condition.isActive, true);
      expect(condition.isResolved, false);
    });

    test('isResolved returns true for resolved conditions', () {
      final condition = Condition(
        id: 'c1',
        userId: 'u1',
        name: 'Test',
        startDate: DateTime.now(),
        status: ConditionStatus.resolved,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(condition.isActive, false);
      expect(condition.isResolved, true);
    });

    test('durationDays calculates correctly for active condition', () {
      final startDate = DateTime.now().subtract(const Duration(days: 5));
      final condition = Condition(
        id: 'c1',
        userId: 'u1',
        name: 'Test',
        startDate: startDate,
        status: ConditionStatus.active,
        createdAt: startDate,
        updatedAt: startDate,
      );

      expect(condition.durationDays, 6);
    });

    test('durationDays calculates correctly for resolved condition', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 5);
      final condition = Condition(
        id: 'c1',
        userId: 'u1',
        name: 'Test',
        startDate: startDate,
        endDate: endDate,
        status: ConditionStatus.resolved,
        createdAt: startDate,
        updatedAt: endDate,
      );

      expect(condition.durationDays, 5);
    });

    test('toJsonForUpdate includes correct fields', () {
      final condition = Condition(
        id: 'c1',
        userId: 'u1',
        name: 'Migraine',
        startDate: DateTime(2024, 1, 1),
        status: ConditionStatus.active,
        colorValue: 0xFFE57373,
        iconCodePoint: 0xf36e,
        notes: 'Test',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final json = condition.toJsonForUpdate();
      
      expect(json['name'], 'Migraine');
      expect(json['condition_status'], 'active');
      expect(json['color_value'], 0xFFE57373);
      expect(json['icon_code_point'], 0xf36e);
      expect(json['notes'], 'Test');
      expect(json.containsKey('start_date'), true);
      expect(json.containsKey('updated_at'), true);
    });

    test('ConditionStatus displayName returns correct values', () {
      expect(ConditionStatus.active.displayName, 'Active');
      expect(ConditionStatus.resolved.displayName, 'Resolved');
    });
  });
}

