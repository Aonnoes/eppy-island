import 'dart:async';
import 'dart:ui';

import 'package:eppy_island/components/direction.dart';
import 'package:eppy_island/components/level.dart';
import 'package:eppy_island/components/player.dart';
import 'package:eppy_island/components/screen_fade.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class EppyIsland extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks {
  static const double _viewWidth = 440;
  static const double _viewHeight = 283;
  static const String _startingLevel = 'Level-01';

  /// How long the fade to black, and the fade back in, each take.
  static const Duration _fadeDuration = Duration(milliseconds: 500);

  /// How long the screen stays fully black once the new level is ready.
  static const Duration _blackHold = Duration(milliseconds: 500);

  Player player = Player(character: 'Teemo');
  final bool showJoystick = false;

  /// Drives the black fade overlay (see main.dart's overlayBuilderMap).
  final ScreenFade fade = ScreenFade();

  late final CameraComponent cam;
  late final JoystickComponent _joystick;
  Level? _currentLevel;
  bool _isTransitioning = false;

  /// True while a level change (fade out, load, fade in) is in progress.
  bool get isTransitioning => _isTransitioning;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    final world = Level(player: player, levelName: _startingLevel);
    _currentLevel = world;

    cam = CameraComponent.withFixedResolution(
      world: world,
      width: _viewWidth,
      height: _viewHeight,
    );
    cam.viewfinder.anchor = Anchor.topLeft;

    addAll([cam, world]);
    overlays.add(ScreenFade.overlayKey);

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

  /// Fades to black, replaces the current level with [levelName], then fades
  /// back in. If [spawnName] is given, the player starts at the spawn point
  /// with that name in the new level.
  Future<void> loadLevel(String levelName, {String? spawnName}) async {
    if (_isTransitioning) return;
    _isTransitioning = true;
    debugPrint('loadLevel: $levelName (spawn: $spawnName)');

    final previousLevel = _currentLevel;
    final previousPlayer = player;
    Level? nextLevel;

    try {
      overlays.add(ScreenFade.overlayKey); // No-op if already showing.
      previousPlayer.canMove = false;
      await fade.fadeTo(1, duration: _fadeDuration);

      // A fresh player per level; carry over the held direction so movement
      // doesn't stop until the next key event.
      final nextPlayer = Player(character: previousPlayer.character)
        ..direction = previousPlayer.direction;

      nextLevel = Level(
        levelName: levelName,
        player: nextPlayer,
        spawnName: spawnName,
      );

      await add(nextLevel);

      // Only switch over once the new level has loaded successfully.
      player = nextPlayer;
      cam.world = nextLevel;
      _currentLevel = nextLevel;
      previousLevel?.removeFromParent();

      await Future<void>.delayed(_blackHold);
      await fade.fadeTo(0, duration: _fadeDuration);
    } catch (error, stackTrace) {
      // Loading failed: stay in the current level and show the reason.
      debugPrint('loadLevel failed for "$levelName": $error\n$stackTrace');
      nextLevel?.removeFromParent();
      previousLevel?.rearmWarps();
      previousPlayer.canMove = true;
      await fade.fadeTo(0, duration: _fadeDuration);
    } finally {
      _isTransitioning = false;
    }
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
