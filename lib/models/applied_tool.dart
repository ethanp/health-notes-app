import 'package:freezed_annotation/freezed_annotation.dart';

part 'applied_tool.freezed.dart';
part 'applied_tool.g.dart';

@freezed
abstract class AppliedTool with _$AppliedTool {
  const factory AppliedTool({
    @JsonKey(name: 'tool_id') required String toolId,
    @JsonKey(name: 'tool_name') required String toolName,
    @Default('') String note,
  }) = _AppliedTool;

  factory AppliedTool.fromJson(Map<String, dynamic> json) =>
      _$AppliedToolFromJson(json);
}
