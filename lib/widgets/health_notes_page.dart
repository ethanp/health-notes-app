import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

class const HealthNotesPage({
  required final String title,
  required final Widget body,
  final Widget? leading,
  final List<Widget> actions = const [],
  final Widget? floatingActionButton,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EScaffoldShell(
      contentMaxWidth: double.infinity,
      appBar: EAppHeader(title: title, leading: leading, actions: actions),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}
