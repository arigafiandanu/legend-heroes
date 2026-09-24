import 'dart:math';

/// Deterministic [Random] for tests.
///
/// [nextDouble] returns [doubles] in order (repeating the last one), so
/// `0.5` makes every variance roll exactly neutral (0.95–1.05 → 1.0,
/// 0.9–1.1 → 1.0). [nextInt] returns [ints] the same way, clamped to max.
class FixedRandom implements Random {
  FixedRandom({List<double>? doubles, List<int>? ints})
      : _doubles = doubles ?? const [0.5],
        _ints = ints ?? const [0];

  final List<double> _doubles;
  final List<int> _ints;
  int _d = 0;
  int _i = 0;

  @override
  double nextDouble() =>
      _doubles[_d < _doubles.length ? _d++ : _doubles.length - 1];

  @override
  int nextInt(int max) {
    final v = _ints[_i < _ints.length ? _i++ : _ints.length - 1];
    return v.clamp(0, max - 1);
  }

  @override
  bool nextBool() => nextDouble() < 0.5;
}
