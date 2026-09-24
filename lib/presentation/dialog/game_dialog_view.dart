import 'dart:async';

import 'package:jenny/jenny.dart';

import 'dialog_cubit.dart';

/// Bridges jenny's DialogueRunner to [DialogCubit].
class GameDialogView extends DialogueView {
  GameDialogView(this.cubit);

  final DialogCubit cubit;

  @override
  FutureOr<void> onDialogueStart() {
    cubit.begin();
  }

  @override
  FutureOr<bool> onLineStart(DialogueLine line) async {
    await cubit.showLine(line.character?.name, line.text);
    return true;
  }

  @override
  FutureOr<int?> onChoiceStart(DialogueChoice choice) =>
      cubit.showChoices([for (final o in choice.options) o.text]);

  @override
  FutureOr<void> onDialogueFinish() {
    cubit.end();
  }
}
