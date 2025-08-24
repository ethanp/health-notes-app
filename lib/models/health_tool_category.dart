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
  bool get isValid => name.isNotEmpty && description.isNotEmpty;

  HealthToolCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    String? colorHex,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthToolCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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
