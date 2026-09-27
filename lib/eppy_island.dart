import 'dart:async';
import 'dart:ui';

import 'package:eppy_island/actors/player.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:eppy_island/levels/level.dart';
import 'package:flame/input.dart';
import 'package:flutter/cupertino.dart';

class EppyIsland extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks {
  @override
  Color backgroundColor() => const Color(0xFF000000);
  late final CameraComponent cam;
  Player player = Player(character: "Teemo");
  late JoystickComponent joystick;
  bool showJoystic = true;

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    final world = Level(player: player, levelName: 'Level-01');

    cam = CameraComponent.withFixedResolution(
      world: world,
      width: 440,
      height: 283,
    );
    cam.viewfinder.anchor = Anchor.topLeft;

    addAll([cam, world]);

    if (showJoystic) {
      addJoystick();
    }

    return super.onLoad();
  }

  void update(double dt) {
    if (showJoystic) {
      updateJoystick(dt);
    }
    super.update(dt);
  }

  void addJoystick() {
    joystick = JoystickComponent(
      knob: SpriteComponent(sprite: Sprite(images.fromCache('hud/Knob.png'))),
      background: SpriteComponent(
        sprite: Sprite(images.fromCache('hud/Joystick.png')),
      ),
      margin: const EdgeInsets.only(left: 32, bottom: 32),
    );
    add(joystick);
  }

  void updateJoystick(double dt) {
    switch (joystick.direction) {
      case JoystickDirection.up:
        player.playerDirection = PlayerDirection.N;
        break;
      case JoystickDirection.down:
        player.playerDirection = PlayerDirection.S;
        break;
      case JoystickDirection.left:
        player.playerDirection = PlayerDirection.W;
        break;
      case JoystickDirection.right:
        player.playerDirection = PlayerDirection.E;
        break;
      case JoystickDirection.downLeft:
        player.playerDirection = PlayerDirection.SW;
        break;
      case JoystickDirection.downRight:
        player.playerDirection = PlayerDirection.SE;
        break;
      case JoystickDirection.upLeft:
        player.playerDirection = PlayerDirection.NW;
        break;
      case JoystickDirection.upRight:
        player.playerDirection = PlayerDirection.NE;
        break;
      default:
        player.playerDirection = PlayerDirection.none;
    }
  }
}
