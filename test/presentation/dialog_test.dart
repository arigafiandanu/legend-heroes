import 'package:ashen_crest/data/dialog_project.dart';
import 'package:ashen_crest/presentation/dialog/dialog_cubit.dart';
import 'package:ashen_crest/presentation/dialog/game_dialog_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jenny/jenny.dart';

class Host implements DialogHost {
  final flags = <String>{};
  final given = <String, int>{};
  var rested = 0;
  var saveMenus = 0;
  @override
  bool hasFlag(String flag) => flags.contains(flag);
  @override
  void setFlag(String flag) => flags.add(flag);
  @override
  void giveItem(String id, int count) => given[id] = (given[id] ?? 0) + count;
  @override
  void restParty() => rested++;
  @override
  Future<void> openSaveMenu() async => saveMenus++;
}

const script = '''
title: Elder
---
<<if has_flag("quest_started")>>
    Elder: Go east.
<<else>>
    Elder: The Crest cracked.
    Kael: I'll go.
    <<flag quest_started>>
    <<give herbal 3>>
<<endif>>
===
title: Campfire
---
The campfire burns warm.
-> Rest and save
    <<rest>>
    <<save_menu>>
-> Leave
===
''';

void main() {
  late Host host;
  late DialogCubit cubit;
  late DialogueRunner runner;

  setUp(() {
    host = Host();
    cubit = DialogCubit();
    runner = DialogueRunner(
      yarnProject: buildYarnProject([script], host),
      dialogueViews: [GameDialogView(cubit)],
    );
  });

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('shows lines one at a time with the speaker, runs commands', () async {
    final done = runner.startDialogue('Elder');
    await pump();
    expect(cubit.state.active, isTrue);
    expect(cubit.state.speaker, 'Elder');
    expect(cubit.state.text, 'The Crest cracked.');

    cubit.advance();
    await pump();
    expect(cubit.state.speaker, 'Kael');

    cubit.advance();
    await done;
    expect(cubit.state.active, isFalse);
    expect(host.flags, {'quest_started'});
    expect(host.given, {'herbal': 3});
  });

  test('branches on flags', () async {
    host.flags.add('quest_started');
    final done = runner.startDialogue('Elder');
    await pump();
    expect(cubit.state.text, 'Go east.');
    cubit.advance();
    await done;
    expect(host.given, isEmpty);
  });

  test('lines without a speaker and choices', () async {
    final done = runner.startDialogue('Campfire');
    await pump();
    expect(cubit.state.speaker, isNull);
    cubit.advance();
    await pump();
    expect(cubit.state.choices, ['Rest and save', 'Leave']);
    cubit.choose(0);
    await done;
    expect(host.rested, 1);
    expect(host.saveMenus, 1);
  });

  test('advance does nothing while choices are shown', () async {
    final done = runner.startDialogue('Campfire');
    await pump();
    cubit.advance();
    await pump();
    cubit.advance(); // ignored: must pick an option
    await pump();
    expect(cubit.state.choices, hasLength(2));
    cubit.choose(1);
    await done;
    expect(host.rested, 0);
  });
}
