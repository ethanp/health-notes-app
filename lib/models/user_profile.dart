import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String email,
    @JsonKey(name: 'full_name') required String fullName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _UserProfile;

  const UserProfile._();

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
