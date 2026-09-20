import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:eppy_island/levels/level.dart';

class EppyIsland extends FlameGame {
  late final CameraComponent cam;
  final world = Level();

  @override
  FutureOr<void> onLoad() async {
    // Load all images into cache
    await images.loadAllImages();

    cam = CameraComponent.withFixedResolution(
      world: world,
      width: 440,
      height: 283,
    );
    cam.viewfinder.anchor = Anchor.topLeft;
    addAll([cam, world]);
    return super.onLoad();
  }
}
