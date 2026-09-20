import 'dart:async';
import 'dart:ui';

import 'package:eppy_island/eppy_island.dart';
import 'package:flame/components.dart';

enum PlayerState { N, W, E, S, NW, NE, SW, SE }

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

  final double stepTime = 0.05;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    return super.onLoad();
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
}
