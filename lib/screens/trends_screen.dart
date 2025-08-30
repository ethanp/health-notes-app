import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/providers/check_ins_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/auth_utils.dart';
import 'package:health_notes/widgets/check_in_trends_chart.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
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

    return CupertinoPageScaffold(
      navigationBar: EnhancedUIComponents.enhancedNavigationBar(
        title: 'Trends',
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => AuthUtils.showSignOutDialog(context),
          child: const Icon(CupertinoIcons.person_circle),
        ),
      ),
      child: SafeArea(
        child: healthNotesAsync.when(
          data: (notes) =>
              notes.isEmpty ? buildEmptyState() : buildTrendsContent(notes),
          loading: () => EnhancedUIComponents.enhancedLoadingIndicator(
            message: 'Loading your health trends...',
          ),
          error: (error, stack) =>
              Center(child: Text('Error: $error', style: AppTheme.error)),
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return EnhancedUIComponents.enhancedEmptyState(
      title: 'No data for trends yet',
      message: 'Add some health notes to see analytics',
      icon: CupertinoIcons.chart_bar,
    );
  }

  Widget buildTrendsContent(List<HealthNote> notes) {
    final symptomStats = _analyzeSymptomFrequency(notes);
    final drugStats = _analyzeDrugUsage(notes);
    final monthlyStats = _analyzeMonthlyTrends(notes);
    final recentSymptomTrends = _analyzeRecentSymptomTrends(notes);

    return Consumer(
      builder: (context, ref, child) {
        final checkInsAsync = ref.watch(checkInsNotifierProvider);

        return checkInsAsync.when(
          data: (checkIns) => CustomScrollView(
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  await ref
                      .read(healthNotesNotifierProvider.notifier)
                      .refreshNotes();
                  await ref.read(checkInsNotifierProvider.notifier).refresh();
                },
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    buildSectionHeader('Check-in Trends'),
                    buildCheckInTrendsSection(checkIns),
                    const SizedBox(height: 20),
                    buildSectionHeader('Recent Symptom Trends'),
                    buildRecentSymptomTrendsCard(recentSymptomTrends),
                    const SizedBox(height: 20),
                    buildSectionHeader('Most Common Symptoms'),
                    buildSymptomFrequencyCard(symptomStats),
                    const SizedBox(height: 20),
                    buildSectionHeader('Drug Usage'),
                    buildDrugUsageCard(drugStats),
                    const SizedBox(height: 20),
                    buildSectionHeader('Monthly Trends'),
                    buildMonthlyTrendsCard(monthlyStats),
                  ]),
                ),
              ),
            ],
          ),
          loading: () => EnhancedUIComponents.enhancedLoadingIndicator(
            message: 'Loading check-in data...',
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error loading check-ins: $error',
              style: AppTheme.error,
            ),
          ),
        );
      },
    );
  }

  Widget buildSectionHeader(String title) {
    return EnhancedUIComponents.enhancedSectionHeader(title: title);
  }

  Widget buildRecentSymptomTrendsCard(Map<String, int> recentTrends) {
    if (recentTrends.isEmpty) {
      return buildEmptyCard('No recent symptoms recorded');
    }

    final sortedTrends = recentTrends.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: AppTheme.primaryCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 30 Days', style: AppTheme.labelLarge),
          const SizedBox(height: 12),
          ...sortedTrends
              .take(3)
              .map((entry) => buildStatRow(entry.key, entry.value, 'times')),
        ],
      ),
    );
  }

  Widget buildSymptomFrequencyCard(Map<String, int> symptomStats) {
    if (symptomStats.isEmpty) {
      return buildEmptyCard('No symptoms recorded yet');
    }

    final sortedSymptoms = symptomStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: AppTheme.primaryCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('All Time', style: AppTheme.labelLarge),
          const SizedBox(height: 12),
          ...sortedSymptoms
              .take(5)
              .map((entry) => buildStatRow(entry.key, entry.value, 'times')),
        ],
      ),
    );
  }

  Widget buildDrugUsageCard(Map<String, int> drugStats) {
    if (drugStats.isEmpty) {
      return buildEmptyCard('No drugs recorded yet');
    }

    final sortedDrugs = drugStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: AppTheme.primaryCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Most Used Drugs', style: AppTheme.labelLarge),
          const SizedBox(height: 12),
          ...sortedDrugs
              .take(5)
              .map((entry) => buildStatRow(entry.key, entry.value, 'times')),
        ],
      ),
    );
  }

  Widget buildMonthlyTrendsCard(Map<String, int> monthlyStats) {
    if (monthlyStats.isEmpty) {
      return buildEmptyCard('No monthly data available');
    }

    final sortedMonths = monthlyStats.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Container(
      decoration: AppTheme.primaryCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes per Month', style: AppTheme.labelLarge),
          const SizedBox(height: 12),
          ...sortedMonths
              .take(6)
              .map(
                (entry) =>
                    buildStatRow(formatMonth(entry.key), entry.value, 'notes'),
              ),
        ],
      ),
    );
  }

  Widget buildStatRow(String label, int value, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTheme.bodyMedium)),
          Text(
            '$value $unit',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyCard(String message) {
    return Container(
      decoration: AppTheme.primaryCard,
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
              style: AppTheme.bodyMedium.copyWith(
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
      // Fallback to original key if parsing fails
    }
    return monthKey;
  }

  Map<String, int> _analyzeSymptomFrequency(List<HealthNote> notes) {
    return notes
        .where((note) => note.hasSymptoms)
        .expand((note) => note.validSymptoms.map((s) => s.majorComponent))
        .where((symptom) => symptom.isNotEmpty)
        .fold<Map<String, int>>(
          {},
          (map, symptom) =>
              map..update(symptom, (count) => count + 1, ifAbsent: () => 1),
        );
  }

  Map<String, int> _analyzeDrugUsage(List<HealthNote> notes) {
    return notes
        .expand((note) => note.drugDoses)
        .map((drug) => drug.name)
        .where((name) => name.isNotEmpty)
        .fold<Map<String, int>>(
          {},
          (map, drugName) =>
              map..update(drugName, (count) => count + 1, ifAbsent: () => 1),
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

    return notes
        .where(
          (note) => note.dateTime.isAfter(thirtyDaysAgo) && note.hasSymptoms,
        )
        .expand((note) => note.validSymptoms.map((s) => s.majorComponent))
        .where((symptom) => symptom.isNotEmpty)
        .fold<Map<String, int>>(
          {},
          (map, symptom) =>
              map..update(symptom, (count) => count + 1, ifAbsent: () => 1),
        );
  }

  Widget buildCheckInTrendsSection(List<CheckIn> checkIns) {
    if (checkIns.isEmpty) {
      return buildEmptyCard('No check-in data available');
    }

    return CheckInTrendsChart(checkIns: checkIns);
  }
}
