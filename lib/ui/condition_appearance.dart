import 'package:flutter/material.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/models/condition_entry.dart';

extension ConditionAppearance on Condition {
  Color get color => Color(colorValue);

  IconData get icon => IconData(
    iconCodePoint, // ignore: non_const_argument_for_const_parameter
    fontFamily: 'MaterialIcons',
  );
}

extension ConditionPhaseAppearance on ConditionPhase {
  Color get color => switch (this) {
    ConditionPhase.onset => const Color(0xFFFF9500),
    ConditionPhase.worsening => const Color(0xFFFF3B30),
    ConditionPhase.peak => const Color(0xFFD32F2F),
    ConditionPhase.improving => const Color(0xFF34C759),
  };
}

extension ConditionEntryDraftAppearance on ConditionEntryDraft {
  Color get color => Color(colorValue);
}
