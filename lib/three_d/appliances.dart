import 'dart:math' as math;

import 'mesh.dart';

/// What a part is made of; the painter turns this into a color.
enum Finish {
  /// The product's own color (stored in the `color` column).
  body,
  trim,
  glass,
  metal,

  /// Indicator lights and displays: dim when idle, bright when active.
  lamp,

  /// TV panel: black when idle, animated picture when active.
  screen,

  /// Microwave window: dark when idle, warm glow when active.
  window,
  bread,

  /// A lighter tint of the product color (blender contents, fan blades).
  fill,
}

/// Animation inputs: [hover] eases 0→1 while the product is hovered or
/// switched on, [spin] is an accumulated angle for rotating parts and
/// [time] is seconds since the view appeared.
class MotionInput {
  const MotionInput(this.hover, this.spin, this.time);

  final double hover;
  final double spin;
  final double time;
}

double easeOut(double t) => 1 - math.pow(1 - t.clamp(0.0, 1.0), 3).toDouble();

abstract class Motion {
  const Motion();

  Vec3 apply(Vec3 p, MotionInput m);
}

/// Swings around a hinge line (doors, lids, flaps).
class Hinge extends Motion {
  const Hinge(this.pivot, this.axis, this.angle);

  final Vec3 pivot;
  final Axis3 axis;
  final double angle;

  @override
  Vec3 apply(Vec3 p, MotionInput m) =>
      rotateAbout(p - pivot, axis, angle * easeOut(m.hover)) + pivot;
}

/// Slides out by [offset] (air fryer drawer).
class Slide extends Motion {
  const Slide(this.offset);

  final Vec3 offset;

  @override
  Vec3 apply(Vec3 p, MotionInput m) => p + offset * easeOut(m.hover);
}

/// Rotates continuously with the accumulated spin angle (fan blades, drums).
class Spin extends Motion {
  const Spin(this.pivot, this.axis, [this.rate = 1]);

  final Vec3 pivot;
  final Axis3 axis;
  final double rate;

  @override
  Vec3 apply(Vec3 p, MotionInput m) => rotateAbout(p - pivot, axis, m.spin * rate) + pivot;
}

/// Grows upward out of a slot at [baseY] (toast popping up).
class Grow extends Motion {
  const Grow(this.baseY);

  final double baseY;

  @override
  Vec3 apply(Vec3 p, MotionInput m) =>
      Vec3(p.x, baseY + (p.y - baseY) * math.max(0.001, easeOut(m.hover)), p.z);
}

/// Running vibration (washer, blender).
class Shake extends Motion {
  const Shake(this.amount);

  final double amount;

  @override
  Vec3 apply(Vec3 p, MotionInput m) => p +
      Vec3(
        math.sin(m.time * 57) * amount * m.hover,
        math.cos(m.time * 43) * amount * 0.5 * m.hover,
        0,
      );
}

/// Loops along [offset] while active (steam, air flow).
class Flow extends Motion {
  const Flow(this.offset, [this.phase = 0]);

  final Vec3 offset;
  final double phase;

  @override
  Vec3 apply(Vec3 p, MotionInput m) =>
      p + offset * (((m.time * 0.8 + phase) % 1.0) * m.hover);
}

class Part {
  const Part(
    this.mesh,
    this.finish, {
    this.motions = const [],
    this.showFrom = 0,
    this.layer = 0,
  });

  final Mesh mesh;
  final Finish finish;
  final List<Motion> motions;

  /// Hidden until `hover` exceeds this (insides that only show when open).
  final double showFrom;

  /// Surface details (screens, windows, displays, buttons) sit almost flush
  /// on a big body face. Depth-sorting by face centre can then put the body
  /// face on top, so higher layers are always drawn after lower ones.
  final int layer;
}

