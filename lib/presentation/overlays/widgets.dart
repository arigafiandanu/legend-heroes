import 'package:flutter/material.dart';

import '../theme.dart';

/// Large touch-friendly menu button used across overlays.
class MenuButton extends StatelessWidget {
  const MenuButton({super.key, required this.label, this.onTap, this.primary = false, this.width = 240});

  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final double width;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: width,
      child: Material(
        color: primary ? HudColors.ember : const Color(0xFF2A2436),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                color: primary
                    ? const Color(0xFF1A1620)
                    : enabled
                        ? HudColors.text
                        : HudColors.textDim.withValues(alpha: 0.5),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String formatPlayTime(double seconds) {
  final s = seconds.floor();
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  return '$h:${m.toString().padLeft(2, '0')}';
}
