import 'dart:async';

import 'package:eppy_island/components/collision_block.dart';
import 'package:eppy_island/components/utils.dart';
import 'package:eppy_island/eppy_island.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

enum PlayerState { N, W, E, S, NW, NE, SW, SE }

enum PlayerDirection { N, W, E, S, NW, NE, SW, SE, none }

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<EppyIsland>, KeyboardHandler {
  String character;
  Player({position, this.character = 'Teemo'}) : super(position: position);

  late final SpriteAnimation NAnimation;
  late final SpriteAnimation WAnimation;
  late final SpriteAnimation EAnimation;
  late final SpriteAnimation SAnimation;
  late final SpriteAnimation NWAnimation;
  late final SpriteAnimation NEAnimation;
  late final SpriteAnimation SWAnimation;
  late final SpriteAnimation SEAnimation;

  final double stepTime = 0.2;
  List<CollisionBlock> collisionBlocks = [];

  PlayerDirection playerDirection = PlayerDirection.none;
  double moveSpeed = 50;
  Vector2 velocity = Vector2.zero();

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    debugMode = false; // show player collisions
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updatePlayerMovement(dt);
    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD);
    final isUpKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyW);
    final isDownKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyS);

    if (isLeftKeyPressed && isUpKeyPressed) {
      playerDirection = PlayerDirection.NW;
    } else if (isLeftKeyPressed && isDownKeyPressed) {
      playerDirection = PlayerDirection.SW;
    } else if (isRightKeyPressed && isUpKeyPressed) {
      playerDirection = PlayerDirection.NE;
    } else if (isRightKeyPressed && isDownKeyPressed) {
      playerDirection = PlayerDirection.SE;
    } else if (isLeftKeyPressed) {
      playerDirection = PlayerDirection.W;
    } else if (isRightKeyPressed) {
      playerDirection = PlayerDirection.E;
    } else if (isUpKeyPressed) {
      playerDirection = PlayerDirection.N;
    } else if (isDownKeyPressed) {
      playerDirection = PlayerDirection.S;
    } else {
      playerDirection = PlayerDirection.none;
    }

    return super.onKeyEvent(event, keysPressed);
  }

  void _loadAllAnimations() {
    NAnimation = _spriteAnimation('N', 3);
    WAnimation = _spriteAnimation('W', 3);
    EAnimation = _spriteAnimation('E', 3);
    SAnimation = _spriteAnimation('S', 3);
    NWAnimation = _spriteAnimation('NW', 3);
    NEAnimation = _spriteAnimation('NE', 3);
    SWAnimation = _spriteAnimation('SW', 3);
    SEAnimation = _spriteAnimation('SE', 3);

    animations = {
      PlayerState.N: NAnimation,
      PlayerState.W: WAnimation,
      PlayerState.E: EAnimation,
      PlayerState.S: SAnimation,
      PlayerState.NW: NWAnimation,
      PlayerState.NE: NEAnimation,
      PlayerState.SW: SWAnimation,
      PlayerState.SE: SEAnimation,
    };

    current = PlayerState.S;
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('characters/$character/$character $state.png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(16),
      ),
    );
  }

  void _updatePlayerMovement(double dt) {
    double dirX = 0.0;
    double dirY = 0.0;
    switch (playerDirection) {
      case PlayerDirection.N:
        current = PlayerState.N;
        dirY = -1;
        break;
      case PlayerDirection.S:
        current = PlayerState.S;
        dirY = 1;
        break;
      case PlayerDirection.W:
        current = PlayerState.W;
        dirX = -1;
        break;
      case PlayerDirection.E:
        current = PlayerState.E;
        dirX = 1;
        break;
      case PlayerDirection.NW:
        current = PlayerState.NW;
        dirX = -1;
        dirY = -1;
        break;
      case PlayerDirection.NE:
        current = PlayerState.NE;
        dirX = 1;
        dirY = -1;
        break;
      case PlayerDirection.SW:
        current = PlayerState.SW;
        dirX = -1;
        dirY = 1;
        break;
      case PlayerDirection.SE:
        current = PlayerState.SE;
        dirX = 1;
        dirY = 1;
        break;
      case PlayerDirection.none:
        break;
    }

    velocity = Vector2(dirX, dirY);
    if (velocity.length2 > 0) {
      velocity.normalize();
    }

    // Resolve movement one axis at a time to avoid corner-clipping/snagging.
    position.x += velocity.x * moveSpeed * dt;
    _checkHorizontalCollisions();

    position.y += velocity.y * moveSpeed * dt;
    _checkVerticalCollisions();
  }

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (checkCollision(this, block)) {
        if (velocity.x > 0) {
          position.x = block.x - width;
        } else if (velocity.x < 0) {
          position.x = block.x + block.width;
        }
      }
    }
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (checkCollision(this, block)) {
        if (velocity.y > 0) {
          position.y = block.y - height;
        } else if (velocity.y < 0) {
          position.y = block.y + block.height;
        }
      }
    }
  }
}
