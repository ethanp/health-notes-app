import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_tool.freezed.dart';
part 'health_tool.g.dart';

@freezed
abstract class HealthTool with _$HealthTool {
  const factory HealthTool({
    required String id,
    required String name,
    required String description,
    @JsonKey(name: 'category_id') required String categoryId,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _HealthTool;

  factory HealthTool.fromJson(Map<String, dynamic> json) =>
      _$HealthToolFromJson(json);
}

extension HealthToolExtensions on HealthTool {
  bool get isValid => name.isNotEmpty && description.isNotEmpty && categoryId.isNotEmpty;

  HealthTool copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthTool(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
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
      'category_id': categoryId,
      'sort_order': sortOrder,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
