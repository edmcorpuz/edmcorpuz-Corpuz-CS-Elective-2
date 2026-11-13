import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'appliances.dart';
import 'mesh.dart';

/// Everything that changes frame to frame. Mutated by [ApplianceView] and
/// used as the painter's repaint signal, so animation never rebuilds widgets.
class AppliancePose extends ChangeNotifier {
  double yaw = 0;
  double pitch = 0.42;
  double hover = 0;
  double spin = 0;
  double time = 0;

  void update({
    required double yaw,
    required double pitch,
    required double hover,
    required double spin,
    required double time,
  }) {
    this.yaw = yaw;
    this.pitch = pitch;
    this.hover = hover;
    this.spin = spin;
    this.time = time;
    notifyListeners();
  }
}

/// Software 3D renderer: animate parts, rotate, perspective-project,
/// back-face cull, depth-sort (painter's algorithm) and flat-shade each
/// face with key, fill, specular and rim light. Glass is drawn
/// see-through and two-sided; lamps and screens glow when active.
class AppliancePainter extends CustomPainter {
  AppliancePainter({
    required this.model,
    required this.color,
    required this.pose,
    this.zoom = 1,
    this.showShadow = true,
  }) : super(repaint: pose);

  final ApplianceModel model;
  final Color color;
  final AppliancePose pose;
  final double zoom;
  final bool showShadow;

  static const _cameraDistance = 4.2;

  /// Sort offset per [Part.layer]; larger than any depth spread on a model.
  static const _layerGap = 2.5;
  static final _keyLight = const Vec3(-0.55, 0.75, 0.62).normalized();
  static final _fillLight = const Vec3(0.85, -0.15, 0.45).normalized();
  static const _rimColor = Color(0xFF9CC9FF);

  static const _trim = Color(0xFF26262D);
  static const _glass = Color(0xFFD8ECF7);
  static const _metal = Color(0xFFBCC2CA);
  static const _bread = Color(0xFFD9A066);
  static const _lampOff = Color(0xFF3A352C);
  static const _lampOn = Color(0xFFFFE49A);
  static const _screenOff = Color(0xFF0E1116);
  static const _windowOff = Color(0xFF1B232C);
  static const _windowOn = Color(0xFFFFC56B);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = math.min(size.width, size.height) * 0.4 * zoom;
    final center = Offset(size.width / 2, size.height / 2 + scale * 0.04);
    final h = pose.hover;
    final lift = 0.09 * easeOut(h);

    Offset project(Vec3 p) {
      final k = _cameraDistance / (_cameraDistance - p.z);
      return Offset(center.dx + p.x * k * scale, center.dy - p.y * k * scale);
    }

    if (showShadow) _paintShadow(canvas, project, scale, h);

    final input = MotionInput(h, pose.spin, pose.time);
    const camera = Vec3(0, 0, _cameraDistance);
    final faces = <_ShadedFace>[];

