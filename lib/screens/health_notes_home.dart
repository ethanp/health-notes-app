import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/screens/health_notes_home_page.dart';
import 'package:health_notes/screens/library_screen.dart';
import 'package:health_notes/screens/trends_screen.dart';

const _mainTabs = <EMainTab>[
  EMainTab(
    icon: Icons.description_outlined,
    label: 'Notes',
    screen: HealthNotesHomePage(),
  ),
  EMainTab(
    icon: Icons.menu_book_outlined,
    label: 'Library',
    screen: LibraryScreen(),
  ),
  EMainTab(
    icon: Icons.bar_chart_outlined,
    label: 'Trends',
    screen: TrendsScreen(),
  ),
];

/// The main tabs, with a full sync kicked off after the first frame.
class const HealthNotesHome() extends ConsumerStatefulWidget {
  @override
  ConsumerState<HealthNotesHome> createState() => _HealthNotesHomeState();
}

class _HealthNotesHomeState() extends ConsumerState<HealthNotesHome> {
  late final SyncNotifier _syncNotifier;

  @override
  void initState() {
    super.initState();
    _syncNotifier = ref.read(syncProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncNotifier.forceSyncAllData();
    });
  }

  @override
  Widget build(BuildContext context) => const EMainTabScreen(tabs: _mainTabs);
}
