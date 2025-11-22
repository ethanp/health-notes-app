import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/symptom.dart';

class DrugDoseControllers {
  final TextEditingController name;
  final TextEditingController dosage;
  final TextEditingController unit;

  DrugDoseControllers(DrugDose dose)
      : name = TextEditingController(text: dose.name),
        dosage = TextEditingController(text: dose.dosage.toString()),
        unit = TextEditingController(text: dose.unit);

  void dispose() {
    name.dispose();
    dosage.dispose();
    unit.dispose();
  }
}

class SymptomControllers {
  final TextEditingController majorComponent;
  final TextEditingController minorComponent;
  final TextEditingController severity;
  final TextEditingController additionalNotes;

  SymptomControllers(Symptom symptom)
      : majorComponent = TextEditingController(text: symptom.majorComponent),
        minorComponent = TextEditingController(text: symptom.minorComponent),
        severity = TextEditingController(text: symptom.severityLevel.toString()),
        additionalNotes = TextEditingController(text: symptom.additionalNotes);

  void dispose() {
    majorComponent.dispose();
    minorComponent.dispose();
    severity.dispose();
    additionalNotes.dispose();
  }
}
