import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/models/medication_schedule.dart';

void main() {
  final createdAt = DateTime(2026, 1, 1);
  final prednisoneStart = DateTime(2026, 3, 1);

  MedicationSchedule prednisone({DateTime? endDate}) {
    return MedicationSchedule(
      id: 'pred-1',
      userId: 'user-1',
      medicationName: const DrugName('Prednisone'),
      startDate: prednisoneStart,
      endDate: endDate,
      steps: [
        ScheduleStep(
          id: 'step-40',
          durationDays: 7,
          doses: [
            ScheduledDose(
              id: 'dose-40',
              amount: 40,
              when: const DoseWhen.partOfDay(PartOfDay.morning),
            ),
          ],
        ),
        ScheduleStep(
          id: 'step-30',
          durationDays: 3,
          doses: [
            ScheduledDose(
              id: 'dose-30',
              amount: 30,
              when: const DoseWhen.partOfDay(PartOfDay.morning),
            ),
          ],
        ),
      ],
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  MedicationSchedule gabapentin() {
    return MedicationSchedule(
      id: 'gaba-1',
      userId: 'user-1',
      medicationName: const DrugName('Gabapentin'),
      startDate: DateTime(2026, 8, 12),
      steps: [
        ScheduleStep(
          id: 'step-daily',
          doses: [
            ScheduledDose(
              id: 'slot-am',
              amount: 200,
              when: const DoseWhen.clock(hour: 10, minute: 30),
            ),
            ScheduledDose(
              id: 'slot-afternoon',
              amount: 200,
              when: const DoseWhen.clock(hour: 16, minute: 30),
            ),
            ScheduledDose(
              id: 'slot-pm',
              amount: 300,
              when: const DoseWhen.clock(hour: 22, minute: 30),
            ),
          ],
        ),
      ],
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  group('sentence', () {
    test('reads a taper as a course of days', () {
      expect(
        prednisone().sentence,
        '40mg each morning for 7 days, then 30mg for 3 days',
      );
    });

    test('reads daily clock times without a duration', () {
      expect(
        gabapentin().sentence,
        '200mg at 10:30 AM, 200mg at 4:30 PM, 300mg at 10:30 PM',
      );
    });
  });

  group('taper day boundaries', () {
    test('covers only the 10 days from start', () {
      final schedule = prednisone();
      expect(schedule.covers(DateTime(2026, 2, 28)), isFalse);
      expect(schedule.covers(DateTime(2026, 3, 1)), isTrue);
      expect(schedule.covers(DateTime(2026, 3, 7)), isTrue);
      expect(schedule.covers(DateTime(2026, 3, 8)), isTrue);
      expect(schedule.covers(DateTime(2026, 3, 10)), isTrue);
      expect(schedule.covers(DateTime(2026, 3, 11)), isFalse);
    });

    test('uses the 40mg step for the first 7 mornings', () {
      final schedule = prednisone();
      final firstMorning = schedule.occurrencesOn(DateTime(2026, 3, 1)).single;
      expect(firstMorning.scheduledDose.amount, 40);
      expect(firstMorning.stepProgressCaption, '1 of 7 mornings');

      final seventhMorning = schedule.occurrencesOn(DateTime(2026, 3, 7)).single;
      expect(seventhMorning.scheduledDose.amount, 40);
      expect(seventhMorning.stepProgressCaption, '7 of 7 mornings');
    });

    test('uses the 30mg step for the next 3 mornings', () {
      final schedule = prednisone();
      final eighthMorning = schedule.occurrencesOn(DateTime(2026, 3, 8)).single;
      expect(eighthMorning.scheduledDose.amount, 30);
      expect(eighthMorning.stepProgressCaption, '1 of 3 mornings');

      final lastMorning = schedule.occurrencesOn(DateTime(2026, 3, 10)).single;
      expect(lastMorning.scheduledDose.amount, 30);
      expect(lastMorning.stepProgressCaption, '3 of 3 mornings');
      expect(schedule.occurrencesOn(DateTime(2026, 3, 11)), isEmpty);
    });

    test('stop on day 4 ends coverage that calendar day', () {
      final schedule = prednisone(endDate: DateTime(2026, 3, 4));
      expect(schedule.covers(DateTime(2026, 3, 4)), isTrue);
      expect(schedule.covers(DateTime(2026, 3, 5)), isFalse);
    });
  });

  group('open-ended multi-slot day', () {
    test('returns three clock slots on a covered day', () {
      final schedule = gabapentin();
      final occurrences = schedule.occurrencesOn(DateTime(2026, 8, 20));
      expect(occurrences.map((occurrence) => occurrence.scheduledDose.id), [
        'slot-am',
        'slot-afternoon',
        'slot-pm',
      ]);
      expect(occurrences.map((occurrence) => occurrence.amountCaption), [
        '200mg',
        '200mg',
        '300mg',
      ]);
      expect(occurrences.map((occurrence) => occurrence.whenCaption), [
        '10:30 AM',
        '4:30 PM',
        '10:30 PM',
      ]);
    });

    test('does not cover days before start', () {
      expect(gabapentin().covers(DateTime(2026, 8, 11)), isFalse);
    });
  });

  group('DosesWaitingForNote', () {
    test('keeps two 200mg slots distinct after one is logged', () {
      final schedule = gabapentin();
      final day = DateTime(2026, 8, 20, 16, 40);
      final morningDose = schedule.occurrencesOn(day).first.asDrugDose;
      expect(morningDose.fromSchedule?.scheduledDoseId, 'slot-am');

      final waiting = DosesWaitingForNote(
        schedules: [schedule],
        day: day,
        alreadyLogged: [morningDose],
      ).waiting;

      expect(waiting.map((occurrence) => occurrence.scheduledDoseId), [
        'slot-afternoon',
        'slot-pm',
      ]);
    });

    test('hides a taper dose logged on another note the same day', () {
      final schedule = prednisone();
      final day = DateTime(2026, 3, 3, 9);
      final logged = schedule.occurrencesOn(day).single.asDrugDose;

      expect(
        DosesWaitingForNote(
          schedules: [schedule],
          day: day,
          alreadyLogged: [logged],
        ).waiting,
        isEmpty,
      );
    });

    test('does not hide an ad-hoc matching amount without a schedule ref', () {
      final schedule = prednisone();
      final day = DateTime(2026, 3, 3);
      final waiting = DosesWaitingForNote(
        schedules: [schedule],
        day: day,
        alreadyLogged: [const DrugDose(name: DrugName('Prednisone'), dosage: 40)],
      ).waiting;

      expect(waiting.single.scheduledDoseId, 'dose-40');
    });

    test('nearestTo prefers the slot closest to the note time', () {
      final schedule = gabapentin();
      final nearest = DosesWaitingForNote(
        schedules: [schedule],
        day: DateTime(2026, 8, 20),
        alreadyLogged: const [],
      ).nearestTo(DateTime(2026, 8, 20, 16, 40));

      expect(nearest?.scheduledDoseId, 'slot-afternoon');
    });
  });

  group('DrugDose from a schedule', () {
    test('asDrugDose stamps the slot so fullDisplay includes when', () {
      final dose = gabapentin()
          .occurrencesOn(DateTime(2026, 8, 20))
          .first
          .asDrugDose;
      expect(dose.fullDisplay, 'Gabapentin - 200mg · 10:30 AM');
    });

    test('JSON roundtrip keeps LoggedFromSchedule', () {
      const dose = DrugDose(
        name: DrugName('Gabapentin'),
        dosage: 200,
        fromSchedule: LoggedFromSchedule(
          scheduleId: 'gaba-1',
          scheduledDoseId: 'slot-am',
          whenCaption: '10:30 AM',
        ),
      );
      final restored = DrugDose.fromJson(dose.toJson());
      expect(restored.fromSchedule?.scheduleId, 'gaba-1');
      expect(restored.fromSchedule?.scheduledDoseId, 'slot-am');
    });
  });
}
