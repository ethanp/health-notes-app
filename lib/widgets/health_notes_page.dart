import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

class HealthNotesPage extends StatelessWidget {
  const HealthNotesPage({
    required this.title,
    required this.body,
    this.leading,
    this.actions = const [],
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? floatingActionButton;

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
