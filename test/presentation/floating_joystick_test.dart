import 'package:flame/extensions.dart';
import 'package:ashen_crest/presentation/controls/floating_joystick.dart';
import 'package:ashen_crest/presentation/controls/input_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dragging sets the joystick vector; release resets it', (tester) async {
    final input = InputState();
    await tester.pumpWidget(MaterialApp(home: FloatingJoystick(input: input)));
    final g = await tester.startGesture(const Offset(100, 100));
    await g.moveBy(const Offset(26, 0));
    await tester.pump();
    expect(input.joystick.x, closeTo(0.5, 0.01));
    await g.up();
    expect(input.joystick.isZero(), isTrue);
  });

  testWidgets('releasing after the overlay was removed (battle started) is safe', (tester) async {
    final input = InputState();
    final show = ValueNotifier(true);
    await tester.pumpWidget(MaterialApp(
      home: ValueListenableBuilder<bool>(
        valueListenable: show,
        builder: (_, visible, __) => visible ? FloatingJoystick(input: input) : const SizedBox(),
      ),
    ));
    final g = await tester.startGesture(const Offset(100, 100));
    await g.moveBy(const Offset(30, 0));
    await tester.pump();
    show.value = false;
    await tester.pump();
    await g.moveBy(const Offset(5, 0));
    await g.up();
    expect(tester.takeException(), isNull);
    expect(input.joystick.isZero(), isTrue);
  });
}
