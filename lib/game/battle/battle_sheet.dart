import 'dart:convert';
import 'dart:ui';

/// One animation row of a battle sheet (written by tools/art/enemies.py).
class AnimClip {
  const AnimClip({
    required this.row,
    required this.ms,
    required this.offsets,
    this.loop = false,
    this.contact,
  });

  factory AnimClip.fromJson(Map<String, dynamic> json) => AnimClip(
        row: json['row'] as int,
        loop: json['loop'] as bool? ?? false,
        ms: [for (final v in json['ms'] as List) v as int],
        offsets: [
          for (final o in json['offsets'] as List) Offset((o[0] as num).toDouble(), (o[1] as num).toDouble()),
        ],
        contact: json['contact'] as int?,
      );

  final int row;
  final bool loop;

  /// Duration of each frame.
  final List<int> ms;

  /// Where the engine moves the sprite on each frame (+x = toward the party).
  final List<Offset> offsets;

  /// Frame on which an attack lands.
  final int? contact;

  int get frames => ms.length;
  int get totalMs => ms.fold(0, (a, b) => a + b);

  /// Time from the clip's start until [frame] begins.
  int msUntil(int frame) => ms.take(frame).fold(0, (a, b) => a + b);

  /// Frame shown [t] ms after the clip started (wraps if looping, else holds the last).
  int frameAt(double t) {
    var left = loop ? t % totalMs : t;
    for (var i = 0; i < frames; i++) {
      if (left < ms[i]) return i;
      left -= ms[i];
    }
    return frames - 1;
  }
}

/// Square battle sheet: one row per animation, one column per frame.
class BattleSheetMeta {
  const BattleSheetMeta({required this.size, required this.anims, double? shadowX}) : shadowX = shadowX ?? size / 2;

  factory BattleSheetMeta.parse(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    return BattleSheetMeta(
      size: (m['size'] as num).toDouble(),
      shadowX: (m['shadowX'] as num?)?.toDouble(),
      anims: {
        for (final e in (m['anims'] as Map<String, dynamic>).entries)
          e.key: AnimClip.fromJson(e.value as Map<String, dynamic>),
      },
    );
  }

  final double size;
  final Map<String, AnimClip> anims;

  /// Centre of the ground shadow within the frame (the feet).
  final double shadowX;
}

/// Which frame of which clip to show. One-shot clips fall back to `idle`
/// when they end, except `ko`, which holds its last frame.
class AnimPlayback {
  AnimPlayback(this.meta) : assert(meta.anims.containsKey('idle'));

  final BattleSheetMeta meta;
  String _name = 'idle';
  double _t = 0;

  String get name => _name;
  AnimClip get clip => meta.anims[_name]!;
  int get frame => clip.frameAt(_t);
  Offset get offset => clip.offsets[frame];

  /// Starts [name] from its first frame; unknown names are ignored.
  void play(String name) {
    if (!meta.anims.containsKey(name)) return;
    _name = name;
    _t = 0;
  }

  void update(double dtMs) {
    _t += dtMs;
    if (!clip.loop && _t >= clip.totalMs && _name != 'ko') play('idle');
  }
}

/// A loaded battle sheet (image + metadata) that draws its current frame.
class BattleSheet {
  BattleSheet(this.image, this.meta);

  final Image image;
  final BattleSheetMeta meta;

  /// One-frame white hit flash (art bible §9).
  static const flash = ColorFilter.mode(Color(0xFFFFFFFF), BlendMode.srcATop);
  static final _shadow = Paint();

  /// Draws [anim]'s frame into a size×size box at the local origin, moved by
  /// the clip's offset. The ground shadow only follows it sideways, so a
  /// falling flyer drops onto its shadow.
  void drawFrame(Canvas canvas, AnimPlayback anim, {double opacity = 1, ColorFilter? filter}) {
    final s = meta.size;
    final off = anim.offset;
    _shadow.color = Color.fromRGBO(0, 0, 0, 0.35 * opacity);
    canvas.drawOval(Rect.fromCenter(center: Offset(off.dx + meta.shadowX, s - 2), width: s * 0.6, height: 6), _shadow);
    final p = Paint()
      ..filterQuality = FilterQuality.none
      ..color = Color.fromRGBO(255, 255, 255, opacity)
      ..colorFilter = filter;
    canvas.drawImageRect(
        image, Rect.fromLTWH(anim.frame * s, anim.clip.row * s, s, s), Rect.fromLTWH(off.dx, off.dy, s, s), p);
  }
}
