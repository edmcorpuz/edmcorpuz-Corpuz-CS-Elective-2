import 'dart:math' as math;

import 'mesh.dart';

/// The 3D form a product is rendered as. Stored in the `shape` column.
enum ShapeKind {
  cube('Cube'),
  sphere('Sphere'),
  torus('Torus'),
  cylinder('Cylinder'),
  cone('Cone'),
  gem('Gem');

  const ShapeKind(this.label);

  final String label;

  static ShapeKind fromName(String? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => ShapeKind.cube);
}

/// How finely curved shapes are tessellated. Cards use [low] so a full grid
/// of spinning objects stays smooth; the hero and detail views use [high].
enum MeshDetail { low, high }

class Shapes {
  Shapes._();

  static final Map<(ShapeKind, MeshDetail), Mesh> _cache = {};

  static Mesh of(ShapeKind kind, [MeshDetail detail = MeshDetail.low]) =>
      _cache.putIfAbsent((kind, detail), () => build(kind, detail));

  static Mesh build(ShapeKind kind, MeshDetail detail) {
    final hi = detail == MeshDetail.high;
    return switch (kind) {
      ShapeKind.cube => cube(),
      ShapeKind.sphere => sphere(rings: hi ? 18 : 10, segments: hi ? 28 : 16),
      ShapeKind.torus => torus(segments: hi ? 40 : 22, sides: hi ? 18 : 10),
      ShapeKind.cylinder => cylinder(segments: hi ? 36 : 18),
      ShapeKind.cone => cone(segments: hi ? 36 : 18),
      ShapeKind.gem => gem(facets: hi ? 12 : 8),
    };
  }

  /// Axis-aligned cube, each face built from (normal, u, v) with u x v = n.
  static Mesh cube([double s = 0.62]) {
    final vertices = <Vec3>[];
    final faces = <List<int>>[];
    const axes = [
      (Vec3(0, 0, 1), Vec3(1, 0, 0), Vec3(0, 1, 0)),
      (Vec3(0, 0, -1), Vec3(-1, 0, 0), Vec3(0, 1, 0)),
      (Vec3(1, 0, 0), Vec3(0, 0, -1), Vec3(0, 1, 0)),
      (Vec3(-1, 0, 0), Vec3(0, 0, 1), Vec3(0, 1, 0)),
      (Vec3(0, 1, 0), Vec3(1, 0, 0), Vec3(0, 0, -1)),
      (Vec3(0, -1, 0), Vec3(1, 0, 0), Vec3(0, 0, 1)),
    ];
    for (final (n, u, v) in axes) {
      final c = n * s;
      final us = u * s, vs = v * s;
      final base = vertices.length;
      vertices.addAll([c - us - vs, c + us - vs, c + us + vs, c - us + vs]);
      faces.add([base, base + 1, base + 2, base + 3]);
    }
    return Mesh(vertices, faces);
  }

  static Mesh sphere({double r = 0.86, int rings = 10, int segments = 16}) {
    final vertices = <Vec3>[];
    for (var i = 0; i <= rings; i++) {
      final theta = math.pi * i / rings;
      for (var j = 0; j <= segments; j++) {
        final phi = 2 * math.pi * j / segments;
        vertices.add(Vec3(
          r * math.sin(theta) * math.cos(phi),
          r * math.cos(theta),
          r * math.sin(theta) * math.sin(phi),
        ));
      }
    }
    final faces = <List<int>>[];
    int idx(int i, int j) => i * (segments + 1) + j;
    for (var i = 0; i < rings; i++) {
      for (var j = 0; j < segments; j++) {
        if (i == 0) {
          faces.add([idx(0, j), idx(1, j + 1), idx(1, j)]);
        } else if (i == rings - 1) {
          faces.add([idx(i, j), idx(i, j + 1), idx(i + 1, j)]);
        } else {
          faces.add([idx(i, j), idx(i, j + 1), idx(i + 1, j + 1), idx(i + 1, j)]);
        }
      }
    }
    return Mesh(vertices, faces);
  }

