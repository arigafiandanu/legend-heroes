import 'package:flutter/material.dart';

/// Placeholder HUD palette (ember on dusk) until the UI art set exists.
abstract final class HudColors {
  static const panel = Color(0xE6181520);
  static const panelBorder = Color(0xFF3D3550);
  static const text = Color(0xFFEDE7DA);
  static const textDim = Color(0xFF9D95AD);
  static const ember = Color(0xFFE8A23A);
  static const emberHot = Color(0xFFFF7A2E);
  static const hp = Color(0xFF6CCB7A);
  static const hpLow = Color(0xFFE0564F);
  static const sp = Color(0xFF5FA8E8);
  static const party = Color(0xFF3F6FB5);
  static const enemy = Color(0xFFA2463B);
}

BoxDecoration hudPanel({bool highlight = false}) => BoxDecoration(
      color: HudColors.panel,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: highlight ? HudColors.ember : HudColors.panelBorder,
        width: highlight ? 2 : 1,
      ),
    );
