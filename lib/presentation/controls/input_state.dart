import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

/// Movement input shared by the touch overlay, the keyboard and the game.
class InputState {
  /// Touch joystick vector, length 0–1.
  final Vector2 joystick = Vector2.zero();

  /// Keyboard vector (WASD / arrows), components −1/0/1.
  final Vector2 keyboard = Vector2.zero();

  bool runHeld = false;
  bool runKey = false;

  /// Fired by the Action button (talk / inspect). Stub until M2.
  VoidCallback? onAction;

  Vector2 get direction => joystick.isZero() ? keyboard : joystick;
  bool get running => runHeld || runKey;

  void reset() {
    joystick.setZero();
    keyboard.setZero();
    runHeld = false;
    runKey = false;
  }
}
