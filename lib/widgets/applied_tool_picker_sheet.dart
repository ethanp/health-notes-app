import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_tool.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/theme/spacing.dart';

class AppliedToolPickerSheet extends ConsumerStatefulWidget {
  final List<dynamic> appliedTools;
  final void Function(HealthTool tool) onSelect;

  const AppliedToolPickerSheet({
    super.key,
    required this.appliedTools,
    required this.onSelect,
  });

  @override
  ConsumerState<AppliedToolPickerSheet> createState() =>
      _AppliedToolPickerSheetState();
}

class _AppliedToolPickerSheetState
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
                color: AppColors.backgroundSecondary,
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
        VSpace.of(12),
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
        color: AppColors.backgroundQuinary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget headerRow() {
    return paddingHorizontal(
      Row(
        children: [
          Expanded(
            child: Text('Select a tool', style: AppTypography.headlineSmall),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(CupertinoIcons.xmark),
          ),
        ],
      ),
    );
  }

  Widget searchField() {
    return EnhancedUIComponents.searchField(
      controller: _searchController,
      placeholder: 'Search tools',
      onChanged: (_) => setState(() {}),
      showSuffix: _searchController.text.isNotEmpty,
      onSuffixTap: () {
        _searchController.clear();
        setState(() {});
      },
    );
  }

  Widget toolsList() {
    final toolsAsync = ref.watch(healthToolsNotifierProvider);
    return toolsAsync.when(
      data: (tools) {
        final q = _searchController.text.trim().toLowerCase();
        final filtered = q.isEmpty
            ? tools
            : tools.where((t) => t.name.toLowerCase().contains(q)).toList();

        if (filtered.isEmpty) {
          return EnhancedUIComponents.emptyState(
            title: 'No tools found',
            message: 'Try a different search or add tools in My Tools',
            icon: CupertinoIcons.search,
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
      loading: () =>
          EnhancedUIComponents.loadingIndicator(message: 'Loading tools...'),
      error: (e, st) =>
          Center(child: Text('Error: $e', style: AppTypography.error)),
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
                  Text(tool.name, style: AppTypography.labelLarge),
                  VSpace.xs,
                  Text(
                    tool.description,
                    style: AppTypography.bodySmallSecondary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            HSpace.m,
            if (isSelected)
              Text(
                'Selected',
                style: AppTypography.bodySmallSystemGreySemibold,
              ),
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
