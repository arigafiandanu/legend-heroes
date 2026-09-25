import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/constants.dart';
import '../../core/l10n/gen/app_localizations.dart';
import '../../data/game_data.dart';
import '../../domain/battle/battle_action.dart';
import '../../domain/battle/battle_event.dart';
import '../../presentation/battle/battle_cubit.dart';
import '../ashen_crest_game.dart';
import '../character_sprite.dart';
import 'battle_sheet.dart';
import 'enemy_view.dart';
import 'party_view.dart';
import 'popup_text.dart';

/// Battle scene. Plays back engine events as animations.
/// Layout is in the 480×270 virtual space; wider screens see more backdrop.
class BattleWorld extends World with HasGameReference<AshenCrestGame> {
  BattleWorld({required this.cubit, required this.data, required this.l10n, this.backdrop});

  final BattleCubit cubit;
  final GameData data;
  final AppLocalizations l10n;

  /// Area backdrop (`assets/images/backdrops/<name>.png`), or null for the
  /// procedural placeholder.
  final String? backdrop;

  final Map<String, EnemyView> _enemies = {};
  final Map<String, PositionComponent> _party = {};
  final Map<String, Vector2> _home = {};
  StreamSubscription<List<BattleEvent>>? _sub;
  bool _started = false;

  // Feet positions. Kept in the upper ~60% of the 480×270 space because the
  // Flutter HUD (command menu bottom-left, party panel bottom-right) covers
  // the bottom band on 16:9 phones.
  static const _enemySlots = [
    [Offset(170, 125)],
    [Offset(185, 105), Offset(115, 140)],
    [Offset(205, 84), Offset(115, 118), Offset(205, 152)],
    [Offset(190, 90), Offset(115, 105), Offset(195, 135), Offset(120, 150)],
  ];
  static const _partySlots = [Offset(370, 105), Offset(405, 148)];

  @override
  Future<void> onLoad() async {
    final bg = backdrop;
    add(bg == null ? _Backdrop() : _ImageBackdrop(await game.images.load('backdrops/$bg.png')));
    final enemies = cubit.engine.enemies;
    final slots = _enemySlots[enemies.length.clamp(1, 4) - 1];
    final sheets = <String, BattleSheet>{};
    Future<BattleSheet?> sheet(String? sprite) async {
      if (sprite == null) return null;
      return sheets[sprite] ??= BattleSheet(
        await game.images.load('$sprite.png'),
        BattleSheetMeta.parse(await (game.bundle ?? rootBundle).loadString('assets/images/$sprite.json')),
      );
    }

    for (var i = 0; i < enemies.length; i++) {
      final u = enemies[i];
      final def = data.enemies[u.id.split('#').first]!;
      final c = _enemies[u.id] = EnemyView(
        unit: u,
        color: Color(def.color),
        sheet: await sheet(def.sprite),
        position: slots[i % slots.length].toVector2(),
      )..priority = slots[i % slots.length].dy.toInt();
      _home[u.id] = c.position.clone();
    }
    final party = cubit.engine.party;
    for (var i = 0; i < party.length; i++) {
      final u = party[i];
      final def = data.characters[u.id]!;
      final battleSheet = await sheet(def.battleSprite);
      final pos = _partySlots[i].toVector2();
      final c = _party[u.id] = (battleSheet != null
          ? PartyView(sheet: battleSheet, position: pos)
          : CharacterSprite(sheetPath: def.sheet, facing: Facing.left, position: pos))
        ..priority = _partySlots[i].dy.toInt();
      _home[u.id] = c.position.clone();
    }
    await addAll([..._enemies.values, ..._party.values]);
    _sub = cubit.playback.listen(_playBatch);
  }

  @override
  void onMount() {
    super.onMount();
    game.camera
      ..stop()
      ..setBounds(null)
      ..viewfinder.position = Vector2(Screen.virtualWidth / 2, Screen.virtualHeight / 2);
    if (!_started) {
      _started = true;
      cubit.start();
    }
  }

  @override
  void onRemove() {
    _sub?.cancel();
    super.onRemove();
  }

