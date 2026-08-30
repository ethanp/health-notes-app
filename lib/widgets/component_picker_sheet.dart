import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/symptom_component.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/widgets/health_notes_search_field.dart';

class const ComponentPickerSheet({
  required final String title,
  final String? subtitle,
  required final List<SymptomComponent> components,
  required final void Function(String name) onSelect,
  required final void Function(SymptomComponent component) onTogglePin,
  required final void Function(String name) onCreate,
}) extends StatefulWidget {
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<SymptomComponent> components,
    required void Function(String name) onSelect,
    required void Function(SymptomComponent component) onTogglePin,
    required void Function(String name) onCreate,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: EColors.backgroundLift,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.7,
        child: ComponentPickerSheet(
          title: title,
          subtitle: subtitle,
          components: components,
          onSelect: onSelect,
          onTogglePin: onTogglePin,
          onCreate: onCreate,
        ),
      ),
    );
  }

  @override
  State<ComponentPickerSheet> createState() => _ComponentPickerSheetState();
}

class _ComponentPickerSheetState() extends State<ComponentPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SymptomComponent> get filteredComponents {
    if (_searchQuery.isEmpty) return widget.components;
    final query = _searchQuery.toLowerCase();
    return widget.components
        .where((component) => component.normalizedName.contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final _GroupedComponents sections = _groupBySection(filteredComponents);
    return Column(
      children: [
        VSpace.m,
        _grabber(),
        VSpace.m,
        Text(widget.title, style: EText.headline.small),
        if (widget.subtitle != null) ...[
          VSpace.xs,
          Text(widget.subtitle!, style: EText.body.small),
        ],
        VSpace.m,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: HealthNotesSearchField(
            controller: _searchController,
            placeholder: 'Search...',
            onChanged: (value) => setState(() => _searchQuery = value),
            onClear: _searchQuery.isEmpty
                ? null
                : () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
          ),
        ),
        VSpace.m,
        Expanded(child: _componentList(sections)),
      ],
    );
  }

  Widget _grabber() {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: EColors.textMuted,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    );
  }

  Widget _componentList(_GroupedComponents sections) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (sections.pinned.isNotEmpty) ...[
          _sectionHeader('PINNED'),
          ...sections.pinned.map(_componentRow),
          VSpace.m,
        ],
        if (sections.recent.isNotEmpty) ...[
          _sectionHeader('RECENT'),
          ...sections.recent.map(_componentRow),
          VSpace.m,
        ],
        if (sections.historical.isNotEmpty) ...[
          _sectionHeader('HISTORICAL'),
          ...sections.historical.map(_componentRow),
          VSpace.m,
        ],
        if (filteredComponents.isEmpty) ...[
          VSpace.l,
          Center(child: Text('No matches', style: EText.body.medium.secondary)),
          VSpace.m,
        ],
        _createNewRow(),
        VSpace.xl,
      ],
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: EText.label.small),
    );
  }

  Widget _componentRow(SymptomComponent component) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: InkWell(
          onTap: () {
            widget.onSelect(component.name);
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => widget.onTogglePin(component),
                  child: Icon(
                    component.isPinned ? Icons.star : Icons.star_border,
                    size: 20,
                    color: component.isPinned
                        ? EColors.warning
                        : EColors.textMuted,
                  ),
                ),
                HSpace.m,
                Expanded(
                  child: Text(
                    component.name.isEmpty ? '(none)' : component.name,
                    style: EText.body.medium,
                  ),
                ),
                Text('(${component.displayCount})', style: EText.body.small),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _createNewRow() {
    return Material(
      color: EColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: () => _showCreateDialog(context),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: EColors.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 18, color: EColors.accent),
              HSpace.s,
              Text(
                'Create New',
                style: EText.body.medium.copyWith(color: EColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController(
      text: _searchQuery.isNotEmpty ? _searchQuery : '',
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'New ${widget.subtitle != null ? "Minor" : "Major"} Component',
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Enter name...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(dialogContext).pop();
              Navigator.of(this.context).pop();
              widget.onCreate(name);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(nameController.dispose);
  }

  _GroupedComponents _groupBySection(List<SymptomComponent> components) {
    final pinned = <SymptomComponent>[];
    final recent = <SymptomComponent>[];
    final historical = <SymptomComponent>[];

    for (final component in components) {
      switch (component.section) {
        case ComponentSection.pinned:
          pinned.add(component);
        case ComponentSection.recent:
          recent.add(component);
        case ComponentSection.historical:
          historical.add(component);
      }
    }

    return _GroupedComponents(
      pinned: pinned,
      recent: recent,
      historical: historical,
    );
  }
}

class _GroupedComponents({
  required final List<SymptomComponent> pinned,
  required final List<SymptomComponent> recent,
  required final List<SymptomComponent> historical,
});
