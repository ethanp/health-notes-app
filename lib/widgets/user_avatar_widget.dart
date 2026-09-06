import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

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
              return const CircularProgressIndicator();
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
        color: EColors.textMuted,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.account_circle,
        size: size,
        color: Colors.white,
      ),
    );
  }
}
