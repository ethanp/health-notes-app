import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/grouped_health_notes.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/screens/filter_modal.dart';
import 'package:health_notes/screens/health_note_form.dart';
import 'package:health_notes/screens/health_note_view_screen.dart';
import 'package:health_notes/services/search_service.dart';
import 'package:health_notes/theme/app_theme.dart';

import 'package:health_notes/utils/auth_utils.dart';
import 'package:health_notes/widgets/animated_welcome_card.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/refreshable_list_view.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';
import 'package:intl/intl.dart';

class HealthNotesHomePage extends ConsumerStatefulWidget {
  const HealthNotesHomePage();

  @override
  ConsumerState<HealthNotesHomePage> createState() =>
      _HealthNotesHomePageState();
}

class _HealthNotesHomePageState extends ConsumerState<HealthNotesHomePage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  String? _selectedDrug;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimation.medium,
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppAnimation.slideCurve,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void showAddNoteModal() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => const HealthNoteForm(
        title: 'Add Health Note',
        saveButtonText: 'Save',
      ),
    );
  }

  void navigateToView(HealthNote note) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => HealthNoteViewScreen(note: note),
      ),
    );
  }

  void clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedDate = null;
      _selectedDrug = null;
      _searchController.clear();
    });
  }

  List<HealthNote> filterNotes(List<HealthNote> notes) {
    return notes.where((note) {
      bool matchesSearch = SearchService.matchesSearch(note, _searchQuery);

      bool matchesDate =
          _selectedDate == null ||
          (note.dateTime.year == _selectedDate!.year &&
              note.dateTime.month == _selectedDate!.month &&
              note.dateTime.day == _selectedDate!.day);

      bool matchesDrug =
          _selectedDrug == null ||
          note.drugDoses.any((dose) => dose.name == _selectedDrug);

      return matchesSearch && matchesDate && matchesDrug;
    }).toList();
  }

  List<String> getUniqueDrugs(List<HealthNote> notes) {
    return notes
        .expand((note) => note.drugDoses)
        .map((dose) => dose.name)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  Widget build(BuildContext context) {
    final groupedNotesAsync = ref.watch(groupedHealthNotesProvider);

    return CupertinoPageScaffold(
      navigationBar: EnhancedUIComponents.navigationBar(
        title: 'Health Notes',
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => AuthUtils.showSignOutDialog(context),
          child: const Icon(CupertinoIcons.person_circle),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CompactSyncStatusWidget(),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: showAddNoteModal,
              child: const Icon(CupertinoIcons.add),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: groupedNotesAsync.when(
          data: (groupedNotes) => groupedNotes.isEmpty
              ? emptyTable()
              : filteredContent(groupedNotes),
          loading: () => const SyncStatusWidget.loading(
            message: 'Loading your health notes...',
          ),
          error: (error, stack) =>
              Center(child: Text('Error: $error', style: AppTypography.error)),
        ),
      ),
    );
  }

  Widget filteredContent(List<GroupedHealthNotes> groupedNotes) {
    final allNotes = groupedNotes.expand((group) => group.notes).toList();
    final filteredNotes = filterNotes(allNotes);
    final hasActiveFilters =
        _searchQuery.isNotEmpty ||
        _selectedDate != null ||
        _selectedDrug != null;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Column(
        children: [
          searchBar(),
          if (hasActiveFilters) filterChips(allNotes),
          Expanded(
            child: filteredNotes.isEmpty
                ? noResultsMessage(hasActiveFilters)
                : groupedTable(groupedNotes, filteredNotes),
          ),
        ],
      ),
    );
  }

  Widget searchBar() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          Expanded(
            child: EnhancedUIComponents.searchField(
              controller: _searchController,
              placeholder: 'Search your health notes...',
              onChanged: (value) => setState(() => _searchQuery = value),
              onSuffixTap: _searchQuery.isNotEmpty
                  ? () => setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    })
                  : null,
              showSuffix: _searchQuery.isNotEmpty,
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          EnhancedUIComponents.button(
            text: '',
            onPressed: () => showFilterModal(),
            isPrimary: false,
            icon: CupertinoIcons.slider_horizontal_3,
            width: 48,
          ),
        ],
      ),
    );
  }

  void showFilterModal() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => FilterModal(
        selectedDate: _selectedDate,
        selectedDrug: _selectedDrug,
        availableDrugs: getUniqueDrugs(
          ref.read(healthNotesNotifierProvider).value ?? [],
        ),
        onDateChanged: (date) => setState(() => _selectedDate = date),
        onDrugChanged: (drug) => setState(() => _selectedDrug = drug),
      ),
    );
  }

  Widget filterChips(List<HealthNote> notes) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_selectedDate != null)
            filterChip(
              'Date: ${DateFormat('M/d/yyyy').format(_selectedDate!)}',
              () => setState(() => _selectedDate = null),
            ),
          if (_selectedDrug != null)
            filterChip(
              'Drug: $_selectedDrug',
              () => setState(() => _selectedDrug = null),
            ),
          if (_searchQuery.isNotEmpty ||
              _selectedDate != null ||
              _selectedDrug != null)
            filterChip('Clear All', clearFilters, isClearAll: true),
        ],
      ),
    );
  }

  Widget filterChip(
    String label,
    VoidCallback onTap, {
    bool isClearAll = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.s),
      child: EnhancedUIComponents.filterChip(
        label: label,
        isActive: isClearAll,
        onTap: onTap,
      ),
    );
  }

  Widget noResultsMessage(bool hasActiveFilters) {
    if (hasActiveFilters) {
      return EnhancedUIComponents.emptyState(
        title: 'No matches found',
        message:
            'Try adjusting your search or filters to find what you\'re looking for',
        icon: CupertinoIcons.search,
      );
    } else {
      return AnimatedWelcomeCard(
        title: 'Welcome to Health Notes',
        message: 'Start tracking your health journey by adding your first note',
        icon: CupertinoIcons.heart_fill,
        iconColor: AppColors.primary,
        action: EnhancedUIComponents.button(
          text: 'Add First Note',
          onPressed: showAddNoteModal,
          icon: CupertinoIcons.add,
        ),
      );
    }
  }

  Widget emptyTable() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await ref.read(healthNotesNotifierProvider.notifier).refreshNotes();
          },
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: AnimatedWelcomeCard(
            title: 'Welcome to Health Notes',
            message:
                'Start tracking your health journey by adding your first note',
            icon: CupertinoIcons.heart_fill,
            iconColor: AppColors.primary,
            action: EnhancedUIComponents.button(
              text: 'Add First Note',
              onPressed: showAddNoteModal,
              icon: CupertinoIcons.add,
            ),
          ),
        ),
      ],
    );
  }

  Widget groupedTable(
    List<GroupedHealthNotes> groupedNotes,
    List<HealthNote> filteredNotes,
  ) {
    final filteredNoteIds = filteredNotes.map((note) => note.id).toSet();
    final visibleGroups = groupedNotes.where((group) {
      final visibleNotes = group.notes
          .where((note) => filteredNoteIds.contains(note.id))
          .toList();
      return visibleNotes.isNotEmpty;
    }).toList();

    return RefreshableListView<GroupedHealthNotes>(
      onRefresh: () async {
        await ref.read(healthNotesNotifierProvider.notifier).refreshNotes();
      },
      items: visibleGroups,
      itemBuilder: (group) => groupedNotesSection(group, filteredNoteIds),
    );
  }

  Widget groupedNotesSection(
    GroupedHealthNotes group,
    Set<String> filteredNoteIds,
  ) {
    final visibleNotes = group.notes
        .where((note) => filteredNoteIds.contains(note.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        groupHeader(group.date, visibleNotes.length),
        ...visibleNotes.map((note) => noteCard(note)),
      ],
    );
  }

  Widget groupHeader(DateTime date, int count) {
    return EnhancedUIComponents.sectionHeader(
      title: _formatGroupDate(date),
      subtitle: '$count note${count == 1 ? '' : 's'}',
    );
  }

  Widget noteCard(HealthNote note) {
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: noteDismissBackground(),
      confirmDismiss: (direction) async => await showDeleteConfirmation(note),
      onDismissed: (direction) => deleteNote(note.id),
      child: EnhancedUIComponents.card(
        onTap: () => navigateToView(note),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            noteContent(note),
            if (note.notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.m),
              noteSummary(note.notes),
            ],
          ],
        ),
      ),
    );
  }

  Widget noteDismissBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.destructive,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.l),
      child: const Icon(
        CupertinoIcons.delete,
        color: CupertinoColors.white,
        size: 30,
      ),
    );
  }

  Widget noteContent(HealthNote note) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Expanded(child: noteContentColumn(note))],
    );
  }

  Widget noteContentColumn(HealthNote note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (note.hasSymptoms) ...symptomDetails(note),
        if (note.drugDoses.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s),
          ...note.drugDoses.map(medicationRow),
        ],
        if (note.appliedTools.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s),
          appliedToolsRow(note),
        ],
      ],
    );
  }

  List<Widget> symptomDetails(HealthNote note) {
    return note.validSymptoms.map((symptom) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            symptomHeader(note, symptom),
            if (symptom.additionalNotes.isNotEmpty)
              symptomAdditionalNotes(symptom),
          ],
        ),
      );
    }).toList();
  }

  Widget symptomHeader(HealthNote note, Symptom symptom) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        EnhancedUIComponents.statusIndicator(
          text: '${symptom.severityLevel}/10',
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text(
            symptom.minorComponent.isNotEmpty
                ? '${symptom.majorComponent} - ${symptom.minorComponent}'
                : symptom.majorComponent,
            style: AppTypography.labelLarge,
          ),
        ),
        Text(
          DateFormat('h:mm a').format(note.dateTime),
          style: AppTypography.caption,
        ),
      ],
    );
  }

  Widget symptomAdditionalNotes(Symptom symptom) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.s + 8),
      child: Text(
        symptom.additionalNotes,
        style: AppTypography.bodySmallSecondary,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget medicationRow(DrugDose dose) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              '${dose.name} ${dose.dosage}',
              style: AppTypography.labelMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget appliedToolsRow(HealthNote note) {
    final toolNames = note.appliedTools.map((t) => t.toolName).toList();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.s,
        runSpacing: AppSpacing.s,
        children: toolNames.map((name) {
          return Container(
            decoration: AppComponents.filterChip,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.wrench,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.s),
                Text(name, style: AppTypography.labelMedium),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget noteSummary(String notes) {
    return Text(
      notes,
      style: AppTypography.bodySmall,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groupDate = DateTime(date.year, date.month, date.day);

    if (groupDate == today) {
      return 'Today';
    } else if (groupDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d').format(date);
    }
  }

  Future<bool> showDeleteConfirmation(HealthNote note) async {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => AppAlertDialogs.confirmDestructive(
            title: 'Delete Note',
            content:
                'Are you sure you want to delete this note from ${DateFormat('M/d/yyyy').format(note.dateTime)}?',
            confirmText: 'Delete',
          ),
        ) ??
        false;
  }

  void deleteNote(String noteId) {
    ref.read(healthNotesNotifierProvider.notifier).deleteNote(noteId);
  }
}
