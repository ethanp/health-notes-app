import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/auth_utils.dart';
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
      navigationBar: CupertinoNavigationBar(
        middle: Text('Trends', style: AppTheme.titleMedium),
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
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) =>
              Center(child: Text('Error: $error', style: AppTheme.error)),
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chart_bar,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No data for trends yet',
            style: AppTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add some health notes to see analytics',
            style: AppTheme.subtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildTrendsContent(List<HealthNote> notes) {
    final symptomStats = _analyzeSymptomFrequency(notes);
    final drugStats = _analyzeDrugUsage(notes);
    final monthlyStats = _analyzeMonthlyTrends(notes);
    final recentSymptomTrends = _analyzeRecentSymptomTrends(notes);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
      ],
    );
  }

  Widget buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget buildRecentSymptomTrendsCard(Map<String, int> recentTrends) {
    if (recentTrends.isEmpty) {
      return buildEmptyCard('No recent symptoms recorded');
    }

    final sortedTrends = recentTrends.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: AppTheme.cardContainer,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 30 Days',
            style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w600),
          ),
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
      decoration: AppTheme.cardContainer,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Time',
            style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w600),
          ),
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
      decoration: AppTheme.cardContainer,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Most Used Drugs',
            style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w600),
          ),
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
      decoration: AppTheme.cardContainer,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes per Month',
            style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w600),
          ),
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
      decoration: AppTheme.cardContainer,
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
        .where((note) => note.symptoms.isNotEmpty)
        .expand((note) => note.symptoms.split(',').map((s) => s.trim()))
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
          (note) =>
              note.dateTime.isAfter(thirtyDaysAgo) && note.symptoms.isNotEmpty,
        )
        .expand((note) => note.symptoms.split(',').map((s) => s.trim()))
        .where((symptom) => symptom.isNotEmpty)
        .fold<Map<String, int>>(
          {},
          (map, symptom) =>
              map..update(symptom, (count) => count + 1, ifAbsent: () => 1),
        );
  }
}
