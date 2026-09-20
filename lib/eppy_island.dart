import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:eppy_island/levels/level.dart';

class EppyIsland extends FlameGame<Level> {
  static const double gameWidth = 440;
  static const double gameHeight = 283;

  EppyIsland()
    : super(
        world: Level(),
        camera: CameraComponent(
          viewport: FixedSizeViewport(gameWidth, gameHeight),
        ),
      );

  @override
  Color backgroundColor() => const Color(0xFF000000); // letterbox bars

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    // Largest whole-number scale that fits, never below 1.
    final scale = math.max(
      1,
      math.min(size.x ~/ gameWidth, size.y ~/ gameHeight),
    );

    final viewport = camera.viewport;
    viewport.size = Vector2(gameWidth * scale, gameHeight * scale);
    viewport.anchor = Anchor.center;
    viewport.position = size / 2;

    camera.viewfinder.zoom = scale.toDouble();
  }
}
