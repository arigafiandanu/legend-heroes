import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

class DialogViewState {
  const DialogViewState({this.active = false, this.speaker, this.text = '', this.choices = const []});

  final bool active;
  final String? speaker;
  final String text;

  /// Non-empty while the player must pick an option.
  final List<String> choices;
}

/// Current dialog line/choices for the Flutter dialog box. The Yarn runner
/// awaits [showLine]/[showChoices]; the widget calls [advance]/[choose].
class DialogCubit extends Cubit<DialogViewState> {
  DialogCubit() : super(const DialogViewState());

  Completer<void>? _line;
  Completer<int>? _choice;

  void begin() => emit(const DialogViewState(active: true));

  Future<void> showLine(String? speaker, String text) {
    _line = Completer<void>();
    emit(DialogViewState(active: true, speaker: speaker, text: text));
    return _line!.future;
  }

  Future<int> showChoices(List<String> options) {
    _choice = Completer<int>();
    emit(DialogViewState(active: true, speaker: state.speaker, text: state.text, choices: options));
    return _choice!.future;
  }

  void advance() {
    if (state.choices.isNotEmpty) return;
    final line = _line;
    _line = null;
    line?.complete();
  }

  void choose(int index) {
    final choice = _choice;
    if (choice == null) return;
    _choice = null;
    emit(DialogViewState(active: true, speaker: state.speaker, text: state.text));
    choice.complete(index);
  }

  void end() => emit(const DialogViewState());
}
