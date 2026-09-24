import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/character_def.dart';
import '../domain/game_state.dart';

class SaveSummary {
  const SaveSummary({
    required this.slot,
    required this.mapId,
    required this.leadLevel,
    required this.playSeconds,
    required this.savedAt,
  });

  final int slot;
  final String mapId;
  final int leadLevel;
  final double playSeconds;
  final DateTime savedAt;
}

/// JSON save files in the app documents folder: slot 0 = auto-save,
/// slots 1–3 = manual saves at campfires.
class SaveRepository {
  SaveRepository(this.directory);

  static const autoSlot = 0;
  static const manualSlots = [1, 2, 3];
  static const allSlots = [autoSlot, ...manualSlots];

  final Directory directory;

  static Future<SaveRepository> inAppDocuments() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/saves');
    await dir.create(recursive: true);
    return SaveRepository(dir);
  }

  File _file(int slot) => File('${directory.path}/slot_$slot.json');

  Future<void> save(int slot, GameState state) async {
    final json = {...state.toJson(), 'savedAt': DateTime.now().toIso8601String()};
    final tmp = File('${_file(slot).path}.tmp');
    await tmp.writeAsString(jsonEncode(json), flush: true);
    await tmp.rename(_file(slot).path);
  }

  Future<Map<String, dynamic>?> _read(int slot) async {
    final f = _file(slot);
    if (!await f.exists()) return null;
    try {
      return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  Future<GameState?> load(int slot, Map<String, CharacterDef> characters) async {
    final json = await _read(slot);
    if (json == null) return null;
    try {
      return GameState.fromJson(json, characters);
    } on FormatException {
      return null;
    }
  }

  Future<SaveSummary?> summary(int slot) async {
    final json = await _read(slot);
    if (json == null) return null;
    final party = json['party'] as List? ?? const [];
    return SaveSummary(
      slot: slot,
      mapId: json['mapId'] as String? ?? '',
      leadLevel: party.isEmpty ? 1 : (party.first as Map)['level'] as int,
      playSeconds: (json['playSeconds'] as num? ?? 0).toDouble(),
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime(2000),
    );
  }

  Future<int?> latestSlot() async {
    SaveSummary? latest;
    for (final slot in allSlots) {
      final s = await summary(slot);
      if (s != null && (latest == null || s.savedAt.isAfter(latest.savedAt))) latest = s;
    }
    return latest?.slot;
  }
}
