import 'package:ethan_sync/ethan_sync.dart';
import 'package:health_notes/models/health_tool.dart';
import 'package:health_notes/models/health_tool_category.dart';
import 'package:health_notes/providers/dao_providers.dart';
import 'package:health_notes/utils/data_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'health_tools_provider.g.dart';

@riverpod
class HealthToolCategoriesNotifier() extends _$HealthToolCategoriesNotifier {
  @override
  Future<List<HealthToolCategory>> build() async {
    ref.watch(localDataRevisionProvider);
    final toolsDao = await ref.watch(healthToolsDaoProvider.future);
    return toolsDao.getCategories();
  }

  Future<void> addCategory(HealthToolCategory category) async {
    final toolsDao = await ref.read(healthToolsDaoProvider.future);
    final stored = category.id.isEmpty
        ? category.copyWith(id: DataUtils.uuid.v4())
        : category;
    await toolsDao.upsertCategory(stored);
    ref.invalidateSelf();
  }

  Future<void> updateCategory(HealthToolCategory category) async {
    final toolsDao = await ref.read(healthToolsDaoProvider.future);
    await toolsDao.upsertCategory(category);
    ref.invalidateSelf();
  }

  Future<void> deleteCategory(String id) async {
    final toolsDao = await ref.read(healthToolsDaoProvider.future);
    await toolsDao.deleteCategory(id);
    ref.invalidate(healthToolsProvider);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

@riverpod
class HealthToolsNotifier() extends _$HealthToolsNotifier {
  @override
  Future<List<HealthTool>> build() async {
    ref.watch(localDataRevisionProvider);
    final toolsDao = await ref.watch(healthToolsDaoProvider.future);
    return toolsDao.getTools();
  }

  Future<void> addTool(HealthTool tool) async {
    final toolsDao = await ref.read(healthToolsDaoProvider.future);
    final stored = tool.id.isEmpty ? tool.copyWith(id: DataUtils.uuid.v4()) : tool;
    await toolsDao.upsertTool(stored);
    ref.invalidateSelf();
  }

  Future<void> updateTool(HealthTool tool) async {
    final toolsDao = await ref.read(healthToolsDaoProvider.future);
    await toolsDao.upsertTool(tool);
    ref.invalidateSelf();
  }

  Future<void> deleteTool(String id) async {
    final toolsDao = await ref.read(healthToolsDaoProvider.future);
    await toolsDao.deleteTool(id);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

@riverpod
Future<List<HealthTool>> toolsByCategory(Ref ref, String categoryId) async {
  final tools = await ref.watch(healthToolsProvider.future);
  return tools.where((tool) => tool.categoryId == categoryId).toList();
}

@riverpod
Future<HealthTool?> toolById(Ref ref, String toolId) async {
  final tools = await ref.watch(healthToolsProvider.future);
  return tools.where((tool) => tool.id == toolId).firstOrNull;
}

@riverpod
Future<HealthToolCategory?> categoryById(Ref ref, String categoryId) async {
  final categories = await ref.watch(healthToolCategoriesProvider.future);
  return categories.where((category) => category.id == categoryId).firstOrNull;
}
