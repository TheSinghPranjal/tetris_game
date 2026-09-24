import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_game/game/motions.dart';
import 'package:tetris_game/game/tick.dart';

void main() {
  test('touch zones use the Android diagonal split', () {
    expect(resolveTouchDirection(0.1, 0.5), Motion.left);
    expect(resolveTouchDirection(0.5, 0.1), Motion.rotate);
    expect(resolveTouchDirection(0.5, 0.9), Motion.down);
    expect(resolveTouchDirection(0.9, 0.5), Motion.right);

    expect(resolveTouchDirection(0.5, 0.5), Motion.rotate);
    expect(resolveTouchDirection(0, 0), Motion.rotate);
    expect(resolveTouchDirection(1, 0), Motion.rotate);
    expect(resolveTouchDirection(0, 1), Motion.left);
    expect(resolveTouchDirection(1, 1), Motion.right);
  });

  test('soft-drop delay is 500ms and the boundary counts as due', () {
    var now = DateTime(2026);
    final scheduler = MoveScheduler(clock: () => now);
    expect(scheduler.delay, const Duration(milliseconds: 500));
    expect(scheduler.isDue, isTrue);

    scheduler.mark();
    expect(scheduler.isDue, isFalse);

    now = now.add(const Duration(milliseconds: 499));
    expect(scheduler.isDue, isFalse);

    now = now.add(const Duration(milliseconds: 1));
    expect(scheduler.isDue, isTrue);

    scheduler.reset();
    expect(scheduler.isDue, isTrue);
  });
}
