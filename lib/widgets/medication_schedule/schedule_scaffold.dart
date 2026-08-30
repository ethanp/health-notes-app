import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

class const MedicationScheduleScaffold({
  required final String title,
  required final Widget body,
  final List<Widget>? actions,
  final Widget? floatingActionButton,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EScaffoldShell(
      contentMaxWidth: double.infinity,
      appBar: EAppHeader(title: title, actions: actions ?? const []),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}
