import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/widgets/accent_border_card.dart';
import 'package:health_notes/widgets/form_section_container.dart';
import 'package:health_notes/theme/spacing.dart';

class const GeneralNotesSection({
  required final bool isEditable,
  final TextEditingController? notesController,
  final Function(String)? onNotesChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FormSectionContainer(
      isEditable: isEditable,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_header(), VSpace.s, _content()],
      ),
    );
  }

  Widget _header() {
    return ESectionHeader(title: 'Notes');
  }

  Widget _content() {
    if (isEditable) {
      return CupertinoTextField(
        controller: notesController,
        placeholder: 'Additional Notes (optional)',
        placeholderStyle: EText.body.medium.muted,
        style: EText.body.medium,
        maxLines: 4,
        onChanged: onNotesChanged,
      );
    }

    if (notesController?.text.isNotEmpty != true) {
      return Text('No additional notes', style: EText.body.medium);
    }

    return AccentBorderCard(
      accentColor: EColors.accent,
      margin: EdgeInsets.zero,
      child: Text(notesController!.text, style: EText.body.medium),
    );
  }
}
