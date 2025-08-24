import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/screens/filter_modal.dart';
import 'package:health_notes/screens/health_note_form.dart';
import 'package:health_notes/screens/health_note_view_screen.dart';
import 'package:health_notes/services/auth_service.dart';
import 'package:health_notes/services/search_service.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:intl/intl.dart';

class HealthNotesHomePage extends ConsumerStatefulWidget {
  const HealthNotesHomePage();

  @override
  ConsumerState<HealthNotesHomePage> createState() =>
      _HealthNotesHomePageState();
}

class _HealthNotesHomePageState extends ConsumerState<HealthNotesHomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  String? _selectedDrug;

  @override
  void dispose() {
    _searchController.dispose();
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
    final notesAsync = ref.watch(healthNotesNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Health Notes', style: AppTheme.titleMedium),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: showSignOutDialog,
          child: const Icon(CupertinoIcons.person_circle),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: showAddNoteModal,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: notesAsync.when(
          data: (notes) =>
              notes.isEmpty ? emptyTable() : buildFilteredContent(notes),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) =>
              Center(child: Text('Error: $error', style: AppTheme.error)),
        ),
      ),
    );
  }

  Widget buildFilteredContent(List<HealthNote> notes) {
    final filteredNotes = filterNotes(notes);
    final hasActiveFilters =
        _searchQuery.isNotEmpty ||
        _selectedDate != null ||
        _selectedDrug != null;

    return Column(
      children: [
        buildSearchBar(),
        if (hasActiveFilters) buildFilterChips(notes),
        Expanded(
          child: filteredNotes.isEmpty
              ? buildNoResultsMessage(hasActiveFilters)
              : table(filteredNotes),
        ),
      ],
    );
  }

  Widget buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: 'Search...',
              placeholderStyle: AppTheme.inputPlaceholder,
              style: AppTheme.input,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onSuffixTap: _searchQuery.isNotEmpty
                  ? () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    }
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.all(12),
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
            onPressed: () => showFilterModal(),
            child: Icon(
              CupertinoIcons.slider_horizontal_3,
              color: (_selectedDate != null || _selectedDrug != null)
                  ? CupertinoColors.systemBlue
                  : CupertinoColors.systemGrey,
            ),
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
        onDateChanged: (date) {
          setState(() {
            _selectedDate = date;
          });
        },
        onDrugChanged: (drug) {
          setState(() {
            _selectedDrug = drug;
          });
        },
      ),
    );
  }

  Widget buildFilterChips(List<HealthNote> notes) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_selectedDate != null)
            buildFilterChip(
              'Date: ${DateFormat('M/d/yyyy').format(_selectedDate!)}',
              () {
                setState(() {
                  _selectedDate = null;
                });
              },
            ),
          if (_selectedDrug != null)
            buildFilterChip('Drug: $_selectedDrug', () {
              setState(() {
                _selectedDrug = null;
              });
            }),
          if (_searchQuery.isNotEmpty ||
              _selectedDate != null ||
              _selectedDrug != null)
            buildFilterChip('Clear All', clearFilters, isClearAll: true),
        ],
      ),
    );
  }

  Widget buildFilterChip(
    String label,
    VoidCallback onTap, {
    bool isClearAll = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: isClearAll
            ? CupertinoColors.systemGrey
            : CupertinoColors.systemBlue,
        borderRadius: BorderRadius.circular(16),
        onPressed: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTheme.labelSmallWhite),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.xmark_circle_fill,
              size: 14,
              color: CupertinoColors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNoResultsMessage(bool hasActiveFilters) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.search,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            hasActiveFilters
                ? 'No notes match your filters'
                : 'No health notes yet',
            style: AppTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveFilters
                ? 'Try adjusting your search or filters'
                : 'Tap + to add your first note',
            style: AppTheme.subtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget emptyTable() {
    return Center(
      child: Text(
        'No health notes yet.\nTap + to add your first note.',
        textAlign: TextAlign.center,
        style: AppTheme.subtitle,
      ),
    );
  }

  Widget table(List<HealthNote> notes) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Dismissible(
          key: Key(note.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: AppTheme.deleteContainer,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(
              CupertinoIcons.delete,
              color: CupertinoColors.white,
              size: 30,
            ),
          ),
          confirmDismiss: (direction) async {
            return await showDeleteConfirmation(note);
          },
          onDismissed: (direction) {
            deleteNote(note.id);
          },
          child: GestureDetector(
            onTap: () => navigateToView(note),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: AppTheme.cardContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            note.symptoms.isNotEmpty
                                ? note.symptoms
                                : 'No symptoms recorded',
                            style: AppTheme.titleMedium,
                          ),
                        ),
                        const Icon(CupertinoIcons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (note.drugDoses.isNotEmpty) ...[
                      Text('Drugs:', style: AppTheme.titleSmall),
                      const SizedBox(height: 4),
                      ...note.drugDoses.map(
                        (dose) => Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            '• ${dose.name} - ${dose.dosage} ${dose.unit}',
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (note.notes.isNotEmpty) ...[
                      Text('Notes: ${note.notes}', style: AppTheme.bodyMedium),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      'Date: ${formatDateTime(note.dateTime)}',
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('M/d/yyyy \'at\' h:mm a').format(dateTime);
  }

  Future<bool> showDeleteConfirmation(HealthNote note) async {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Delete Health Note', style: AppTheme.titleMedium),
            content: Text(
              'Are you sure you want to delete this health note from ${formatDateTime(note.dateTime)}?',
              style: AppTheme.bodyMedium,
            ),
            actions: [
              CupertinoDialogAction(
                child: Text('Cancel', style: AppTheme.buttonSecondary),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: Text('Delete', style: AppTheme.error),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }

  void deleteNote(String noteId) {
    ref.read(healthNotesNotifierProvider.notifier).deleteNote(noteId);
  }

  Future<void> showSignOutDialog() async {
    final shouldSignOut = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Sign Out', style: AppTheme.titleMedium),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel', style: AppTheme.buttonSecondary),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Sign Out', style: AppTheme.error),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        final authService = AuthService();
        await authService.signOut();
      } catch (e) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: Text('Error', style: AppTheme.titleMedium),
              content: Text('Failed to sign out: $e', style: AppTheme.error),
              actions: [
                CupertinoDialogAction(
                  child: Text('OK', style: AppTheme.buttonSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}
