import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../three_d/appliance_view.dart';
import '../three_d/appliances.dart';

/// Shown when the app was started without Supabase keys.
class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Create a project at supabase.com and run supabase/schema.sql, then supabase/seed.sql, in its SQL editor.',
      'Copy env.example.json to env.json and paste your Project URL and publishable key into it.',
      'Run: flutter run --dart-define-from-file=env.json (or press F5 in VS Code: the launch config already passes it).',
    ];
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 180,
                  child: ApplianceView(kind: ApplianceKind.fridge, color: AppColors.accent, detail: MeshDetail.high, interactive: true, activateOnHover: true),
                ),
                const SizedBox(height: 12),
                Text('Connect Supabase', style: displayStyle(44)),
                const SizedBox(height: 12),
                Text(
                  'FACET reads its appliance catalogue from Supabase, and no project keys were found at build time.',
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 24),
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('0${i + 1}', style: monoLabel(color: AppColors.accent)),
                        const SizedBox(width: 14),
                        Expanded(child: SelectableText(steps[i], style: const TextStyle(height: 1.5))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
