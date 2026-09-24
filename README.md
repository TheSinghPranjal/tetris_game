# Tetris

A portrait Flutter Tetris game with the rules of [Landfathich/Tetris](https://github.com/Landfathich/Tetris) and a dark neon arcade UI.

## Run

```bash
flutter pub get
flutter run
```

Web preview:

```bash
flutter run -d chrome
```

## Architecture

Riverpod owns the session. The UI only paints snapshots and forwards input.

| Path | Role |
| --- | --- |
| `lib/game/pieces.dart` | Seven tetrominoes, frames, and spawn offset from `Shape` / `Block.createBlock` |
| `lib/game/board.dart` | 20×10 well, collision, and `assessField` / `shiftRows` line clear |
| `lib/game/game_model.dart` | Statuses, motions, lock, +10 score, high score, spawn game over |
| `lib/game/motions.dart` | `LEFT` / `RIGHT` / `DOWN` / `ROTATE` and the diagonal touch split |
| `lib/game/tick.dart` | 500ms soft-drop cadence from `TetrisView` |
| `lib/providers/` | `GameNotifier`, gravity timer, `shared_preferences` high score |
| `lib/ui/` | Landing, game HUD, and `CustomPainter` well |

`AWAITING_START`, `ACTIVE`, and `OVER` match `AppModel.Statuses`. A piece locks only when `DOWN` is blocked. That lock adds **10** points (`boostScore`), even if rows also clear. If the score is greater than the saved best, the best is written to `shared_preferences` under `HIGH_SCORE` and restored on the next launch.

The next piece is shown beside the score. It is generated with the same random shape and color draw as `Block.createBlock`; the preview does not change movement, rotation, or scoring.

## Controls

The playfield is split on the same diagonals as `GameActivity.resolveTouchDirection`:

- Left region moves left
- Top region rotates
- Bottom region soft-drops one row
- Right region moves right

Tap the well while the game is waiting or over to start. The first soft-drop tick runs immediately, then gravity repeats every 500ms. A left, right, or rotate tap applies at once and restarts that timer. A bottom-zone tap drops one row and leaves the timer alone. Restart clears the well and score, then starts again. Keyboard (useful on desktop and web): arrows, Up or Space to rotate, Enter to start, R to restart.

Game over happens when a new piece cannot enter at the top. The stack is cleared, matching `resetField(false)`. Your score stays on the game-over card; the best score remains saved.
