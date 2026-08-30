import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/providers/auth_provider.dart';
import 'package:health_notes/screens/auth_screen.dart';
import 'package:health_notes/screens/main_tab_screen.dart';
import 'package:health_notes/services/auth_service.dart';
import 'package:health_notes/services/connectivity_service.dart';
import 'package:health_notes/services/local_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadAppDotEnv(isOptional: false);
  await Supabase.initialize(
    url: dotenv.env['URL']!,
    anonKey: dotenv.env['ANON_KEY']!,
  );
  AuthService.initializeGoogleSignIn(
    clientId: dotenv.env['GOOGLE_IOS_CLIENT_ID']!,
    serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID']!,
  );
  await LocalDatabase.database;
  await LocalDatabase.fixNullUpdatedAtValues();
  await ConnectivityService().initialize();
  runApp(const ProviderScope(child: MainScreen()));
}

class const MainScreen() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Health Notes',
      theme: ETheme.build(),
      debugShowCheckedModeBanner: false,
      home: ref
          .watch(isAuthenticatedProvider)
          .when(
            data: (isAuthenticated) =>
                isAuthenticated ? const MainTabScreen() : const AuthScreen(),
            loading: () => const EScaffoldShell(
              contentMaxWidth: double.infinity,
              body: ELoadingState(message: 'Initializing app...'),
            ),
            error: (error, stack) => EScaffoldShell(
              contentMaxWidth: double.infinity,
              body: Center(child: Text('Error: $error', style: EText.error)),
            ),
          ),
    );
  }
}
