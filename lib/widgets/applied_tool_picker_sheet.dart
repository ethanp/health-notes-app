import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_tool.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/health_notes_search_field.dart';
import 'package:health_notes/theme/spacing.dart';

class const AppliedToolPickerSheet({
  required final List<dynamic> appliedTools,
  required final void Function(HealthTool tool) onSelect,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<AppliedToolPickerSheet> createState() =>
      _AppliedToolPickerSheetState();
}

class _AppliedToolPickerSheetState()
    extends ConsumerState<AppliedToolPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  double _dragOffset = 0.0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        final dy = _dragOffset + details.delta.dy;
        if (dy >= 0) setState(() => _dragOffset = dy);
      },
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0.0;
        if (_dragOffset > 120 || velocity > 800) {
          Navigator.of(context).pop();
        } else {
          setState(() => _dragOffset = 0.0);
        }
      },
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.7,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.extraLarge),
                topRight: Radius.circular(AppRadius.extraLarge),
              ),
              child: Container(
                color: EColors.backgroundLift,
                child: SafeArea(top: false, child: sheetContent()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget sheetContent() {
    return Column(
      children: [
        VSpace.s,
        grabber(),
        VSpace.sm,
        headerRow(),
        paddingHorizontal(searchField()),
        VSpace.s,
        Expanded(child: toolsList()),
      ],
    );
  }

  Widget grabber() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: EColors.borderStrong,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    );
  }

  Widget headerRow() {
    return paddingHorizontal(
      Row(
        children: [
          Expanded(child: Text('Select a tool', style: EText.headline.small)),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget searchField() {
    return HealthNotesSearchField(
      controller: _searchController,
      placeholder: 'Search tools',
      onChanged: (_) => setState(() {}),
      onClear: _searchController.text.isNotEmpty
          ? () {
              _searchController.clear();
              setState(() {});
            }
          : null,
    );
  }

  Widget toolsList() {
    final toolsAsync = ref.watch(healthToolsProvider);
    return toolsAsync.when(
      data: (tools) {
        final q = _searchController.text.trim().toLowerCase();
        final filtered = q.isEmpty
            ? tools
            : tools.where((t) => t.name.toLowerCase().contains(q)).toList();

        if (filtered.isEmpty) {
          return EEmptyState(
            title: 'No tools found',
            message: 'Try a different search or add tools in Library → Tools',
            icon: Icons.search,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.m),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => VSpace.s,
          itemBuilder: (context, i) {
            final t = filtered[i];
            final isSelected = widget.appliedTools.any(
              (at) => at.toolId == t.id,
            );
            return toolListItem(t, isSelected);
          },
        );
      },
      loading: () => ELoadingState(message: 'Loading tools...'),
      error: (e, st) => Center(child: Text('Error: $e', style: EText.error)),
    );
  }

  Widget toolListItem(HealthTool tool, bool isSelected) {
    return GestureDetector(
      onTap: () => onSelect(tool),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppComponents.primaryCardWithBorder,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tool.name, style: EText.label.large),
                  VSpace.xs,
                  Text(
                    tool.description,
                    style: EText.body.small.secondary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            HSpace.m,
            if (isSelected)
              Text('Selected', style: EText.body.small.muted.semibold),
          ],
        ),
      ),
    );
  }

  void onSelect(HealthTool tool) {
    widget.onSelect(tool);
  }

  Widget paddingHorizontal(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: child,
    );
  }
}
