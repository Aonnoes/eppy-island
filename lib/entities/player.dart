import 'dart:async';
import 'dart:ui';

import 'package:eppy_island/entities/blocks.dart';
import 'package:eppy_island/game/eppy_island.dart';
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
    return switch (direction) {
      JoystickDirection.up => Direction.n,
      JoystickDirection.down => Direction.s,
      JoystickDirection.left => Direction.w,
      JoystickDirection.right => Direction.e,
      JoystickDirection.upLeft => Direction.nw,
      JoystickDirection.upRight => Direction.ne,
      JoystickDirection.downLeft => Direction.sw,
      JoystickDirection.downRight => Direction.se,
      _ => Direction.none,
    };
  }
}

class Player extends SpriteAnimationGroupComponent<Direction>
    with HasGameRef<EppyIsland>, KeyboardHandler {
  Player({super.position, this.character = 'Teemo'});

  static const int _framesPerAnimation = 3;
  static const double _stepTime = 0.2;
  static const double _textureSize = 16;

  final String character;

  /// Direction the player is currently trying to move in. Set by keyboard
  /// input here, or by the game when using the on-screen joystick.
  Direction direction = Direction.none;

  double moveSpeed = 50;

  /// Set to false to freeze the player (e.g. during a level transition).
  bool canMove = true;

  List<CollisionBlock> _collisionBlocks = const [];

  /// Tells the player which blocks it must not walk through.
  void bindCollisionBlocks(List<CollisionBlock> blocks) {
    _collisionBlocks = blocks;
  }

  @override
  FutureOr<void> onLoad() {
    _loadAnimations();
    debugMode = false; // set to true to show player collisions
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updateMovement(dt);
    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    direction = Direction.fromKeys(keysPressed);
    return super.onKeyEvent(event, keysPressed);
  }

  // ---------------------------------------------------------------- animation

  void _loadAnimations() {
    animations = {
      for (final dir in Direction.values)
        if (dir.isMoving) dir: _buildAnimation(dir),
    };
    current = Direction.s;
  }

  SpriteAnimation _buildAnimation(Direction dir) {
    final animation = SpriteAnimation.fromFrameData(
      game.images.fromCache(
        'characters/$character/$character ${dir.spriteSuffix}.png',
      ),
      SpriteAnimationData.sequenced(
        amount: _framesPerAnimation,
        stepTime: _stepTime,
        textureSize: Vector2.all(_textureSize),
      ),
    );

    for (final frame in animation.frames) {
      frame.sprite.paint
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false;
    }

    return animation;
  }

  // ----------------------------------------------------------------- movement

  void _updateMovement(double dt) {
    if (!canMove) return;

    if (direction.isMoving) current = direction;

    final velocity = direction.vector;

    // Resolve movement one axis at a time to avoid corner-clipping/snagging.
    position.x += velocity.x * moveSpeed * dt;
    for (final block in _collisionBlocks) {
      block.resolveHorizontal(this, velocity.x);
    }

    position.y += velocity.y * moveSpeed * dt;
    for (final block in _collisionBlocks) {
      block.resolveVertical(this, velocity.y);
    }
  }
}