  PositionComponent? _view(String id) => _enemies[id] ?? _party[id];

  Future<void> _playBatch(List<BattleEvent> events) async {
    for (final e in events) {
      if (!isMounted || cubit.isClosed) return;
      await _playEvent(e);
    }
    if (!cubit.isClosed) cubit.playbackDone();
  }

  Future<void> _wait(int ms) => Future.delayed(Duration(milliseconds: ms));

  Future<void> _playEvent(BattleEvent e) async {
    switch (e) {
      case BattleStarted():
        cubit.onEventPlayed(e);
        await _wait(350);
      case RoundStarted():
        cubit.onEventPlayed(e);
        await _wait(150);
      case TurnStarted(:final unitId):
        _stepBackAll();
        cubit
          ..onEventPlayed(e)
          ..announce(null);
        final v = _party[unitId];
        if (v != null) {
          v.add(MoveToEffect(_home[unitId]! + Vector2(-14, 0), EffectController(duration: 0.15)));
        }
        await _wait(v != null ? 180 : 250);
      case ActionAnnounced(:final unitId, :final action):
        cubit
          ..onEventPlayed(e)
          ..announce('${cubit.engine.unit(unitId).name} · ${_actionLabel(action)}');
        final enemy = _enemies[unitId];
        final member = _party[unitId];
        final clip = switch (action) {
          AttackAction() => 'attack',
          SkillAction(:final skill) => skill.isPhysical ? 'attack' : 'cast',
          ItemAction() => 'cast',
          _ => null,
        };
        if (enemy != null && (action is AttackAction || action is SkillAction)) {
          await _wait(300); // time to read the announcement
          await enemy.attack(); // damage shows as the blow lands
        } else if (member is PartyView && clip != null) {
          await _wait(300);
          await member.act(clip);
        } else {
          await _wait(450);
        }
      case DamageDealt(:final targetId, :final amount, :final weakness, :final hpAfter):
        cubit.onEventPlayed(e);
        final view = _view(targetId)!;
        final enemy = _enemies[targetId];
        if (enemy != null) {
          enemy
            ..hpRatio = hpAfter / enemy.unit.stats.hp
            ..hit();
        } else if (view is PartyView) {
          view.hit();
        } else {
          _shakeParty(view);
        }
        final top = view.position - Vector2(0, view.size.y + 8);
        add(PopupText('$amount',
            position: top, color: weakness ? const Color(0xFFFFD34E) : const Color(0xFFFFFFFF)));
        if (weakness) {
          add(PopupText(l10n.weakText, position: top - Vector2(0, 11), color: const Color(0xFFFFD34E), fontSize: 7));
        }
        await _wait(300);
      case ItemUsed():
        cubit.onEventPlayed(e);
        await _wait(150);
      case Revived(:final unitId, :final hp):
        cubit.onEventPlayed(e);
        final view = _party[unitId];
        if (view != null) {
          if (view is PartyView) view.revive();
          view.add(OpacityEffect.to(1, EffectController(duration: 0.3)));
          add(PopupText('+$hp', position: view.position - Vector2(0, view.size.y + 8), color: const Color(0xFF7CE38B)));
        }
        await _wait(450);
      case Healed(:final targetId, :final amount):
        cubit.onEventPlayed(e);
        final view = _view(targetId)!;
        add(PopupText('+$amount', position: view.position - Vector2(0, view.size.y + 8), color: const Color(0xFF7CE38B)));
        await _wait(350);
      case WeaknessRevealed(:final unitId, :final type):
        cubit.onEventPlayed(e);
        _enemies[unitId]?.revealed.add(type);
        await _wait(120);
      case ShieldReduced(:final unitId, :final shield):
        cubit.onEventPlayed(e);
        _enemies[unitId]?.shield = shield;
        await _wait(80);
      case BreakStarted(:final unitId):
        cubit.onEventPlayed(e);
        final enemy = _enemies[unitId]!..broken = true;
        add(PopupText(l10n.breakText,
            position: enemy.position - Vector2(0, enemy.size.y / 2), color: const Color(0xFFFF8A3D), fontSize: 14));
        await _wait(550);
      case BreakRecovered(:final unitId, :final shield):
        cubit.onEventPlayed(e);
        _enemies[unitId]
          ?..broken = false
          ..shield = shield;
        await _wait(250);
      case DefendStarted():
        cubit.onEventPlayed(e);
        await _wait(200);
      case UnitDefeated(:final unitId):
        cubit.onEventPlayed(e);
        final enemy = _enemies[unitId];
        final member = _party[unitId];
        if (enemy != null) {
          enemy.defeat();
        } else if (member is PartyView) {
          member.knockOut();
        } else {
          member?.add(OpacityEffect.to(0.35, EffectController(duration: 0.3)));
        }
        await _wait(420);
      case EscapeFailed():
        cubit
          ..onEventPlayed(e)
          ..announce(l10n.escapeFailed);
        await _wait(600);
      case BpChanged() || SpChanged() || Escaped() || Victory() || Defeat():
        cubit.onEventPlayed(e);
        if (e is Victory || e is Defeat || e is Escaped) {
          _stepBackAll();
          await _wait(300);
        }
    }
  }

