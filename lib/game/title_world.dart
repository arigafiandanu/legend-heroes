import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/constants.dart';
import 'ashen_crest_game.dart';

/// Backdrop behind the title menu: dusk sky with rising embers.
class TitleWorld extends World with HasGameReference<AshenCrestGame> {
  final _random = Random(3);
  final List<_Ember> _embers = [];
  static final _glow = Paint()
    ..color = const Color(0x55FF8A3D)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < 40; i++) {
      _embers.add(_Ember(_random, Screen.virtualWidth, Screen.virtualHeight, scatter: true));
    }
  }

  @override
  void onMount() {
    super.onMount();
    game.camera
      ..stop()
      ..setBounds(null)
      ..viewfinder.position = Vector2(Screen.virtualWidth / 2, Screen.virtualHeight / 2);
  }

  @override
  void update(double dt) {
    for (final e in _embers) {
      e.update(dt, _random);
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(const Rect.fromLTRB(-400, -300, 880, 570), Paint()..color = const Color(0xFF15111C));
    canvas.drawCircle(const Offset(240, 250), 120, _glow);
    for (final e in _embers) {
      canvas.drawRect(Rect.fromLTWH(e.x, e.y, 2, 2), Paint()..color = Color.fromRGBO(255, 150 + (e.heat * 80).toInt(), 60, e.alpha));
    }
  }
}

class _Ember {
  _Ember(Random r, this.w, this.h, {bool scatter = false}) {
    _reset(r, scatter);
  }

  final double w, h;
  late double x, y, vy, drift, heat, alpha;

  void _reset(Random r, bool scatter) {
    x = r.nextDouble() * w;
    y = scatter ? r.nextDouble() * h : h + 4;
    vy = 8 + r.nextDouble() * 18;
    drift = (r.nextDouble() - 0.5) * 8;
    heat = r.nextDouble();
    alpha = 0.4 + r.nextDouble() * 0.6;
  }

  void update(double dt, Random r) {
    y -= vy * dt;
    x += drift * dt;
    if (y < -4) _reset(r, false);
  }
}
