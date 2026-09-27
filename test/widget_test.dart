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
  Future<ProviderContainer> openGame(
    WidgetTester tester,
    MemoryHighScoreStore store,
  ) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    await tester.tap(find.byKey(const Key('play-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    return ProviderScope.containerOf(tester.element(find.byType(GameScreen)));
  }

  testWidgets('landing opens a well that starts on tap', (tester) async {
    final container = await openGame(tester, MemoryHighScoreStore(70));
    expect(find.text('TAP TO START'), findsOneWidget);
    expect(find.text('70'), findsWidgets);

    await tester.tap(find.byKey(const Key('playfield')));
    await tester.pump();
    final state = container.read(gameProvider);
    expect(state.status, GameStatus.active);
    expect(state.current, isNotNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pad buttons move, rotate, soft drop and hard drop', (
    tester,
  ) async {
    final container = await openGame(tester, MemoryHighScoreStore());
    await tester.tap(find.byKey(const Key('playfield')));
    await tester.pump();
    // First piece from the zero RNG bag is the O; use the T next for rotation.
    final x0 = container.read(gameProvider).current!.x;

    await tester.tap(find.byKey(const Key('control-left')));
    await tester.pump();
    expect(container.read(gameProvider).current!.x, x0 - 1);

    await tester.tap(find.byKey(const Key('control-right')));
    await tester.tap(find.byKey(const Key('control-right')));
    await tester.pump();
    expect(container.read(gameProvider).current!.x, x0 + 1);

    final y0 = container.read(gameProvider).current!.y;
    await tester.tap(find.byKey(const Key('control-down')));
    await tester.pump();
    expect(container.read(gameProvider).current!.y, y0 + 1);
    expect(container.read(gameProvider).score, 1);

    await tester.tap(find.byKey(const Key('control-drop')));
    await tester.pump();
    final afterDrop = container.read(gameProvider);
    expect(afterDrop.lockEpoch, 1);
    expect(afterDrop.field[19].where((c) => c != 0), hasLength(2));

    final rotation = afterDrop.current!.rotation;
    await tester.tap(find.byKey(const Key('control-rotate')));
    await tester.pump();
    expect(container.read(gameProvider).current!.rotation, (rotation + 1) % 4);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('holding LEFT auto-repeats to the wall', (tester) async {
    final container = await openGame(tester, MemoryHighScoreStore());
    await tester.tap(find.byKey(const Key('playfield')));
    await tester.pump();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('control-left'))),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.up();
    await tester.pump();
    final cols = container.read(gameProvider).current!.cells.map((c) => c.col);
    expect(cols.reduce((a, b) => a < b ? a : b), 0);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('gravity pulls the piece down and a grounded piece locks', (
    tester,
  ) async {
    final container = await openGame(tester, MemoryHighScoreStore());
    await tester.tap(find.byKey(const Key('playfield')));
    await tester.pump();
    final y0 = container.read(gameProvider).current!.y;

    await tester.pump(const Duration(milliseconds: 1000));
    expect(container.read(gameProvider).current!.y, y0 + 1);

    // Sideways moves do not delay gravity.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const Key('control-right')));
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(container.read(gameProvider).current!.y, y0 + 2);

    // Level 1 needs 18 rows plus the lock delay to land the O.
    await tester.pump(const Duration(seconds: 20));
    expect(container.read(gameProvider).lockEpoch, greaterThanOrEqualTo(1));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pause freezes the game', (tester) async {
    final container = await openGame(tester, MemoryHighScoreStore());
    await tester.tap(find.byKey(const Key('playfield')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pause-button')));
    await tester.pump();
    final paused = container.read(gameProvider);
    expect(paused.status, GameStatus.paused);
    expect(find.text('PAUSED'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(container.read(gameProvider).current!.y, paused.current!.y);

    await tester.tap(find.byKey(const Key('control-left')));
    await tester.pump();
    expect(container.read(gameProvider).current!.x, paused.current!.x);

    await tester.tap(find.byKey(const Key('playfield')));
    await tester.pump();
    expect(container.read(gameProvider).status, GameStatus.active);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('game over saves the high score', () async {
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
    notifier.start();
    // First piece is the O; it lands on rows 1–2 and blocks the spawn.
    for (var row = 3; row < 20; row++) {
      for (var col = 0; col < 10; col++) {
        notifier.debugBoard.cells[row][col] = col == 0 ? 0 : 9;
      }
    }
    notifier.handleMotion(Motion.hardDrop);

    final state = container.read(gameProvider);
    expect(state.status, GameStatus.over);
    expect(state.score, greaterThan(0));
    expect(store.value, state.score);
  });
}