  String _actionLabel(BattleAction action) => switch (action) {
        AttackAction() => l10n.cmdAttack,
        SkillAction(:final skill) => skill.name(l10n.localeName),
        DefendAction() => l10n.cmdDefend,
        FleeAction() => l10n.cmdFlee,
        ItemAction(:final itemId) => data.items[itemId]?.name(l10n.localeName) ?? itemId,
      };

  void _stepBackAll() {
    for (final entry in _party.entries) {
      final home = _home[entry.key]!;
      if (entry.value.position != home) {
        entry.value.add(MoveToEffect(home, EffectController(duration: 0.15)));
      }
    }
  }

  void _shakeParty(PositionComponent view) => view.add(SequenceEffect([
        MoveByEffect(Vector2(4, 0), EffectController(duration: 0.05)),
        MoveByEffect(Vector2(-4, 0), EffectController(duration: 0.08)),
      ]));
}

/// Dark forest-clearing backdrop, oversized so wide screens see no edges.
class _Backdrop extends Component {
  _Backdrop() : super(priority: -100000);

  static final _sky = Paint()..color = const Color(0xFF1E2A2A);
  static final _trees = Paint()..color = const Color(0xFF16201F);
  static final _ground = Paint()..color = const Color(0xFF3B4A33);
  static final _groundLight = Paint()..color = const Color(0xFF45563B);

  @override
  void render(Canvas canvas) {
    canvas
      ..drawRect(const Rect.fromLTRB(-600, -400, 1080, 95), _sky)
      ..drawRect(const Rect.fromLTRB(-600, 95, 1080, 700), _ground)
      ..drawOval(const Rect.fromLTRB(40, 70, 460, 190), _groundLight);
    for (var x = -600.0; x < 1080; x += 26) {
      final h = 40 + (x * 7 % 23);
      canvas.drawRect(Rect.fromLTWH(x, 95 - h, 22, h), _trees);
    }
  }
}

/// Area backdrop image repeated sideways; above and below it (tall screens)
/// continue with its top and bottom colours.
class _ImageBackdrop extends Component {
  _ImageBackdrop(this.image) : super(priority: -100000);

  final Image image;
  static final _paint = Paint()..filterQuality = FilterQuality.none;
  static final _top = Paint()..color = const Color(0xFF1E1828);
  static final _bottom = Paint()..color = const Color(0xFF306242);

  @override
  void render(Canvas canvas) {
    final w = image.width.toDouble(), h = image.height.toDouble();
    canvas
      ..drawRect(Rect.fromLTRB(-1200, -400, 1680, 0), _top)
      ..drawRect(Rect.fromLTRB(-1200, h, 1680, h + 400), _bottom);
    for (var x = -w * 2; x < 1680; x += w) {
      canvas.drawImage(image, Offset(x, 0), _paint);
    }
  }
}
