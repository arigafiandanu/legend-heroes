import 'package:flutter/material.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../domain/encounter.dart';
import '../../game/ashen_crest_game.dart';
import '../theme.dart';

/// Danger indicator (maps with encounters) and short toasts.
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});

  final AshenCrestGame game;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 12,
            child: ValueListenableBuilder<Danger?>(
              valueListenable: game.danger,
              builder: (context, danger, _) {
                if (danger == null) return const SizedBox.shrink();
                final (color, label) = switch (danger) {
                  Danger.low => (const Color(0xFF6CCB7A), l10n.dangerLow),
                  Danger.medium => (const Color(0xFFE8C04A), l10n.dangerMedium),
                  Danger.high => (const Color(0xFFE0564F), l10n.dangerHigh),
                };
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0x99181520), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(label, style: const TextStyle(color: HudColors.text, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<String?>(
              valueListenable: game.toast,
              builder: (context, text, _) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: text == null
                    ? const SizedBox.shrink()
                    : Center(
                        key: ValueKey(text),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: hudPanel(),
                          child: Text(text, style: const TextStyle(color: HudColors.text, fontWeight: FontWeight.w700)),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