    for (final part in model.parts) {
      if (part.showFrom > 0 && h <= part.showFrom) continue;
      final world = <Vec3>[];
      for (var v in part.mesh.vertices) {
        for (final motion in part.motions) {
          v = motion.apply(v, input);
        }
        final p = ((v - model.center) * model.scale).rotated(pose.yaw, pose.pitch, 0);
        world.add(Vec3(p.x, p.y + lift, p.z));
      }

      final seeThrough = part.finish == Finish.glass;
      for (final face in part.mesh.faces) {
        final pts = [for (final i in face) world[i]];
        var normal = Mesh.faceNormal(pts);
        if (normal.length == 0) continue;
        final mid = Mesh.centroid(pts);
        final view = (camera - mid).normalized();
        var facing = normal.dot(view);
        if (facing <= 0.0001) {
          if (!seeThrough) continue;
          normal = normal * -1;
          facing = -facing;
        }
        faces.add(_ShadedFace(
          points: [for (final p in pts) project(p)],
          depth: mid.z + part.layer * _layerGap,
          color: _shade(part, face, normal, view, facing),
          seeThrough: seeThrough,
        ));
      }
    }
    faces.sort((a, b) => a.depth.compareTo(b.depth));

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (final f in faces) {
      final path = Path()..addPolygon(f.points, true);
      fill.color = f.color;
      canvas.drawPath(path, fill);
      if (!f.seeThrough) {
        seam.color = f.color;
        canvas.drawPath(path, seam);
      }
    }
  }

  Color _shade(Part part, List<int> face, Vec3 n, Vec3 view, double facing) {
    final h = pose.hover;
    var specular = 0.5;
    var alpha = 1.0;
    Color base;
    Color? glow;
    var glowAmount = 0.0;

    switch (part.finish) {
      case Finish.body:
        base = color;
      case Finish.fill:
        base = Color.lerp(color, const Color(0xFFFFFFFF), 0.3)!;
      case Finish.trim:
        base = _trim;
        specular = 0.35;
      case Finish.metal:
        base = _metal;
        specular = 0.85;
      case Finish.glass:
        base = _glass;
        specular = 1;
        alpha = 0.3;
      case Finish.bread:
        base = _bread;
        specular = 0.15;
      case Finish.lamp:
        base = _lampOff;
        glow = _lampOn;
        glowAmount = 0.25 + 0.75 * h;
      case Finish.window:
        base = _windowOff;
        specular = 0.9;
        glow = _windowOn;
        glowAmount = 0.9 * h;
      case Finish.screen:
        base = _screenOff;
        specular = 0.8;
        final local = Mesh.centroid([for (final i in face) part.mesh.vertices[i]]);
        final hue = ((local.x + 1) * 0.28 + (local.y + 1) * 0.12 + pose.time * 0.07) % 1.0;
        glow = HSVColor.fromAHSV(1, hue * 360, 0.55, 1).toColor();
        glowAmount = 0.95 * h;
    }

    final key = math.max(0.0, n.dot(_keyLight));
    final fillLight = math.max(0.0, n.dot(_fillLight)) * 0.28;
    final half = (_keyLight + view).normalized();
    final spec = math.pow(math.max(0.0, n.dot(half)), 32).toDouble() * specular;
    final rim = math.pow(1 - facing, 2.6).toDouble() * 0.42;
    final lit = 0.2 + key * 0.86 + fillLight;

    double channel(double b, double r) => (b * lit + spec + rim * r).clamp(0.0, 1.0);

    var out = Color.from(
      alpha: alpha,
      red: channel(base.r, _rimColor.r),
      green: channel(base.g, _rimColor.g),
      blue: channel(base.b, _rimColor.b),
    );
    if (glow != null && glowAmount > 0) {
      out = Color.lerp(out, glow.withValues(alpha: alpha), glowAmount)!;
    }
    return out;
  }

  void _paintShadow(Canvas canvas, Offset Function(Vec3) project, double scale, double h) {
    final floor = Vec3(0, model.floorY - 0.02, 0).rotated(0, pose.pitch, 0);
    final c = project(floor);
    final width = model.footprint * 2.1 * scale * (1 - 0.15 * easeOut(h));
    final height = width * 0.22;
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        c,
        width / 2,
        [Color.fromRGBO(0, 0, 0, 0.6 - 0.2 * h), const Color(0x00000000)],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1, height / width);
    canvas.translate(-c.dx, -c.dy);
    canvas.drawCircle(c, width / 2, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(AppliancePainter old) =>
      old.model != model ||
      old.color != color ||
      old.pose != pose ||
      old.zoom != zoom ||
      old.showShadow != showShadow;
}

class _ShadedFace {
  _ShadedFace({
    required this.points,
    required this.depth,
    required this.color,
    required this.seeThrough,
  });

  final List<Offset> points;
  final double depth;
  final Color color;
  final bool seeThrough;
}
