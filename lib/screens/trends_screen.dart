import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/check_in_metrics_provider.dart';
import 'package:health_notes/providers/check_ins_provider.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/screens/check_in_form.dart';
import 'package:health_notes/screens/drug_trends_screen.dart';
import 'package:health_notes/screens/symptom_trends_screen.dart';
import 'package:health_notes/services/text_normalizer.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/log_out_button.dart';
import 'package:health_notes/widgets/check_in_trends_chart.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';
import 'package:health_notes/widgets/monthly_notes_chart.dart';
import 'package:health_notes/widgets/recent_symptoms_chart.dart';
import 'package:health_notes/widgets/searchable_stats_table.dart';
import 'package:health_notes/widgets/stats_card.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:health_notes/widgets/health_notes_activity_calendar.dart';
import 'package:health_notes/screens/check_in_date_detail_screen.dart';
import 'package:health_notes/screens/health_note_date_detail_screen.dart';
import 'package:intl/intl.dart';

enum TrendsCategory { notes, checkIns }

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen();

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  TrendsCategory selectedCategory = TrendsCategory.notes;

  @override
  Widget build(BuildContext context) {
    final healthNotesAsync = ref.watch(healthNotesNotifierProvider);
    final checkInsAsync = ref.watch(checkInsNotifierProvider);
    final userMetricsAsync = ref.watch(checkInMetricsNotifierProvider);

    return EScaffoldShell(
      contentMaxWidth: double.infinity,
      appBar: EAppHeader(
        title: 'Trends',
        leading: const LogOutButton(),
        actions: [
          const CompactSyncStatusWidget(),
          IconButton(
            tooltip: 'Add check-in',
            onPressed: () => context.push(const CheckInForm()),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: trendsBody(healthNotesAsync, checkInsAsync, userMetricsAsync),
    );
  }

  Widget trendsBody(
    AsyncValue<List<HealthNote>> healthNotesAsync,
    AsyncValue<List<CheckIn>> checkInsAsync,
    AsyncValue userMetricsAsync,
  ) {
    return healthNotesAsync.when(
      data: (notes) => notesLayer(notes, checkInsAsync, userMetricsAsync),
      loading: () => const SyncStatusWidget.loading(
        message: 'Loading your health trends...',
      ),
      error: (error, stack) => SyncStatusWidget.error(
        errorMessage: 'Error: $error',
        onRetry: () => ref.invalidate(healthNotesNotifierProvider),
      ),
    );
  }

  Widget notesLayer(
    List<HealthNote> notes,
    AsyncValue<List<CheckIn>> checkInsAsync,
    AsyncValue userMetricsAsync,
  ) {
    return checkInsAsync.when(
      data: (checkIns) => metricsLayer(notes, checkIns, userMetricsAsync),
      loading: () => notes.isEmpty
          ? const SyncStatusWidget.loading(message: 'Loading check-ins...')
          : userMetricsAsync.when(
              data: (_) => trendsContent(notes, []),
              loading: () => trendsContent(notes, []),
              error: (error, stack) => trendsContent(notes, []),
            ),
      error: (error, stack) => notes.isEmpty
          ? SyncStatusWidget.error(
              errorMessage: 'Error loading check-ins: $error',
              onRetry: () => ref.invalidate(checkInsNotifierProvider),
            )
          : userMetricsAsync.when(
              data: (_) => trendsContent(notes, []),
              loading: () => trendsContent(notes, []),
              error: (error, stack) => trendsContent(notes, []),
            ),
    );
  }

  Widget metricsLayer(
    List<HealthNote> notes,
    List<CheckIn> checkIns,
    AsyncValue userMetricsAsync,
  ) {
    return userMetricsAsync.when(
      data: (_) => _shouldShowEmptyState(notes, checkIns)
          ? emptyState()
          : trendsContent(notes, checkIns),
      loading: () => notes.isEmpty
          ? const SyncStatusWidget.loading(message: 'Loading metrics...')
          : trendsContent(notes, checkIns),
      error: (error, stack) => notes.isEmpty
          ? SyncStatusWidget.error(
              errorMessage: 'Error loading metrics: $error',
              onRetry: () => ref.invalidate(checkInMetricsNotifierProvider),
            )
          : trendsContent(notes, checkIns),
    );
  }

  bool _shouldShowEmptyState(List<HealthNote> notes, List<CheckIn> checkIns) {
    return notes.isEmpty && checkIns.isEmpty;
  }

  Widget emptyState() {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () =>
              ref.read(syncNotifierProvider.notifier).syncAllData(),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: EEmptyState(
            title: 'No data for trends yet',
            message: 'Add some health notes to see analytics',
            icon: CupertinoIcons.chart_bar,
          ),
        ),
      ],
    );
  }

  Widget trendsContent(List<HealthNote> notes, List<CheckIn> checkIns) {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () =>
              ref.read(syncNotifierProvider.notifier).syncAllData(),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.m),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              categorySelector(),
              VSpace.of(20),
              ...selectedCategorySections(notes, checkIns),
            ]),
          ),
        ),
      ],
    );
  }

  Widget categorySelector() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<TrendsCategory>(
        groupValue: selectedCategory,
        onValueChanged: (category) {
          if (category == null) return;
          setState(() => selectedCategory = category);
        },
        children: const {
          TrendsCategory.notes: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('Note Trends'),
          ),
          TrendsCategory.checkIns: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('Check-in Trends'),
          ),
        },
      ),
    );
  }

  List<Widget> selectedCategorySections(
    List<HealthNote> notes,
    List<CheckIn> checkIns,
  ) {
    if (selectedCategory == TrendsCategory.checkIns) {
      return checkInSections(checkIns);
    }
    return noteSections(notes);
  }

  List<Widget> noteSections(List<HealthNote> notes) {
    final symptomStats = _analyzeSymptomFrequency(notes);
    final drugStats = _analyzeDrugUsage(notes);
    final monthlyStats = _analyzeMonthlyTrends(notes);
    final recentSymptomTrends = _analyzeRecentSymptomTrends(notes);

    return [
      sectionHeader('Recent Symptom Trends (Last 30 Days)'),
      recentSymptomTrendsCard(recentSymptomTrends),
      VSpace.of(20),
      sectionHeader('All Symptoms'),
      SearchableStatsTable(
        searchPlaceholder: 'Search symptoms...',
        stats: symptomStats,
        onItemTap: _openSymptomTrends,
      ),
      VSpace.of(20),
      sectionHeader('All Drugs'),
      SearchableStatsTable(
        searchPlaceholder: 'Search drugs...',
        stats: drugStats,
        onItemTap: _openDrugTrends,
      ),
      VSpace.of(20),
      sectionHeader('Notes per Month'),
      monthlyTrendsCard(monthlyStats),
      VSpace.of(20),
      sectionHeader('Note Activity'),
      notesCalendar(notes),
    ];
  }

  List<Widget> checkInSections(List<CheckIn> checkIns) {
    return [
      sectionHeader('Check-in Metrics'),
      checkInTrendsSection(checkIns),
      VSpace.of(20),
      sectionHeader('Check-in Activity'),
      checkInsCalendar(checkIns),
    ];
  }

  Widget sectionHeader(String title) {
    return ESectionHeader(title: title);
  }

  Widget recentSymptomTrendsCard(Map<String, int> recentTrends) {
    if (recentTrends.isEmpty) {
      return StatsCard(
        statRows: [
          Text(
            'No recent symptoms recorded',
            style: EText.body.medium.muted,
          ),
        ],
      );
    }

    return RecentSymptomsChart(
      symptomStats: recentTrends,
      onSymptomTap: _openSymptomTrends,
    );
  }

  Widget monthlyTrendsCard(Map<String, int> monthlyStats) {
    if (monthlyStats.isEmpty) {
      return StatsCard(
        statRows: [
          Text(
            'No monthly data available',
            style: EText.body.medium.muted,
          ),
        ],
      );
    }

    return MonthlyNotesChart(monthlyStats: monthlyStats);
  }

  void _openSymptomTrends(String symptomName) {
    context.push(SymptomTrendsScreen(symptomName: symptomName));
  }

  void _openDrugTrends(String drugName) {
    context.push(DrugTrendsScreen(drugName: DrugName(drugName)));
  }

  String formatMonth(String monthKey) {
    try {
      final parts = monthKey.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        return DateFormat('MMMM yyyy').format(DateTime(year, month));
      }
    } catch (_) {}
    return monthKey;
  }

  Map<String, int> _analyzeSymptomFrequency(List<HealthNote> notes) {
    return CaseInsensitiveAggregator.aggregateStrings(
      notes
          .where((note) => note.hasSymptoms)
          .expand((note) => note.validSymptoms.map((s) => s.majorComponent))
          .where((symptom) => symptom.isNotEmpty),
    );
  }

  Map<String, int> _analyzeDrugUsage(List<HealthNote> notes) {
    final counts = <DrugName, int>{};
    for (final dose in notes
        .expand((note) => note.drugDoses)
        .where((dose) => dose.name.isNotEmpty)) {
      counts[dose.name] = (counts[dose.name] ?? 0) + 1;
    }
    return {
      for (final count in counts.entries) count.key.display: count.value,
    };
  }

  Map<String, int> _analyzeMonthlyTrends(List<HealthNote> notes) {
    return notes
        .map(
          (note) =>
              '${note.dateTime.year}-${note.dateTime.month.toString().padLeft(2, '0')}',
        )
        .fold<Map<String, int>>(
          {},
          (map, monthKey) =>
              map..update(monthKey, (count) => count + 1, ifAbsent: () => 1),
        );
  }

  Map<String, int> _analyzeRecentSymptomTrends(List<HealthNote> notes) {
    final thirtyDaysAgo = DateTime.now().shiftedByDays(-30);

    return CaseInsensitiveAggregator.aggregateStrings(
      notes
          .where(
            (note) => note.dateTime.isAfter(thirtyDaysAgo) && note.hasSymptoms,
          )
          .expand((note) => note.validSymptoms.map((s) => s.majorComponent))
          .where((symptom) => symptom.isNotEmpty),
    );
  }

  Widget notesCalendar(List<HealthNote> notes) {
    if (notes.isEmpty) return const SizedBox.shrink();

    return HealthNotesActivityCalendar(
      notes: notes,
      onDateTap: (date) =>
          context.push(HealthNoteDateDetailScreen(date: date, allNotes: notes)),
      gridHeight: 320,
      scrollToEnd: true,
    );
  }

  Widget checkInsCalendar(List<CheckIn> checkIns) {
    if (checkIns.isEmpty) return const SizedBox.shrink();

    return CheckInsActivityCalendar(
      checkIns: checkIns,
      onDateTap: (date) => context.push(
        CheckInDateDetailScreen(date: date, allCheckIns: checkIns),
      ),
      gridHeight: 320,
      scrollToEnd: true,
    );
  }

  Widget checkInTrendsSection(List<CheckIn> checkIns) {
    final userMetricsAsync = ref.watch(checkInMetricsNotifierProvider);

    return userMetricsAsync.when(
      data: (userMetrics) {
        if (checkIns.isEmpty) {
          return StatsCard(
            statRows: [
              Text(
                'No check-in data available',
                style: EText.body.medium.muted,
              ),
            ],
          );
        }
        return CheckInTrendsChart(checkIns: checkIns, userMetrics: userMetrics);
      },
      loading: () =>
          const SyncStatusWidget.section(message: 'Loading check-in trends...'),
      error: (error, stack) => SyncStatusWidget.error(
        errorMessage: 'Error loading metrics: $error',
        onRetry: () => ref.invalidate(checkInMetricsNotifierProvider),
      ),
    );
  }
}
