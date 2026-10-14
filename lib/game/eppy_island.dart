import 'dart:async';
import 'dart:ui';

import 'package:eppy_island/dungeon/dungeon_level.dart';
import 'package:eppy_island/dungeon/encounter.dart';
import 'package:eppy_island/dungeon/enemy.dart';
import 'package:eppy_island/game/level.dart';
import 'package:eppy_island/entities/player.dart';
import 'package:eppy_island/game/screen_fade.dart';
import 'package:eppy_island/farming/crop_catalog.dart';
import 'package:eppy_island/farming/farm.dart';
import 'package:eppy_island/items/item_catalog.dart';
import 'package:eppy_island/profile/player_profile.dart';
import 'package:eppy_island/shop/shop.dart';
import 'package:eppy_island/save/save_service.dart';
import 'package:eppy_island/save/save_data.dart';
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

  /// Every crop (assets/data/crops.json).
  late final CropCatalog crops;

  /// All farmland: tilled soil, planted crops, watering and harvesting.
  late final Farm farm;

  /// Every dungeon enemy (assets/data/enemies.json).
  late final EnemyCatalog enemies;

  /// The dungeon encounter in progress, if any. It is one object for the
  /// whole game; [DungeonLevel] shows it.
  late final Encounter encounter;

  late final CameraComponent cam;
  late final JoystickComponent _joystick;

  /// The whole game UI, built from UI.tmx. Null until the game has loaded.
  UiManager? ui;

  /// The overworld level the player is in. Null while in the dungeon.
  Level? _currentLevel;

  /// The dungeon level on screen. Null in the overworld. While it is set there
  /// is no player on screen: [player] is the one that walked in, kept for its
  /// position and character.
  DungeonLevel? _dungeon;

  /// The overworld level the player is in, or left to enter the dungeon. This
  /// is the level that gets saved and returned to.
  String _levelName = SaveData.defaultLevel;

  /// Where the player stood on the dungeon entrance.
  Vector2? _returnPosition;

  bool _isTransitioning = false;
  bool _loaded = false;
  int _saveToken = 0; // Bumped to cancel a pending delayed save.
  double _shopClock = 0; // Seconds since the shop last checked its timer.

  /// True while a level change (fade out, load, fade in) is in progress.
  bool get isTransitioning => _isTransitioning;

  /// True while the dungeon level is the one on screen.
  bool get isInDungeon => _dungeon != null;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    // Data first: items, shop, then the player's save.
    final catalog = await ItemCatalog.load();
    shop = await Shop.load(catalog);
    crops = await CropCatalog.load(catalog);
    final save = await _saves.load();
    profile = PlayerProfile.fromJson(save.player, catalog);
    farm = Farm(crops: crops)..loadJson(save.farm, catalog);
    enemies = await EnemyCatalog.load();
    encounter = Encounter(catalog: enemies, profile: profile);
    _levelName = save.level;

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
      delegate: UiController(profile: profile, shop: shop, farm: farm),
    );
    ui = manager;
    cam.viewport.add(manager);

    if (showJoystick) {
      _addJoystick();
    }

    profile.changes.addListener(_scheduleSave);
    farm.changes.addListener(_scheduleSave);
    _loaded = true;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showJoystick) {
      player.direction = Direction.fromJoystick(_joystick.direction);
    }
    if (_loaded) {
      encounter.tick(dt);
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
    // In the dungeon the only key that does anything is Space (to skip a
    // reveal or leave a result). The menu hotkeys and the farming keys are
    // ignored: the encounter menu is all there is to use.
    if (_loaded && _dungeon != null) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
        encounter.advance();
        return KeyEventResult.handled;
      }
      return super.onKeyEvent(event, keysPressed);
    }

    // Space on the dungeon entrance starts an encounter.
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.space &&
        !_isTransitioning &&
        !(ui?.hasOpenScreen ?? false) &&
        (_currentLevel?.tryEnterDungeon() ?? false)) {
      return KeyEventResult.handled;
    }

    // Action key: till / plant / water / harvest the plot in front of you.
    // Checked before the UI hotkeys, so E always farms when no screen is open
    // (the inventory is on Q; set it with the layer's "hotkey" in UI.tmx).
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.keyE ||
            event.logicalKey == LogicalKeyboardKey.space) &&
        !(ui?.hasOpenScreen ?? false) &&
        !_isTransitioning) {
      debugPrint('Farm: action key pressed.');
      _currentLevel?.interactNearest();
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent && (ui?.handleKey(event.logicalKey) ?? false)) {
      return KeyEventResult.handled;
    }
    return super.onKeyEvent(event, keysPressed);
  }

  // --------------------------------------------------------------- dungeon

  /// Fades out of the overworld into the dungeon level [levelName] (a .tmx),
  /// where an encounter starts. Returns false, and does nothing, if the player
  /// can't go in right now.
  ///
  /// The dungeon ends the encounter itself, then calls [leaveDungeon].
  bool enterDungeon(String levelName) {
    if (!_loaded || _isTransitioning || _dungeon != null) return false;
    if (!encounter.canStart) return false;

    ui?.closeAll();
    player.direction = Direction.none;
    _returnPosition = player.position.clone();

    unawaited(
      _changeWorld(
        name: levelName,
        build: () async => DungeonLevel(levelName: levelName),
        adopt: (world) {
          _dungeon = world as DungeonLevel;
          _currentLevel = null;
          ui?.setHudVisible(false); // The dungeon is a screen of its own.
        },
      ),
    );
    return true;
  }

  /// Fades out of the dungeon and back to the overworld level the player came
  /// from, standing on the entrance they used.
  Future<void> leaveDungeon() async {
    // The encounter can end while the fade into the dungeon is still going.
    while (_isTransitioning) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    // Nothing else can be done on the dungeon screen, so a failed return is
    // tried again rather than leaving the player stuck on it.
    for (var attempt = 1; _dungeon != null && attempt <= 3; attempt++) {
      await _changeWorld(
        name: _levelName,
        build: () async => Level(
          levelName: _levelName,
          player: Player(character: player.character),
          startPosition: _returnPosition,
        ),
        adopt: (world) {
          final level = world as Level;
          player = level.player;
          _currentLevel = level;
          _dungeon = null;
          ui?.setHudVisible(true);
        },
      );
    }
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
        farm: farm.toJson(),
        // In the dungeon, save the overworld level the player will return to.
        level: _levelName,
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
    if (_dungeon != null) return;

    await _changeWorld(
      name: levelName,
      // A fresh player per level; carry over the held direction so movement
      // doesn't stop until the next key event.
      build: () async => Level(
        levelName: levelName,
        player: Player(character: player.character)..direction = player.direction,
        spawnName: spawnName,
      ),
      adopt: (world) {
        final level = world as Level;
        player = level.player;
        _currentLevel = level;
        _levelName = levelName;
      },
      onFailure: () => _currentLevel?.rearmWarps(),
    );
  }

  /// Fades to black, builds the next world with [build], swaps it in (calling
  /// [adopt] once it has loaded), then fades back in. Returns false if
  /// another change is already running or this one failed; a failed change
  /// leaves the current world where it is.
  Future<bool> _changeWorld({
    required String name,
    required Future<World> Function() build,
    required void Function(World next) adopt,
    VoidCallback? onFailure,
  }) async {
    if (_isTransitioning) return false;
    _isTransitioning = true;
    debugPrint('Changing level: $name');

    final previous = cam.world;
    World? next;

    try {
      overlays.add(ScreenFade.overlayKey); // No-op if already showing.
      player.canMove = false;
      await fade.fadeTo(1, duration: _fadeDuration);

      next = await build();
      await add(next);

      // Only switch over once the new world has loaded successfully.
      adopt(next);
      cam.world = next;
      previous?.removeFromParent();

      await Future<void>.delayed(_blackHold);
      await fade.fadeTo(0, duration: _fadeDuration);
      _scheduleSave(); // Remember the new level.
      return true;
    } catch (error, stackTrace) {
      // Loading failed: stay where we were and show the reason.
      debugPrint('Changing level failed for "$name": $error\n$stackTrace');
      next?.removeFromParent();
      if (_dungeon == null && encounter.isActive) encounter.end();
      onFailure?.call();
      player.canMove = true;
      await fade.fadeTo(0, duration: _fadeDuration);
      return false;
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
