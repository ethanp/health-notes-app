import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/condition_entry.dart';

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

    test('ConditionPhase displayName returns correct values', () {
      expect(ConditionPhase.onset.displayName, 'Onset');
      expect(ConditionPhase.worsening.displayName, 'Worsening');
      expect(ConditionPhase.peak.displayName, 'Peak');
      expect(ConditionPhase.improving.displayName, 'Improving');
    });

    test('ConditionPhase colors are distinct', () {
      final colors = ConditionPhase.values.map((p) => p.color).toSet();
      expect(colors.length, ConditionPhase.values.length);
    });
  });

  group('ConditionEntryDraft', () {
    test('creates with default values', () {
      final draft = ConditionEntryDraft(
        conditionId: 'c1',
        conditionName: 'Cold',
        conditionColor: const Color(0xFFE57373),
      );

      expect(draft.conditionId, 'c1');
      expect(draft.conditionName, 'Cold');
      expect(draft.severity, 5);
      expect(draft.phase, ConditionPhase.onset);
      expect(draft.notes, '');
      expect(draft.markResolved, false);
    });

    test('can modify mutable fields', () {
      final draft = ConditionEntryDraft(
        conditionId: 'c1',
        conditionName: 'Cold',
        conditionColor: const Color(0xFFE57373),
      );

      draft.severity = 8;
      draft.phase = ConditionPhase.peak;
      draft.notes = 'Very bad today';
      draft.markResolved = true;

      expect(draft.severity, 8);
      expect(draft.phase, ConditionPhase.peak);
      expect(draft.notes, 'Very bad today');
      expect(draft.markResolved, true);
    });
  });
}
