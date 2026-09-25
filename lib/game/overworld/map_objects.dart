import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../character_sprite.dart';

/// Something on the map the player can inspect with the Action button.
abstract interface class Interactable {
  Rect get area;
  Future<void> interact();
}

/// A villager: tinted placeholder sprite, blocks movement, talks.
class Npc extends CharacterSprite implements Interactable {
  Npc({
    required super.sheetPath,
    required this.dialogNode,
    required this.onTalk,
    required Color tint,
    super.position,
    super.facing,
  }) : _tint = tint;

  final String dialogNode;
  final Future<void> Function(String node) onTalk;
  final Color _tint;

  Rect get solid => Rect.fromLTWH(position.x - 6, position.y - 6, 12, 6);

  @override
  Rect get area => Rect.fromLTWH(position.x - 10, position.y - 30, 20, 32);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    paint.colorFilter = ColorFilter.mode(_tint, BlendMode.modulate);
    priority = position.y.toInt();
  }

  /// Turn toward the player before talking.
  void face(Vector2 other) {
    final d = other - position;
    facing = d.x.abs() > d.y.abs()
        ? (d.x < 0 ? Facing.left : Facing.right)
        : (d.y < 0 ? Facing.up : Facing.down);
    animateTowards(Vector2.zero());
  }

  @override
  Future<void> interact() => onTalk(dialogNode);
}

/// Treasure chest: `props/chest.png` (closed, open), 16×16 frames.
class Chest extends PositionComponent with HasGameReference implements Interactable {
  Chest({required Rect rect, required this.opened, required this.onOpen})
      : super(position: Vector2(rect.left, rect.top), size: Vector2(rect.width, rect.height));

  bool opened;
  final Future<void> Function(Chest chest) onOpen;

  static final _shadow = Paint()..color = const Color(0x55000000);
  late final Sprite _closed, _open;

  Rect get solid => toRect().deflate(1);

  @override
  Rect get area => toRect().inflate(4);

  @override
  Future<void> onLoad() async {
    priority = (position.y + size.y).toInt();
    final image = await game.images.load('props/chest.png');
    _closed = Sprite(image, srcSize: Vector2.all(16));
    _open = Sprite(image, srcPosition: Vector2(16, 0), srcSize: Vector2.all(16));
  }

  @override
  void render(Canvas canvas) {
    canvas.drawOval(Rect.fromLTWH(1, size.y - 3, size.x - 1, 4), _shadow);
    (opened ? _open : _closed).render(canvas, position: Vector2(size.x / 2 - 8, size.y - 16), overridePaint: _pixel);
  }

  static final _pixel = Paint()..filterQuality = FilterQuality.none;

  @override
  Future<void> interact() => onOpen(this);
}

/// Campfire: flickering flame + additive glow. Rest and save here.
class Campfire extends PositionComponent implements Interactable {
  Campfire({required Rect rect, required this.onUse})
      : super(position: Vector2(rect.left, rect.top), size: Vector2(rect.width, rect.height));

  final Future<void> Function() onUse;
  double _t = 0;

  Rect get solid => Rect.fromCenter(center: toRect().center.translate(0, 4), width: 20, height: 10);

  @override
  Rect get area => toRect().inflate(6);

  @override
  Future<void> onLoad() async => priority = (position.y + size.y - 6).toInt();

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2 + 4);
    final flicker = 0.85 + 0.15 * sin(_t * 11) * sin(_t * 7.3);
    canvas.drawCircle(
      c,
      30 * flicker,
      Paint()
        ..color = const Color(0x40FF9A3C)
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    final log = Paint()..color = const Color(0xFF5A3A22);
    canvas
      ..drawRect(Rect.fromCenter(center: c.translate(0, 5), width: 22, height: 4), log)
      ..drawRect(Rect.fromCenter(center: c.translate(0, 3), width: 4, height: 16), log);
    for (final (dx, h, color) in [
      (-4.0, 12.0, const Color(0xFFE8572E)),
      (3.0, 14.0, const Color(0xFFFF8A3D)),
      (0.0, 10.0, const Color(0xFFFFD36B)),
    ]) {
      final hh = h * (0.8 + 0.2 * sin(_t * 9 + dx));
      final path = Path()
        ..moveTo(c.dx + dx - 4, c.dy + 3)
        ..quadraticBezierTo(c.dx + dx - 3, c.dy - hh / 2, c.dx + dx, c.dy - hh)
        ..quadraticBezierTo(c.dx + dx + 3, c.dy - hh / 2, c.dx + dx + 4, c.dy + 3)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  @override
  Future<void> interact() => onUse();
}

/// Sign / shrine / anything that just shows a dialog node.
class Examinable implements Interactable {
  Examinable({required this.area, required this.node, required this.onExamine});

  @override
  final Rect area;
  final String node;
  final Future<void> Function(String node) onExamine;

  @override
  Future<void> interact() => onExamine(node);
}

class ExitZone {
  ExitZone({required this.area, this.targetMap, this.targetSpawn, this.requiresFlag, this.blockedDialog});

  final Rect area;
  final String? targetMap;
  final String? targetSpawn;
  final String? requiresFlag;
  final String? blockedDialog;
  bool armed = true;
}
