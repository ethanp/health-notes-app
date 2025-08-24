import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Session? get currentSession => _supabase.auth.currentSession;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  bool get isAuthenticated => currentUser != null;

  Future<void> signInViaGoogle() async {
    final GoogleSignInAccount user = await GoogleSignIn.instance.authenticate();
    await signIntoSupabase(user);
  }

  Future<void> signIntoSupabase(GoogleSignInAccount googleUser) async {
    print('Logging in: ${googleUser.displayName} (${googleUser.email})');
    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleUser.authentication.idToken!,
    );
    await upsertUserProfile(
      fullName: googleUser.displayName ?? 'User',
      avatarUrl: googleUser.photoUrl,
    );
  }

  void loginStatusDidChange(GoogleSignInAuthenticationEvent? authEvent) =>
      print('User signed ${authEvent == null ? 'out' : 'in'}');

  static void onGoogleAuthEvent(
    GoogleSignInAuthenticationEvent? authEvent,
  ) async {
    if (authEvent == null) {
      print('Global: User signed out');
      return;
    }
    print('Global: User signed in (def): $authEvent');
    if (authEvent is! GoogleSignInAuthenticationEventSignIn) {
      print('unexpected authEvent ${authEvent.runtimeType}');
      return;
    }

    try {
      await AuthService().signIntoSupabase(authEvent.user);
    } catch (e) {
      print('Error completing Supabase authentication: $e');
    }
  }

  static void initializeGoogleSignIn({
    required String clientId,
    required String serverClientId,
  }) {
    unawaited(
      GoogleSignIn.instance
          .initialize(clientId: clientId, serverClientId: serverClientId)
          .then((_) {
            GoogleSignIn.instance.authenticationEvents
                .listen(onGoogleAuthEvent)
                .onError((dynamic error) {
                  print('Global authentication error: $error');
                });

            GoogleSignIn.instance.attemptLightweightAuthentication();
          }),
    );
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _supabase.auth.signOut();
  }

  Future<void> upsertUserProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    if (currentUser == null) throw Exception('No authenticated user');

    await _supabase.from('profiles').upsert({
      'id': currentUser!.id,
      'email': currentUser!.email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
