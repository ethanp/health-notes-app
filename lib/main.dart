import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/auth_provider.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/screens/auth_screen.dart';
import 'package:health_notes/services/auth_service.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['URL']!,
    anonKey: dotenv.env['ANON_KEY']!,
  );
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;
  unawaited(
    googleSignIn
        .initialize(
          clientId: dotenv.env['GOOGLE_IOS_CLIENT_ID'],
          serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
        )
        .then((_) {
          googleSignIn.authenticationEvents
              .listen(_handleGlobalAuthenticationEvent)
              .onError(_handleGlobalAuthenticationError);

          // Attempt lightweight authentication
          googleSignIn.attemptLightweightAuthentication();
        }),
  );

  runApp(const MainScreen());
}

void _handleGlobalAuthenticationEvent(
  GoogleSignInAuthenticationEvent? authEvent,
) async {
  if (authEvent != null) {
    print('Global: User signed in (def): $authEvent');
    if (authEvent is GoogleSignInAuthenticationEventSignIn) {
      try {
        final authService = AuthService();
        await authService.signIntoSupabase(authEvent.user);
      } catch (e) {
        print('Error completing Supabase authentication: $e');
      }
    }
  } else {
    print('Global: User signed out');
  }
}

void _handleGlobalAuthenticationError(dynamic error) {
  print('Global authentication error: $error');
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: CupertinoApp(
        title: 'Health Notes',
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticatedAsync = ref.watch(isAuthenticatedProvider);

    return isAuthenticatedAsync.when(
      data: (isAuthenticated) {
        if (isAuthenticated) {
          return const HealthNotesHomePage();
        } else {
          return const AuthScreen();
        }
      },
      loading: () => const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (error, stack) => CupertinoPageScaffold(
        child: Center(child: Text('Error: $error', style: AppTheme.error)),
      ),
    );
  }
}

class HealthNotesHomePage extends ConsumerStatefulWidget {
  const HealthNotesHomePage({super.key});

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

