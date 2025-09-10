import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/screens/health_notes_home_page.dart';
import 'package:health_notes/screens/trends_screen.dart';
import 'package:health_notes/screens/check_ins_screen.dart';
import 'package:health_notes/screens/my_tools_screen.dart';
import 'package:health_notes/providers/auth_provider.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/services/offline_repository.dart';

class MainTabScreen extends ConsumerStatefulWidget {
  const MainTabScreen();

  @override
  ConsumerState<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends ConsumerState<MainTabScreen>
    with TickerProviderStateMixin {
  int selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.animationMedium,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppTheme.animationCurve,
      ),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postLoginSetup();
    });
  }

  Future<void> _postLoginSetup() async {
    try {
      final user = await ref.read(currentUserProvider.future);
      if (user != null) {
        OfflineRepository.syncStatusStream;
        await OfflineRepository.forceSyncAllData(user.id);
      }
    } catch (e) {
      // Sync failed - not critical for app startup
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() => selectedIndex = index);
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return EnhancedUIComponents.animatedGradientBackground(
      child: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          currentIndex: selectedIndex,
          onTap: _onTabChanged,
          backgroundColor: Colors.transparent,
          activeColor: AppTheme.primary,
          inactiveColor: AppTheme.textTertiary,
          border: Border(
            top: BorderSide(
              color: AppTheme.backgroundQuaternary.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
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
          builder: (context) => FadeTransition(
            opacity: _fadeAnimation,
            child: switch (index) {
              0 => const HealthNotesHomePage(),
              1 => const CheckInsScreen(),
              2 => const MyToolsScreen(),
              3 => const TrendsScreen(),
              _ => const HealthNotesHomePage(),
            },
          ),
        ),
      ),
    );
  }
}
