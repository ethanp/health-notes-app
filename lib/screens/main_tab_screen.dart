import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/screens/check_ins_screen.dart';
import 'package:health_notes/screens/health_notes_home_page.dart';
import 'package:health_notes/screens/my_tools_screen.dart';
import 'package:health_notes/screens/trends_screen.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/theme/app_theme.dart';

import 'package:health_notes/widgets/enhanced_ui_components.dart';

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

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(
      duration: AppAnimation.medium,
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeInController,
        curve: AppAnimation.curve,
      ),
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
        tabBar: CupertinoTabBar(
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chart_bar),
              label: 'Trends',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chart_bar_alt_fill),
              label: 'Check-ins',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.doc_text),
              label: 'Notes',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.wrench),
              label: 'My Tools',
            ),
          ],
        ),
        tabBuilder: (context, index) => CupertinoTabView(
          builder: (context) => FadeTransition(
            opacity: _fadeInAnimation,
            child: switch (index) {
              0 => const TrendsScreen(),
              1 => const CheckInsScreen(),
              2 => const HealthNotesHomePage(),
              3 => const MyToolsScreen(),
              _ => const TrendsScreen(),
            },
          ),
        ),
      ),
    );
  }
}
