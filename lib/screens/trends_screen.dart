import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/check_in_metrics_provider.dart';
import 'package:health_notes/providers/check_ins_provider.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/screens/symptom_trends_screen.dart';
import 'package:health_notes/screens/drug_trends_screen.dart';
import 'package:health_notes/theme/app_theme.dart';

import 'package:health_notes/utils/auth_utils.dart';
import 'package:health_notes/widgets/check_in_trends_chart.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';
import 'package:health_notes/services/text_normalizer.dart';
import 'package:intl/intl.dart';

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen();

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  late TextEditingController _symptomSearchController;
  String _symptomSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _symptomSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _symptomSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthNotesAsync = ref.watch(healthNotesNotifierProvider);
    final checkInsAsync = ref.watch(checkInsNotifierProvider);
    final userMetricsAsync = ref.watch(checkInMetricsNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: EnhancedUIComponents.navigationBar(
        title: 'Trends',
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => AuthUtils.showSignOutDialog(context),
          child: const Icon(CupertinoIcons.person_circle),
        ),
        trailing: const CompactSyncStatusWidget(),
      ),
      child: SafeArea(
        child: healthNotesAsync.when(
          data: (notes) => checkInsAsync.when(
            data: (checkIns) => userMetricsAsync.when(
              data: (userMetrics) =>
                  _shouldShowEmptyState(notes, checkIns, userMetrics)
                  ? emptyState()
                  : trendsContent(notes, checkIns, userMetrics),
              loading: () => notes.isEmpty
                  ? const SyncStatusWidget.loading(
                      message: 'Loading metrics...',
                    )
                  : trendsContent(notes, checkIns, []),
              error: (error, stack) => notes.isEmpty
                  ? SyncStatusWidget.error(
                      errorMessage: 'Error loading metrics: $error',
                      onRetry: () =>
                          ref.invalidate(checkInMetricsNotifierProvider),
                    )
                  : trendsContent(notes, checkIns, []),
            ),
            loading: () => notes.isEmpty
                ? const SyncStatusWidget.loading(
                    message: 'Loading check-ins...',
                  )
                : userMetricsAsync.when(
                    data: (userMetrics) =>
                        trendsContent(notes, [], userMetrics),
                    loading: () => trendsContent(notes, [], []),
                    error: (error, stack) => trendsContent(notes, [], []),
                  ),
            error: (error, stack) => notes.isEmpty
                ? SyncStatusWidget.error(
                    errorMessage: 'Error loading check-ins: $error',
                    onRetry: () => ref.invalidate(checkInsNotifierProvider),
                  )
                : userMetricsAsync.when(
                    data: (userMetrics) =>
                        trendsContent(notes, [], userMetrics),
                    loading: () => trendsContent(notes, [], []),
                    error: (error, stack) => trendsContent(notes, [], []),
                  ),
          ),
          loading: () => const SyncStatusWidget.loading(
            message: 'Loading your health trends...',
          ),
          error: (error, stack) => SyncStatusWidget.error(
            errorMessage: 'Error: $error',
            onRetry: () => ref.invalidate(healthNotesNotifierProvider),
          ),
        ),
      ),
    );
  }

  bool _shouldShowEmptyState(
    List<HealthNote> notes,
    List<CheckIn> checkIns,
    List<CheckInMetric> userMetrics,
  ) {
    return notes.isEmpty && checkIns.isEmpty;
  }

  Widget emptyState() {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await ref.read(syncNotifierProvider.notifier).syncAllData();
          },
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

  Widget trendsContent(
    List<HealthNote> notes,
    List<CheckIn> checkIns,
    List<CheckInMetric> userMetrics,
  ) {
    final symptomStats = _analyzeSymptomFrequency(notes);
    final drugStats = _analyzeDrugUsage(notes);
    final monthlyStats = _analyzeMonthlyTrends(notes);
    final recentSymptomTrends = _analyzeRecentSymptomTrends(notes);

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await ref.read(syncNotifierProvider.notifier).syncAllData();
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              sectionHeader('Check-in Trends'),
              checkInTrendsSection(checkIns, userMetrics),
              const SizedBox(height: 20),
              sectionHeader('Recent Symptom Trends'),
              recentSymptomTrendsCard(recentSymptomTrends),
              const SizedBox(height: 20),
              sectionHeader('All Symptoms'),
              searchableSymptomsTable(symptomStats),
              const SizedBox(height: 20),
              sectionHeader('Drug Usage'),
              drugUsageCard(drugStats),
              const SizedBox(height: 20),
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
      return emptyCard('No recent symptoms recorded');
    }

    final sortedTrends = recentTrends.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: AppComponents.primaryCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 30 Days', style: AppTypography.labelLarge),
          const SizedBox(height: 12),
          ...sortedTrends
              .take(3)
              .map(
                (entry) => clickableStatRow(entry.key, entry.value, 'times'),
              ),
        ],
      ),
    );
  }

  Widget searchableSymptomsTable(Map<String, int> symptomStats) {
    if (symptomStats.isEmpty) {
      return emptyCard('No symptoms recorded yet');
    }

    final filteredSymptoms = _filterSymptoms(symptomStats);
    final sortedSymptoms = filteredSymptoms.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: AppComponents.primaryCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'All Symptoms (${filteredSymptoms.length})',
                  style: AppTypography.labelLarge,
                ),
              ),
              Text(
                'Tap to view trends',
                style: AppTypography.bodySmall.copyWith(
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          EnhancedUIComponents.searchField(
            controller: _symptomSearchController,
            placeholder: 'Search symptoms...',
            onChanged: (query) {
              setState(() {
                _symptomSearchQuery = query;
              });
            },
          ),
          const SizedBox(height: 12),
          if (sortedSymptoms.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No symptoms match your search',
                style: AppTypography.bodyMedium.copyWith(
                  color: CupertinoColors.systemGrey,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...sortedSymptoms.map(
              (entry) => symptomRow(entry.key, entry.value),
            ),
        ],
      ),
    );
  }

  Widget symptomRow(String symptomName, int frequency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) =>
                    SymptomTrendsScreen(symptomName: symptomName),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        symptomName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$frequency occurrences',
                        style: AppTypography.bodySmall.copyWith(
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.systemGrey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget drugUsageCard(Map<String, int> drugStats) {
    if (drugStats.isEmpty) {
      return emptyCard('No drugs recorded yet');
    }

    final sortedDrugs = drugStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: AppComponents.primaryCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Most Used Drugs', style: AppTypography.labelLarge),
              ),
              Text(
                'Tap to view trends',
                style: AppTypography.bodySmall.copyWith(
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sortedDrugs
              .take(5)
              .map(
                (entry) => clickableDrugRow(entry.key, entry.value, 'times'),
              ),
        ],
      ),
    );
  }

  Widget monthlyTrendsCard(Map<String, int> monthlyStats) {
    if (monthlyStats.isEmpty) {
      return emptyCard('No monthly data available');
    }

    final sortedMonths = monthlyStats.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Container(
      decoration: AppComponents.primaryCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes per Month', style: AppTypography.labelLarge),
          const SizedBox(height: 12),
          ...sortedMonths
              .take(6)
              .map(
                (entry) =>
                    statRow(formatMonth(entry.key), entry.value, 'notes'),
              ),
        ],
      ),
    );
  }

  Widget clickableStatRow(String label, int value, String unit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => SymptomTrendsScreen(symptomName: label),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(label, style: AppTypography.bodyMedium)),
                Text(
                  '$value $unit',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget clickableDrugRow(String drugName, int value, String unit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => DrugTrendsScreen(drugName: drugName),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(drugName, style: AppTypography.bodyMedium)),
                Text(
                  '$value $unit',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget statRow(String label, int value, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          Text(
            '$value $unit',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyCard(String message) {
    return Container(
      decoration: AppComponents.primaryCard,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.info_circle,
            color: CupertinoColors.systemGrey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        ],
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
    } catch (e) {
      // Invalid date format - return original key
    }
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

  Map<String, int> _filterSymptoms(Map<String, int> allSymptoms) {
    if (_symptomSearchQuery.isEmpty) return allSymptoms;

    final normalizer = CaseInsensitiveNormalizer();
    return Map.fromEntries(
      allSymptoms.entries.where(
        (entry) => normalizer.contains(entry.key, _symptomSearchQuery),
      ),
    );
  }

  Widget checkInTrendsSection(
    List<CheckIn> checkIns,
    List<CheckInMetric> userMetrics,
  ) {
    final checkInsAsync = ref.watch(checkInsNotifierProvider);
    final userMetricsAsync = ref.watch(checkInMetricsNotifierProvider);

    if (checkInsAsync.isLoading || userMetricsAsync.isLoading) {
      return const SyncStatusWidget.section(
        message: 'Loading check-in trends...',
      );
    }

    if (checkIns.isEmpty) {
      return emptyCard('No check-in data available');
    }

    return CheckInTrendsChart(checkIns: checkIns, userMetrics: userMetrics);
  }
}
