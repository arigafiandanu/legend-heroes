import 'dart:io';

import 'package:flame_audio/flame_audio.dart';

/// Background music. iOS cannot play Ogg, so it gets the AAC copies.
class Bgm {
  Bgm({this.enabled = true});

  bool enabled;
  String? current;

  static String get _ext => Platform.isIOS || Platform.isMacOS ? 'm4a' : 'ogg';

  Future<void> init() async {
    if (enabled) FlameAudio.bgm.initialize();
  }

  Future<void> play(String name, {double volume = 0.6}) async {
    if (!enabled || name == current) return;
    current = name;
    await FlameAudio.bgm.play('bgm/$name.$_ext', volume: volume);
  }

  Future<void> stop() async {
    current = null;
    if (enabled) await FlameAudio.bgm.stop();
  }
}
