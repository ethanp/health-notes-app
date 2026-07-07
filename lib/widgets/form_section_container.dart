import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';

class FormSectionContainer extends StatelessWidget {
  final bool isEditable;
  final Widget child;

  const FormSectionContainer({
    super.key,
    required this.isEditable,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: isEditable
          ? AppComponents.inputField
          : AppComponents.primaryCard,
      child: child,
    );
  }
}
