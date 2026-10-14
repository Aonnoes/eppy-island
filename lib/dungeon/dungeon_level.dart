import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:eppy_island/dungeon/dungeon_bindings.dart';
import 'package:eppy_island/dungeon/encounter.dart';
import 'package:eppy_island/game/eppy_island.dart';
import 'package:eppy_island/ui/ui_elements.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';

/// A dungeon level: a screen of its own with no player character and no
/// walking around. The only thing to do in it is use the encounter menu.
///
/// It is built from a Tiled map (Level-04.tmx). The tile layers are the
/// picture. The object layer [_uiLayer] says where the live parts go, using
/// the same classes and properties as UI.tmx:
///
///   Image   bind | sprite
///             flash_bind                     hidden until this value changes,
///                                            then shown for 1.5 s and faded out
///             fallback_bind, fallback_size   text shown while the image is
///                                            missing (the enemy's initial)
///             count_bind                     small text in the bottom-right
///                                            corner (the consumable's count)
///             lives                          (life bars) lives each side
///                                            starts with
///   Label   bind | text, size, color, align, wrap
///             color_bind                     a colour that changes (the
///                                            action label: yellow question,
///                                            green win, red loss)
///   Button  action: consume, no or yes, and sprite: the picture's name, with
///           `_unpressed.png` and `_pressed.png` added, like UI.tmx. The
///           three buttons are never covered or replaced: while a minigame
///           is being played Yes and No answer the one-word question in the
///           action label, and the buttons that can't be used just show
///           their unpressed picture.
///   Box     color
///
/// Objects with no class are skipped. The values to `bind` to are listed in
/// [DungeonBindings].
///
/// Loading the level starts an encounter. When the encounter ends, the game
/// fades back to the level the player came from.
class DungeonLevel extends World with HasGameRef<EppyIsland> {
  DungeonLevel({required this.levelName});

  static const double _tileSize = 16;

  /// Name of the object layer that holds the menu's objects.
  static const String _uiLayer = 'Dungeon UI';

  final String levelName;

  late final TiledComponent _map;
  late final DungeonBindings _bindings;

  /// The buttons for the current phase. Rebuilt whenever the phase changes.
  final PositionComponent _controls = PositionComponent(priority: 10);

  /// The Button objects, left to right.
  final List<_Spot> _spots = [];

  int _lives = Encounter.defaultLives;
  EncounterPhase? _controlsFor;
  bool _listening = false;

  /// The encounter is over: nothing can be pressed any more.
  bool _finished = false;

  @override
  FutureOr<void> onLoad() async {
    _map = await TiledComponent.load(
      '$levelName.tmx',
      Vector2.all(_tileSize),
      layerPaintFactory: (opacity) => Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false
        ..color = Color.fromRGBO(255, 255, 255, opacity),
      useAtlas: false,
    );
    _map.priority = -2; // The picture at the very back.
    add(_map);

    final layer = _map.tileMap.getLayer<ObjectGroup>(_uiLayer);
    if (layer == null) {
      throw StateError('$levelName.tmx has no "$_uiLayer" object layer.');
    }

    _bindings = DungeonBindings(game);
    _buildObjects(layer);
    _spots.sort((a, b) => a.position.x.compareTo(b.position.x));
    if (!_spots.any((s) => s.action == 'yes') ||
        !_spots.any((s) => s.action == 'no')) {
      throw StateError(
        '$levelName.tmx needs Button objects with the actions "yes" and "no".',
      );
    }
    add(_controls);

    // Start last: if anything above failed the player is simply left where
    // they were, with no encounter running.
    final encounter = game.encounter;
    encounter.addListener(_onEncounterChanged);
    _listening = true;
    if (!encounter.start(lives: _lives)) {
      encounter.removeListener(_onEncounterChanged);
      _listening = false;
      throw StateError('Dungeon: there is no encounter to start.');
    }

    return super.onLoad();
  }

  @override
  void onRemove() {
    if (_listening) {
      game.encounter.removeListener(_onEncounterChanged);
      _listening = false;
    }
    super.onRemove();
  }

  // ------------------------------------------------------------------ build

