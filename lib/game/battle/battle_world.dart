import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';

import '../../core/constants.dart';
import '../../core/l10n/gen/app_localizations.dart';
import '../../data/game_data.dart';
import '../../domain/battle/battle_action.dart';
import '../../domain/battle/battle_event.dart';
import '../../presentation/battle/battle_cubit.dart';
import '../ashen_crest_game.dart';
import '../character_sprite.dart';
import 'enemy_placeholder.dart';
import 'popup_text.dart';

/// Placeholder battle scene. Plays back engine events as simple animations.
/// Layout is in the 480×270 virtual space; wider screens see more backdrop.
class BattleWorld extends World with HasGameReference<AshenCrestGame> {
  BattleWorld({required this.cubit, required this.data, required this.l10n});

  final BattleCubit cubit;
  final GameData data;
  final AppLocalizations l10n;

  final Map<String, EnemyPlaceholder> _enemies = {};
  final Map<String, CharacterSprite> _party = {};
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
    add(_Backdrop());
    final enemies = cubit.engine.enemies;
    final slots = _enemySlots[enemies.length.clamp(1, 4) - 1];
    for (var i = 0; i < enemies.length; i++) {
      final u = enemies[i];
      final def = data.enemies[u.id.split('#').first]!;
      final c = _enemies[u.id] = EnemyPlaceholder(
        unit: u,
        color: Color(def.color),
        position: slots[i % slots.length].toVector2(),
      )..priority = slots[i % slots.length].dy.toInt();
      _home[u.id] = c.position.clone();
    }
    final party = cubit.engine.party;
    for (var i = 0; i < party.length; i++) {
      final u = party[i];
      final c = _party[u.id] = CharacterSprite(
        sheetPath: data.characters[u.id]!.sheet,
        facing: Facing.left,
        position: _partySlots[i].toVector2(),
      )..priority = _partySlots[i].dy.toInt();
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
        await _wait(450);
      case DamageDealt(:final targetId, :final amount, :final weakness, :final hpAfter):
        cubit.onEventPlayed(e);
        final view = _view(targetId)!;
        final enemy = _enemies[targetId];
        if (enemy != null) {
          enemy
            ..hpRatio = hpAfter / enemy.unit.stats.hp
            ..shake();
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
        if (enemy != null) {
          enemy.defeat();
        } else {
          _party[unitId]?.add(OpacityEffect.to(0.35, EffectController(duration: 0.3)));
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
