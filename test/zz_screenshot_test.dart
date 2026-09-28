// Temporary: renders the game screen to PNGs for a visual check.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_game/game/game_model.dart';
import 'package:tetris_game/game/motions.dart';
import 'package:tetris_game/providers/game_provider.dart';
import 'package:tetris_game/providers/high_score_store.dart';
import 'package:tetris_game/ui/screens/game_screen.dart';
import 'package:tetris_game/ui/theme/neon.dart';
import 'package:tetris_game/ui/widgets/neon_backdrop.dart';

const _out = String.fromEnvironment('OUT', defaultValue: '/tmp');

Future<void> _loadFonts() async {
  final orbitron = FontLoader('Orbitron');
  for (final f in ['Regular', 'Bold', 'Black']) {
    orbitron.addFont(rootBundle.load('assets/fonts/Orbitron-$f.ttf'));
  }
  final rajdhani = FontLoader('Rajdhani');
  for (final f in ['Medium', 'SemiBold', 'Bold']) {
    rajdhani.addFont(rootBundle.load('assets/fonts/Rajdhani-$f.ttf'));
  }
  await orbitron.load();
  await rajdhani.load();
  final material = FontLoader('MaterialIcons');
  final manifest = File(
    '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (manifest.existsSync()) {
    material.addFont(
      Future.value(ByteData.sublistView(manifest.readAsBytesSync())),
    );
    await material.load();
  }
}

Future<void> _shot(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('screenshots', (tester) async {
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          highScoreStoreProvider.overrideWith(
            (ref) => MemoryHighScoreStore(248),
          ),
          rngProvider.overrideWith((ref) => (int max) => 0),
        ],
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: neonTheme(),
            home: const MediaQuery(
              data: MediaQueryData(
                size: Size(390, 844),
                padding: EdgeInsets.only(top: 47, bottom: 34),
              ),
              child: GameScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final element = tester.element(find.byType(GameScreen));
      await precacheImage(const AssetImage(NeonBackdrop.asset), element);
    });
    await tester.pump();
    await tester.pump();
    await _shot(tester, key, 'screen_ready');

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameScreen)),
    );
    final notifier = container.read(gameProvider.notifier);
    notifier.start();
    final board = notifier.debugBoard;
    const rows = <String>[
      '..........',
      '....7.....',
      '....777...',
      '.....66...',
      '....66....',
      '.......5..',
      '.....555..',
      '.......8..',
      '...4.888..',
      '..444.3...',
      '22.33.33.2',
      '22553333.2',
    ];
    for (var i = 0; i < rows.length; i++) {
      for (var c = 0; c < 10; c++) {
        final ch = rows[i][c];
        board.cells[20 - rows.length + i][c] = ch == '.' ? 0 : int.parse(ch);
      }
    }
    notifier.handleMotion(Motion.left);
    await tester.pump();
    await _shot(tester, key, 'screen_play');

    // Stack to the top, then drop so the next spawn is blocked.
    for (var r = 2; r < 8; r++) {
      for (var c = 1; c < 10; c++) {
        board.cells[r][c] = 2 + (r + c) % 7;
      }
    }
    notifier.debugModel.current = notifier.debugModel.current!.copyWith(x: 4);
    notifier.debugModel.score = 165;
    notifier.handleMotion(Motion.hardDrop);
    await tester.pump();
    expect(container.read(gameProvider).status, GameStatus.over);
    await _shot(tester, key, 'screen_over');
    await tester.pumpWidget(const SizedBox());
  });
}
