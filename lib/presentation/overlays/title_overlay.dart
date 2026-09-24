import 'package:flutter/material.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../game/ashen_crest_game.dart';
import '../theme.dart';
import 'widgets.dart';

class TitleOverlay extends StatefulWidget {
  const TitleOverlay({super.key, required this.game});

  final AshenCrestGame game;

  @override
  State<TitleOverlay> createState() => _TitleOverlayState();
}

class _TitleOverlayState extends State<TitleOverlay> {
  int? _latest;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    widget.game.saves.latestSlot().then((slot) {
      if (mounted) {
        setState(() {
          _latest = slot;
          _checked = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final latest = _latest;
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'LEGEND HEROES',
              style: TextStyle(
                color: HudColors.ember,
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                shadows: [Shadow(color: Color(0xAAFF7A2E), blurRadius: 24)],
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.titleSubtitle,
                style: const TextStyle(color: HudColors.textDim, fontSize: 16, letterSpacing: 2)),
            const SizedBox(height: 28),
            if (latest != null) ...[
              MenuButton(label: l10n.titleContinue, primary: true, onTap: () => widget.game.loadSlot(latest)),
              const SizedBox(height: 10),
            ],
            MenuButton(label: l10n.titleNewGame, primary: _checked && latest == null, onTap: widget.game.newGame),
            const SizedBox(height: 10),
            MenuButton(
              label: l10n.titleLoad,
              onTap: latest == null ? null : () => widget.game.openSlots(SlotMode.load),
            ),
          ],
        ),
      ),
    );
  }
}
