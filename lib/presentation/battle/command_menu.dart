import 'package:flutter/material.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../domain/skill.dart';
import '../l10n_names.dart';
import '../theme.dart';
import 'battle_cubit.dart';
import 'battle_state.dart';

/// Party command panel: Boost selector + Attack / Skill / Item / Defend /
/// Flee, with weapon, skill and target sub-menus.
class CommandMenu extends StatelessWidget {
  const CommandMenu({super.key, required this.cubit, required this.state});

  final BattleCubit cubit;
  final BattleViewState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actor = cubit.actor!;
    return Container(
      width: 270,
      padding: const EdgeInsets.all(8),
      decoration: hudPanel(highlight: true),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(actor.name,
                  style: const TextStyle(color: HudColors.ember, fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              _BoostSelector(cubit: cubit, boost: state.boost, label: l10n.boostTitle),
            ],
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 140),
            child: SingleChildScrollView(child: _page(context, l10n)),
          ),
        ],
      ),
    );
  }

  Widget _page(BuildContext context, AppLocalizations l10n) {
    final actor = cubit.actor!;
    switch (state.menu) {
      case BattleMenu.root:
        return _Grid(columns: 3, children: [
          _Cmd(l10n.cmdAttack, onTap: cubit.openAttack),
          _Cmd(l10n.cmdSkill, onTap: actor.skills.isEmpty ? null : cubit.openSkills),
          _Cmd(l10n.cmdItem), // inventory arrives in M2
          _Cmd(l10n.cmdDefend, onTap: cubit.defend),
          _Cmd(l10n.cmdFlee, onTap: cubit.canFlee ? cubit.flee : null),
        ]);
      case BattleMenu.weapons:
        return _Grid(children: [
          for (final w in actor.weapons) _Cmd(w.label(l10n), onTap: () => cubit.chooseWeapon(w)),
          _Cmd(l10n.cmdBack, onTap: cubit.back, subtle: true),
        ]);
      case BattleMenu.skills:
        return Column(children: [
          for (final s in actor.skills)
            _Cmd(
              s.name(l10n.localeName),
              trailing: l10n.spCost(s.spCost),
              detail: _skillDetail(s, l10n),
              onTap: cubit.canUse(s) ? () => cubit.chooseSkill(s) : null,
            ),
          _Cmd(l10n.cmdBack, onTap: cubit.back, subtle: true),
        ]);
      case BattleMenu.targets:
        return _Grid(children: [
          for (final t in cubit.targets)
            _Cmd(t.name, trailing: '${cubit.shownHp(t.id)}', onTap: () => cubit.chooseTarget(t.id)),
          _Cmd(l10n.cmdBack, onTap: cubit.back, subtle: true),
        ]);
    }
  }

  String _skillDetail(Skill s, AppLocalizations l10n) =>
      s.types.map((t) => t.label(l10n)).join(' · ');
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children, this.columns = 2});

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final child in children)
              SizedBox(width: (c.maxWidth - 6 * (columns - 1)) / columns, child: child),
          ],
        ),
      );
}

class _Cmd extends StatelessWidget {
  const _Cmd(this.label, {this.onTap, this.trailing, this.detail, this.subtle = false});

  final String label;
  final String? trailing;
  final String? detail;
  final VoidCallback? onTap;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: subtle ? Colors.transparent : const Color(0xFF2A2436),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                            color: enabled ? HudColors.text : HudColors.textDim.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          )),
                      if (detail != null && detail!.isNotEmpty)
                        Text(detail!, style: const TextStyle(color: HudColors.textDim, fontSize: 10)),
                    ],
                  ),
                ),
                if (trailing != null)
                  Text(trailing!, style: const TextStyle(color: HudColors.sp, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BoostSelector extends StatelessWidget {
  const _BoostSelector({required this.cubit, required this.boost, required this.label});

  final BattleCubit cubit;
  final int boost;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: HudColors.textDim, fontSize: 11)),
          _RoundIcon(icon: Icons.remove, onTap: boost > 0 ? () => cubit.changeBoost(-1) : null),
          SizedBox(
            width: 22,
            child: Text('$boost',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: boost > 0 ? HudColors.emberHot : HudColors.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                )),
          ),
          _RoundIcon(icon: Icons.add, onTap: boost < cubit.maxBoost ? () => cubit.changeBoost(1) : null),
        ],
      );
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        color: HudColors.ember,
        disabledColor: HudColors.panelBorder,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(backgroundColor: const Color(0xFF2A2436)),
      );
}
