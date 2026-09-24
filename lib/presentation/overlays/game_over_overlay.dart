import 'package:flutter/material.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../game/ashen_crest_game.dart';
import '../theme.dart';
import 'widgets.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});

  final AshenCrestGame game;

  Future<void> _loadLatest() async {
    final slot = await game.saves.latestSlot();
    if (slot == null || !await game.loadSlot(slot)) await game.quitToTitle();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: const Color(0xEE0B0910),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.gameOverTitle,
                style: const TextStyle(color: HudColors.hpLow, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 4)),
            const SizedBox(height: 24),
            MenuButton(label: l10n.gameOverLoad, primary: true, onTap: _loadLatest),
            const SizedBox(height: 10),
            MenuButton(label: l10n.gameOverToTitle, onTap: game.quitToTitle),
          ],
        ),
      ),
    );
  }
}
