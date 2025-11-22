import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/note_filter_utils.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/spacing.dart';
import 'package:health_notes/widgets/trends_components.dart';

abstract class BaseTrendsScreen extends ConsumerStatefulWidget {
  final String itemName;

  const BaseTrendsScreen({required this.itemName});
}

abstract class BaseTrendsState<T extends BaseTrendsScreen, V extends num>
    extends ConsumerState<T> {
  String get itemNoun;

  late final TextEditingController searchController;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<HealthNote> filterSourceNotes(List<HealthNote> notes);

  Map<DateTime, V> buildActivityData(List<HealthNote> notes);

  Widget buildActivityContent(
    Map<DateTime, V> activityData,
    List<HealthNote> sortedNotes,
  );

  List<Widget> buildNotesContent(List<HealthNote> notes);

  Widget? buildNotesHeader(List<HealthNote> notes) => null;

  Future<void> onRefresh();

  IconData get emptyIcon => CupertinoIcons.exclamationmark_triangle;

  bool hasActivityForValue(V value) => value != 0;

  List<HealthNote> notesForDate(List<HealthNote> notes, DateTime date);

  CupertinoAlertDialog buildNoActivityDialog(
    BuildContext dialogContext,
    DateTime date,
  );

  CupertinoAlertDialog buildValueOnlyDialog(
    BuildContext dialogContext,
    DateTime date,
    V value,
    List<HealthNote> scopedNotes,
  );

  CupertinoAlertDialog buildDetailDialog(
    BuildContext dialogContext,
    DateTime date,
    V value,
    List<HealthNote> relevantNotes,
  );

  String get title => '${widget.itemName} Trends';
  String get emptyTitle => 'No data for ${widget.itemName}';
  String get emptyMessage =>
      'No health notes with this $itemNoun have been recorded yet';
  String get searchPlaceholder => 'Search notes for ${widget.itemName}...';
  String get loadingMessage => 'Loading $itemNoun trends...';

  @override
  Widget build(BuildContext context) {
    final healthNotesAsync = ref.watch(healthNotesNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: SafeArea(
        child: healthNotesAsync.when(
          data: (notes) => buildContent(notes),
          loading: () =>
              EnhancedUIComponents.loadingIndicator(message: loadingMessage),
          error: (error, stack) =>
              Center(child: Text('Error: $error', style: AppTypography.error)),
        ),
      ),
    );
  }

  Widget buildContent(List<HealthNote> notes) {
    final scopedNotes = filterSourceNotes(notes);

    if (scopedNotes.isEmpty) {
      return EnhancedUIComponents.emptyState(
        title: emptyTitle,
        message: emptyMessage,
        icon: emptyIcon,
      );
    }

    final sortedNotes = NoteFilterUtils.sortByDateDescending(scopedNotes);
    final activityData = buildActivityData(sortedNotes);
    final filteredNotes = applySearch(sortedNotes);

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: onRefresh),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              buildActivityContent(activityData, sortedNotes),
              VSpace.of(20),
              buildSearchSection(),
              VSpace.of(20),
              buildNotesSection(filteredNotes),
            ]),
          ),
        ),
      ],
    );
  }

  List<HealthNote> applySearch(List<HealthNote> notes) {
    if (searchQuery.isEmpty) return notes;
    final filtered = NoteFilterUtils.bySearchQuery(notes, searchQuery);
    return NoteFilterUtils.sortByDateDescending(filtered);
  }

  Widget buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Search Notes', style: AppTypography.labelLarge),
        VSpace.of(12),
        EnhancedUIComponents.searchField(
          controller: searchController,
          placeholder: searchPlaceholder,
          onChanged: (query) => setState(() => searchQuery = query),
        ),
      ],
    );
  }

  Widget buildNotesSection(List<HealthNote> filteredNotes) {
    if (filteredNotes.isEmpty) {
      return const NoMatchingNotesState();
    }

    final header = buildNotesHeader(filteredNotes);
    final cards = buildNotesContent(filteredNotes);

    return NotesSection(
      noteCount: filteredNotes.length,
      noteCards: [if (header != null) header, ...cards],
    );
  }

  void handleDateTap(
    BuildContext context,
    DateTime date,
    V value,
    List<HealthNote> scopedNotes,
  ) {
    if (!hasActivityForValue(value)) {
      showCupertinoDialog(
        context: context,
        builder: (dialogContext) => buildNoActivityDialog(dialogContext, date),
      );
      return;
    }

    final relevantNotes = notesForDate(scopedNotes, date);

    if (relevantNotes.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (dialogContext) =>
            buildValueOnlyDialog(dialogContext, date, value, scopedNotes),
      );
    } else {
      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) =>
            buildDetailDialog(dialogContext, date, value, relevantNotes),
      );
    }
  }
}
