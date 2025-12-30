import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_notes/models/health_tool.dart';
import 'package:health_notes/models/health_tool_category.dart';

part 'health_tools_provider.g.dart';

@riverpod
class HealthToolCategoriesNotifier extends _$HealthToolCategoriesNotifier {
  @override
  Future<List<HealthToolCategory>> build() async {
    return _fetchCategories();
  }

  Future<List<HealthToolCategory>> _fetchCategories() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('health_tool_categories')
        .select()
        .order('sort_order', ascending: true);

    return response.map((json) => HealthToolCategory.fromJson(json)).toList();
  }

  Future<void> addCategory(HealthToolCategory category) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('health_tool_categories')
        .insert(category.toJsonForUpdate())
        .select()
        .single();

    final newCategory = HealthToolCategory.fromJson(response);
    state = AsyncValue.data([...state.value ?? [], newCategory]);
  }

  Future<void> updateCategory(HealthToolCategory category) async {
    final supabase = Supabase.instance.client;
    await supabase
        .from('health_tool_categories')
        .update(category.toJsonForUpdate())
        .eq('id', category.id);

    final currentCategories = state.value ?? [];
    final updatedCategories = currentCategories.map((c) {
      return c.id == category.id ? category : c;
    }).toList();

    state = AsyncValue.data(updatedCategories);
  }

  Future<void> deleteCategory(String id) async {
    final supabase = Supabase.instance.client;
    await supabase.from('health_tool_categories').delete().eq('id', id);

    final currentCategories = state.value ?? [];
    final updatedCategories = currentCategories
        .where((c) => c.id != id)
        .toList();

    state = AsyncValue.data(updatedCategories);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCategories());
  }
}

@riverpod
class HealthToolsNotifier extends _$HealthToolsNotifier {
  @override
  Future<List<HealthTool>> build() async {
    return _fetchTools();
  }

  Future<List<HealthTool>> _fetchTools() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('health_tools')
        .select()
        .order('sort_order', ascending: true);

    return response.map((json) => HealthTool.fromJson(json)).toList();
  }

  Future<void> addTool(HealthTool tool) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('health_tools')
        .insert(tool.toJsonForUpdate())
        .select()
        .single();

    final newTool = HealthTool.fromJson(response);
    state = AsyncValue.data([...state.value ?? [], newTool]);
  }

  Future<void> updateTool(HealthTool tool) async {
    final supabase = Supabase.instance.client;
    await supabase
        .from('health_tools')
        .update(tool.toJsonForUpdate())
        .eq('id', tool.id);

    final currentTools = state.value ?? [];
    final updatedTools = currentTools.map((t) {
      return t.id == tool.id ? tool : t;
    }).toList();

    state = AsyncValue.data(updatedTools);
  }

  Future<void> deleteTool(String id) async {
    final supabase = Supabase.instance.client;
    await supabase.from('health_tools').delete().eq('id', id);

    final currentTools = state.value ?? [];
    final updatedTools = currentTools.where((t) => t.id != id).toList();

    state = AsyncValue.data(updatedTools);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTools());
  }
}

@riverpod
Future<List<HealthTool>> toolsByCategory(Ref ref, String categoryId) async {
  final toolsAsync = ref.watch(healthToolsNotifierProvider);

  return toolsAsync.when(
    data: (tools) =>
        tools.where((tool) => tool.categoryId == categoryId).toList(),
    loading: () => [],
    error: (error, stack) => [],
  );
}

@riverpod
Future<HealthTool?> toolById(Ref ref, String toolId) async {
  final tools = await ref.watch(healthToolsNotifierProvider.future);
  return tools.where((t) => t.id == toolId).firstOrNull;
}

@riverpod
Future<HealthToolCategory?> categoryById(Ref ref, String categoryId) async {
  final categories = await ref.watch(
    healthToolCategoriesNotifierProvider.future,
  );
  return categories.where((c) => c.id == categoryId).firstOrNull;
}