  void _showAddNoteModal() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => const AddNoteModal(),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedDate = null;
      _selectedDrug = null;
      _searchController.clear();
    });
  }

  List<HealthNote> _filterNotes(List<HealthNote> notes) {
    return notes.where((note) {
      bool matchesSearch =
          _searchQuery.isEmpty ||
          note.symptoms.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.notes.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.drugDoses.any(
            (dose) =>
                dose.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          );

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

  List<String> _getUniqueDrugs(List<HealthNote> notes) {
    final drugs = <String>{};
    for (final note in notes) {
      for (final dose in note.drugDoses) {
        if (dose.name.isNotEmpty) {
          drugs.add(dose.name);
        }
      }
    }
    return drugs.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(healthNotesNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Health Notes', style: AppTheme.titleMedium),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showSignOutDialog,
          child: const Icon(CupertinoIcons.person_circle),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showAddNoteModal,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: notesAsync.when(
          data: (notes) =>
              notes.isEmpty ? emptyTable() : _buildFilteredContent(notes),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) =>
              Center(child: Text('Error: $error', style: AppTheme.error)),
        ),
      ),
    );
  }

  Widget _buildFilteredContent(List<HealthNote> notes) {
    final filteredNotes = _filterNotes(notes);
    final hasActiveFilters =
        _searchQuery.isNotEmpty ||
        _selectedDate != null ||
        _selectedDrug != null;

    return Column(
      children: [
        _buildSearchBar(),
        if (hasActiveFilters) _buildFilterChips(notes),
        Expanded(
          child: filteredNotes.isEmpty
              ? _buildNoResultsMessage(hasActiveFilters)
              : table(filteredNotes),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: 'Search symptoms, notes, or drugs...',
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
            onPressed: () => _showFilterModal(),
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

  void _showFilterModal() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => FilterModal(
        selectedDate: _selectedDate,
        selectedDrug: _selectedDrug,
        availableDrugs: _getUniqueDrugs(
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

  Widget _buildFilterChips(List<HealthNote> notes) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_selectedDate != null)
            _buildFilterChip(
              'Date: ${DateFormat('M/d/yyyy').format(_selectedDate!)}',
              () {
                setState(() {
                  _selectedDate = null;
                });
              },
            ),
          if (_selectedDrug != null)
            _buildFilterChip('Drug: $_selectedDrug', () {
              setState(() {
                _selectedDrug = null;
              });
            }),
          if (_searchQuery.isNotEmpty ||
              _selectedDate != null ||
              _selectedDrug != null)
            _buildFilterChip('Clear All', _clearFilters, isClearAll: true),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
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
            Text(
              label,
              style: AppTheme.labelSmall.copyWith(color: CupertinoColors.white),
            ),
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

  Widget _buildNoResultsMessage(bool hasActiveFilters) {
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
            return await _showDeleteConfirmation(note);
          },
          onDismissed: (direction) {
            _deleteNote(note.id);
          },
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
                    'Date: ${_formatDateTime(note.dateTime)}',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('M/d/yyyy \'at\' h:mm a').format(dateTime);
  }

  Future<bool> _showDeleteConfirmation(HealthNote note) async {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Delete Health Note', style: AppTheme.titleMedium),
            content: Text(
              'Are you sure you want to delete this health note from ${_formatDateTime(note.dateTime)}?',
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

  void _deleteNote(String noteId) {
    ref.read(healthNotesNotifierProvider.notifier).deleteNote(noteId);
  }

  Future<void> _showSignOutDialog() async {
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

class FilterModal extends StatefulWidget {
  final DateTime? selectedDate;
  final String? selectedDrug;
  final List<String> availableDrugs;
  final Function(DateTime?) onDateChanged;
  final Function(String?) onDrugChanged;

  const FilterModal({
    super.key,
    required this.selectedDate,
    required this.selectedDrug,
    required this.availableDrugs,
    required this.onDateChanged,
    required this.onDrugChanged,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  DateTime? _tempSelectedDate;
  String? _tempSelectedDrug;
  bool _isDatePickerVisible = false;

  @override
  void initState() {
    super.initState();
    _tempSelectedDate = widget.selectedDate;
    _tempSelectedDrug = widget.selectedDrug;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Filters', style: AppTheme.titleMedium),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _applyFilters,
          child: Text('Apply', style: AppTheme.buttonSecondary),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.filterContainerWithBorder(
                CupertinoColors.systemGreen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter by Date', style: AppTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: _tempSelectedDate != null
                              ? CupertinoColors.systemBlue
                              : CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                          onPressed: () {
                            setState(() {
                              _isDatePickerVisible = !_isDatePickerVisible;
                            });
                          },
                          child: Text(
                            _tempSelectedDate != null
                                ? DateFormat(
                                    'M/d/yyyy',
                                  ).format(_tempSelectedDate!)
                                : 'Select Date',
                            style: _tempSelectedDate != null
                                ? AppTheme.button
                                : AppTheme.bodyMedium,
                          ),
                        ),
                      ),
                      if (_tempSelectedDate != null) ...[
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: const EdgeInsets.all(8),
                          color: CupertinoColors.destructiveRed,
                          borderRadius: BorderRadius.circular(8),
                          onPressed: () {
                            setState(() {
                              _tempSelectedDate = null;
                            });
                          },
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: CupertinoColors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.filterContainerWithBorder(
                CupertinoColors.systemOrange,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter by Drug', style: AppTheme.titleMedium),
                  const SizedBox(height: 16),
                  if (widget.availableDrugs.isEmpty)
                    Text('No drugs recorded yet', style: AppTheme.subtitle)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...widget.availableDrugs.map(
                          (drug) => CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            color: _tempSelectedDrug == drug
                                ? CupertinoColors.systemBlue
                                : CupertinoColors.systemBackground,
                            borderRadius: BorderRadius.circular(16),
                            onPressed: () {
                              setState(() {
                                _tempSelectedDrug = _tempSelectedDrug == drug
                                    ? null
                                    : drug;
                              });
                            },
                            child: Text(
                              drug,
                              style: _tempSelectedDrug == drug
                                  ? AppTheme.button
                                  : AppTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            if (_isDatePickerVisible) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.datePickerContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Select Date', style: AppTheme.titleMedium),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              _isDatePickerVisible = false;
                            });
                          },
                          child: const Icon(CupertinoIcons.xmark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 300,
                      decoration: AppTheme.datePickerContainer,
                      child: _buildCustomDatePicker(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDatePicker() {
    final currentDate = _tempSelectedDate ?? DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final days = List.generate(31, (index) => (index + 1).toString());
    final years = List.generate(
      11,
      (index) => (currentDate.year - 5 + index).toString(),
    );

    return Row(
      children: [
        Expanded(
          child: CupertinoPicker(
            itemExtent: 40,
            backgroundColor: CupertinoColors.systemGrey5,
            onSelectedItemChanged: (index) {
              setState(() {
                _tempSelectedDate = DateTime(
                  currentDate.year,
                  index + 1,
                  currentDate.day,
                );
              });
            },
            children: months
                .map(
                  (month) =>
                      Center(child: Text(month, style: AppTheme.bodyMedium)),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: CupertinoPicker(
            itemExtent: 40,
            backgroundColor: CupertinoColors.systemGrey5,
            onSelectedItemChanged: (index) {
              setState(() {
                _tempSelectedDate = DateTime(
                  currentDate.year,
                  currentDate.month,
                  index + 1,
                );
              });
            },
            children: days
                .map(
                  (day) => Center(child: Text(day, style: AppTheme.bodyMedium)),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: CupertinoPicker(
            itemExtent: 40,
            backgroundColor: CupertinoColors.systemGrey5,
            onSelectedItemChanged: (index) {
              setState(() {
                _tempSelectedDate = DateTime(
                  int.parse(years[index]),
                  currentDate.month,
                  currentDate.day,
                );
              });
            },
            children: years
                .map(
                  (year) =>
                      Center(child: Text(year, style: AppTheme.bodyMedium)),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  void _applyFilters() {
    widget.onDateChanged(_tempSelectedDate);
    widget.onDrugChanged(_tempSelectedDrug);
    Navigator.of(context).pop();
  }
}

class AddNoteModal extends ConsumerStatefulWidget {
  const AddNoteModal({super.key});

  @override
  ConsumerState<AddNoteModal> createState() => _AddNoteModalState();
}

class _AddNoteModalState extends ConsumerState<AddNoteModal> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  bool _isLoading = false;
  final List<DrugDose> _drugDoses = <DrugDose>[];

  @override
  void dispose() {
    _symptomsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(healthNotesNotifierProvider.notifier)
          .addNote(
            dateTime: _selectedDateTime,
            symptoms: _symptomsController.text,
            drugDoses: _drugDoses,
            notes: _notesController.text,
          );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Error', style: AppTheme.titleMedium),
            content: Text('Failed to save note: $e', style: AppTheme.error),
            actions: [
              CupertinoDialogAction(
                child: Text('OK', style: AppTheme.buttonSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Add Health Note', style: AppTheme.titleMedium),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: _isLoading
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _saveNote,
                child: Text('Save', style: AppTheme.buttonSecondary),
              ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date & Time', style: AppTheme.titleMedium),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: AppTheme.inputContainer,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.dateAndTime,
                        initialDateTime: _selectedDateTime,
                        backgroundColor: CupertinoColors.systemGrey6,
                        onDateTimeChanged: (DateTime newDateTime) {
                          setState(() => _selectedDateTime = newDateTime);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              CupertinoTextField(
                controller: _symptomsController,
                placeholder: 'Symptoms (optional)',
                placeholderStyle: AppTheme.inputPlaceholder,
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.inputContainer,
                style: AppTheme.input,
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.inputContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Drugs/Medications', style: AppTheme.titleMedium),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _addDrugDose,
                          child: const Icon(CupertinoIcons.add),
                        ),
                      ],
                    ),
                    if (_drugDoses.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ..._drugDoses.asMap().entries.map((entry) {
                        final index = entry.key;
                        final dose = entry.value;
                        return _buildDrugDoseItem(index, dose);
                      }),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              CupertinoTextField(
                controller: _notesController,
                placeholder: 'Additional Notes (optional)',
                placeholderStyle: AppTheme.inputPlaceholder,
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.inputContainer,
                style: AppTheme.input,
                maxLines: 4,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _addDrugDose() {
    setState(() {
      _drugDoses.add(const DrugDose(name: '', dosage: 0.0));
    });
  }

  void _removeDrugDose(int index) {
    setState(() {
      _drugDoses.removeAt(index);
    });
  }

  void _updateDrugDose(int index, DrugDose dose) {
    setState(() {
      _drugDoses[index] = dose;
    });
  }

  Widget _buildDrugDoseItem(int index, DrugDose dose) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardContainer,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  placeholder: 'Drug name',
                  placeholderStyle: AppTheme.inputPlaceholder,
                  style: AppTheme.input,
                  onChanged: (value) {
                    _updateDrugDose(index, dose.copyWith(name: value));
                  },
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _removeDrugDose(index),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: CupertinoColors.destructiveRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  placeholder: 'Dosage',
                  placeholderStyle: AppTheme.inputPlaceholder,
                  style: AppTheme.input,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final dosage = double.tryParse(value) ?? 0.0;
                    _updateDrugDose(index, dose.copyWith(dosage: dosage));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: AppTheme.labelContainer,
                child: Text('mg', style: AppTheme.labelMedium),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
