import 'package:flutter/material.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../domain/battle/battle_unit.dart';
import '../theme.dart';
import 'battle_cubit.dart';

/// Turn order: who is acting, who is left this round, then next round.
class TimelineBar extends StatelessWidget {
  const TimelineBar({super.key, required this.cubit});

  final BattleCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final engine = cubit.engine;
    final actor = engine.currentActor;
    final now = [
      if (actor != null && actor.isAlive && !engine.isOver) actor,
      ...engine.upcomingThisRound,
    ];
    final next = engine.isOver ? const <BattleUnit>[] : engine.nextRoundOrder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: hudPanel(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.roundLabel(engine.round),
              style: const TextStyle(color: HudColors.ember, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(width: 8),
          for (var i = 0; i < now.length; i++) _Chip(unit: now[i], active: i == 0 && now[i] == actor),
          if (next.isNotEmpty) ...[
            const SizedBox(width: 6),
            Container(width: 1, height: 18, color: HudColors.panelBorder),
            const SizedBox(width: 6),
            Text(l10n.nextRoundLabel, style: const TextStyle(color: HudColors.textDim, fontSize: 11)),
            const SizedBox(width: 6),
            for (final u in next) _Chip(unit: u, dim: true),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.unit, this.active = false, this.dim = false});

  final BattleUnit unit;
  final bool active;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final base = unit.isParty ? HudColors.party : HudColors.enemy;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: dim ? base.withValues(alpha: 0.35) : base,
        borderRadius: BorderRadius.circular(6),
        border: active ? Border.all(color: HudColors.ember, width: 2) : null,
      ),
      child: Text(
        unit.name.split(' ').first,
        style: TextStyle(
          color: dim ? HudColors.textDim : HudColors.text,
          fontSize: 11,
          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}
