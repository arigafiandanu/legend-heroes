import 'package:flutter/material.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../data/save_repository.dart';
import '../../game/ashen_crest_game.dart';
import '../theme.dart';
import 'widgets.dart';

/// Pick a slot to save into (campfire) or load from (title).
class SaveSlotsOverlay extends StatefulWidget {
  const SaveSlotsOverlay({super.key, required this.game});

  final AshenCrestGame game;

  @override
  State<SaveSlotsOverlay> createState() => _SaveSlotsOverlayState();
}

class _SaveSlotsOverlayState extends State<SaveSlotsOverlay> {
  Map<int, SaveSummary?> _summaries = {};

  bool get _saving => widget.game.slotMode == SlotMode.save;
  List<int> get _slots => _saving ? SaveRepository.manualSlots : SaveRepository.allSlots;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final result = {for (final s in _slots) s: await widget.game.saves.summary(s)};
    if (mounted) setState(() => _summaries = result);
  }

  Future<void> _pick(int slot) async {
    final game = widget.game;
    if (_saving) {
      await game.saveToSlot(slot);
      game.closeSlots();
    } else {
      game.closeSlots();
      await game.loadSlot(slot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: const Color(0xAA000000),
      child: SafeArea(
        child: Center(
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(16),
            decoration: hudPanel(highlight: true),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_saving ? l10n.saveTitle : l10n.loadTitle,
                    style: const TextStyle(color: HudColors.ember, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                for (final slot in _slots) ...[
                  _SlotTile(
                    title: slot == SaveRepository.autoSlot ? l10n.slotAuto : l10n.slotManual(slot),
                    summary: _summaries[slot],
                    emptyLabel: l10n.slotEmpty,
                    mapName: _mapName(l10n, _summaries[slot]?.mapId),
                    onTap: (_saving || _summaries[slot] != null) ? () => _pick(slot) : null,
                  ),
                  const SizedBox(height: 6),
                ],
                const SizedBox(height: 4),
                MenuButton(label: l10n.cmdBack, onTap: widget.game.closeSlots, width: 160),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _mapName(AppLocalizations l10n, String? id) => switch (id) {
      null => '',
      'hollowmere' => l10n.mapHollowmere,
      _ when id.startsWith('whisperwood') => l10n.mapWhisperwood,
      _ => id,
    };

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.title,
    required this.summary,
    required this.emptyLabel,
    required this.mapName,
    this.onTap,
  });

  final String title;
  final SaveSummary? summary;
  final String emptyLabel;
  final String mapName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Material(
      color: const Color(0xFF2A2436),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(title, style: const TextStyle(color: HudColors.text, fontWeight: FontWeight.w800)),
              ),
              Expanded(
                child: s == null
                    ? Text(emptyLabel, style: const TextStyle(color: HudColors.textDim))
                    : Text('$mapName · Lv ${s.leadLevel} · ${formatPlayTime(s.playSeconds)}',
                        style: const TextStyle(color: HudColors.text)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
