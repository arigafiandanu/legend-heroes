import 'dart:math';

enum Danger { low, medium, high }

/// Distance-based random encounters: walk a random distance between
/// [minDistance] and [maxDistance], then a battle starts.
class EncounterMeter {
  EncounterMeter({required Random random, required this.minDistance, required this.maxDistance})
      : _random = random {
    _roll();
  }

  final Random _random;
  final double minDistance;
  final double maxDistance;
  double traveled = 0;
  late double threshold;
  double _safe = 0;

  Danger get danger {
    final ratio = traveled / threshold;
    return ratio < 0.5 ? Danger.low : ratio < 0.8 ? Danger.medium : Danger.high;
  }

  bool get isSafe => _safe > 0;

  /// No encounters for [seconds] (spec: 3 s after every battle).
  void startSafePeriod([double seconds = 3]) => _safe = seconds;

  /// Adds [distance] walked during [dt]; true when an encounter triggers.
  bool advance(double distance, double dt) {
    if (_safe > 0) {
      if (dt <= _safe) {
        _safe -= dt;
        return false;
      }
      distance *= (dt - _safe) / dt;
      _safe = 0;
    }
    traveled += distance;
    if (traveled < threshold) return false;
    traveled = 0;
    _roll();
    return true;
  }

  void _roll() => threshold = minDistance + _random.nextDouble() * (maxDistance - minDistance);
}

class EncounterGroup {
  const EncounterGroup(this.weight, this.enemies);
  final int weight;
  final List<String> enemies;
}

class EncounterTable {
  const EncounterTable({required this.minDistance, required this.maxDistance, required this.groups});

  factory EncounterTable.fromJson(Map<String, dynamic> json) => EncounterTable(
        minDistance: (json['minDistance'] as num).toDouble(),
        maxDistance: (json['maxDistance'] as num).toDouble(),
        groups: [
          for (final g in json['groups'] as List)
            EncounterGroup(g['weight'] as int, List<String>.from(g['enemies'] as List)),
        ],
      );

  final double minDistance;
  final double maxDistance;
  final List<EncounterGroup> groups;

  List<String> pick(Random random) {
    final total = groups.fold(0, (sum, g) => sum + g.weight);
    var roll = random.nextDouble() * total;
    for (final g in groups) {
      if (roll < g.weight) return g.enemies;
      roll -= g.weight;
    }
    return groups.last.enemies;
  }
}
