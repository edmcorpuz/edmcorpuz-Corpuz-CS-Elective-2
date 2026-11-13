import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/shop_controller.dart';
import '../theme/app_theme.dart';
import 'filter_panel.dart';

/// Desktop filter sidebar that collapses to a slim rail. The full panel
/// stays mounted while collapsed, so search text and slider state survive.
class FilterSidebar extends ConsumerWidget {
  const FilterSidebar({super.key, required this.open, required this.onToggle});

  final bool open;
  final VoidCallback onToggle;

  static const openWidth = 310.0;
  static const railWidth = 64.0;
  static const _duration = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtering = ref.watch(shopControllerProvider.select((s) => s.filter.isActive));

    return AnimatedContainer(
      duration: _duration,
      curve: Curves.easeOutCubic,
      width: open ? openWidth : railWidth,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      child: ClipRect(
        child: Stack(
          children: [
            IgnorePointer(
              ignoring: !open,
              child: AnimatedOpacity(
                opacity: open ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: openWidth,
                  maxWidth: openWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 14, 10, 0),
                        child: Row(
                          children: [
                            Text('FILTERS', style: monoLabel(color: AppColors.text)),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Collapse filters',
                              onPressed: onToggle,
                              icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                          child: FilterPanel(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              ignoring: open,
              child: AnimatedOpacity(
                opacity: open ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: railWidth,
                  child: Column(
                    children: [
                      const SizedBox(height: 14),
                      IconButton(
                        tooltip: 'Show filters',
                        onPressed: onToggle,
                        icon: const Icon(Icons.keyboard_double_arrow_right_rounded),
                      ),
                      const SizedBox(height: 6),
                      IconButton(
                        tooltip: filtering ? 'Filters (active)' : 'Filters',
                        onPressed: onToggle,
                        icon: Badge(
                          isLabelVisible: filtering,
                          backgroundColor: AppColors.accent,
                          smallSize: 8,
                          child: const Icon(Icons.tune_rounded),
                        ),
                      ),
                      const SizedBox(height: 18),
                      RotatedBox(
                        quarterTurns: 3,
                        child: Text('FILTERS', style: monoLabel()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
