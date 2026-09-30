import 'dart:async';
import 'dart:ui';

import 'package:eppy_island/components/direction.dart';
import 'package:eppy_island/components/level.dart';
import 'package:eppy_island/components/player.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/painting.dart';

class EppyIsland extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks {
  static const double _viewWidth = 440;
  static const double _viewHeight = 283;
  static const String _startingLevel = 'Level-01';

  final Player player = Player(character: 'Teemo');
  final bool showJoystick = false;

  late final CameraComponent cam;
  late final JoystickComponent _joystick;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    final world = Level(player: player, levelName: _startingLevel);

    cam = CameraComponent.withFixedResolution(
      world: world,
      width: _viewWidth,
      height: _viewHeight,
    );
    cam.viewfinder.anchor = Anchor.topLeft;

    addAll([cam, world]);

    if (showJoystick) {
      _addJoystick();
    }
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showJoystick) {
      player.direction = Direction.fromJoystick(_joystick.direction);
    }
    super.update(dt);
  }

  void _addJoystick() {
    _joystick = JoystickComponent(
      knob: SpriteComponent(sprite: Sprite(images.fromCache('hud/Knob.png'))),
      background: SpriteComponent(
        sprite: Sprite(images.fromCache('hud/Joystick.png')),
      ),
      margin: const EdgeInsets.only(left: 32, bottom: 32),
    );
    add(_joystick);
  }
}
