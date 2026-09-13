import 'dart:async';

import 'package:ethan_sync/ethan_sync.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/app_identity.dart';
import 'package:health_notes/screens/main_tab_screen.dart';
import 'package:health_notes/sync/sync_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _logger = ELogger('HealthNotesMain');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadAppDotEnv();

  if (!DotEnvSyncBootstrap.isConfigured()) {
    throw StateError(
      'Set POWERSYNC_JWT_SECRET and SERVER_HOST_LAN or '
      'SERVER_HOST_TAILSCALE in .env '
      '(ethan_sync is required for local storage).',
    );
  }

  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      syncConfigProvider.overrideWith(
        (ref) => buildHealthNotesSyncConfig(preferences),
      ),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MainScreen(),
    ),
  );
  unawaited(_startSync(container));
}

Future<void> _startSync(ProviderContainer container) async {
  try {
    await SyncLifecycle.start(container);
    _logger.fine('ethan_sync started');
  } catch (error, stackTrace) {
    _logger.error('ethan_sync failed to start', error, stackTrace);
  }
}

class const MainScreen() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppIdentity.displayName,
      theme: ETheme.material3Dark,
      debugShowCheckedModeBanner: false,
      home: const MainTabScreen(),
    );
  }
}
