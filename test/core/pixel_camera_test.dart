import 'package:ashen_crest/core/pixel_camera.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('1080p-tall phone gets 4 physical pixels per virtual pixel', () {
    // 2400×1080 panel at DPR 2.625 → 411.43 logical px tall.
    final zoom = pixelZoom(logicalHeight: 1080 / 2.625, devicePixelRatio: 2.625);
    expect(zoom * 2.625, closeTo(4, 1e-9));
  });

  test('scale is floored to an integer multiple of physical pixels', () {
    // iPhone 11 landscape: 414 pt × DPR 2 = 828 px → 3× (not 3.07×).
    final zoom = pixelZoom(logicalHeight: 414, devicePixelRatio: 2);
    expect(zoom * 2, 3);
  });

  test('never scales below 1 physical pixel', () {
    final zoom = pixelZoom(logicalHeight: 200, devicePixelRatio: 1);
    expect(zoom, 1);
  });
}
