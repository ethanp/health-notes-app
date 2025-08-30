import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_notes/models/check_in.dart';

part 'check_ins_provider.g.dart';

@riverpod
class CheckInsNotifier extends _$CheckInsNotifier {
  @override
  Future<List<CheckIn>> build() async {
    return _fetchCheckIns();
  }

  Future<List<CheckIn>> _fetchCheckIns() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('check_ins')
          .select()
          .order('date_time', ascending: false);

      return response.map((json) => CheckIn.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch check-ins: $e');
    }
  }

  Future<void> addCheckIn(CheckIn checkIn) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('check_ins')
          .insert(checkIn.toJsonForUpdate())
          .select()
          .single();

      final newCheckIn = CheckIn.fromJson(response);
      state = AsyncValue.data([newCheckIn, ...state.value ?? []]);
    } catch (e) {
      throw Exception('Failed to add check-in: $e');
    }
  }

  Future<void> updateCheckIn(CheckIn checkIn) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('check_ins')
          .update(checkIn.toJsonForUpdate())
          .eq('id', checkIn.id);

      final currentCheckIns = state.value ?? [];
      final updatedCheckIns = currentCheckIns.map((c) {
        return c.id == checkIn.id ? checkIn : c;
      }).toList();

      state = AsyncValue.data(updatedCheckIns);
    } catch (e) {
      throw Exception('Failed to update check-in: $e');
    }
  }

  Future<void> deleteCheckIn(String id) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('check_ins').delete().eq('id', id);

      final currentCheckIns = state.value ?? [];
      final updatedCheckIns = currentCheckIns.where((c) => c.id != id).toList();

      state = AsyncValue.data(updatedCheckIns);
    } catch (e) {
      throw Exception('Failed to delete check-in: $e');
    }
  }

  Future<void> deleteCheckInGroup(List<String> checkInIds) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('check_ins').delete().inFilter('id', checkInIds);

      final currentCheckIns = state.value ?? [];
      final updatedCheckIns = currentCheckIns
          .where((c) => !checkInIds.contains(c.id))
          .toList();

      state = AsyncValue.data(updatedCheckIns);
    } catch (e) {
      throw Exception('Failed to delete check-in group: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCheckIns());
  }
}
