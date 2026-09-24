import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../domain/battle/battle_engine.dart';
import '../../game/ashen_crest_game.dart';
import '../theme.dart';
import 'battle_cubit.dart';
import 'battle_state.dart';
import 'command_menu.dart';
import 'party_panel.dart';
import 'timeline_bar.dart';

class BattleHud extends StatelessWidget {
  const BattleHud({super.key, required this.game});

  final AshenCrestGame game;

  @override
  Widget build(BuildContext context) {
    final cubit = game.battle;
    if (cubit == null) return const SizedBox.shrink();
    return BlocBuilder<BattleCubit, BattleViewState>(
      bloc: cubit,
      builder: (context, state) => SafeArea(
        child: Stack(
          children: [
            Positioned(top: 8, left: 0, right: 0, child: Center(child: TimelineBar(cubit: cubit))),
            if (state.announcement != null)
              Positioned(
                top: 52,
                left: 0,
                right: 0,
                child: Center(child: _Banner(text: state.announcement!)),
              ),
            Positioned(right: 12, bottom: 12, child: PartyPanel(cubit: cubit, boost: state.boost)),
            if (!state.busy && state.outcome == null && cubit.engine.awaitingPlayer)
              Positioned(left: 12, bottom: 12, child: CommandMenu(cubit: cubit, state: state)),
            if (state.outcome != null)
              Positioned.fill(child: _ResultOverlay(outcome: state.outcome!, onContinue: game.endBattle)),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: hudPanel(),
        child: Text(text, style: const TextStyle(color: HudColors.text, fontWeight: FontWeight.w700, fontSize: 14)),
      );
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({required this.outcome, required this.onContinue});

  final BattleOutcome outcome;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = switch (outcome.phase) {
      BattlePhase.victory => l10n.victoryTitle,
      BattlePhase.defeat => l10n.defeatTitle,
      _ => l10n.escapedTitle,
    };
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: hudPanel(highlight: true),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(color: HudColors.ember, fontSize: 26, fontWeight: FontWeight.w900)),
              if (outcome.phase == BattlePhase.victory) ...[
                const SizedBox(height: 8),
                Text(l10n.victoryRewards(outcome.exp, outcome.keping),
                    style: const TextStyle(color: HudColors.text, fontSize: 15)),
              ],
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: HudColors.ember,
                  foregroundColor: const Color(0xFF1A1620),
                  minimumSize: const Size(160, 48),
                ),
                onPressed: onContinue,
                child: Text(l10n.continueButton, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
