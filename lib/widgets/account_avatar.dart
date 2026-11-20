import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../theme/app_theme.dart';

/// Google profile photo when there is one, otherwise the first letter of
/// the name. Admins get an accent ring.
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, required this.user, this.admin = false, this.radius = 15});

  final AccountUser user;
  final bool admin;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = user.displayName.characters.first.toUpperCase();
    final photo = user.avatarUrl;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: admin ? AppColors.accent : AppColors.line, width: 1.5),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surfaceHigh,
        foregroundImage: photo == null ? null : NetworkImage(photo),
        onForegroundImageError: photo == null ? null : (_, _) {},
        child: Text(initial, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }
}
