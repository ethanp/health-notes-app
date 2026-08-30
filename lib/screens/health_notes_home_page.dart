import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/models/grouped_health_notes.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/screens/filter_modal.dart';
import 'package:health_notes/screens/health_note_form.dart';
import 'package:health_notes/screens/health_note_view_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/log_out_button.dart';
import 'package:health_notes/widgets/app_dialogs.dart';
import 'package:health_notes/widgets/app_filter_chip.dart';
import 'package:health_notes/widgets/health_notes_search_field.dart';
import 'package:health_notes/widgets/health_note_card.dart';
import 'package:health_notes/widgets/animated_welcome_card.dart';
import 'package:health_notes/widgets/refreshable_list_view.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:intl/intl.dart';

class const HealthNotesHomePage() extends ConsumerStatefulWidget {
  @override
  ConsumerState<HealthNotesHomePage> createState() =>
      _HealthNotesHomePageState();
}

class _HealthNotesHomePageState()
    extends ConsumerState<HealthNotesHomePage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  DrugName? _selectedDrug;
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
    context.push(
      const HealthNoteForm(title: 'Add Health Note', saveButtonText: 'Save'),
    );
  }

  void navigateToView(HealthNote note) {
    context.push(HealthNoteViewScreen(note: note));
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
      bool matchesSearch = note.matchesSearch(_searchQuery);

      bool matchesDate =
          _selectedDate == null ||
          (note.dateTime.year == _selectedDate!.year &&
              note.dateTime.month == _selectedDate!.month &&
              note.dateTime.day == _selectedDate!.day);

      bool matchesDrug = _selectedDrug == null || note.hasDrug(_selectedDrug!);

      return matchesSearch && matchesDate && matchesDrug;
    }).toList();
  }

  List<DrugName> getUniqueDrugs(List<HealthNote> notes) {
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

    return EScaffoldShell(
      contentMaxWidth: double.infinity,
      appBar: EAppHeader(
        title: 'Health Notes',
        leading: const LogOutButton(),
        actions: [
          const CompactSyncStatusWidget(),
          IconButton(
            tooltip: 'Add note',
            onPressed: showAddNoteModal,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: groupedNotesAsync.when(
        data: (groupedNotes) =>
            groupedNotes.isEmpty ? emptyTable() : filteredContent(groupedNotes),
        loading: () => const SyncStatusWidget.loading(
          message: 'Loading your health notes...',
        ),
        error: (error, stack) =>
            Center(child: Text('Error: $error', style: EText.error)),
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
            child: HealthNotesSearchField(
              controller: _searchController,
              placeholder: 'Search your health notes...',
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: _searchQuery.isNotEmpty
                  ? () => setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    })
                  : null,
            ),
          ),
          HSpace.s,
          IconButton(
            tooltip: 'Filters',
            onPressed: () => showFilterModal(),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
    );
  }

  void showFilterModal() {
    context.push(
      FilterModal(
        selectedDate: _selectedDate,
        selectedDrug: _selectedDrug,
        availableDrugs: getUniqueDrugs(
          ref.read(healthNotesProvider).value ?? [],
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
              'Drug: ${_selectedDrug!.display}',
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
      child: AppFilterChip(label: label, isActive: isClearAll, onTap: onTap),
    );
  }

  Widget noResultsMessage(bool hasActiveFilters) {
    if (hasActiveFilters) {
      return EEmptyState(
        title: 'No matches found',
        message: 'Try adjusting your search or filters to find what you\'re looking for',
        icon: CupertinoIcons.search,
      );
    } else {
      return AnimatedWelcomeCard(
        title: 'Welcome to Health Notes',
        message: 'Start tracking your health journey by adding your first note',
        icon: CupertinoIcons.heart_fill,
        iconColor: EColors.accent,
        action: FilledButton.icon(
          onPressed: showAddNoteModal,
          icon: const Icon(Icons.add),
          label: const Text('Add First Note'),
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
            await ref.read(healthNotesProvider.notifier).refreshNotes();
          },
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: AnimatedWelcomeCard(
            title: 'Welcome to Health Notes',
            message:
                'Start tracking your health journey by adding your first note',
            icon: CupertinoIcons.heart_fill,
            iconColor: EColors.accent,
            action: FilledButton.icon(
              onPressed: showAddNoteModal,
              icon: const Icon(Icons.add),
              label: const Text('Add First Note'),
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
      onReloadRequested: () async {
        await ref.read(healthNotesProvider.notifier).refreshNotes();
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
    return ESectionHeader(
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
      child: HealthNoteCard(note: note, onTap: () => navigateToView(note)),
    );
  }

  Widget noteDismissBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: EColors.danger,
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

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = now.startOfDay;
    final yesterday = today.shiftedByDays(-1);
    final groupDate = date.startOfDay;
    final formattedDate = DateFormat('MMM d, yyyy').format(date);

    if (groupDate == today) {
      return 'Today ($formattedDate)';
    } else if (groupDate == yesterday) {
      return 'Yesterday ($formattedDate)';
    } else {
      return DateFormat('EEEE, MMMM d, yyyy').format(date);
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
    ref.read(healthNotesProvider.notifier).deleteNote(noteId);
  }
}
