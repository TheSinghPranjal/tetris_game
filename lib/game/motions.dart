/// Player inputs.
enum Motion { left, right, down, rotate, rotateCounter, hardDrop }

/// Diagonal split of the playfield into four tap zones.
///
/// Normalized [x] and [y] are in the 0–1 range of the playfield.
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
