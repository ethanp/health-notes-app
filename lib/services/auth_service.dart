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
      // iOS Client ID that you registered with Google Cloud
      const iosClientId =
          '514002384587-cerg0oevd7cv698ockkmoesvqkcq42q4.apps.googleusercontent.com';

      // Web Client ID that you registered with Google Cloud (for Supabase)
      const webClientId =
          '514002384587-tg39uqob0ue1g191duhjbg7e6urdb5vh.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      // Initialize following the official documentation
      await googleSignIn.initialize(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      // Set up authentication event listener
      googleSignIn.authenticationEvents.listen(_handleAuthenticationEvent);

      // Attempt lightweight authentication first
      await googleSignIn.attemptLightweightAuthentication();

      // Authenticate user
      GoogleSignInAccount? googleUser;
      if (googleSignIn.supportsAuthenticate()) {
        googleUser = await googleSignIn.authenticate();
      } else {
        throw Exception('Google Sign-In is not supported on this platform');
      }

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('No ID Token found.');
      }

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

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent? authEvent) {
    if (authEvent != null) {
      print('User signed in (abc): $authEvent');
    } else {
      print('authEvent was null User signed out?');
    }
  }

  Future<void> completeSignInWithGoogle(
    GoogleSignInAuthenticationEventSignIn authEvent,
  ) async {
    try {
      print('Starting completeSignInWithGoogle...');

      // Get the user from the authentication event
      final GoogleSignInAccount googleUser = authEvent.user;
      print('Google user: ${googleUser.displayName} (${googleUser.email})');

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      print('ID Token length: ${idToken?.length ?? 0}');

      if (idToken == null) {
        throw Exception('No ID Token found.');
      }

      print('Attempting Supabase signInWithIdToken...');
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      print('Supabase signInWithIdToken successful!');

      print('Creating/updating user profile...');
      await upsertUserProfile(
        fullName: googleUser.displayName ?? 'User',
        avatarUrl: googleUser.photoUrl,
      );
      print('User profile updated successfully!');
    } catch (e) {
      print('Error in completeSignInWithGoogle: $e');
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
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

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

  Future<void> deleteAccount() async {
    try {
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      await _supabase.from('profiles').delete().eq('id', currentUser!.id);
      await _supabase.auth.admin.deleteUser(currentUser!.id);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  Future<AuthResponse> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      return response;
    } catch (e) {
      throw Exception('Failed to refresh session: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }
}