/// A built appliance plus the numbers needed to frame it on screen.
class ApplianceModel {
  ApplianceModel(this.parts) {
    var minX = double.infinity, minY = double.infinity, minZ = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity, maxZ = -double.infinity;
    for (final part in parts) {
      if (part.showFrom > 0) continue;
      for (final v in part.mesh.vertices) {
        minX = math.min(minX, v.x);
        minY = math.min(minY, v.y);
        minZ = math.min(minZ, v.z);
        maxX = math.max(maxX, v.x);
        maxY = math.max(maxY, v.y);
        maxZ = math.max(maxZ, v.z);
      }
    }
    center = Vec3((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2);
    var radius = 0.0, foot = 0.0;
    for (final part in parts) {
      if (part.showFrom > 0) continue;
      for (final v in part.mesh.vertices) {
        final d = v - center;
        radius = math.max(radius, d.length);
        foot = math.max(foot, math.sqrt(d.x * d.x + d.z * d.z));
      }
    }
    scale = 1 / radius;
    floorY = (minY - center.y) * scale;
    footprint = foot * scale;
  }

  final List<Part> parts;
  late final Vec3 center;
  late final double scale;

  /// Bottom of the model and its widest horizontal reach, after scaling.
  late final double floorY;
  late final double footprint;

  int get faceCount => parts.fold(0, (n, p) => n + p.mesh.faces.length);
}

/// How finely curved parts are tessellated. Grid cards use [low] so a page
/// of animated appliances stays smooth; hero and detail views use [high].
enum MeshDetail { low, high }

/// The appliance types the store sells. [dbName] is stored in the `model`
/// column; [action] labels the demo button on the product page.
enum ApplianceKind {
  fridge('fridge', 'Refrigerator', 'Refrigeration', 'Open door'),
  washer('washer', 'Washing machine', 'Laundry', 'Start wash'),
  microwave('microwave', 'Microwave', 'Kitchen', 'Start'),
  tv('tv', 'Smart TV', 'Entertainment', 'Turn on'),
  fan('fan', 'Stand fan', 'Cooling', 'Full speed'),
  aircon('aircon', 'Air conditioner', 'Cooling', 'Turn on'),
  riceCooker('rice_cooker', 'Rice cooker', 'Kitchen', 'Open lid'),
  blender('blender', 'Blender', 'Kitchen', 'Blend'),
  airFryer('air_fryer', 'Air fryer', 'Kitchen', 'Pull basket'),
  toaster('toaster', 'Toaster', 'Kitchen', 'Pop toast'),
  kettle('kettle', 'Electric kettle', 'Kitchen', 'Boil'),
  robotVacuum('robot_vacuum', 'Robot vacuum', 'Cleaning', 'Start cleaning');

  const ApplianceKind(this.dbName, this.label, this.category, this.action);

  final String dbName;
  final String label;
  final String category;
  final String action;

  static ApplianceKind fromDb(String? value) =>
      values.firstWhere((k) => k.dbName == value, orElse: () => ApplianceKind.fridge);
}

class Appliances {
  Appliances._();

  static final Map<(ApplianceKind, MeshDetail), ApplianceModel> _cache = {};

  static ApplianceModel of(ApplianceKind kind, [MeshDetail detail = MeshDetail.low]) =>
      _cache.putIfAbsent((kind, detail), () => ApplianceModel(build(kind, detail)));

