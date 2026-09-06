import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/note_filter_utils.dart';
import 'package:health_notes/widgets/grouped_notes_section.dart';
import 'package:health_notes/widgets/health_notes_page.dart';
import 'package:health_notes/widgets/health_notes_search_field.dart';
import 'package:health_notes/widgets/app_dialogs.dart';
import 'package:health_notes/theme/spacing.dart';

abstract class const BaseTrendsScreen() extends ConsumerStatefulWidget {
  String get itemName;
}

class const TrendsSegment({
  required final String title,
  required final List<Widget> content,
});

abstract class BaseTrendsState<T extends BaseTrendsScreen, V extends num>()
    extends ConsumerState<T> {
  String get itemNoun;

  late final TextEditingController searchController;
  String searchQuery = '';
  int selectedSegmentIndex = 0;

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

  /// Optional extra segments shown after the built-in Calendar and Notes tabs.
  List<TrendsSegment> extraSegments(List<HealthNote> sortedNotes) => [];

  Future<void> reloadNotes();

  IconData get emptyIcon => Icons.warning_amber;

  bool hasActivityForValue(V value) => value != 0;

  List<HealthNote> notesForDate(List<HealthNote> notes, DateTime date);

  /// Message shown when tapping a date with no activity at all.
  String noActivityMessage(DateTime date);

  /// Message shown when tapping a date that has a value but no linkable notes.
  String valueOnlyMessage(DateTime date, V value);

  /// Optional summary widget shown above the note links in the detail dialog.
  Widget? dateSummary(DateTime date, V value, List<HealthNote> notes) => null;

  /// Label widget for each note link in the detail dialog.
  Widget noteDetailLabel(HealthNote note);

  String get title => '${widget.itemName} Trends';
  String get emptyTitle => 'No data for ${widget.itemName}';
  String get emptyMessage =>
      'No health notes with this $itemNoun have been recorded yet';
  String get searchPlaceholder => 'Search notes for ${widget.itemName}...';
  String get loadingMessage => 'Loading $itemNoun trends...';

  @override
  Widget build(BuildContext context) {
    final healthNotesAsync = ref.watch(healthNotesProvider);

    return HealthNotesPage(
      title: title,
      body: healthNotesAsync.when(
        data: (notes) => buildContent(notes),
        loading: () => ELoadingState(message: loadingMessage),
        error: (error, stack) =>
            Center(child: Text('Error: $error', style: EText.error)),
      ),
    );
  }

  Widget buildContent(List<HealthNote> notes) {
    final scopedNotes = filterSourceNotes(notes);

    if (scopedNotes.isEmpty) {
      return EEmptyState(
        title: emptyTitle,
        message: emptyMessage,
        icon: emptyIcon,
      );
    }

    final sortedNotes = NoteFilterUtils.sortByDateDescending(scopedNotes);
    final activityData = buildActivityData(sortedNotes);
    final filteredNotes = newestFirstMatchingQuery(sortedNotes);

    final segments = buildSegments(activityData, sortedNotes, filteredNotes);
    final activeIndex = selectedSegmentIndex.clamp(0, segments.length - 1);

    return RefreshIndicator(
      onRefresh: reloadNotes,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.m),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                buildViewSelector(segments, activeIndex),
                VSpace.of(20),
                ...segments[activeIndex].content,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<TrendsSegment> buildSegments(
    Map<DateTime, V> activityData,
    List<HealthNote> sortedNotes,
    List<HealthNote> filteredNotes,
  ) {
    return [
      TrendsSegment(
        title: 'Calendar',
        content: [buildActivityContent(activityData, sortedNotes)],
      ),
      TrendsSegment(
        title: 'Notes',
        content: [
          buildSearchSection(),
          VSpace.of(20),
          buildNotesSection(filteredNotes),
        ],
      ),
      ...extraSegments(sortedNotes),
    ];
  }

  Widget buildViewSelector(List<TrendsSegment> segments, int activeIndex) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<int>(
        segments: [
          for (var index = 0; index < segments.length; index++)
            ButtonSegment<int>(
              value: index,
              label: Text(segments[index].title),
            ),
        ],
        selected: {activeIndex},
        onSelectionChanged: (selection) {
          setState(() => selectedSegmentIndex = selection.first);
        },
        showSelectedIcon: false,
      ),
    );
  }

  List<HealthNote> newestFirstMatchingQuery(List<HealthNote> notes) {
    if (searchQuery.isEmpty) return notes;
    final filtered = NoteFilterUtils.bySearchQuery(notes, searchQuery);
    return NoteFilterUtils.sortByDateDescending(filtered);
  }

  Widget buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Search Notes', style: EText.label.large),
        VSpace.sm,
        HealthNotesSearchField(
          controller: searchController,
          placeholder: searchPlaceholder,
          onChanged: (query) => setState(() => searchQuery = query),
        ),
      ],
    );
  }

  Widget buildNotesSection(List<HealthNote> filteredNotes) =>
      GroupedNotesSection(
        notes: filteredNotes,
        cardBuilder: buildNotesContent,
        header: buildNotesHeader(filteredNotes),
      );

  void handleDateTap(
    BuildContext context,
    DateTime date,
    V value,
    List<HealthNote> scopedNotes,
  ) {
    if (!hasActivityForValue(value)) {
      showDateInfoDialog(
        context: context,
        date: date,
        message: noActivityMessage(date),
      );
      return;
    }

    final relevantNotes = notesForDate(scopedNotes, date);

    if (relevantNotes.isEmpty) {
      showDateInfoDialog(
        context: context,
        date: date,
        message: valueOnlyMessage(date, value),
      );
      return;
    }

    showNoteDateDialog(
      context: context,
      date: date,
      notes: relevantNotes,
      summary: dateSummary(date, value, relevantNotes),
      noteLabelBuilder: noteDetailLabel,
    );
  }
}
