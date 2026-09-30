import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// The eight directions a character can face and move in, plus [none].
///
/// Each direction knows its own movement vector and how to be built from
/// keyboard or joystick input, so nobody else needs a switch over it.
enum Direction {
  n(0, -1),
  s(0, 1),
  w(-1, 0),
  e(1, 0),
  nw(-1, -1),
  ne(1, -1),
  sw(-1, 1),
  se(1, 1),
  none(0, 0);

  const Direction(this.dx, this.dy);

  final double dx;
  final double dy;

  bool get isMoving => this != Direction.none;

  /// Unit-length movement vector (zero vector for [none]).
  Vector2 get vector {
    final v = Vector2(dx, dy);
    if (v.length2 > 0) v.normalize();
    return v;
  }

  /// Suffix used in sprite sheet file names, e.g. "NW".
  String get spriteSuffix => name.toUpperCase();

  /// WASD input -> direction.
  static Direction fromKeys(Set<LogicalKeyboardKey> keysPressed) {
    final left = keysPressed.contains(LogicalKeyboardKey.keyA);
    final right = keysPressed.contains(LogicalKeyboardKey.keyD);
    final up = keysPressed.contains(LogicalKeyboardKey.keyW);
    final down = keysPressed.contains(LogicalKeyboardKey.keyS);

    if (left && up) return Direction.nw;
    if (left && down) return Direction.sw;
    if (right && up) return Direction.ne;
    if (right && down) return Direction.se;
    if (left) return Direction.w;
    if (right) return Direction.e;
    if (up) return Direction.n;
    if (down) return Direction.s;
    return Direction.none;
  }

  /// On-screen joystick input -> direction.
  static Direction fromJoystick(JoystickDirection direction) {
    switch (direction) {
      case JoystickDirection.up:
        return Direction.n;
      case JoystickDirection.down:
        return Direction.s;
      case JoystickDirection.left:
        return Direction.w;
      case JoystickDirection.right:
        return Direction.e;
      case JoystickDirection.upLeft:
        return Direction.nw;
      case JoystickDirection.upRight:
        return Direction.ne;
      case JoystickDirection.downLeft:
        return Direction.sw;
      case JoystickDirection.downRight:
        return Direction.se;
      default:
        return Direction.none;
    }
  }
}
