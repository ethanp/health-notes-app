import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/health_tool.dart';
import 'package:health_notes/models/health_tool_category.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/screens/health_note_view_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/date_utils.dart';
import 'package:health_notes/utils/note_filter_utils.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';
import 'package:health_notes/widgets/tool_activity_calendar.dart';
import 'package:health_notes/widgets/tool_note_card.dart';
import 'package:health_notes/theme/spacing.dart';

class ToolDetailScreen extends ConsumerStatefulWidget {
  final String toolId;
  final String? toolName;

  const ToolDetailScreen({required this.toolId, this.toolName});

  @override
  ConsumerState<ToolDetailScreen> createState() => _ToolDetailScreenState();
}

class _ToolDetailScreenState extends ConsumerState<ToolDetailScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolAsync = ref.watch(toolByIdProvider(widget.toolId));
    final notesAsync = ref.watch(healthNotesNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: EnhancedUIComponents.navigationBar(
        title: widget.toolName ?? 'Tool Details',
      ),
      child: SafeArea(
        child: toolAsync.when(
          data: (tool) => notesAsync.when(
            data: (notes) => buildContent(context, tool, notes),
            loading: () =>
                const SyncStatusWidget.loading(message: 'Loading notes...'),
            error: (error, stack) => Center(
              child: Text('Error: $error', style: AppTypography.error),
            ),
          ),
          loading: () =>
              const SyncStatusWidget.loading(message: 'Loading tool...'),
          error: (error, stack) =>
              Center(child: Text('Error: $error', style: AppTypography.error)),
        ),
      ),
    );
  }

  Widget buildContent(
    BuildContext context,
    HealthTool? tool,
    List<HealthNote> allNotes,
  ) {
    final toolNotes = NoteFilterUtils.byToolId(allNotes, widget.toolId);

    if (toolNotes.isEmpty) {
      return EnhancedUIComponents.emptyState(
        title: 'No usage history',
        message: 'This tool hasn\'t been applied to any health notes yet',
        icon: CupertinoIcons.wrench,
      );
    }

    final sortedNotes = NoteFilterUtils.sortByDateDescending(toolNotes);
    final activityData = generateActivityData(sortedNotes);
    final filteredNotes = applySearch(sortedNotes);
    final toolName = tool?.name ?? widget.toolName ?? 'Tool';

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () =>
              ref.read(healthNotesNotifierProvider.notifier).refreshNotes(),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (tool != null) ...[toolHeaderCard(tool), VSpace.l],
              statisticsCard(sortedNotes),
              VSpace.l,
              ToolActivityCalendar(
                toolName: toolName,
                activityData: activityData,
                onDateTap: (context, date, count) =>
                    handleDateTap(context, date, count, sortedNotes),
              ),
              VSpace.l,
              searchSection(),
              VSpace.l,
              notesSection(filteredNotes),
            ]),
          ),
        ),
      ],
    );
  }

  Widget toolHeaderCard(HealthTool tool) {
    final categoryAsync = ref.watch(categoryByIdProvider(tool.categoryId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.wrench,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              HSpace.m,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tool.name, style: AppTypography.headlineSmall),
                    VSpace.xs,
                    categoryAsync.when(
                      data: (category) => category != null
                          ? categoryBadge(category)
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (error, stack) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (tool.description.isNotEmpty) ...[
            VSpace.m,
            Text(tool.description, style: AppTypography.bodyMediumSecondary),
          ],
        ],
      ),
    );
  }

  Widget categoryBadge(HealthToolCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(category.name, style: AppTypography.caption),
    );
  }

  Widget statisticsCard(List<HealthNote> notes) {
    final totalUses = notes.fold<int>(
      0,
      (sum, note) =>
          sum +
          note.appliedTools.where((t) => t.toolId == widget.toolId).length,
    );

    final firstUse = notes.isNotEmpty ? notes.last.dateTime : null;
    final lastUse = notes.isNotEmpty ? notes.first.dateTime : null;

    final monthsSpan = firstUse != null && lastUse != null
        ? (lastUse.difference(firstUse).inDays / 30).clamp(1, double.infinity)
        : 1.0;
    final avgPerMonth = (totalUses / monthsSpan).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistics', style: AppTypography.labelLargePrimary),
          VSpace.m,
          Row(
            children: [
              Expanded(child: statItem('Total Uses', '$totalUses')),
              HSpace.m,
              Expanded(
                child: statItem(
                  'First Applied',
                  firstUse != null
                      ? AppDateUtils.formatShortDate(firstUse)
                      : '-',
                ),
              ),
            ],
          ),
          VSpace.m,
          Row(
            children: [
              Expanded(
                child: statItem(
                  'Last Applied',
                  lastUse != null ? AppDateUtils.formatShortDate(lastUse) : '-',
                ),
              ),
              HSpace.m,
              Expanded(child: statItem('Uses / Month', avgPerMonth)),
            ],
          ),
        ],
      ),
    );
  }

  Widget statItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          VSpace.xs,
          Text(value, style: AppTypography.headlineMedium),
        ],
      ),
    );
  }

  Widget searchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Search Notes', style: AppTypography.labelLarge),
        VSpace.s,
        EnhancedUIComponents.searchField(
          controller: searchController,
          placeholder: 'Search notes...',
          onChanged: (query) => setState(() => searchQuery = query),
        ),
      ],
    );
  }

  Widget notesSection(List<HealthNote> notes) {
    if (notes.isEmpty) {
      return EnhancedUIComponents.emptyState(
        title: 'No matching notes',
        message: 'Try adjusting your search terms',
        icon: CupertinoIcons.search,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Notes (${notes.length})',
          style: AppTypography.headlineSmall,
        ),
        VSpace.s,
        ...notes.map((note) => ToolNoteCard(note: note, toolId: widget.toolId)),
      ],
    );
  }

  Map<DateTime, int> generateActivityData(List<HealthNote> notes) {
    final data = <DateTime, int>{};

    for (final note in notes) {
      final dateKey = DateTime(
        note.dateTime.year,
        note.dateTime.month,
        note.dateTime.day,
      );
      final usageCount = note.appliedTools
          .where((t) => t.toolId == widget.toolId)
          .length;
      data.update(
        dateKey,
        (count) => count + usageCount,
        ifAbsent: () => usageCount,
      );
    }

    return data;
  }

  List<HealthNote> applySearch(List<HealthNote> notes) {
    if (searchQuery.isEmpty) return notes;
    return NoteFilterUtils.bySearchQuery(notes, searchQuery);
  }

  void handleDateTap(
    BuildContext context,
    DateTime date,
    int count,
    List<HealthNote> allNotes,
  ) {
    if (count == 0) {
      showCupertinoDialog(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(AppDateUtils.formatLongDate(date)),
          content: const Text('No uses on this date.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      );
      return;
    }

    final dateKey = DateTime(date.year, date.month, date.day);
    final notesForDate = allNotes.where((note) {
      final noteDate = DateTime(
        note.dateTime.year,
        note.dateTime.month,
        note.dateTime.day,
      );
      return noteDate.isAtSameMomentAs(dateKey);
    }).toList();

    if (notesForDate.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(AppDateUtils.formatLongDate(date)),
          content: Text('$count use${count == 1 ? '' : 's'} on this date.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      );
      return;
    }

    if (notesForDate.length == 1) {
      final note = notesForDate.first;
      final appliedTool = note.appliedTools.firstWhere(
        (t) => t.toolId == widget.toolId,
        orElse: () => note.appliedTools.first,
      );

      showCupertinoDialog(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(AppDateUtils.formatLongDate(date)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              usageBadge(count),
              if (appliedTool.note.isNotEmpty) ...[
                VSpace.m,
                Text(appliedTool.note, style: AppTypography.bodyMediumWhite),
              ],
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Close'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('View Note'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.push((_) => HealthNoteViewScreen(note: note));
              },
            ),
          ],
        ),
      );
    } else {
      showCupertinoDialog(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(AppDateUtils.formatLongDate(date)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              usageBadge(count),
              VSpace.m,
              Text(
                'Applied in ${notesForDate.length} note${notesForDate.length == 1 ? '' : 's'}',
                style: AppTypography.bodyMediumWhite,
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Close'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ...notesForDate
                .take(3)
                .map(
                  (note) => CupertinoDialogAction(
                    child: Text(AppDateUtils.formatTime(note.dateTime)),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.push((_) => HealthNoteViewScreen(note: note));
                    },
                  ),
                ),
          ],
        ),
      );
    }
  }

  Widget usageBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        '$count use${count == 1 ? '' : 's'}',
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
