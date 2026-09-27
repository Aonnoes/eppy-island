import 'dart:async';
import 'dart:ui';

import 'package:eppy_island/eppy_island.dart';
import 'package:flame/components.dart';

enum PlayerState { N, W, E, S, NW, NE, SW, SE }

enum PlayerDirection { N, W, E, S, NW, NE, SW, SE, none }

class Player extends SpriteAnimationGroupComponent with HasGameRef<EppyIsland> {
  String character;
  Player({position, required this.character}) : super(position: position);

  late final SpriteAnimation NAnimation;
  late final SpriteAnimation WAnimation;
  late final SpriteAnimation EAnimation;
  late final SpriteAnimation SAnimation;
  late final SpriteAnimation NWAnimation;
  late final SpriteAnimation NEAnimation;
  late final SpriteAnimation SWAnimation;
  late final SpriteAnimation SEAnimation;

  final double stepTime = 0.2;

  PlayerDirection playerDirection = PlayerDirection.W;
  double moveSpeed = 5;
  Vector2 velocity = Vector2.zero();

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updatePlayerMovement(dt);
    super.update(dt);
  }

  @override
  void onKeyEvent(event, keysPressed) {}

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
        dirY = moveSpeed;
        break;
      case PlayerDirection.S:
        current = PlayerState.S;
        dirY = -moveSpeed;
        break;
      case PlayerDirection.W:
        current = PlayerState.W;
        dirX = -moveSpeed;
        break;
      case PlayerDirection.E:
        current = PlayerState.E;
        dirX = moveSpeed;
        break;
      case PlayerDirection.NW:
        current = PlayerState.NW;
        dirX = -moveSpeed;
        dirY = moveSpeed;
        break;
      case PlayerDirection.NE:
        current = PlayerState.NE;
        dirX = moveSpeed;
        dirY = moveSpeed;
        break;
      case PlayerDirection.SW:
        current = PlayerState.SW;
        dirX = -moveSpeed;
        dirY = -moveSpeed;
        break;
      case PlayerDirection.SE:
        current = PlayerState.SE;
        dirX = moveSpeed;
        dirY = -moveSpeed;
        break;
      case PlayerDirection.none:
        break;
      default:
        dirX = 0.0;
        dirY = 0.0;
        break;
    }
    velocity.x = dirX * moveSpeed;
    velocity.y = dirY * moveSpeed;
    position += velocity * dt;
  }
}
