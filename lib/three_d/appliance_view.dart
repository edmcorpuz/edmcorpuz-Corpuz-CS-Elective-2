import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'appliance_painter.dart';
import 'appliances.dart';

/// A live 3D appliance. It idles with a gentle sway; when [active] (or
/// hovered, with [activateOnHover]) it lifts, turns to face the viewer and
/// plays its own animation: doors open, drums spin, toast pops.
/// With [interactive] it can also be dragged to rotate.
class ApplianceView extends StatefulWidget {
  const ApplianceView({
    super.key,
    required this.kind,
    required this.color,
    this.detail = MeshDetail.low,
    this.speed = 0.4,
    this.zoom = 1,
    this.interactive = false,
    this.active = false,
    this.activateOnHover = false,
    this.tilt = Offset.zero,
    this.phase = 0,
    this.showShadow = true,
  });

  final ApplianceKind kind;
  final Color color;
  final MeshDetail detail;

  /// Idle sway speed.
  final double speed;
  final double zoom;
  final bool interactive;
  final bool active;
  final bool activateOnHover;

  /// Pointer lean from a parent tilt card, -1..1 on each axis.
  final Offset tilt;

  /// Sway offset so a grid of appliances doesn't move in lockstep.
  final double phase;
  final bool showShadow;

  @override
  State<ApplianceView> createState() => _ApplianceViewState();
}

class _ApplianceViewState extends State<ApplianceView> with SingleTickerProviderStateMixin {
  static const _restPitch = 0.42;

  /// Three-quarter front view the appliance turns to while active.
  static const _showcaseYaw = -0.45;
  static const _swayAmount = 0.42;

  late final Ticker _ticker;
  final _pose = AppliancePose();
  Duration _last = Duration.zero;

  double _yaw = 0;
  double _pitch = _restPitch;
  double _yawVelocity = 0;
  /// Linear progress toward the hovered pose; [_hover] is it eased.
  double _hoverProgress = 0;
  double _hover = 0;
  double _spin = 0;
  double _time = 0;
  bool _dragging = false;
  bool _pointerInside = false;
  bool _reduceMotion = false;

  bool get _isActive => widget.active || (widget.activateOnHover && _pointerInside);

  @override
  void initState() {
    super.initState();
    _yaw = _showcaseYaw + math.sin(widget.phase) * _swayAmount;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _time += dt;

    // Ease in and out over ~0.8 s so the hover reads as a smooth showroom
    // turn instead of a snap.
    final target = _isActive ? 1.0 : 0.0;
    final step = dt * (_reduceMotion ? 20.0 : 1.25);
    _hoverProgress = target > _hoverProgress
        ? math.min(target, _hoverProgress + step)
        : math.max(target, _hoverProgress - step);
    _hover = Curves.easeInOutCubic.transform(_hoverProgress);

    _spin += dt * (_reduceMotion ? 0 : (0.8 + 8 * _hover));

    if (!_dragging) {
      // Momentum from a drag, then settle back toward the front.
      _yaw += _yawVelocity * dt;
      _yawVelocity *= math.pow(0.08, dt).toDouble();

      // Appliances are front-facing, so idle is a gentle sway around a
      // three-quarter front view (not a full turntable); active holds still.
      final sway = (_isActive || _reduceMotion)
          ? 0.0
          : math.sin(_time * widget.speed * 1.6 + widget.phase) * _swayAmount;
      final turns = ((_yaw - _showcaseYaw) / (2 * math.pi)).roundToDouble();
      final goal = _showcaseYaw + turns * 2 * math.pi + sway;
      if (_yawVelocity.abs() < 0.6) {
        _yaw += (goal - _yaw) * math.min(1, dt * (_isActive ? 2.4 : 1.0));
      }
      _pitch += (_restPitch - _pitch) * math.min(1, dt * 1.2);
    }

    _pose.update(
      yaw: _yaw + widget.tilt.dx * 0.5,
      pitch: _pitch + widget.tilt.dy * 0.3,
      hover: _hover,
      spin: _spin,
      time: _time,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = RepaintBoundary(
      child: CustomPaint(
        painter: AppliancePainter(
          model: Appliances.of(widget.kind, widget.detail),
          color: widget.color,
          pose: _pose,
          zoom: widget.zoom,
          showShadow: widget.showShadow,
        ),
        size: Size.infinite,
      ),
    );
    if (widget.interactive) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          _dragging = true;
          _yawVelocity = 0;
        },
        onPanUpdate: (d) {
          _yaw += d.delta.dx * 0.012;
          _pitch = (_pitch + d.delta.dy * 0.01).clamp(-0.4, 1.3);
        },
        onPanEnd: (d) {
          _dragging = false;
          _yawVelocity = (d.velocity.pixelsPerSecond.dx * 0.004).clamp(-9.0, 9.0);
        },
        child: child,
      );
    }
    if (widget.activateOnHover || widget.interactive) {
      child = MouseRegion(
        cursor: widget.interactive ? SystemMouseCursors.grab : MouseCursor.defer,
        onEnter: (_) => _pointerInside = true,
        onExit: (_) => _pointerInside = false,
        child: child,
      );
    }
    return child;
  }
}
