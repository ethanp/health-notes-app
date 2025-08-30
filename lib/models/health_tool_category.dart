import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_tool_category.freezed.dart';
part 'health_tool_category.g.dart';

@freezed
abstract class HealthToolCategory with _$HealthToolCategory {
  const factory HealthToolCategory({
    required String id,
    required String name,
    required String description,
    @JsonKey(name: 'icon_name') @Default('') String iconName,
    @JsonKey(name: 'color_hex') @Default('#007AFF') String colorHex,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _HealthToolCategory;

  factory HealthToolCategory.fromJson(Map<String, dynamic> json) =>
      _$HealthToolCategoryFromJson(json);
}

extension HealthToolCategoryExtensions on HealthToolCategory {
  Map<String, dynamic> toJsonForUpdate() {
    return {
      'name': name,
      'description': description,
      'icon_name': iconName,
      'color_hex': colorHex,
      'sort_order': sortOrder,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
