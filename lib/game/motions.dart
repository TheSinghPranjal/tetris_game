/// Motions from `AppModel.Motions`.
enum Motion { left, right, down, rotate }

/// Diagonal split used by `GameActivity.resolveTouchDirection`.
///
/// Normalized [x] and [y] are in the 0–1 range of the playfield.
/// Returns 0 left, 1 rotate, 2 down, 3 right — mapped here to [Motion].
Motion resolveTouchDirection(double x, double y) {
  if (y > x) {
    if (x > 1 - y) {
      return Motion.down;
    }
    return Motion.left;
  }
  if (x > 1 - y) {
    return Motion.right;
  }
  return Motion.rotate;
}
