import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/applied_tool.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/symptom.dart';

void main() {
  test('AppliedTool JSON serialization roundtrip', () {
    final tool = AppliedTool(toolId: 't1', toolName: 'Breathing', note: '5m');
    final json = tool.toJson();
    final from = AppliedTool.fromJson(json);
    expect(from, tool);
  });

  test('HealthNote includes appliedTools in toJsonForUpdate', () {
    final note = HealthNote(
      id: 'n1',
      dateTime: DateTime.parse('2024-01-01T00:00:00Z'),
      symptomsList: const [
        Symptom(
          severityLevel: 5,
          majorComponent: 'Headache',
          minorComponent: 'Right',
          additionalNotes: '',
        ),
      ],
      drugDoses: const [DrugDose(name: 'Ibuprofen', dosage: 200, unit: 'mg')],
      appliedTools: const [
        AppliedTool(toolId: 't1', toolName: 'Breathing', note: '5m'),
      ],
      notes: 'ok',
      createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
    );

    final json = note.toJsonForUpdate();
    expect(json['applied_tools'], isA<List>());
    final list = json['applied_tools'] as List<dynamic>;
    expect(list.length, 1);
    expect(list.first['tool_id'], 't1');
    expect(list.first['tool_name'], 'Breathing');
    expect(list.first['note'], '5m');
  });
}

