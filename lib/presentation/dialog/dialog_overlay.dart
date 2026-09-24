import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme.dart';
import 'dialog_cubit.dart';

/// Bottom dialog box. Text types out; tap to finish the line or continue,
/// hold to type faster. Choices appear as big buttons.
class DialogOverlay extends StatelessWidget {
  const DialogOverlay({super.key, required this.cubit});

  final DialogCubit cubit;

  @override
  Widget build(BuildContext context) => BlocBuilder<DialogCubit, DialogViewState>(
        bloc: cubit,
        builder: (context, s) {
          if (!s.active || (s.text.isEmpty && s.choices.isEmpty)) return const SizedBox.shrink();
          return SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _TypingBox(key: ValueKey(s.text), state: s, cubit: cubit),
                ),
              ],
            ),
          );
        },
      );
}

class _TypingBox extends StatefulWidget {
  const _TypingBox({super.key, required this.state, required this.cubit});

  final DialogViewState state;
  final DialogCubit cubit;

  @override
  State<_TypingBox> createState() => _TypingBoxState();
}

class _TypingBoxState extends State<_TypingBox> {
  static const _charsPerSecond = 45;
  Timer? _timer;
  int _shown = 0;
  bool _fast = false;

  String get _text => widget.state.text;
  bool get _done => _shown >= _text.length;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1000 ~/ _charsPerSecond), (_) {
      if (_done) return;
      setState(() => _shown = (_shown + (_fast ? 4 : 1)).clamp(0, _text.length));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tap() {
    if (widget.state.choices.isNotEmpty) return;
    if (_done) {
      widget.cubit.advance();
    } else {
      setState(() => _shown = _text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      onLongPressStart: (_) => _fast = true,
      onLongPressEnd: (_) => _fast = false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (s.choices.isNotEmpty && _done)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < s.choices.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _ChoiceButton(label: s.choices[i], onTap: () => widget.cubit.choose(i)),
                        ),
                    ],
                  ),
                ),
              Container(
                constraints: const BoxConstraints(maxWidth: 720, minHeight: 96),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                decoration: hudPanel(highlight: true),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (s.speaker != null)
                      Text(s.speaker!,
                          style: const TextStyle(color: HudColors.ember, fontWeight: FontWeight.w800, fontSize: 15)),
                    if (s.speaker != null) const SizedBox(height: 4),
                    Text(_text.substring(0, _shown),
                        style: const TextStyle(color: HudColors.text, fontSize: 16, height: 1.35)),
                    if (_done && s.choices.isEmpty)
                      const Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(Icons.arrow_drop_down, color: HudColors.ember),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: HudColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: HudColors.ember),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 220, minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            alignment: Alignment.centerLeft,
            child: Text(label, style: const TextStyle(color: HudColors.text, fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      );
}
