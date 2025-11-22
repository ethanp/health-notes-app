import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/spacing.dart';

/// Searchable symptoms table with search and body
class SymptomsTable extends StatefulWidget {
  final Map<String, int> symptomStats;

  const SymptomsTable({super.key, required this.symptomStats});

  @override
  State<SymptomsTable> createState() => _SymptomsTableState();
}

class _SymptomsTableState extends State<SymptomsTable> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSymptoms = _filterSymptoms();

    return Container(
      decoration: AppComponents.primaryCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          VSpace.of(12),
          _buildSearchField(),
          VSpace.m,
          _buildBody(filteredSymptoms),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('All Symptoms', style: AppTypography.headlineSmall),
        Text(
          '${widget.symptomStats.length} total',
          style: AppTypography.bodySmallSystemGrey,
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return CupertinoSearchTextField(
      controller: _searchController,
      placeholder: 'Search symptoms...',
      placeholderStyle: AppTypography.inputPlaceholder,
      style: AppTypography.input,
      onChanged: (query) => setState(() => _searchQuery = query),
    );
  }

  Widget _buildBody(List<MapEntry<String, int>> sortedSymptoms) {
    return Column(
      children: sortedSymptoms
          .map(
            (entry) =>
                SymptomRow(symptomName: entry.key, frequency: entry.value),
          )
          .toList(),
    );
  }

  List<MapEntry<String, int>> _filterSymptoms() {
    final allSymptoms = widget.symptomStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (_searchQuery.isEmpty) return allSymptoms;

    return allSymptoms
        .where(
          (entry) =>
              entry.key.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }
}

/// Individual symptom row with frequency
class SymptomRow extends StatelessWidget {
  final String symptomName;
  final int frequency;

  const SymptomRow({
    super.key,
    required this.symptomName,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              symptomName,
              style: AppTypography.bodyMediumWhiteSemibold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '$frequency',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stats card for summary information
class StatsCard extends StatelessWidget {
  final String title;
  final List<Widget> statRows;

  const StatsCard({super.key, required this.title, required this.statRows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppComponents.primaryCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.headlineSmall),
          VSpace.m,
          ...statRows,
        ],
      ),
    );
  }
}

/// Individual stat row
class StatRow extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final VoidCallback? onTap;

  const StatRow({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMediumWhite)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value $unit',
                style: AppTypography.bodyMediumPrimarySemibold,
              ),
              if (onTap != null) HSpace.s,
              if (onTap != null)
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: CupertinoColors.systemGrey,
                ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) {
      return row;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: row,
    );
  }
}