  void _buildObjects(ObjectGroup layer) {
    var lives = 0;
    for (final o in layer.objects) {
      lives = math.max(lives, o.integer('lives'));
      switch (o.class_) {
        case '':
          break; // A sketch, or art that is already in the tile layers.
        case 'Image':
          _addImage(o);
        case 'Label':
          _addLabel(o);
        case 'Button':
          _spots.add(
            _Spot(
              o.str('action'),
              o.str('sprite'),
              o.uiPosition,
              o.uiSize,
            ),
          );
        case 'Box':
          add(
            UiBox(
              color: parseUiColor(o.str('color'), const Color(0x99000000)),
              position: o.uiPosition,
              size: o.uiSize,
            ),
          );
        default:
          debugPrint('Dungeon: unknown class "${o.class_}" on "${o.name}".');
      }
    }
    if (lives > 0) _lives = lives;
  }

  ValueListenable<Object?>? _binding(String key, TiledObject o) {
    final binding = _bindings.values[key];
    if (binding == null) {
      debugPrint('Dungeon: "${o.name}" binds to unknown key "$key".');
    }
    return binding;
  }

  void _addImage(TiledObject o) {
    final bindKey = o.str('bind');
    final spriteName = o.str('sprite');
    if (bindKey.isEmpty && spriteName.isEmpty) {
      debugPrint('Dungeon: image "${o.name}" has neither "sprite" nor "bind".');
      return;
    }

    final position = o.uiPosition;
    final size = o.uiSize;
    final flashKey = o.str('flash_bind');
    final flash = flashKey.isEmpty ? null : _binding(flashKey, o);
    final spriteBinding = bindKey.isEmpty ? null : _binding(bindKey, o);
    add(
      flash == null
          ? UiImage(
              loadSprite: (name) => loadUiSprite(game, name),
              spriteName: spriteName,
              spriteBinding: spriteBinding,
              position: position.clone(),
              size: size.clone(),
            )
          : UiFlashImage(
              loadSprite: (name) => loadUiSprite(game, name),
              spriteName: spriteName,
              spriteBinding: spriteBinding,
              flash: flash,
              position: position.clone(),
              size: size.clone(),
            ),
    );

    final fallbackKey = o.str('fallback_bind');
    if (fallbackKey.isNotEmpty) {
      add(
        _label(
          position: position,
          size: size,
          fontSize: o.integer('fallback_size', 14),
          binding: _binding(fallbackKey, o),
        ),
      );
    }

    final countKey = o.str('count_bind');
    if (countKey.isNotEmpty) {
      const strip = 8.0;
      add(
        _label(
          position: Vector2(position.x, position.y + size.y - strip),
          size: Vector2(size.x, strip),
          align: 'right',
          binding: _binding(countKey, o),
        ),
      );
    }
  }

  void _addLabel(TiledObject o) {
    final key = o.str('bind');
    final colorKey = o.str('color_bind');
    add(
      _label(
        position: o.uiPosition,
        size: o.uiSize,
        text: o.str('text'),
        fontSize: o.integer('size', 7),
        color: parseUiColor(o.str('color'), const Color(0xFFFFFFFF)),
        align: o.str('align', 'left'),
        wrap: o.flag('wrap'),
        binding: key.isEmpty ? null : _binding(key, o),
        colorBinding: colorKey.isEmpty ? null : _binding(colorKey, o),
      ),
    );
  }

  UiLabel _label({
    required Vector2 position,
    required Vector2 size,
    String text = '',
    int fontSize = 7,
    Color color = const Color(0xFFFFFFFF),
    String align = 'center',
    bool wrap = false,
    ValueListenable<Object?>? binding,
    ValueListenable<Object?>? colorBinding,
  }) {
    return UiLabel(
      position: position.clone(),
      size: size.clone(),
      text: text,
      style: uiTextStyle(size: fontSize.toDouble(), color: color),
      align: align,
      wrap: wrap,
      binding: binding,
      colorBinding: colorBinding,
    );
  }

  // --------------------------------------------------------------- encounter

