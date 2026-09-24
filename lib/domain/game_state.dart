import 'attack_type.dart';
import 'character_def.dart';
import 'inventory.dart';
import 'party_member.dart';

/// Everything that persists between sessions. Serialised as a save file.
class GameState {
  GameState({
    required this.party,
    required this.mapId,
    this.x,
    this.y,
    this.facing = 'down',
    this.spawn,
    this.keping = 0,
    this.playSeconds = 0,
    Inventory? inventory,
    Set<String>? flags,
    Set<String>? openedChests,
    Map<String, Set<AttackType>>? bestiary,
  })  : inventory = inventory ?? Inventory(),
        flags = flags ?? {},
        openedChests = openedChests ?? {},
        bestiary = bestiary ?? {};

  /// Bumped whenever the save layout changes; older saves get migrated.
  static const saveVersion = 1;

  final List<PartyMember> party;
  String mapId;

  /// Player feet position on [mapId]; null means use [spawn].
  double? x;
  double? y;
  String facing;

  /// Named spawn point to use when [x]/[y] are null (new game, map exits).
  String? spawn;
  int keping;
  double playSeconds;
  final Inventory inventory;
  final Set<String> flags;
  final Set<String> openedChests;

  /// Weaknesses the player has discovered, per enemy id.
  final Map<String, Set<AttackType>> bestiary;

  void reveal(String enemyId, AttackType type) =>
      bestiary.putIfAbsent(enemyId, () => {}).add(type);

  Map<String, dynamic> toJson() => {
        'saveVersion': saveVersion,
        'mapId': mapId,
        'x': x,
        'y': y,
        'facing': facing,
        'spawn': spawn,
        'keping': keping,
        'playSeconds': playSeconds,
        'party': [for (final m in party) m.toJson()],
        'inventory': inventory.toJson(),
        'flags': flags.toList()..sort(),
        'openedChests': openedChests.toList()..sort(),
        'bestiary': {
          for (final e in bestiary.entries) e.key: [for (final t in e.value) t.name],
        },
      };

  static GameState fromJson(Map<String, dynamic> json, Map<String, CharacterDef> characters) {
    final version = json['saveVersion'];
    if (version is! int) throw const FormatException('Missing saveVersion');
    if (version > saveVersion) {
      throw FormatException('Save version $version is newer than supported $saveVersion');
    }
    return GameState(
      party: [
        for (final m in json['party'] as List)
          PartyMember.fromJson(m as Map<String, dynamic>, characters[m['id']]!),
      ],
      mapId: json['mapId'] as String,
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
      facing: json['facing'] as String? ?? 'down',
      spawn: json['spawn'] as String?,
      keping: json['keping'] as int? ?? 0,
      playSeconds: (json['playSeconds'] as num? ?? 0).toDouble(),
      inventory: Inventory.fromJson(json['inventory'] as Map<String, dynamic>? ?? const {}),
      flags: {...List<String>.from(json['flags'] as List? ?? const [])},
      openedChests: {...List<String>.from(json['openedChests'] as List? ?? const [])},
      bestiary: {
        for (final e in (json['bestiary'] as Map? ?? const {}).entries)
          e.key as String: {
            for (final t in e.value as List) AttackType.values.byName(t as String),
          },
      },
    );
  }
}
