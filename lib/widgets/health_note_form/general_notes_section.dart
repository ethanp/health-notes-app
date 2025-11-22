import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/spacing.dart';

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
    return Text('Notes', style: AppTypography.labelLarge);
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

    final text = notesController?.text.isNotEmpty == true
        ? notesController!.text
        : 'No additional notes';
    return Text(text, style: AppTypography.bodyMedium);
  }
}
