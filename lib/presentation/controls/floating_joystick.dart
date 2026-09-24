import 'package:flutter/material.dart';

import 'input_state.dart';

/// Joystick that appears wherever the thumb lands (left half of the screen).
class FloatingJoystick extends StatefulWidget {
  const FloatingJoystick({super.key, required this.input, this.radius = 52});

  final InputState input;
  final double radius;

  @override
  State<FloatingJoystick> createState() => _FloatingJoystickState();
}

class _FloatingJoystickState extends State<FloatingJoystick> {
  int? _pointer;
  Offset? _origin;
  Offset _knob = Offset.zero;

  void _down(PointerDownEvent e) {
    if (_pointer != null) return;
    setState(() {
      _pointer = e.pointer;
      _origin = e.localPosition;
      _knob = Offset.zero;
    });
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    var d = e.localPosition - _origin!;
    if (d.distance > widget.radius) d = d / d.distance * widget.radius;
    widget.input.joystick.setValues(d.dx / widget.radius, d.dy / widget.radius);
    setState(() => _knob = d);
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    widget.input.joystick.setZero();
    setState(() {
      _pointer = null;
      _origin = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final origin = _origin;
    final r = widget.radius;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: Stack(
        children: [
          if (origin != null) ...[
            Positioned(
              left: origin.dx - r,
              top: origin.dy - r,
              child: Container(
                width: r * 2,
                height: r * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x33FFFFFF),
                  border: Border.all(color: const Color(0x66FFFFFF), width: 2),
                ),
              ),
            ),
            Positioned(
              left: origin.dx + _knob.dx - 22,
              top: origin.dy + _knob.dy - 22,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xAAFFFFFF)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
