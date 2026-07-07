import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/app_card.dart';
import 'package:health_notes/theme/spacing.dart';

class SearchableStatsTable extends StatefulWidget {
  final String searchPlaceholder;
  final Map<String, int> stats;
  final void Function(String)? onItemTap;

  const SearchableStatsTable({
    super.key,
    required this.searchPlaceholder,
    required this.stats,
    this.onItemTap,
  });

  @override
  State<SearchableStatsTable> createState() => _SearchableStatsTableState();
}

class _SearchableStatsTableState extends State<SearchableStatsTable> {
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
    final filtered = _filter();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoSearchTextField(
            controller: _searchController,
            placeholder: widget.searchPlaceholder,
            placeholderStyle: AppText.inputPlaceholder,
            style: AppText.input,
            onChanged: (query) => setState(() => _searchQuery = query),
          ),
          VSpace.s,
          Text(
            '${widget.stats.length} total',
            style: AppText.body.small.systemGrey,
          ),
          VSpace.s,
          _buildList(filtered),
        ],
      ),
    );
  }

  Widget _buildList(List<MapEntry<String, int>> items) {
    const rowHeight = 48.0;
    const maxVisibleRows = 6;
    final listHeight = (items.length.clamp(1, maxVisibleRows)) * rowHeight;

    return SizedBox(
      height: listHeight,
      child: ListView.builder(
        itemCount: items.length,
        itemExtent: rowHeight,
        itemBuilder: (context, index) {
          final entry = items[index];
          return _StatsRow(
            label: entry.key,
            count: entry.value,
            onTap: widget.onItemTap != null
                ? () => widget.onItemTap!(entry.key)
                : null,
          );
        },
      ),
    );
  }

  List<MapEntry<String, int>> _filter() {
    final all = widget.stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (_searchQuery.isEmpty) return all;

    return all
        .where((e) => e.key.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }
}

class _StatsRow extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback? onTap;

  const _StatsRow({required this.label, required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: AppText.body.medium.white.semibold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.s),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '$count',
              style: AppText.label.small.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}

