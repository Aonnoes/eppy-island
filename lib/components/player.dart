import 'dart:async';
import 'dart:ui';

import 'package:eppy_island/components/collision_block.dart';
import 'package:eppy_island/components/direction.dart';
import 'package:eppy_island/eppy_island.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

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

  Vector2 _velocity = Vector2.zero();
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
    if (direction.isMoving) {
      current = direction;
    }

    _velocity = direction.vector;

    // Resolve movement one axis at a time to avoid corner-clipping/snagging.
    position.x += _velocity.x * moveSpeed * dt;
    for (final block in _collisionBlocks) {
      block.resolveHorizontal(this, _velocity.x);
    }

    position.y += _velocity.y * moveSpeed * dt;
    for (final block in _collisionBlocks) {
      block.resolveVertical(this, _velocity.y);
    }
  }
}
