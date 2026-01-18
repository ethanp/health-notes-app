import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/screens/conditions_screen.dart';
import 'package:health_notes/screens/health_notes_home_page.dart';
import 'package:health_notes/screens/my_tools_screen.dart';
import 'package:health_notes/screens/trends_screen.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/theme/app_theme.dart';

import 'package:health_notes/widgets/enhanced_ui_components.dart';

class TabDefinition {
  const TabDefinition({required this.item, required this.view});
  final BottomNavigationBarItem item;
  final Widget view;
}

class MainTabScreen extends ConsumerStatefulWidget {
  const MainTabScreen();

  @override
  ConsumerState<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends ConsumerState<MainTabScreen>
    with TickerProviderStateMixin {
  int currentTabIndex = 0;
  late AnimationController _fadeInController;
  late Animation<double> _fadeInAnimation;

  static const _tabs = <TabDefinition>[
    TabDefinition(
      item: BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.doc_text),
        label: 'Notes',
      ),
      view: HealthNotesHomePage(),
    ),
    TabDefinition(
      item: BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.bandage),
        label: 'Conditions',
      ),
      view: ConditionsScreen(),
    ),
    TabDefinition(
      item: BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.chart_bar),
        label: 'Trends',
      ),
      view: TrendsScreen(),
    ),
    TabDefinition(
      item: BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.wrench),
        label: 'Tools',
      ),
      view: MyToolsScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(
      duration: AppAnimation.medium,
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeInController, curve: AppAnimation.curve),
    );
    _fadeInController.forward();

    // Force sync when app first loads, and ensure providers refresh after sync.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(syncNotifierProvider.notifier).forceSyncAllData();
      } catch (e) {
        // Sync failed - not critical for app startup
      }
    });
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EnhancedUIComponents.animatedGradientBackground(
      child: CupertinoTabScaffold(
        tabBar: mainTabBar(),
        tabBuilder: (context, index) => tabView(index),
      ),
    );
  }

  CupertinoTabBar mainTabBar() {
    return CupertinoTabBar(
      currentIndex: currentTabIndex,
      onTap: (int index) {
        setState(() => currentTabIndex = index);
        _fadeInController.reset();
        _fadeInController.forward();
      },
      backgroundColor: Colors.transparent,
      activeColor: AppColors.primary,
      inactiveColor: AppColors.textTertiary,
      border: Border(
        top: BorderSide(
          color: AppColors.backgroundQuaternary.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      items: _tabs.map((t) => t.item).toList(),
    );
  }

  Widget tabView(int index) {
    return CupertinoTabView(
      builder: (context) =>
          FadeTransition(opacity: _fadeInAnimation, child: _tabs[index].view),
    );
  }
}
