import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_game/game/game_model.dart';
import 'package:tetris_game/game/motions.dart';
import 'package:tetris_game/main.dart';
import 'package:tetris_game/providers/game_provider.dart';
import 'package:tetris_game/providers/high_score_store.dart';
import 'package:tetris_game/ui/screens/game_screen.dart';

void main() {
  testWidgets('landing shows the best score and opens a playable well', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryHighScoreStore(70);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          highScoreStoreProvider.overrideWith((ref) => store),
          rngProvider.overrideWith(
            (ref) =>
                (int max) => 0,
          ),
        ],
        child: const TetrisApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('TETRIS'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);

    await tester.tap(find.byKey(const Key('play-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('TAP TO START'), findsOneWidget);
    expect(find.text('70'), findsWidgets);

    await tester.tap(find.byKey(const Key('playfield')));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameScreen)),
    );
    final started = container.read(gameProvider);
    expect(started.status, GameStatus.active);
    expect(started.current!.y, 1);
    expect(started.current!.x, 4);

    final rect = tester.getRect(find.byKey(const Key('playfield')));
    await tester.tapAt(rect.centerLeft + const Offset(6, 0));
    await tester.pump();
    expect(container.read(gameProvider).current!.x, 3);

    await tester.tapAt(rect.bottomCenter - const Offset(0, 6));
    await tester.pump();
    expect(container.read(gameProvider).current!.y, 2);

    await tester.tap(find.byKey(const Key('restart-button')));
    await tester.pump();
    final restarted = container.read(gameProvider);
    expect(restarted.status, GameStatus.active);
    expect(restarted.score, 0);
    expect(restarted.current!.y, 1);
    expect(restarted.highScore, 70);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('a lock writes the high score through the provider', () async {
    final store = MemoryHighScoreStore();
    final container = ProviderContainer(
      overrides: [
        highScoreStoreProvider.overrideWith((ref) => store),
        rngProvider.overrideWith(
          (ref) =>
              (int max) => 0,
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    notifier.handlePlayfieldTap(0.5, 0.5);
    notifier.debugBoard.cells[3][4] = 2;
    notifier.debugBoard.cells[3][5] = 2;
    notifier.handleMotion(Motion.down);

    expect(container.read(gameProvider).status, GameStatus.over);
    expect(container.read(gameProvider).displayedScore, 10);
    expect(store.value, 10);

    notifier.pause();
  });
}
