import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight;

import '../../domain/attack_type.dart';
import '../../domain/battle/battle_unit.dart';
import 'weakness_icon.dart';

/// Colored blob standing in for an enemy battle sprite (none exist yet),
/// with HP bar, shield count and weakness icons like the final HUD will have.
class EnemyPlaceholder extends PositionComponent with HasPaint {
  EnemyPlaceholder({required this.unit, required this.color, super.position})
      : shield = unit.shield,
        hpRatio = 1,
        super(size: Vector2(40, 36), anchor: Anchor.bottomCenter);

  final BattleUnit unit;
  final Color color;

  int shield;
  double hpRatio;
  bool broken = false;
  final Set<AttackType> revealed = {};

  static final _name = TextPaint(
    style: const TextStyle(fontSize: 7, color: Color(0xFFE6E1D6)),
  );
  static final _shieldText = TextPaint(
    style: const TextStyle(fontSize: 7, color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
  );

  @override
  void render(Canvas canvas) {
    final alpha = paint.color.a;
    final body = broken ? Color.lerp(color, const Color(0xFF6E6E6E), 0.6)! : color;
    final outline = Color.lerp(body, const Color(0xFF000000), 0.55)!;

    // Shadow + body.
    canvas.drawOval(Rect.fromLTWH(2, size.y - 4, size.x - 4, 6),
        Paint()..color = Color.fromRGBO(0, 0, 0, 0.35 * alpha));
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(4, 4, size.x - 8, size.y - 6), const Radius.circular(10));
    canvas
      ..drawRRect(rrect, Paint()..color = body.withValues(alpha: alpha))
      ..drawRRect(
          rrect,
          Paint()
            ..color = outline.withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);

    // Eyes (look right, toward the party); X eyes while broken.
    final eye = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: alpha);
    final pupil = Paint()
      ..color = const Color(0xFF1A1620).withValues(alpha: alpha)
      ..strokeWidth = 1;
    for (final x in [20.0, 28.0]) {
      if (broken) {
        canvas
          ..drawLine(Offset(x - 2, 13), Offset(x + 2, 17), pupil)
          ..drawLine(Offset(x - 2, 17), Offset(x + 2, 13), pupil);
      } else {
        canvas
          ..drawRect(Rect.fromLTWH(x - 2, 12, 4, 5), eye)
          ..drawRect(Rect.fromLTWH(x, 14, 2, 3), pupil);
      }
    }

    if (alpha < 0.05) return;

    // Name + HP bar above.
    _name.render(canvas, unit.name, Vector2(size.x / 2, -9), anchor: Anchor.bottomCenter);
    final bar = Rect.fromLTWH(2, -7, size.x - 4, 3);
    canvas
      ..drawRect(bar, Paint()..color = const Color(0xFF2A2433))
      ..drawRect(Rect.fromLTWH(bar.left, bar.top, bar.width * hpRatio, bar.height),
          Paint()..color = const Color(0xFFD9534F));

    // Shield + weakness icons below.
    final top = size.y + 4;
    final shieldRect = Rect.fromLTWH(-6, top, 11, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shieldRect, const Radius.circular(2)),
      Paint()..color = broken ? const Color(0xFF8A2E2E) : const Color(0xFF3F6FB5),
    );
    _shieldText.render(canvas, broken ? '!' : '$shield', Vector2(shieldRect.center.dx, shieldRect.center.dy),
        anchor: Anchor.center);
    var x = 7.0;
    for (final type in AttackType.values.where(unit.weaknesses.contains)) {
      drawWeaknessIcon(canvas, Offset(x, top + 0.5), revealed.contains(type) ? type : null);
      x += 10;
    }
  }

  void shake() => add(SequenceEffect([
        MoveByEffect(Vector2(-3, 0), EffectController(duration: 0.04)),
        MoveByEffect(Vector2(6, 0), EffectController(duration: 0.06)),
        MoveByEffect(Vector2(-3, 0), EffectController(duration: 0.04)),
      ]));

  void defeat() => add(OpacityEffect.fadeOut(EffectController(duration: 0.4)));
}
