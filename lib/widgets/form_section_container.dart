import 'package:health_notes/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

class const FormSectionContainer({
  required final bool isEditable,
  required final Widget child,
}) extends StatelessWidget {
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
