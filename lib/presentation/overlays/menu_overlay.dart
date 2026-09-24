import 'package:flutter/material.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../domain/item.dart';
import '../../domain/party_member.dart';
import '../../game/ashen_crest_game.dart';
import '../theme.dart';
import 'widgets.dart';

/// Field menu: party status and items. Equipment arrives in M4.
class MenuOverlay extends StatefulWidget {
  const MenuOverlay({super.key, required this.game});

  final AshenCrestGame game;

  @override
  State<MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<MenuOverlay> {
  int _tab = 0;
  ItemDef? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final game = widget.game;
    final state = game.state!;
    return ColoredBox(
      color: const Color(0xCC0B0910),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 190,
                child: Column(
                  children: [
                    MenuButton(label: l10n.menuParty, primary: _tab == 0, width: 190, onTap: () => setState(() => _tab = 0)),
                    const SizedBox(height: 8),
                    MenuButton(label: l10n.menuItems, primary: _tab == 1, width: 190, onTap: () => setState(() => _tab = 1)),
                    const Spacer(),
                    Text('${state.keping} Keping', style: const TextStyle(color: HudColors.ember, fontWeight: FontWeight.w800)),
                    Text(formatPlayTime(state.playSeconds), style: const TextStyle(color: HudColors.textDim)),
                    const SizedBox(height: 8),
                    MenuButton(label: l10n.menuQuitToTitle, width: 190, onTap: game.quitToTitle),
                    const SizedBox(height: 8),
                    MenuButton(label: l10n.menuClose, width: 190, onTap: game.closeMenu),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: hudPanel(),
                  child: _tab == 0 ? _party(l10n, state.party) : _items(l10n),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _party(AppLocalizations l10n, List<PartyMember> party) => ListView(
        children: [
          for (final m in party)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF221D2C), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(m.def.name, style: const TextStyle(color: HudColors.text, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 10),
                    Text(l10n.levelLabel(m.level), style: const TextStyle(color: HudColors.ember, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text(l10n.expToNext(m.expToNext - m.exp), style: const TextStyle(color: HudColors.textDim, fontSize: 12)),
                  ]),
                  const SizedBox(height: 6),
                  Text('HP ${m.hp}/${m.maxHp}   SP ${m.sp}/${m.maxSp}',
                      style: TextStyle(color: m.isKnockedOut ? HudColors.hpLow : HudColors.text, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    'ATK ${m.stats.atk}  DEF ${m.stats.def}  EATK ${m.stats.eatk}  EDEF ${m.stats.edef}  SPD ${m.stats.spd}',
                    style: const TextStyle(color: HudColors.textDim, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      );

  Widget _items(AppLocalizations l10n) {
    final game = widget.game;
    final state = game.state!;
    final lang = l10n.localeName;
    final entries = state.inventory.items.entries.where((e) => game.data.items.containsKey(e.key)).toList();
    if (entries.isEmpty) return Center(child: Text(l10n.noItems, style: const TextStyle(color: HudColors.textDim)));
    final selected = _selected;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            children: [
              for (final e in entries)
                _ItemRow(
                  item: game.data.items[e.key]!,
                  count: e.value,
                  lang: lang,
                  selected: selected?.id == e.key,
                  onTap: () => setState(() => _selected = game.data.items[e.key]),
                ),
            ],
          ),
        ),
        if (selected != null && selected.isConsumable) ...[
          const SizedBox(width: 12),
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.useOn, style: const TextStyle(color: HudColors.textDim)),
                const SizedBox(height: 6),
                for (final m in state.party) ...[
                  MenuButton(
                    width: 200,
                    label: '${m.def.name}  ${m.hp}/${m.maxHp}',
                    onTap: selected.canUseOn(m) && state.inventory.count(selected.id) > 0
                        ? () => setState(() {
                              selected.use(m);
                              state.inventory.remove(selected.id);
                              if (state.inventory.count(selected.id) == 0) _selected = null;
                            })
                        : null,
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.count, required this.lang, required this.selected, required this.onTap});

  final ItemDef item;
  final int count;
  final String lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? const Color(0x33E8A23A) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.name(lang), style: const TextStyle(color: HudColors.text, fontWeight: FontWeight.w700)),
                      Text(item.description(lang), style: const TextStyle(color: HudColors.textDim, fontSize: 11)),
                    ],
                  ),
                ),
                Text('×$count', style: const TextStyle(color: HudColors.ember, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      );
}
