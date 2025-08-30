import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/providers/auth_provider.dart';
import 'package:health_notes/screens/auth_screen.dart';
import 'package:health_notes/screens/main_tab_screen.dart';
import 'package:health_notes/services/auth_service.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['URL']!,
    anonKey: dotenv.env['ANON_KEY']!,
  );
  AuthService.initializeGoogleSignIn(
    clientId: dotenv.env['GOOGLE_IOS_CLIENT_ID']!,
    serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID']!,
  );

  runApp(const ProviderScope(child: MainScreen()));
}

/// Top-level widget in the whole app.
/// Shows the appropriate UI based on whether the user is logged-in or not.
class MainScreen extends ConsumerWidget {
  const MainScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoApp(
      title: 'Health Notes',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: ref
          .watch(isAuthenticatedProvider)
          .when(
            data: (isAuthenticated) =>
                isAuthenticated ? const MainTabScreen() : const AuthScreen(),
            loading: () => CupertinoPageScaffold(
              child: EnhancedUIComponents.enhancedLoadingIndicator(
                message: 'Initializing app...',
              ),
            ),
            error: (error, stack) => CupertinoPageScaffold(
              child: Center(
                child: Text('Error: $error', style: AppTheme.error),
              ),
            ),
          ),
    );
  }
}
