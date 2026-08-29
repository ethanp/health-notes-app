import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/screens/health_notes_home_page.dart';
import 'package:health_notes/screens/library_screen.dart';
import 'package:health_notes/screens/trends_screen.dart';

class MainTab {
  const MainTab({
    required this.icon,
    required this.label,
    required this.screen,
  });

  final IconData icon;
  final String label;
  final Widget screen;
}

const _mainTabs = <MainTab>[
  MainTab(
    icon: Icons.description_outlined,
    label: 'Notes',
    screen: HealthNotesHomePage(),
  ),
  MainTab(
    icon: Icons.menu_book_outlined,
    label: 'Library',
    screen: LibraryScreen(),
  ),
  MainTab(
    icon: Icons.bar_chart_outlined,
    label: 'Trends',
    screen: TrendsScreen(),
  ),
];

class MainTabScreen extends ConsumerStatefulWidget {
  const MainTabScreen();

  @override
  ConsumerState<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends ConsumerState<MainTabScreen> {
  int _selectedTabIndex = 0;
  final _navigatorKeys = List<GlobalKey<NavigatorState>>.generate(
    _mainTabs.length,
    (_) => GlobalKey<NavigatorState>(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(syncNotifierProvider.notifier).forceSyncAllData();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return EScaffoldShell(
      contentMaxWidth: double.infinity,
      bottomBar: ETabBar(
        selectedIndex: _selectedTabIndex,
        tabs: [
          for (final tab in _mainTabs) ETab(icon: tab.icon, label: tab.label),
        ],
        onSelected: (index) {
          if (index == _selectedTabIndex) {
            _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
            return;
          }
          setState(() => _selectedTabIndex = index);
        },
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          for (var tabIndex = 0; tabIndex < _mainTabs.length; tabIndex++)
            Navigator(
              key: _navigatorKeys[tabIndex],
              onGenerateRoute: (settings) => MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => _mainTabs[tabIndex].screen,
              ),
            ),
        ],
      ),
    );
  }
}