  /// Torus lying in the XZ plane (axis = Y).
  static Mesh torus({
    double major = 0.66,
    double minor = 0.27,
    int segments = 22,
    int sides = 10,
  }) {
    final vertices = <Vec3>[];
    for (var i = 0; i < segments; i++) {
      final phi = 2 * math.pi * i / segments;
      for (var j = 0; j < sides; j++) {
        final theta = 2 * math.pi * j / sides;
        final ring = major + minor * math.cos(theta);
        vertices.add(Vec3(
          ring * math.cos(phi),
          minor * math.sin(theta),
          ring * math.sin(phi),
        ));
      }
    }
    final faces = <List<int>>[];
    int idx(int i, int j) => (i % segments) * sides + (j % sides);
    for (var i = 0; i < segments; i++) {
      for (var j = 0; j < sides; j++) {
        faces.add([idx(i, j), idx(i, j + 1), idx(i + 1, j + 1), idx(i + 1, j)]);
      }
    }
    return Mesh(vertices, faces);
  }

  static Mesh cylinder({double r = 0.56, double h = 1.3, int segments = 18}) {
    final vertices = <Vec3>[];
    final top = h / 2, bottom = -h / 2;
    for (var j = 0; j < segments; j++) {
      final phi = 2 * math.pi * j / segments;
      final x = r * math.cos(phi), z = r * math.sin(phi);
      vertices.add(Vec3(x, top, z));
      vertices.add(Vec3(x, bottom, z));
    }
    final faces = <List<int>>[];
    for (var j = 0; j < segments; j++) {
      final k = (j + 1) % segments;
      faces.add([2 * j, 2 * k, 2 * k + 1, 2 * j + 1]);
    }
    faces.add([for (var j = segments - 1; j >= 0; j--) 2 * j]);
    faces.add([for (var j = 0; j < segments; j++) 2 * j + 1]);
    return Mesh(vertices, faces);
  }

  static Mesh cone({double r = 0.72, double h = 1.45, int segments = 18}) {
    final vertices = <Vec3>[Vec3(0, h * 0.55, 0)];
    final baseY = -h * 0.45;
    for (var j = 0; j < segments; j++) {
      final phi = 2 * math.pi * j / segments;
      vertices.add(Vec3(r * math.cos(phi), baseY, r * math.sin(phi)));
    }
    final faces = <List<int>>[];
    for (var j = 0; j < segments; j++) {
      final a = 1 + j, b = 1 + (j + 1) % segments;
      faces.add([0, b, a]);
    }
    faces.add([for (var j = 0; j < segments; j++) 1 + j]);
    return Mesh(vertices, faces);
  }

  /// Brilliant-cut style gem: table, crown, girdle and pointed pavilion.
  static Mesh gem({int facets = 8}) {
    const tableR = 0.5, tableY = 0.42, girdleR = 0.9, girdleY = 0.12;
    const apexY = -0.95;
    final vertices = <Vec3>[];
    for (var j = 0; j < facets; j++) {
      final phi = 2 * math.pi * j / facets;
      vertices.add(Vec3(tableR * math.cos(phi), tableY, tableR * math.sin(phi)));
    }
    for (var j = 0; j < facets; j++) {
      final phi = 2 * math.pi * (j + 0.5) / facets;
      vertices.add(Vec3(girdleR * math.cos(phi), girdleY, girdleR * math.sin(phi)));
    }
    final apex = vertices.length;
    vertices.add(const Vec3(0, apexY, 0));

    final faces = <List<int>>[];
    faces.add([for (var j = facets - 1; j >= 0; j--) j]);
    for (var j = 0; j < facets; j++) {
      final t0 = j, t1 = (j + 1) % facets;
      final g0 = facets + j, gPrev = facets + (j - 1 + facets) % facets;
      faces.add([t0, t1, g0]);
      faces.add([t0, g0, gPrev]);
      faces.add([gPrev, g0, apex]);
    }
    return Mesh(vertices, faces);
  }
}
