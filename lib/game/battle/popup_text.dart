import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart' show TextStyle, FontWeight, Shadow;

/// Floating number / label that rises, then removes itself.
class PopupText extends TextComponent {
  PopupText(String text, {required Vector2 position, required Color color, double fontSize = 10})
      : super(
          text: text,
          position: position,
          anchor: Anchor.bottomCenter,
          priority: 10000,
          textRenderer: TextPaint(
            style: TextStyle(
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(color: Color(0xFF000000), offset: Offset(1, 1))],
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    add(SequenceEffect([
      MoveByEffect(Vector2(0, -14), EffectController(duration: 0.35, curve: Curves.easeOut)),
      MoveByEffect(Vector2(0, 0), EffectController(duration: 0.35)),
      RemoveEffect(),
    ]));
  }
}
