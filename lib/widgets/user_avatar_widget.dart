import 'package:flutter/cupertino.dart';

/// Widget that displays user avatar with fallbacks
class const UserAvatarWidget({
  final String? avatarUrl,
  final String? fullName,
  final double size = 60,
  final bool showLoadingIndicator = true,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(width: size, height: size, child: avatarContent()),
    );
  }

  Widget avatarContent() {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return defaultAvatar();
    }

    return Image.network(
      avatarUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: showLoadingIndicator
          ? (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const CupertinoActivityIndicator();
            }
          : null,
      errorBuilder: (context, error, stackTrace) {
        return defaultAvatar();
      },
    );
  }

  Widget defaultAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGrey,
        shape: BoxShape.circle,
      ),
      child: Icon(
        CupertinoIcons.person_circle_fill,
        size: size,
        color: CupertinoColors.white,
      ),
    );
  }
}
