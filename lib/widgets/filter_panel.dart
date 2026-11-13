import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../state/shop_controller.dart';
import '../state/shop_filter.dart';
import '../theme/app_theme.dart';

/// Search, category, price-range slider and sort. Every change is sent to
/// [ShopController], which re-queries Supabase from page 1.
class FilterPanel extends ConsumerStatefulWidget {
  const FilterPanel({super.key});

  @override
  ConsumerState<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends ConsumerState<FilterPanel> {
  static const _step = 50.0;

  late final TextEditingController _search;
  Timer? _debounce;
  RangeValues? _dragValues;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(shopControllerProvider).filter.search,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(shopControllerProvider.notifier).setSearch(value);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopControllerProvider);
    final controller = ref.read(shopControllerProvider.notifier);
    final filter = state.filter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _label('SEARCH'),
        TextField(
          controller: _search,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Find an object…',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _search.clear();
                      _onSearchChanged('');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 26),
        _label('CATEGORY'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _choice('All', filter.category == null, () => controller.setCategory(null)),
            for (final c in state.categories)
              _choice(c, filter.category == c, () => controller.setCategory(c)),
          ],
        ),
        const SizedBox(height: 26),
        ..._priceSection(state, controller),
        const SizedBox(height: 26),
        _label('SORT BY'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in ShopSort.values)
              _choice(s.label, filter.sort == s, () => controller.setSort(s)),
          ],
        ),
        const SizedBox(height: 22),
        AnimatedOpacity(
          opacity: filter.isActive ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: filter.isActive
                  ? () {
                      _debounce?.cancel();
                      _search.clear();
                      setState(() => _dragValues = null);
                      controller.resetFilters();
                    }
                  : null,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset filters'),
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _priceSection(ShopState state, ShopController controller) {
    final bounds = state.bounds;
    if (bounds == null) return [_label('PRICE'), const Text('—')];

    final min = (bounds.min / _step).floorToDouble() * _step;
    final max = math.max(min + _step, (bounds.max / _step).ceilToDouble() * _step);
    final filter = state.filter;
    final values = _dragValues ??
        RangeValues(
          (filter.minPrice ?? min).clamp(min, max),
          (filter.maxPrice ?? max).clamp(min, max),
        );

    return [
      Row(
        children: [
          _label('PRICE'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${formatPeso(values.start)} – ${formatPeso(values.end)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
      RangeSlider(
        values: values,
        min: min,
        max: max,
        divisions: ((max - min) / _step).round(),
        labels: RangeLabels(formatPeso(values.start), formatPeso(values.end)),
        onChanged: (v) => setState(() => _dragValues = v),
        onChangeEnd: (v) {
          setState(() => _dragValues = null);
          controller.setPriceRange(v.start, v.end);
        },
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatPeso(min), style: monoLabel(size: 10)),
            Text(formatPeso(max), style: monoLabel(size: 10)),
          ],
        ),
      ),
    ];
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: monoLabel()),
      );

  Widget _choice(String label, bool selected, VoidCallback onTap) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      );
}
