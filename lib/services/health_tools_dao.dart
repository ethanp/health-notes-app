import 'package:ethan_sync/ethan_sync.dart';
import 'package:health_notes/models/health_tool.dart';
import 'package:health_notes/models/health_tool_category.dart';
import 'package:powersync/powersync.dart';

class HealthToolsDao(final PowerSyncDatabase _powerSync) {
  Future<List<HealthToolCategory>> getCategories() async {
    final categoryRows = await _powerSync.getAll(
      'SELECT * FROM health_tool_categories ORDER BY sort_order ASC',
    );
    return [
      for (final categoryRow in categoryRows) _mapToCategory(categoryRow),
    ];
  }

  Future<List<HealthTool>> getTools() async {
    final toolRows = await _powerSync.getAll(
      'SELECT * FROM health_tools ORDER BY sort_order ASC',
    );
    return [for (final toolRow in toolRows) _mapToTool(toolRow)];
  }

  Future<void> upsertCategory(HealthToolCategory category) async {
    await _powerSync.upsert('health_tool_categories', {
      'id': category.id,
      'name': category.name,
      'description': category.description,
      'icon_name': category.iconName,
      'color_hex': category.colorHex,
      'sort_order': category.sortOrder,
      'is_active': category.isActive ? 1 : 0,
      'created_at': category.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteCategory(String id) async {
    await _powerSync.execute(
      'DELETE FROM health_tools WHERE category_id = ?',
      [id],
    );
    await _powerSync.execute(
      'DELETE FROM health_tool_categories WHERE id = ?',
      [id],
    );
  }

  Future<void> upsertTool(HealthTool tool) async {
    await _powerSync.upsert('health_tools', {
      'id': tool.id,
      'name': tool.name,
      'description': tool.description,
      'category_id': tool.categoryId,
      'sort_order': tool.sortOrder,
      'is_active': tool.isActive ? 1 : 0,
      'created_at': tool.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteTool(String id) async {
    await _powerSync.execute('DELETE FROM health_tools WHERE id = ?', [id]);
  }

  static HealthToolCategory _mapToCategory(Map<String, dynamic> categoryRow) {
    return HealthToolCategory(
      id: categoryRow['id'] as String,
      name: categoryRow['name'] as String,
      description: categoryRow['description'] as String,
      iconName: categoryRow['icon_name'] as String? ?? '',
      colorHex: categoryRow['color_hex'] as String? ?? '#007AFF',
      sortOrder: categoryRow['sort_order'] as int? ?? 0,
      isActive: (categoryRow['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(categoryRow['created_at'] as String),
      updatedAt: DateTime.parse(categoryRow['updated_at'] as String),
    );
  }

  static HealthTool _mapToTool(Map<String, dynamic> toolRow) {
    return HealthTool(
      id: toolRow['id'] as String,
      name: toolRow['name'] as String,
      description: toolRow['description'] as String,
      categoryId: toolRow['category_id'] as String,
      sortOrder: toolRow['sort_order'] as int? ?? 0,
      isActive: (toolRow['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(toolRow['created_at'] as String),
      updatedAt: DateTime.parse(toolRow['updated_at'] as String),
    );
  }
}
