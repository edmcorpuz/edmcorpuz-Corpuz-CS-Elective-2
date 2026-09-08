import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.light);

  final GlobalKey contentKey = GlobalKey();
  Offset? revealOrigin;
  ui.Image? previousImage;
  int transitionId = 0;
  bool _capturing = false;

  Future<void> toggle({Offset? origin}) async {
    if (_capturing) return;
    _capturing = true;

    try {
      ui.Image? image;
      final renderObject = contentKey.currentContext?.findRenderObject();
      if (renderObject is RenderRepaintBoundary) {
        try {
          final devicePixelRatio =
              ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
          // The old frame is visible for less than a second, so cap the
          // capture resolution to reduce GPU readback and startup latency.
          image = await renderObject.toImage(
            pixelRatio: math.min(devicePixelRatio, 1.25),
          );
        } catch (_) {
          // The transition still works with the lightweight ripple fallback.
        }
      }

      previousImage = image;
      revealOrigin = origin;
      transitionId++;
      value = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    } finally {
      _capturing = false;
    }
  }
}

final themeController = ThemeController();
