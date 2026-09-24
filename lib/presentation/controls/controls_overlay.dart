import 'package:flutter/material.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../game/ashen_crest_game.dart';
import '../theme.dart';
import 'floating_joystick.dart';

/// Overworld touch controls: floating joystick (left half), Action + Run
/// (bottom right), Menu (top right).
class ControlsOverlay extends StatelessWidget {
  const ControlsOverlay({super.key, required this.game});

  final AshenCrestGame game;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.sizeOf(context).width / 2,
            child: FloatingJoystick(input: game.input),
          ),
          Positioned(
            right: 16,
            top: 12,
            child: Row(
              children: [
                _PillButton(label: l10n.menuButton, icon: Icons.menu, onTap: game.openMenu),
              ],
            ),
          ),
          Positioned(
            right: 24,
            bottom: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _HoldButton(
                  label: l10n.runButton,
                  size: 64,
                  onChanged: (held) => game.input.runHeld = held,
                ),
                const SizedBox(width: 14),
                Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: _HoldButton(
                    label: l10n.actionButton,
                    size: 76,
                    onChanged: (held) {
                      if (held) game.input.onAction?.call();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldButton extends StatefulWidget {
  const _HoldButton({required this.label, required this.size, required this.onChanged});

  final String label;
  final double size;
  final ValueChanged<bool> onChanged;

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _held = false;

  void _set(bool held) {
    if (held == _held) return;
    setState(() => _held = held);
    widget.onChanged(held);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _held ? const Color(0x88E8A23A) : const Color(0x44FFFFFF),
            border: Border.all(color: const Color(0x88FFFFFF), width: 2),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(color: HudColors.text, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      );
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0x99181520),
        shape: const StadiumBorder(side: BorderSide(color: Color(0x66FFFFFF))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: HudColors.text),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(color: HudColors.text, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
}
