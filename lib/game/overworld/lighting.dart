import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Warm light falling through the canopy: a slanted band from [rect]'s top
/// edge down to its bottom edge, shifted right because the sun is top-left.
class LightShaft {
  const LightShaft(this.rect);

  final Rect rect;

  Path get path {
    final slant = rect.height * 0.45;
    return Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right + slant, rect.bottom)
      ..lineTo(rect.left + slant, rect.bottom)
      ..close();
  }
}

/// A small pulsing glow (Ashblight embers).
class Glow {
  const Glow(this.center, {this.radius = 14, this.color = const Color(0xFFEEA664), this.phase = 0});

  final Offset center;
  final double radius;
  final Color color;
  final double phase;
}

/// Basic HD-2D lighting over a map (art bible §9): the area's ambient colour
/// multiplied over everything, then additive light. Static shafts are baked
/// once into an image; glows are drawn live so they can pulse.
class Lighting extends Component {
  Lighting({required this.size, this.ambient, this.shafts = const [], this.glows = const []})
      : super(priority: 200000);

  final Size size;
  final Color? ambient;
  final List<LightShaft> shafts;
  final List<Glow> glows;

  static const shaftColor = Color(0x2EFAD65A);
  Image? _baked;
  bool _baking = false;
  double _t = 0;

  /// Baked on every mount: the map world is taken off screen during battles
  /// and put back afterwards, and the image is released while it is away.
  @override
  void onMount() {
    super.onMount();
    if (shafts.isNotEmpty && _baked == null && !_baking) _bake();
  }

  Future<void> _bake() async {
    _baking = true;
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = shaftColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    for (final s in shafts) {
      canvas.drawPath(s.path, paint);
    }
    final image = await recorder.endRecording().toImage(size.width.ceil(), size.height.ceil());
    _baking = false;
    if (isMounted) {
      _baked = image;
    } else {
      image.dispose();
    }
  }

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final a = ambient;
    if (a != null) {
      canvas.drawRect(Offset.zero & size, Paint()
        ..color = a
        ..blendMode = BlendMode.multiply);
    }
    final baked = _baked;
    if (baked != null) canvas.drawImage(baked, Offset.zero, Paint()..blendMode = BlendMode.plus);
    for (final g in glows) {
      final pulse = 0.75 + 0.25 * sin(_t * 2.2 + g.phase);
      final r = g.radius * (0.9 + 0.1 * pulse);
      canvas.drawCircle(
        g.center,
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = Gradient.radial(g.center, r, [
            g.color.withValues(alpha: 0.30 * pulse),
            g.color.withValues(alpha: 0),
          ]),
      );
    }
  }

  @override
  void onRemove() {
    _baked?.dispose();
    _baked = null;
    super.onRemove();
  }
}

/// Parses a `#RRGGBB` map property.
Color? parseHexColor(String? hex) =>
    hex == null ? null : Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);