  static List<Part> build(ApplianceKind kind, MeshDetail detail) {
    final s = detail == MeshDetail.high ? 28 : 14;
    Mesh m(void Function(MeshBuilder b) f) {
      final b = MeshBuilder(segments: s);
      f(b);
      return b.build();
    }

    return switch (kind) {
      ApplianceKind.fridge => _fridge(m),
      ApplianceKind.washer => _washer(m),
      ApplianceKind.microwave => _microwave(m),
      ApplianceKind.tv => _tv(m, detail),
      ApplianceKind.fan => _fan(m),
      ApplianceKind.aircon => _aircon(m),
      ApplianceKind.riceCooker => _riceCooker(m),
      ApplianceKind.blender => _blender(m),
      ApplianceKind.airFryer => _airFryer(m),
      ApplianceKind.toaster => _toaster(m),
      ApplianceKind.kettle => _kettle(m),
      ApplianceKind.robotVacuum => _robotVacuum(m),
    };
  }
}

typedef _M = Mesh Function(void Function(MeshBuilder b) f);

/// Rotates the vertices added since [start] around the Z axis through
/// [pivot]; used to fan out copies of a blade.
void _turnZ(MeshBuilder b, int start, Vec3 pivot, double angle) =>
    b.transformFrom(start, (v) => rotateAbout(v - pivot, Axis3.z, angle) + pivot);

void _turnY(MeshBuilder b, int start, Vec3 pivot, double angle) =>
    b.transformFrom(start, (v) => rotateAbout(v - pivot, Axis3.y, angle) + pivot);

List<Part> _fridge(_M m) {
  // Main door swings open toward the viewer around its left edge.
  const door = Hinge(Vec3(-0.42, 0, 0.395), Axis3.y, -1.8);
  return [
    Part(m((b) => b.box(const Vec3(0, 0, -0.02), const Vec3(0.42, 0.95, 0.34))), Finish.body),
    // Interior light and shelves (layers 1–2) sit just in front of the
    // body; the swinging door (3) and its handle (4) always draw over them.
    Part(m((b) => b.box(const Vec3(0, -0.33, 0.322), const Vec3(0.38, 0.56, 0.002))), Finish.lamp, showFrom: 0.02, layer: 1),
    Part(
      m((b) {
        for (final y in [-0.6, -0.33, -0.06]) {
          b.box(Vec3(0, y, 0.335), const Vec3(0.37, 0.01, 0.012));
        }
      }),
      Finish.metal,
      showFrom: 0.02,
      layer: 2,
    ),
    Part(m((b) => b.box(const Vec3(0, 0.63, 0.36), const Vec3(0.42, 0.3, 0.035))), Finish.body, layer: 1),
    Part(m((b) => b.box(const Vec3(0.34, 0.46, 0.415), const Vec3(0.02, 0.1, 0.02))), Finish.metal, layer: 2),
    Part(m((b) => b.box(const Vec3(0, -0.33, 0.36), const Vec3(0.42, 0.6, 0.035))), Finish.body, motions: const [door], layer: 3),
    Part(m((b) => b.box(const Vec3(0.34, -0.05, 0.415), const Vec3(0.02, 0.18, 0.02))), Finish.metal, motions: const [door], layer: 4),
  ];
}

List<Part> _washer(_M m) {
  const shake = Shake(0.014);
  const drum = Spin(Vec3(0, -0.06, 0.56), Axis3.z, 0.7);
  return [
    Part(m((b) => b.box(Vec3.zero, const Vec3(0.6, 0.62, 0.55))), Finish.body, motions: const [shake]),
    Part(m((b) => b.box(const Vec3(0, 0.5, 0.558), const Vec3(0.58, 0.1, 0.008))), Finish.trim, motions: const [shake], layer: 1),
    Part(m((b) => b.box(const Vec3(0.28, 0.5, 0.568), const Vec3(0.13, 0.04, 0.003))), Finish.lamp, motions: const [shake], layer: 2),
    Part(m((b) => b.frustum(const Vec3(-0.36, 0.5, 0.575), r0: 0.05, r1: 0.05, h: 0.03, axis: Axis3.z)), Finish.metal, motions: const [shake], layer: 2),
    Part(m((b) => b.frustum(const Vec3(0, -0.06, 0.553), r0: 0.27, r1: 0.27, h: 0.006, axis: Axis3.z)), Finish.trim, motions: const [shake], layer: 1),
    Part(
      m((b) {
        for (var k = 0; k < 3; k++) {
          final start = b.mark;
          b.box(const Vec3(0, 0.12, 0.562), const Vec3(0.035, 0.09, 0.006));
          _turnZ(b, start, const Vec3(0, -0.06, 0), k * 2 * math.pi / 3);
        }
      }),
      Finish.metal,
      motions: const [drum, shake],
      layer: 2,
    ),
    Part(m((b) => b.frustum(const Vec3(0, -0.06, 0.585), r0: 0.27, r1: 0.27, h: 0.02, axis: Axis3.z)), Finish.glass, motions: const [shake], layer: 3),
    Part(m((b) => b.torus(const Vec3(0, -0.06, 0.59), 0.3, 0.045, axis: Axis3.z)), Finish.metal, motions: const [shake], layer: 3),
  ];
}

List<Part> _microwave(_M m) => [
      Part(m((b) => b.box(Vec3.zero, const Vec3(0.75, 0.42, 0.5))), Finish.body),
      Part(m((b) => b.box(const Vec3(-0.16, 0, 0.505), const Vec3(0.5, 0.32, 0.006))), Finish.window, layer: 1),
      Part(m((b) => b.box(const Vec3(0.6, 0, 0.505), const Vec3(0.12, 0.36, 0.006))), Finish.trim, layer: 1),
      Part(m((b) => b.box(const Vec3(0.6, 0.22, 0.513), const Vec3(0.085, 0.045, 0.003))), Finish.lamp, layer: 2),
      Part(
        m((b) {
          for (final y in [0.08, -0.02, -0.12]) {
            b.box(Vec3(0.6, y, 0.514), const Vec3(0.07, 0.028, 0.005));
          }
        }),
        Finish.metal,
        layer: 2,
      ),
      Part(m((b) => b.frustum(const Vec3(0.6, -0.26, 0.525), r0: 0.05, r1: 0.05, h: 0.03, axis: Axis3.z)), Finish.metal, layer: 2),
    ];

List<Part> _tv(_M m, MeshDetail detail) {
  final cells = detail == MeshDetail.high ? 12 : 7;
  return [
    Part(m((b) => b.box(const Vec3(0, 0.2, 0), const Vec3(0.98, 0.56, 0.035))), Finish.body),
    Part(m((b) => b.grid(const Vec3(0, 0.2, 0.0365), 0.93, 0.51, cells, (cells * 0.6).round())), Finish.screen, layer: 1),
    Part(m((b) => b.box(const Vec3(0, -0.45, -0.03), const Vec3(0.05, 0.11, 0.022))), Finish.body),
    Part(m((b) => b.box(const Vec3(0, -0.575, -0.03), const Vec3(0.34, 0.02, 0.16))), Finish.body),
  ];
}

List<Part> _fan(_M m) {
  const hub = Vec3(0, 0.2, 0.03);
  return [
    Part(m((b) => b.frustum(const Vec3(0, -0.9, 0), r0: 0.4, r1: 0.36, h: 0.06)), Finish.body),
    Part(m((b) => b.frustum(const Vec3(0, -0.36, -0.1), r0: 0.032, r1: 0.032, h: 1.02, seg: 8)), Finish.metal),
    Part(m((b) => b.ellipsoid(const Vec3(0, 0.2, -0.14), const Vec3(0.13, 0.13, 0.15))), Finish.body),
    Part(m((b) => b.frustum(const Vec3(0, 0.2, 0.05), r0: 0.075, r1: 0.06, h: 0.05, axis: Axis3.z)), Finish.body),
    Part(
      m((b) {
        for (var k = 0; k < 3; k++) {
          final start = b.mark;
          b.ellipsoid(const Vec3(0, 0.41, 0.03), const Vec3(0.1, 0.19, 0.012), rings: 5, seg: 10);
          _turnZ(b, start, hub, k * 2 * math.pi / 3);
        }
      }),
      Finish.fill,
      motions: const [Spin(hub, Axis3.z, 1.4)],
    ),
    Part(m((b) => b.torus(const Vec3(0, 0.2, 0.04), 0.46, 0.018, axis: Axis3.z, sides: 5)), Finish.metal),
  ];
}

List<Part> _aircon(_M m) {
  const flap = Hinge(Vec3(0, -0.125, 0.255), Axis3.x, -1.0);
  return [
    Part(m((b) => b.box(const Vec3(0, 0.05, 0), const Vec3(0.98, 0.3, 0.25))), Finish.body),
    Part(m((b) => b.box(const Vec3(0, -0.18, 0.252), const Vec3(0.88, 0.05, 0.003))), Finish.trim, showFrom: 0.02, layer: 1),
    Part(m((b) => b.box(const Vec3(0, -0.18, 0.262), const Vec3(0.9, 0.055, 0.01))), Finish.metal, motions: const [flap], layer: 2),
    Part(m((b) => b.box(const Vec3(0.8, 0.02, 0.252), const Vec3(0.025, 0.012, 0.003))), Finish.lamp, layer: 1),
    Part(m((b) => b.box(const Vec3(0, 0.1, 0.252), const Vec3(0.09, 0.04, 0.003))), Finish.lamp, layer: 1),
    for (var i = 0; i < 3; i++)
      Part(
        m((b) => b.box(Vec3(-0.5 + i * 0.5, -0.26, 0.32), const Vec3(0.22, 0.008, 0.008))),
        Finish.glass,
        motions: [Flow(const Vec3(0, -0.45, 0.4), i / 3)],
        showFrom: 0.3,
      ),
  ];
}

List<Part> _riceCooker(_M m) {
  const lid = Hinge(Vec3(0, -0.02, -0.5), Axis3.x, -1.15);
  return [
    Part(m((b) => b.frustum(const Vec3(0, -0.33, 0), r0: 0.46, r1: 0.5, h: 0.6, capTop: false)), Finish.body),
    Part(m((b) => b.torus(const Vec3(0, -0.03, 0), 0.46, 0.04)), Finish.body),
    Part(m((b) => b.frustum(const Vec3(0, -0.07, 0), r0: 0.4, r1: 0.42, h: 0.07)), Finish.metal, showFrom: 0.02),
    Part(m((b) => b.box(const Vec3(0, -0.36, 0.49), const Vec3(0.15, 0.11, 0.02))), Finish.trim, layer: 1),
    Part(m((b) => b.box(const Vec3(0, -0.33, 0.512), const Vec3(0.035, 0.02, 0.004))), Finish.lamp, layer: 2),
    Part(m((b) => b.ellipsoid(const Vec3(0, -0.02, 0), const Vec3(0.5, 0.27, 0.5), hemisphere: true)), Finish.body, motions: const [lid]),
    Part(m((b) => b.box(const Vec3(0, 0.265, 0), const Vec3(0.22, 0.022, 0.05))), Finish.trim, motions: const [lid]),
    Part(m((b) => b.frustum(const Vec3(0, 0.23, -0.2), r0: 0.06, r1: 0.05, h: 0.04, seg: 10)), Finish.trim, motions: const [lid]),
    for (var i = 0; i < 3; i++)
      Part(
        m((b) => b.ellipsoid(Vec3(-0.1 + i * 0.1, 0.05, 0.05), const Vec3(0.07, 0.06, 0.07), rings: 4, seg: 8)),
        Finish.glass,
        motions: [Flow(const Vec3(0, 0.55, 0), i / 3)],
        showFrom: 0.5,
      ),
  ];
}

List<Part> _blender(_M m) {
  const shake = Shake(0.012);
  return [
    Part(m((b) => b.box(const Vec3(0, -0.72, 0), const Vec3(0.28, 0.18, 0.28))), Finish.body, motions: const [shake]),
    Part(m((b) => b.frustum(const Vec3(0, -0.74, 0.29), r0: 0.055, r1: 0.055, h: 0.03, axis: Axis3.z)), Finish.metal, motions: const [shake], layer: 1),
    Part(m((b) => b.frustum(const Vec3(0, -0.51, 0), r0: 0.22, r1: 0.2, h: 0.05)), Finish.trim, motions: const [shake]),
    Part(
      m((b) => b.frustum(const Vec3(0, -0.29, 0), r0: 0.17, r1: 0.23, h: 0.38, seg: 9)),
      Finish.fill,
      motions: const [Spin(Vec3.zero, Axis3.y, 2.5), shake],
    ),
    Part(m((b) => b.frustum(const Vec3(0, -0.06, 0), r0: 0.2, r1: 0.28, h: 0.84, capTop: false)), Finish.glass, motions: const [shake]),
    Part(m((b) => b.frustum(const Vec3(0, 0.39, 0), r0: 0.29, r1: 0.29, h: 0.05)), Finish.trim, motions: const [shake]),
    Part(m((b) => b.frustum(const Vec3(0, 0.44, 0), r0: 0.08, r1: 0.07, h: 0.05)), Finish.trim, motions: const [shake]),
    Part(
      m((b) {
        b.box(const Vec3(0.36, -0.05, 0), const Vec3(0.03, 0.24, 0.04));
        b.box(const Vec3(0.3, 0.17, 0), const Vec3(0.06, 0.03, 0.04));
        b.box(const Vec3(0.27, -0.27, 0), const Vec3(0.06, 0.03, 0.04));
      }),
      Finish.trim,
      motions: const [shake],
    ),
  ];
}

List<Part> _airFryer(_M m) {
  const pull = Slide(Vec3(0, 0, 0.45));
  return [
    Part(m((b) => b.box(const Vec3(0, 0.04, 0), const Vec3(0.44, 0.56, 0.42))), Finish.body),
    Part(m((b) => b.box(const Vec3(0, 0.603, 0), const Vec3(0.38, 0.004, 0.34))), Finish.trim, layer: 1),
    Part(m((b) => b.box(const Vec3(0, 0.61, 0.14), const Vec3(0.13, 0.003, 0.06))), Finish.lamp, layer: 2),
    Part(m((b) => b.box(const Vec3(0, -0.27, 0.2), const Vec3(0.36, 0.2, 0.2))), Finish.metal, motions: const [pull], showFrom: 0.05),
    Part(
      m((b) {
        for (var k = 0; k < 7; k++) {
          final start = b.mark;
          b.box(Vec3(-0.24 + k * 0.08, -0.055, 0.2), const Vec3(0.015, 0.015, 0.11));
          _turnY(b, start, Vec3(-0.24 + k * 0.08, 0, 0.2), (k.isEven ? 1 : -1) * 0.35);
        }
      }),
      Finish.bread,
      motions: const [pull],
      showFrom: 0.05,
      layer: 1,
    ),
    Part(m((b) => b.box(const Vec3(0, -0.26, 0.435), const Vec3(0.42, 0.25, 0.016))), Finish.trim, motions: const [pull], layer: 1),
    Part(m((b) => b.box(const Vec3(0, -0.22, 0.5), const Vec3(0.14, 0.035, 0.05))), Finish.metal, motions: const [pull], layer: 2),
  ];
}

List<Part> _toaster(_M m) => [
      Part(m((b) => b.box(const Vec3(0, -0.25, 0), const Vec3(0.55, 0.33, 0.3))), Finish.body),
      Part(
        m((b) {
          b.box(const Vec3(0, 0.082, -0.1), const Vec3(0.42, 0.003, 0.035));
          b.box(const Vec3(0, 0.082, 0.1), const Vec3(0.42, 0.003, 0.035));
        }),
        Finish.trim,
        layer: 1,
      ),
      Part(
        m((b) {
          b.box(const Vec3(0, 0.25, -0.1), const Vec3(0.34, 0.17, 0.025));
          b.box(const Vec3(0, 0.25, 0.1), const Vec3(0.34, 0.17, 0.025));
        }),
        Finish.bread,
        motions: const [Grow(0.08)],
        showFrom: 0.03,
        layer: 2,
      ),
      Part(m((b) => b.box(const Vec3(0.575, -0.05, 0), const Vec3(0.025, 0.03, 0.07))), Finish.trim),
      Part(m((b) => b.frustum(const Vec3(0.38, -0.36, 0.31), r0: 0.045, r1: 0.045, h: 0.03, axis: Axis3.z, seg: 10)), Finish.metal, layer: 1),
      Part(m((b) => b.box(const Vec3(-0.38, -0.36, 0.302), const Vec3(0.03, 0.015, 0.003))), Finish.lamp, layer: 1),
    ];

List<Part> _kettle(_M m) {
  const lid = Hinge(Vec3(0, 0.16, -0.26), Axis3.x, -0.8);
  return [
    Part(m((b) => b.frustum(const Vec3(0, -0.86, 0), r0: 0.44, r1: 0.42, h: 0.06)), Finish.trim),
    Part(m((b) => b.torus(const Vec3(0, -0.825, 0), 0.4, 0.016, sides: 4)), Finish.lamp, layer: 1),
    Part(m((b) => b.frustum(const Vec3(0, -0.36, 0), r0: 0.4, r1: 0.28, h: 0.92)), Finish.body),
    Part(m((b) => b.frustum(const Vec3(0.42, -0.05, 0), r0: 0.09, r1: 0.035, h: 0.22, axis: Axis3.x, seg: 10)), Finish.body),
    Part(
      m((b) {
        b.box(const Vec3(-0.47, -0.3, 0), const Vec3(0.035, 0.3, 0.05));
        b.box(const Vec3(-0.39, 0.0, 0), const Vec3(0.1, 0.035, 0.05));
        b.box(const Vec3(-0.42, -0.62, 0), const Vec3(0.06, 0.035, 0.05));
      }),
      Finish.trim,
    ),
    Part(m((b) => b.frustum(const Vec3(0, 0.13, 0), r0: 0.28, r1: 0.22, h: 0.06)), Finish.body, motions: const [lid]),
    Part(m((b) => b.ellipsoid(const Vec3(0, 0.18, 0), const Vec3(0.06, 0.04, 0.06), rings: 4, seg: 10)), Finish.trim, motions: const [lid]),
    for (var i = 0; i < 3; i++)
      Part(
        m((b) => b.ellipsoid(Vec3(0.55, 0.0 + i * 0.03, 0), const Vec3(0.07, 0.06, 0.07), rings: 4, seg: 8)),
        Finish.glass,
        motions: [Flow(const Vec3(0.1, 0.6, 0), i / 3)],
        showFrom: 0.5,
      ),
  ];
}

List<Part> _robotVacuum(_M m) {
  const brushPivot = Vec3(0.5, -0.19, 0.42);
  return [
    Part(m((b) => b.frustum(const Vec3(0, -0.1, 0), r0: 0.7, r1: 0.68, h: 0.18)), Finish.body),
    Part(m((b) => b.frustum(const Vec3(0, -0.005, 0), r0: 0.6, r1: 0.6, h: 0.01)), Finish.trim, layer: 1),
    Part(m((b) => b.frustum(const Vec3(0, 0.05, -0.22), r0: 0.15, r1: 0.14, h: 0.1)), Finish.body, layer: 2),
    Part(m((b) => b.frustum(const Vec3(0, 0.105, -0.22), r0: 0.12, r1: 0.12, h: 0.01)), Finish.trim, layer: 3),
    Part(m((b) => b.frustum(const Vec3(0, 0.006, 0.25), r0: 0.06, r1: 0.06, h: 0.012, seg: 12)), Finish.lamp, layer: 2),
    Part(
      m((b) {
        for (var k = 0; k < 3; k++) {
          final start = b.mark;
          b.box(brushPivot + const Vec3(0.11, 0, 0), const Vec3(0.11, 0.006, 0.012));
          _turnY(b, start, brushPivot, k * 2 * math.pi / 3);
        }
      }),
      Finish.metal,
      motions: const [Spin(brushPivot, Axis3.y, 2)],
    ),
  ];
}
