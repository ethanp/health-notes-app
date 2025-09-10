import 'package:flutter/cupertino.dart';

/// Widget that displays user avatar with fallbacks
class UserAvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String? fullName;
  final double size;
  final bool showLoadingIndicator;

  const UserAvatarWidget({
    super.key,
    this.avatarUrl,
    this.fullName,
    this.size = 60,
    this.showLoadingIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(width: size, height: size, child: _buildAvatar()),
    );
  }

  Widget _buildAvatar() {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return _getGoogleAvatar();
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
        return _getGoogleAvatar();
      },
    );
  }

  Widget _getGoogleAvatar() {
    return _getDefaultAvatar();
  }

  Widget _getDefaultAvatar() {
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
