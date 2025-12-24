import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/symptom_component.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

class ComponentPickerSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<SymptomComponent> components;
  final void Function(String name) onSelect;
  final void Function(SymptomComponent component) onTogglePin;
  final void Function(String name) onCreate;

  const ComponentPickerSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.components,
    required this.onSelect,
    required this.onTogglePin,
    required this.onCreate,
  });

  @override
  State<ComponentPickerSheet> createState() => _ComponentPickerSheetState();
}

class _ComponentPickerSheetState extends State<ComponentPickerSheet> {
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
        .where((c) => c.normalizedName.contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupBySection(filteredComponents);
    final hasResults = filteredComponents.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VSpace.m,
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textQuaternary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          VSpace.m,
          Text(widget.title, style: AppTypography.headlineSmall),
          if (widget.subtitle != null) ...[
            VSpace.xs,
            Text(widget.subtitle!, style: AppTypography.bodySmall),
          ],
          VSpace.m,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: 'Search...',
              style: AppTypography.bodyMedium,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          VSpace.m,
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (grouped.pinned.isNotEmpty) ...[
                  _sectionHeader('PINNED'),
                  ...grouped.pinned.map(_componentRow),
                  VSpace.m,
                ],
                if (grouped.recent.isNotEmpty) ...[
                  _sectionHeader('RECENT'),
                  ...grouped.recent.map(_componentRow),
                  VSpace.m,
                ],
                if (grouped.historical.isNotEmpty) ...[
                  _sectionHeader('HISTORICAL'),
                  ...grouped.historical.map(_componentRow),
                  VSpace.m,
                ],
                if (!hasResults) ...[
                  VSpace.l,
                  Center(
                    child: Text(
                      'No matches',
                      style: AppTypography.bodyMediumSecondary,
                    ),
                  ),
                  VSpace.m,
                ],
                _createNewRow(),
                VSpace.xl,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTypography.labelSmall),
    );
  }

  Widget _componentRow(SymptomComponent component) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          widget.onSelect(component.name);
          Navigator.of(context).pop();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundTertiary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => widget.onTogglePin(component),
                child: Icon(
                  component.isPinned
                      ? CupertinoIcons.star_fill
                      : CupertinoIcons.star,
                  size: 20,
                  color: component.isPinned
                      ? AppColors.accentWarm
                      : AppColors.textQuaternary,
                ),
              ),
              HSpace.m,
              Expanded(
                child: Text(
                  component.name.isEmpty ? '(none)' : component.name,
                  style: AppTypography.bodyMedium,
                ),
              ),
              Text(
                '(${component.displayCount})',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createNewRow() {
    return GestureDetector(
      onTap: () => _showCreateDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.add, size: 18, color: AppColors.primary),
            HSpace.s,
            Text(
              'Create New',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController(
      text: _searchQuery.isNotEmpty ? _searchQuery : '',
    );

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'New ${widget.subtitle != null ? "Minor" : "Major"} Component',
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Enter name...',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop();
                Navigator.of(this.context).pop();
                widget.onCreate(name);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  _GroupedComponents _groupBySection(List<SymptomComponent> components) {
    final pinned = <SymptomComponent>[];
    final recent = <SymptomComponent>[];
    final historical = <SymptomComponent>[];

    for (final c in components) {
      switch (c.section) {
        case ComponentSection.pinned:
          pinned.add(c);
        case ComponentSection.recent:
          recent.add(c);
        case ComponentSection.historical:
          historical.add(c);
      }
    }

    return _GroupedComponents(
      pinned: pinned,
      recent: recent,
      historical: historical,
    );
  }
}

class _GroupedComponents {
  final List<SymptomComponent> pinned;
  final List<SymptomComponent> recent;
  final List<SymptomComponent> historical;

  _GroupedComponents({
    required this.pinned,
    required this.recent,
    required this.historical,
  });
}
