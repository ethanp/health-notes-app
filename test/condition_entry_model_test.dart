import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/ui/condition_appearance.dart';

void main() {
  group('ConditionEntry', () {
    test('JSON serialization roundtrip', () {
      final now = DateTime.now();
      final entry = ConditionEntry(
        id: 'e1',
        conditionId: 'c1',
        entryDate: now,
        severity: 7,
        phase: ConditionPhase.peak,
        notes: 'Feeling worse today',
        linkedCheckInId: 'ch1',
        createdAt: now,
        updatedAt: now,
      );

      final json = entry.toJson();
      final from = ConditionEntry.fromJson(json);

      expect(from.id, entry.id);
      expect(from.conditionId, entry.conditionId);
      expect(from.severity, entry.severity);
      expect(from.phase, entry.phase);
      expect(from.notes, entry.notes);
      expect(from.linkedCheckInId, entry.linkedCheckInId);
    });

    test('JSON serialization with all phases', () {
      for (final phase in ConditionPhase.values) {
        final entry = ConditionEntry(
          id: 'e1',
          conditionId: 'c1',
          entryDate: DateTime.now(),
          severity: 5,
          phase: phase,
          notes: '',
          linkedCheckInId: 'ch1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final json = entry.toJson();
        final from = ConditionEntry.fromJson(json);

        expect(from.phase, phase);
      }
    });

    test('toJsonForUpdate includes correct fields', () {
      final entry = ConditionEntry(
        id: 'e1',
        conditionId: 'c1',
        entryDate: DateTime(2024, 1, 15),
        severity: 6,
        phase: ConditionPhase.improving,
        notes: 'Better today',
        linkedCheckInId: 'ch1',
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 15),
      );

      final json = entry.toJsonForUpdate();

      expect(json['condition_id'], 'c1');
      expect(json['severity'], 6);
      expect(json['phase'], 'improving');
      expect(json['notes'], 'Better today');
      expect(json['linked_check_in_id'], 'ch1');
      expect(json.containsKey('entry_date'), true);
      expect(json.containsKey('updated_at'), true);
    });

    test('ConditionPhase colors are distinct', () {
      final colors = ConditionPhase.values.map((p) => p.color).toSet();
      expect(colors.length, ConditionPhase.values.length);
    });
  });
}
