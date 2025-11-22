import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/check_in_metrics_provider.dart';
import 'package:health_notes/providers/check_ins_provider.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/screens/drug_trends_screen.dart';
import 'package:health_notes/screens/symptom_trends_screen.dart';
import 'package:health_notes/services/text_normalizer.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/auth_utils.dart';
import 'package:health_notes/widgets/check_in_trends_chart.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';
import 'package:health_notes/widgets/trends_table_components.dart';
import 'package:health_notes/widgets/spacing.dart';
import 'package:intl/intl.dart';

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen();

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  @override
  Widget build(BuildContext context) {
    final healthNotesAsync = ref.watch(healthNotesNotifierProvider);
    final checkInsAsync = ref.watch(checkInsNotifierProvider);
    final userMetricsAsync = ref.watch(checkInMetricsNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: trendsNavigationBar(),
      child: SafeArea(
        child: trendsBody(healthNotesAsync, checkInsAsync, userMetricsAsync),
      ),
    );
  }

  ObstructingPreferredSizeWidget trendsNavigationBar() {
    return EnhancedUIComponents.navigationBar(
      title: 'Trends',
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => AuthUtils.showSignOutDialog(context),
        child: const Icon(CupertinoIcons.person_circle),
      ),
      trailing: const CompactSyncStatusWidget(),
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
          child: EnhancedUIComponents.emptyState(
            title: 'No data for trends yet',
            message: 'Add some health notes to see analytics',
            icon: CupertinoIcons.chart_bar,
          ),
        ),
      ],
    );
  }

  Widget trendsContent(List<HealthNote> notes, List<CheckIn> checkIns) {
    final symptomStats = _analyzeSymptomFrequency(notes);
    final drugStats = _analyzeDrugUsage(notes);
    final monthlyStats = _analyzeMonthlyTrends(notes);
    final recentSymptomTrends = _analyzeRecentSymptomTrends(notes);

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () =>
              ref.read(syncNotifierProvider.notifier).syncAllData(),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              sectionHeader('Check-in Trends'),
              checkInTrendsSection(checkIns),
              VSpace.of(20),
              sectionHeader('Recent Symptom Trends'),
              recentSymptomTrendsCard(recentSymptomTrends),
              VSpace.of(20),
              sectionHeader('All Symptoms'),
              searchableSymptomsTable(symptomStats),
              VSpace.of(20),
              sectionHeader('Drug Usage'),
              drugUsageCard(drugStats),
              VSpace.of(20),
              sectionHeader('Monthly Trends'),
              monthlyTrendsCard(monthlyStats),
            ]),
          ),
        ),
      ],
    );
  }

  Widget sectionHeader(String title) {
    return EnhancedUIComponents.sectionHeader(title: title);
  }

  Widget recentSymptomTrendsCard(Map<String, int> recentTrends) {
    if (recentTrends.isEmpty) {
      return StatsCard(
        title: 'Last 30 Days',
        statRows: [
          Text(
            'No recent symptoms recorded',
            style: AppTypography.bodyMediumSystemGrey,
          ),
        ],
      );
    }

    final sortedTrends = recentTrends.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return StatsCard(
      title: 'Last 30 Days',
      statRows: sortedTrends
          .take(3)
          .map(
            (entry) => StatRow(
              label: entry.key,
              value: entry.value,
              unit: 'times',
              onTap: () => _openSymptomTrends(entry.key),
            ),
          )
          .toList(),
    );
  }

  Widget searchableSymptomsTable(Map<String, int> symptomStats) {
    if (symptomStats.isEmpty) {
      return StatsCard(
        title: 'All Symptoms',
        statRows: [
          Text(
            'No symptoms recorded yet',
            style: AppTypography.bodyMediumSystemGrey,
          ),
        ],
      );
    }

    return SymptomsTable(symptomStats: symptomStats);
  }

  Widget drugUsageCard(Map<String, int> drugStats) {
    if (drugStats.isEmpty) {
      return StatsCard(
        title: 'Most Used Drugs',
        statRows: [
          Text(
            'No drugs recorded yet',
            style: AppTypography.bodyMediumSystemGrey,
          ),
        ],
      );
    }

    final sortedDrugs = drugStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return StatsCard(
      title: 'Most Used Drugs',
      statRows: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Tap to view trends',
            style: AppTypography.bodySmallSystemGrey,
          ),
        ),
        ...sortedDrugs
            .take(5)
            .map(
              (entry) => StatRow(
                label: entry.key,
                value: entry.value,
                unit: 'times',
                onTap: () => _openDrugTrends(entry.key),
              ),
            ),
      ],
    );
  }

  Widget monthlyTrendsCard(Map<String, int> monthlyStats) {
    if (monthlyStats.isEmpty) {
      return StatsCard(
        title: 'Notes per Month',
        statRows: [
          Text(
            'No monthly data available',
            style: AppTypography.bodyMediumSystemGrey,
          ),
        ],
      );
    }

    final sortedMonths = monthlyStats.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return StatsCard(
      title: 'Notes per Month',
      statRows: sortedMonths
          .take(6)
          .map(
            (entry) => StatRow(
              label: formatMonth(entry.key),
              value: entry.value,
              unit: 'notes',
            ),
          )
          .toList(),
    );
  }

  void _openSymptomTrends(String symptomName) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => SymptomTrendsScreen(symptomName: symptomName),
      ),
    );
  }

  void _openDrugTrends(String drugName) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => DrugTrendsScreen(drugName: drugName),
      ),
    );
  }

  String formatMonth(String monthKey) {
    try {
      final parts = monthKey.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        return DateFormat('MMMM yyyy').format(DateTime(year, month));
      }
    } catch (e) {}
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
    return CaseInsensitiveAggregator.aggregateStrings(
      notes
          .expand((note) => note.drugDoses)
          .map((drug) => drug.name)
          .where((name) => name.isNotEmpty),
    );
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
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return CaseInsensitiveAggregator.aggregateStrings(
      notes
          .where(
            (note) => note.dateTime.isAfter(thirtyDaysAgo) && note.hasSymptoms,
          )
          .expand((note) => note.validSymptoms.map((s) => s.majorComponent))
          .where((symptom) => symptom.isNotEmpty),
    );
  }

  Widget checkInTrendsSection(List<CheckIn> checkIns) {
    final userMetricsAsync = ref.watch(checkInMetricsNotifierProvider);

    return userMetricsAsync.when(
      data: (userMetrics) {
        if (checkIns.isEmpty) {
          return StatsCard(
            title: 'Summary',
            statRows: [
              Text(
                'No check-in data available',
                style: AppTypography.bodyMediumSystemGrey,
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
