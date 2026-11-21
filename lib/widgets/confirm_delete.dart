import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Confirmation dialog that names what is about to be deleted.
Future<bool> confirmDelete(BuildContext context, String name, String body) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete $name?'),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.isDark ? AppColors.bg : Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
