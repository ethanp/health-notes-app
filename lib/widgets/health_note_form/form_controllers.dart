import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/utils/number_formatter.dart';

class DrugDoseControllers(DrugDose dose) {
  final TextEditingController name = TextEditingController(
    text: dose.name.display,
  );
  final TextEditingController dosage = TextEditingController(
    text: dose.dosage == 0 ? '' : formatDecimalValue(dose.dosage),
  );
  final TextEditingController unit = TextEditingController(text: dose.unit);

  void dispose() {
    name.dispose();
    dosage.dispose();
    unit.dispose();
  }
}

class SymptomControllers(Symptom symptom) {
  final TextEditingController severity = TextEditingController(
    text: symptom.severityLevel.toString(),
  );
  final TextEditingController additionalNotes = TextEditingController(
    text: symptom.additionalNotes,
  );

  void dispose() {
    severity.dispose();
    additionalNotes.dispose();
  }
}
