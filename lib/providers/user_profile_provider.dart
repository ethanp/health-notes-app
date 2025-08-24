import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_notes/models/user_profile.dart';
import 'package:health_notes/providers/auth_provider.dart';

part 'user_profile_provider.g.dart';

@riverpod
Future<UserProfile?> userProfile(Ref ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;

  try {
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return UserProfile.fromJson(response);
  } catch (e) {
    return null;
  }
}
