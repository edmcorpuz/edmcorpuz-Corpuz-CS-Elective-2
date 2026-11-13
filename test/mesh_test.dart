import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:unang_flutter_project/three_d/mesh.dart';
import 'package:unang_flutter_project/three_d/shapes.dart';

/// Every face must wind counter-clockwise from outside, otherwise back-face
/// culling would hide the visible side of the object.
void main() {
  for (final detail in MeshDetail.values) {
    for (final kind in ShapeKind.values) {
      test('${kind.name} (${detail.name}) faces point outward', () {
        final mesh = Shapes.build(kind, detail);
        for (final face in mesh.faces) {
          final pts = [for (final i in face) mesh.vertices[i]];
          final normal = Mesh.faceNormal(pts);
          final mid = Mesh.centroid(pts);
          final inside = kind == ShapeKind.torus ? _torusTubeCenter(mid) : const Vec3(0, 0, 0);
          expect(normal.length, closeTo(1, 1e-6), reason: 'degenerate face $face');
          expect(normal.dot(mid - inside), greaterThan(0), reason: 'face $face of ${kind.name} points inward');
        }
      });
    }
  }

  test('ShapeKind.fromName falls back to cube', () {
    expect(ShapeKind.fromName('torus'), ShapeKind.torus);
    expect(ShapeKind.fromName('pyramid'), ShapeKind.cube);
    expect(ShapeKind.fromName(null), ShapeKind.cube);
  });
}

Vec3 _torusTubeCenter(Vec3 p) {
  final phi = math.atan2(p.z, p.x);
  return Vec3(0.66 * math.cos(phi), 0, 0.66 * math.sin(phi));
}
