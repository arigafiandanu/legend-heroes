import 'dart:math';

import 'constants.dart';

/// Camera zoom so one virtual pixel covers a whole number of *physical*
/// pixels, fitting [Screen.virtualHeight] rows on screen.
///
/// Wider-than-16:9 screens show extra world horizontally instead of bars.
double pixelZoom({
  required double logicalHeight,
  required double devicePixelRatio,
}) {
  final physical = logicalHeight * devicePixelRatio;
  final scale = max(1, (physical / Screen.virtualHeight + 1e-6).floor());
  return scale / devicePixelRatio;
}
