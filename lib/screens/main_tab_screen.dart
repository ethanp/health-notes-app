import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/screens/health_notes_home_page.dart';
import 'package:health_notes/screens/trends_screen.dart';
import 'package:health_notes/screens/check_ins_screen.dart';
import 'package:health_notes/screens/my_tools_screen.dart';

class MainTabScreen extends ConsumerStatefulWidget {
  const MainTabScreen();

  @override
  ConsumerState<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends ConsumerState<MainTabScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: selectedIndex,
        onTap: (index) => setState(() => selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.doc_text),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar_alt_fill),
            label: 'Check-ins',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.wrench),
            label: 'My Tools',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar),
            label: 'Trends',
          ),
        ],
      ),
      tabBuilder: (context, index) => CupertinoTabView(
        builder: (context) => switch (index) {
          0 => const HealthNotesHomePage(),
          1 => const CheckInsScreen(),
          2 => const MyToolsScreen(),
          3 => const TrendsScreen(),
          _ => const HealthNotesHomePage(),
        },
      ),
    );
  }
}
