import 'dart:ui';

import 'package:flame/components.dart';

import 'battle_sheet.dart';

/// A party member in battle drawn from their battle sheet: idle, attack,
/// cast, hit and KO (lying down until revived).
class PartyView extends PositionComponent with HasPaint {
  PartyView({required this.sheet, super.position})
      : _anim = AnimPlayback(sheet.meta),
        super(size: Vector2.all(sheet.meta.size), anchor: Anchor.bottomCenter);

  final BattleSheet sheet;
  final AnimPlayback _anim;
  double _flash = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _anim.update(dt * 1000);
    if (_flash > 0) _flash -= dt;
  }

  @override
  void render(Canvas canvas) =>
      sheet.drawFrame(canvas, _anim, opacity: paint.color.a, filter: _flash > 0 ? BattleSheet.flash : null);

  /// Plays [clip] (`attack` or `cast`); completes when it lands.
  Future<void> act(String clip) {
    _anim.play(clip);
    final c = _anim.clip;
    return Future.delayed(Duration(milliseconds: c.msUntil(c.contact ?? 0)));
  }

  void hit() {
    _anim.play('hit');
    _flash = 0.07;
  }

  void knockOut() => _anim.play('ko');

  void revive() => _anim.play('idle');
}
