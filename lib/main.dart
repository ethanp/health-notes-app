import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/auth_provider.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/screens/auth_screen.dart';
import 'package:health_notes/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // Debug: Print environment variables (remove in production)
  print('Supabase URL: ${dotenv.env['URL']}');
  print('Supabase Anon Key: ${dotenv.env['ANON_KEY']?.substring(0, 20)}...');

  await Supabase.initialize(
    url: dotenv.env['URL']!,
    anonKey: dotenv.env['ANON_KEY']!,
  );

  // Initialize Google Sign-In following the official documentation
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;
  unawaited(
    googleSignIn
        .initialize(
          clientId:
              '514002384587-cerg0oevd7cv698ockkmoesvqkcq42q4.apps.googleusercontent.com',
          serverClientId:
              '514002384587-tg39uqob0ue1g191duhjbg7e6urdb5vh.apps.googleusercontent.com',
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

    // If this is a sign-in event, complete the Supabase authentication
    if (authEvent is GoogleSignInAuthenticationEventSignIn) {
      try {
        final authService = AuthService();
        await authService.completeSignInWithGoogle(authEvent);
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
        theme: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: CupertinoColors.systemBlue,
          scaffoldBackgroundColor: CupertinoColors.systemBackground,
          barBackgroundColor: CupertinoColors.systemGrey6,
          textTheme: CupertinoTextThemeData(
            primaryColor: CupertinoColors.systemBlue,
            textStyle: TextStyle(color: CupertinoColors.label),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (isAuthenticated) {
      return const HealthNotesHomePage();
    } else {
      return const AuthScreen();
    }
  }
}

class HealthNotesHomePage extends ConsumerStatefulWidget {
  const HealthNotesHomePage({super.key});

  @override
  ConsumerState<HealthNotesHomePage> createState() =>
      _HealthNotesHomePageState();
}

class _HealthNotesHomePageState extends ConsumerState<HealthNotesHomePage> {
  void _showAddNoteModal() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => const AddNoteModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(healthNotesNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Health Notes'),
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
          data: (notes) => notes.isEmpty ? emptyTable() : table(notes),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget emptyTable() {
    return const Center(
      child: Text(
        'No health notes yet.\nTap + to add your first note.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
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
            decoration: BoxDecoration(
              color: CupertinoColors.destructiveRed,
              borderRadius: BorderRadius.circular(8),
            ),
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
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CupertinoColors.separator, width: 0.5),
            ),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (note.drugDoses.isNotEmpty) ...[
                    Text(
                      'Drugs:',
                      style: const TextStyle(
                        color: CupertinoColors.label,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...note.drugDoses.map(
                      (dose) => Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          '• ${dose.name} - ${dose.dosage} ${dose.unit}',
                          style: const TextStyle(color: CupertinoColors.label),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (note.notes.isNotEmpty) ...[
                    Text(
                      'Notes: ${note.notes}',
                      style: const TextStyle(color: CupertinoColors.label),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    'Date: ${_formatDateTime(note.dateTime)}',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 12,
                    ),
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
            title: const Text('Delete Health Note'),
            content: Text(
              'Are you sure you want to delete this health note from ${_formatDateTime(note.dateTime)}?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Delete'),
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
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Sign Out'),
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
              title: const Text('Error'),
              content: Text('Failed to sign out: $e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
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
            title: const Text('Error'),
            content: Text('Failed to save note: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
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
        middle: const Text('Add Health Note'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: _isLoading
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _saveNote,
                child: const Text('Save'),
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
                    const Text(
                      'Date & Time',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: CupertinoColors.systemGrey4),
                      ),
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
                placeholderStyle: const TextStyle(
                  color: CupertinoColors.systemGrey,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(10),
                ),
                style: const TextStyle(color: CupertinoColors.label),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Drugs/Medications',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: CupertinoColors.label,
                          ),
                        ),
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
                placeholderStyle: const TextStyle(
                  color: CupertinoColors.systemGrey,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(10),
                ),
                style: const TextStyle(color: CupertinoColors.label),
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
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        border: Border.all(color: CupertinoColors.separator),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  placeholder: 'Drug name',
                  placeholderStyle: const TextStyle(
                    color: CupertinoColors.systemGrey,
                  ),
                  style: const TextStyle(color: CupertinoColors.label),
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
                  placeholderStyle: const TextStyle(
                    color: CupertinoColors.systemGrey,
                  ),
                  style: const TextStyle(color: CupertinoColors.label),
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
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  border: Border.all(color: CupertinoColors.separator),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'mg',
                  style: TextStyle(
                    color: CupertinoColors.label,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
