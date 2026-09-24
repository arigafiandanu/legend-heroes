import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../theme.dart';
import 'battle_cubit.dart';

/// HP / SP / BP of each party member, following event playback.
class PartyPanel extends StatelessWidget {
  const PartyPanel({super.key, required this.cubit, required this.boost});

  final BattleCubit cubit;

  /// BP the active member is about to spend (highlighted pips).
  final int boost;

  @override
  Widget build(BuildContext context) {
    final engine = cubit.engine;
    return Container(
      width: 250,
      padding: const EdgeInsets.all(8),
      decoration: hudPanel(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final u in engine.party)
            _MemberRow(
              name: u.name,
              hp: cubit.shownHp(u.id),
              maxHp: u.stats.hp,
              sp: cubit.shownSp(u.id),
              maxSp: u.stats.sp,
              bp: cubit.shownBp(u.id),
              boost: engine.awaitingPlayer && engine.currentActor == u ? boost : 0,
              active: engine.currentActor == u && !engine.isOver,
            ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.name,
    required this.hp,
    required this.maxHp,
    required this.sp,
    required this.maxSp,
    required this.bp,
    required this.boost,
    required this.active,
  });

  final String name;
  final int hp, maxHp, sp, maxSp, bp, boost;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ratio = maxHp == 0 ? 0.0 : hp / maxHp;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0x33E8A23A) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(name,
                style: TextStyle(
                  color: hp == 0 ? HudColors.textDim : HudColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                )),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bar(label: 'HP', value: hp, max: maxHp, color: ratio < 0.3 ? HudColors.hpLow : HudColors.hp),
                const SizedBox(height: 3),
                _Bar(label: 'SP', value: sp, max: maxSp, color: HudColors.sp),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _BpPips(bp: bp, boost: boost),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.max, required this.color});

  final String label;
  final int value, max;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(label, style: const TextStyle(color: HudColors.textDim, fontSize: 9)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: max == 0 ? 0 : value / max,
                minHeight: 5,
                color: color,
                backgroundColor: const Color(0xFF2A2433),
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text('$value',
                textAlign: TextAlign.right,
                style: const TextStyle(color: HudColors.text, fontSize: 11, fontFeatures: [FontFeature.tabularFigures()])),
          ),
        ],
      );
}

class _BpPips extends StatelessWidget {
  const _BpPips({required this.bp, required this.boost});

  final int bp, boost;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('BP', style: TextStyle(color: HudColors.textDim, fontSize: 9)),
          const SizedBox(height: 2),
          Row(
            children: [
              for (var i = 0; i < BattleRules.maxBp; i++)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(left: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < boost
                        ? HudColors.emberHot
                        : i < bp
                            ? HudColors.ember
                            : const Color(0xFF3A3346),
                  ),
                ),
            ],
          ),
        ],
      );
}
