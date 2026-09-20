import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:eppy_island/levels/level.dart';

class EppyIsland extends FlameGame {
  late final CameraComponent cam;
  final world = Level();

  @override
  FutureOr<void> onLoad() {
    cam = CameraComponent.withFixedResolution(
      world: world,
      width: 480,
      height: 288,
    );
    cam.viewfinder.anchor = Anchor.topLeft;
    addAll([cam, world]);
    return super.onLoad();
  }
}
