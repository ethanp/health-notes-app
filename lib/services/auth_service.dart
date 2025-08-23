import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId: dotenv.env['GOOGLE_IOS_CLIENT_ID'],
        serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      );
      googleSignIn.authenticationEvents.listen(loginStatusDidChange);
      await googleSignIn.attemptLightweightAuthentication();
      GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) throw Exception('No ID Token found.');
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      await upsertUserProfile(
        fullName: googleUser.displayName ?? 'User',
        avatarUrl: googleUser.photoUrl,
      );
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  void loginStatusDidChange(GoogleSignInAuthenticationEvent? authEvent) =>
      print('User signed ${authEvent == null ? 'out' : 'in'}');

  Future<void> completeSignInWithGoogle(
    GoogleSignInAuthenticationEventSignIn authEvent,
  ) async {
    try {
      final GoogleSignInAccount googleUser = authEvent.user;
      print('Logging in: ${googleUser.displayName} (${googleUser.email})');
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) throw Exception('No ID Token found.');
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      await upsertUserProfile(
        fullName: googleUser.displayName ?? 'User',
        avatarUrl: googleUser.photoUrl,
      );
    } catch (e) {
      throw Exception('Failed to complete Google sign in: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> upsertUserProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    try {
      if (currentUser == null) throw Exception('No authenticated user');

      await _supabase.from('profiles').upsert({
        'id': currentUser!.id,
        'email': currentUser!.email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // TODO call this somewhere.
  Future<void> deleteAccount() async {
    try {
      if (currentUser == null) throw Exception('No authenticated user');
      await _supabase.from('profiles').delete().eq('id', currentUser!.id);
      await _supabase.auth.admin.deleteUser(currentUser!.id);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // TODO call this.
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }
}
