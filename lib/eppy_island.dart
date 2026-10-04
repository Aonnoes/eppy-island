import 'dart:async';
import 'dart:ui';

import 'package:eppy_island/components/direction.dart';
import 'package:eppy_island/components/level.dart';
import 'package:eppy_island/components/player.dart';
import 'package:eppy_island/components/screen_fade.dart';
import 'package:eppy_island/models/item_catalog.dart';
import 'package:eppy_island/models/player_profile.dart';
import 'package:eppy_island/models/shop.dart';
import 'package:eppy_island/services/save_service.dart';
import 'package:eppy_island/ui/ui_controller.dart';
import 'package:eppy_island/ui/ui_manager.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

class EppyIsland extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks {
  // Width matches UI.tmx (30 tiles). Height stays at 283: tiles start to
  // break at 288.
  static const double _viewWidth = 480;
  static const double _viewHeight = 283;

  /// How long the fade to black, and the fade back in, each take.
  static const Duration _fadeDuration = Duration(milliseconds: 500);

  /// How long the screen stays fully black once the new level is ready.
  static const Duration _blackHold = Duration(milliseconds: 200);

  /// Changes are saved this long after the last one, so a burst of changes
  /// (buying 10 items) is written once.
  static const Duration _saveDelay = Duration(seconds: 1);

  final bool showJoystick = false;

  /// Drives the black fade overlay (see main.dart's overlayBuilderMap).
  final ScreenFade fade = ScreenFade();

  final SaveService _saves = SaveService();

  /// The player character in the current level. Set in [onLoad].
  late Player player;

  /// Who the player is: name, picture, coins, luck, inventory, equipment.
  /// Loaded from the save file (or assets/data/default_save.json).
  late final PlayerProfile profile;

  /// What the shop sells (assets/data/shop.json).
  late final Shop shop;

  late final CameraComponent cam;
  late final JoystickComponent _joystick;

  /// The whole game UI, built from UI.tmx. Null until the game has loaded.
  UiManager? ui;

  Level? _currentLevel;
  bool _isTransitioning = false;
  bool _loaded = false;
  int _saveToken = 0; // Bumped to cancel a pending delayed save.
  double _shopClock = 0; // Seconds since the shop last checked its timer.

  /// True while a level change (fade out, load, fade in) is in progress.
  bool get isTransitioning => _isTransitioning;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    // Data first: items, shop, then the player's save.
    final catalog = await ItemCatalog.load();
    shop = await Shop.load(catalog);
    final save = await _saves.load();
    profile = PlayerProfile.fromJson(save.player, catalog);

    player = Player(character: profile.character);
    final world = Level(
      player: player,
      levelName: save.level,
      startPosition: save.hasPosition ? Vector2(save.x!, save.y!) : null,
    );
    _currentLevel = world;

    cam = CameraComponent.withFixedResolution(
      world: world,
      width: _viewWidth,
      height: _viewHeight,
    );
    cam.viewfinder.anchor = Anchor.topLeft;

    addAll([cam, world]);
    overlays.add(ScreenFade.overlayKey);

    // The UI lives on the viewport, so it stays fixed on screen and survives
    // level changes (only cam.world is swapped in loadLevel).
    final manager = UiManager(
      delegate: UiController(profile: profile, shop: shop),
    );
    ui = manager;
    cam.viewport.add(manager);

    if (showJoystick) {
      _addJoystick();
    }

    profile.changes.addListener(_scheduleSave);
    _loaded = true;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showJoystick) {
      player.direction = Direction.fromJoystick(_joystick.direction);
    }
    if (_loaded) {
      _shopClock += dt;
      if (_shopClock >= 1) {
        _shopClock = 0;
        shop.refreshIfDue(); // Re-rolls on the hour; updates the countdown.
      }
    }
    super.update(dt);
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    // The app may be killed after this, so save right away.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(saveNow());
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent && (ui?.handleKey(event.logicalKey) ?? false)) {
      return KeyEventResult.handled;
    }
    return super.onKeyEvent(event, keysPressed);
  }

  // -------------------------------------------------------------------- save

  void _scheduleSave() {
    final token = ++_saveToken;
    Future<void>.delayed(_saveDelay, () {
      if (token == _saveToken) unawaited(saveNow());
    });
  }

  /// Writes the profile, the current level and the player's position now.
  Future<void> saveNow() async {
    if (!_loaded) return;
    _saveToken++; // Cancels any save still waiting on its delay.
    await _saves.save(
      SaveData(
        player: profile.toJson(),
        level: _currentLevel?.levelName ?? SaveData.defaultLevel,
        x: player.x,
        y: player.y,
      ),
    );
  }

  /// Saves, then closes the app. On iOS an app can't close itself, so this
  /// only saves there.
  Future<void> quitGame() async {
    await saveNow();

    final mobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (mobile) {
      await SystemNavigator.pop();
    } else {
      await ServicesBinding.instance.exitApplication(AppExitType.required);
    }
  }

  // ------------------------------------------------------------------ levels

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
      _scheduleSave(); // Remember the new level.
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