  void _onEncounterChanged() {
    final encounter = game.encounter;

    if (!encounter.isActive) {
      // Over. Leave the last picture on screen, with the buttons greyed out,
      // while the game fades out.
      if (_finished) return;
      _finished = true;
      _controlsFor = null;
      _clearControls();
      for (final spot in _spots) {
        _addDisabled(spot);
      }
      unawaited(game.leaveDungeon());
      return;
    }

    _bindings.sync(encounter);
    if (encounter.phase != _controlsFor) {
      _controlsFor = encounter.phase;
      _rebuildControls(encounter);
    }
  }

  void _clearControls() {
    _controls.removeAll(_controls.children.toList());
  }

  /// Puts the buttons the current phase needs on the three Button spots.
  void _rebuildControls(Encounter encounter) {
    _clearControls();

    switch (encounter.phase) {
      case EncounterPhase.intro:
        for (final spot in _spots) {
          _addButton(spot, _introAction(encounter, spot.action));
        }
      case EncounterPhase.prompt:
        // The same Yes and No buttons as the intro; the one-word question
        // is in the action label. No only works when there is something to
        // pick from, and the consumable can't be used any more.
        for (final spot in _spots) {
          final VoidCallback? onPressed = switch (spot.action) {
            'yes' => () => _press(encounter.yes),
            'no' when encounter.canDecline => () => _press(encounter.no),
            _ => null,
          };
          if (onPressed == null) {
            _addDisabled(spot);
          } else {
            _addButton(spot, onPressed);
          }
        }
      case EncounterPhase.reveal:
        // A moment of suspense: nothing to press.
        _spots.forEach(_addDisabled);
      case EncounterPhase.result:
        // Yes is also the proceed button: the result stays up until the
        // player presses it (or Space), so it can be read at their own pace.
        for (final spot in _spots) {
          if (spot.action == 'yes') {
            _addButton(spot, () => _press(encounter.yes));
          } else {
            _addDisabled(spot);
          }
        }
      case EncounterPhase.inactive:
        break;
    }
  }

  VoidCallback? _introAction(Encounter encounter, String action) {
    switch (action) {
      case 'consume':
        return () => _press(encounter.consume);
      case 'no':
        return () => _press(encounter.no);
      case 'yes':
        return () => _press(encounter.yes);
      default:
        return null;
    }
  }

  /// A working button on [spot], using its pressed / unpressed pictures (or a
  /// flat button with a word on it if the pictures are missing).
  void _addButton(_Spot spot, VoidCallback? onPressed) {
    final up = loadUiSprite(game, '${spot.sprite}_unpressed');
    final down = loadUiSprite(game, '${spot.sprite}_pressed');
    if (up == null || down == null) {
      _controls.add(
        UiTextButton(
          label: spot.fallbackLabel,
          onPressed: onPressed,
          position: spot.position.clone(),
          size: spot.size.clone(),
        ),
      );
      return;
    }
    _controls.add(
      SpriteButtonComponent(
        button: up,
        buttonDown: down,
        position: spot.position.clone(),
        size: spot.size.clone(),
        onPressed: onPressed,
      ),
    );
  }

  /// [spot]'s picture, not pressable. Drawn as it is, with nothing laid
  /// over it.
  void _addDisabled(_Spot spot) {
    final up = loadUiSprite(game, '${spot.sprite}_unpressed');
    if (up == null) return;
    _controls.add(
      UiSprite(
        sprite: up,
        position: spot.position.clone(),
        size: spot.size.clone(),
      ),
    );
  }

  /// Runs [action] unless the encounter is over or the screen is fading.
  void _press(VoidCallback action) {
    if (_finished || game.isTransitioning) return;
    action();
  }
}

/// Where one Button object sits.
class _Spot {
  const _Spot(this.action, this.sprite, this.position, this.size);

  final String action;

  /// Picture name; `_unpressed` / `_pressed` are added to it.
  final String sprite;
  final Vector2 position;
  final Vector2 size;

  /// The word on the flat button used when the pictures are missing.
  String get fallbackLabel => switch (action) {
    'consume' => 'ITEM',
    _ => action.toUpperCase(),
  };
}
