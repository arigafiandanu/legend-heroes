import 'dart:convert';
import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/services.dart' show AssetBundle;

/// One prop kind in an area's sheet: where it is and what part of it blocks.
class PropFrame {
  const PropFrame({required this.src, required this.solid, this.glow});

  factory PropFrame.fromJson(Map<String, dynamic> json) {
    double n(Object? v) => (v as num).toDouble();
    final s = json['solid'] as List;
    final g = json['glow'] as Map<String, dynamic>?;
    return PropFrame(
      src: Rect.fromLTWH(n(json['x']), n(json['y']), n(json['w']), n(json['h'])),
      solid: Rect.fromLTWH(n(s[0]), n(s[1]), n(s[2]), n(s[3])),
      glow: g == null
          ? null
          : PropGlow(
              dy: n(g['dy']),
              radius: n(g['radius']),
              color: Color(int.parse((g['color'] as String).substring(1), radix: 16) | 0xFF000000),
            ),
    );
  }

  /// Rectangle in the sheet image.
  final Rect src;

  /// Collision box relative to the prop's base (bottom-centre) point.
  final Rect solid;

  /// Light the prop gives off (lanterns, shrine flames, Ashblight embers).
  final PropGlow? glow;

  static Map<String, PropFrame> parseAll(String json) => {
        for (final e in (jsonDecode(json) as Map<String, dynamic>).entries)
          e.key: PropFrame.fromJson(e.value as Map<String, dynamic>),
      };
}

/// A glow centred [dy] px above a prop's base.
class PropGlow {
  const PropGlow({required this.dy, required this.radius, required this.color});

  final double dy;
  final double radius;
  final Color color;
}

/// An area's prop sprites (`assets/images/props/<area>_props.png`) and frames
/// (`assets/data/props_<area>.json`), both written by tools/art/<area>.py.
class PropSheet {
  PropSheet(this.image, this.frames);

  final Image image;
  final Map<String, PropFrame> frames;

  static Future<PropSheet> load(Images images, AssetBundle bundle, String area) async => PropSheet(
        await images.load('props/${area}_props.png'),
        PropFrame.parseAll(await bundle.loadString('assets/data/props_$area.json')),
      );
}

/// A tree, rock, sign… placed from the map's `props` layer. Drawn y-sorted
/// with the characters so they can walk in front of or behind it.
class Prop extends SpriteComponent {
  factory Prop({required PropSheet sheet, required String kind, required Vector2 base}) {
    final frame = sheet.frames[kind];
    if (frame == null) throw ArgumentError('unknown prop "$kind"');
    return Prop._(sheet.image, kind, frame, base);
  }

  Prop._(Image image, this.kind, this.frame, Vector2 base)
      : super(
          sprite: Sprite(image, srcPosition: frame.src.topLeft.toVector2(), srcSize: frame.src.size.toVector2()),
          position: base,
          anchor: Anchor.bottomCenter,
          priority: base.y.toInt(),
        ) {
    paint.filterQuality = FilterQuality.none;
  }

  final String kind;
  final PropFrame frame;

  static final _shadowPaint = Paint()..color = const Color(0x55000000);

  Rect get solid => frame.solid.shift(position.toOffset());

  @override
  void render(Canvas canvas) {
    // Engine cast shadow (art bible §5): an ellipse under the base, nudged
    // right because the light comes from the top-left.
    final w = (frame.solid.width * 1.6).clamp(12.0, size.x * 0.8);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.x / 2 + 3, size.y - 1), width: w, height: 7), _shadowPaint);
    super.render(canvas);
  }
}
