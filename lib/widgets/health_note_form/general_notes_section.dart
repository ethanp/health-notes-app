import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/accent_border_card.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/theme/spacing.dart';

class GeneralNotesSection extends StatelessWidget {
  final bool isEditable;
  final TextEditingController? notesController;
  final Function(String)? onNotesChanged;

  const GeneralNotesSection({
    super.key,
    required this.isEditable,
    this.notesController,
    this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: isEditable
          ? AppComponents.inputField
          : AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_header(), VSpace.s, _content()],
      ),
    );
  }

  Widget _header() {
    return EnhancedUIComponents.sectionHeader(title: 'Notes');
  }

  Widget _content() {
    if (isEditable) {
      return CupertinoTextField(
        controller: notesController,
        placeholder: 'Additional Notes (optional)',
        placeholderStyle: AppTypography.inputPlaceholder,
        style: AppTypography.input,
        maxLines: 4,
        onChanged: onNotesChanged,
      );
    }

    if (notesController?.text.isNotEmpty != true) {
      return Text('No additional notes', style: AppTypography.bodyMedium);
    }

    return AccentBorderCard(
      accentColor: AppColors.primary,
      margin: EdgeInsets.zero,
      child: Text(notesController!.text, style: AppTypography.bodyMedium),
    );
  }
}
