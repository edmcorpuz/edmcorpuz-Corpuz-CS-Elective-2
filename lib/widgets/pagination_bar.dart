import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Prev / numbered pages / next. Shows at most [window] page numbers around
/// the current page.
class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onPage,
    this.enabled = true,
    this.window = 5,
  });

  final int page;
  final int pageCount;
  final ValueChanged<int> onPage;
  final bool enabled;
  final int window;

  @override
  Widget build(BuildContext context) {
    final start = math.max(0, math.min(page - window ~/ 2, pageCount - window));
    final end = math.min(pageCount, start + window);

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 8,
      children: [
        _arrow(Icons.arrow_back_rounded, 'Previous page', page > 0, () => onPage(page - 1)),
        for (var i = start; i < end; i++) _number(i),
        _arrow(Icons.arrow_forward_rounded, 'Next page', page < pageCount - 1, () => onPage(page + 1)),
      ],
    );
  }

  Widget _arrow(IconData icon, String tooltip, bool active, VoidCallback onTap) {
    return IconButton.outlined(
      tooltip: tooltip,
      onPressed: enabled && active ? onTap : null,
      style: IconButton.styleFrom(
        side: const BorderSide(color: AppColors.line),
        foregroundColor: AppColors.text,
        disabledForegroundColor: AppColors.line,
      ),
      icon: Icon(icon, size: 18),
    );
  }

  Widget _number(int i) {
    final selected = i == page;
    return SizedBox(
      width: 44,
      height: 44,
      child: TextButton(
        onPressed: enabled && !selected ? () => onPage(i) : null,
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          backgroundColor: selected ? AppColors.accent : Colors.transparent,
          foregroundColor: AppColors.text,
          disabledForegroundColor: selected ? Colors.black : AppColors.muted,
        ),
        child: Text(
          '${i + 1}',
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
