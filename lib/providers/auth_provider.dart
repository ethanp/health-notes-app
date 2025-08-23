import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_notes/services/auth_service.dart';

part 'auth_provider.g.dart';

@riverpod
Stream<AuthState> authStateChanges(Ref ref) {
  final authService = AuthService();
  return authService.authStateChanges;
}

@riverpod
Stream<User?> currentUser(Ref ref) {
  final authService = AuthService();
  return authService.authStateChanges.map(
    (authState) => authState.session?.user,
  );
}

@riverpod
Stream<bool> isAuthenticated(Ref ref) {
  final authService = AuthService();
  return authService.authStateChanges.map(
    (authState) => authState.session?.user != null,
  );
}
