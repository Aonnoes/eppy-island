import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:eppy_island/eppy_island.dart';
import 'package:eppy_island/ui/ui_contracts.dart';
import 'package:eppy_island/ui/ui_elements.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// Builds the whole game UI from UI.tmx and runs it.
///
/// Every object layer in the map is a "screen". Objects in a layer are turned
/// into components by their Tiled class:
///
///   Panel, Image  sprite | bind, show_bind, show_min
///   Box           color                                  (flat rectangle)
///   Button        sprite, action, target, enabled, text
///   Label         bind | text, size, color, align, wrap
///   Slot          kind, slot, item_scale, (sprite)
///   Grid          columns, rows, kind, item_scale, (sprite)  -> one Slot per cell
///
/// Objects with no class are skipped, so you can sketch a layout first and
/// classify it later.
///
/// A Button whose `[sprite]_unpressed.png` / `[sprite]_pressed.png` don't exist
/// is drawn as a flat coloured button showing its `text`, so a screen works
/// before its art does. A Label with `wrap` breaks its text to fit its width.
///
/// Button actions: open_screen, switch_screen, close_screen, exit_game, and
/// anything else is passed to the [UiDelegate] (qty_up, qty_down, confirm).
///
/// Layer properties:
///
///   persistent  always shown (the HUD)
///   modal       dims the game and blocks taps behind it
///   freeze_game the player can't move while it is open
///   hotkey      key that opens / closes it, e.g. "P"
///   include     comma-separated layers drawn underneath it, e.g. "Profile,Details"
///
/// Keys: each screen's `hotkey` opens / closes it, and Escape closes the top
/// screen (or opens "Paused" when nothing is open).
///
/// A layer's Offset X / Y in Tiled shifts the whole layer.
///
/// Add it to `cam.viewport` so it stays fixed on screen.
class UiManager extends PositionComponent with HasGameRef<EppyIsland> {
  UiManager({required this.delegate}) : super(priority: 10);

  static const String _mapFile = 'UI.tmx';

  /// Provides the live values, slot contents and game rules.
  final UiDelegate delegate;

  late final TiledComponent _map;
  final PositionComponent _persistentLayer = PositionComponent();
  final PositionComponent _screenLayer = PositionComponent();
  final List<_OpenScreen> _stack = [];

  /// Hotkey label (upper case) -> screen name.
  final Map<String, String> _hotkeys = {};

  // ----------------------------------------------------------------- queries

  bool get hasOpenScreen => _stack.isNotEmpty;

  String? get topScreen => _stack.isEmpty ? null : _stack.last.name;

  bool isOpen(String name) => _stack.any((s) => s.name == name);

  // -------------------------------------------------------------------- load

  @override
  Future<void> onLoad() async {
    _map = await TiledComponent.load(
      _mapFile,
      Vector2.all(16),
      useAtlas: false,
    );
    size = _map.size;
    debugPrint(
      'UI: loaded $_mapFile (${size.x.toInt()}x${size.y.toInt()}), layers: '
      '${_map.tileMap.map.layers.map((l) => l.name).join(', ')}',
    );

    _persistentLayer.size = size.clone();
    _screenLayer.size = size.clone();
    addAll([_persistentLayer, _screenLayer]);

    for (final layer in _map.tileMap.map.layers.whereType<ObjectGroup>()) {
      final hotkey = layer.properties.getValue<String>('hotkey') ?? '';
      if (hotkey.isNotEmpty) _hotkeys[hotkey.toUpperCase()] = layer.name;

      if (layer.properties.getValue<bool>('persistent') ?? false) {
        _persistentLayer.add(_buildScreen(layer));
      }
    }
  }

  ObjectGroup? _layer(String name) => _map.tileMap.getLayer<ObjectGroup>(name);

  // ------------------------------------------------------------------ screens

  /// Opens [name] on top of whatever is showing.
  void open(String name) {
    if (name.isEmpty || game.isTransitioning || isOpen(name)) return;

    final layer = _layer(name);
    if (layer == null) {
      debugPrint('UI: no layer named "$name".');
      return;
    }

    delegate.reset();
    final root = _buildScreen(layer);
    _screenLayer.add(root);
    _stack.add(
      _OpenScreen(
        name,
        root,
        freezeGame: layer.properties.getValue<bool>('freeze_game') ?? false,
      ),
    );
    _syncFreeze();
  }

  /// Closes the top screen.
  void close() {
    if (_stack.isEmpty) return;
    delegate.reset();
    _stack.removeLast().root.removeFromParent();
    _syncFreeze();
  }

  /// Replaces the top screen with [name] (used by previous / next buttons).
  void switchTo(String name) {
    if (name.isEmpty) return;
    close();
    open(name);
  }

  /// Closes [name] if it is on top, otherwise opens it.
  void toggle(String name) {
    if (topScreen == name) {
      close();
    } else {
      open(name);
    }
  }

  void closeAll() {
    while (_stack.isNotEmpty) {
      close();
    }
  }

  /// Handles a hotkey press. Returns true if it opened or closed a screen.
  bool handleKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.escape) {
      if (_stack.isEmpty) {
        open('Paused');
      } else {
        close();
      }
      return true;
    }

    final name = _hotkeys[key.keyLabel.toUpperCase()];
    if (name == null) return false;

    if (topScreen == name) {
      close();
      return true;
    }
    if (_stack.isEmpty) {
      open(name);
      return true;
    }
    return false; // Another screen is open; ignore.
  }

  void _syncFreeze() {
    if (game.isTransitioning) return;
    game.player.canMove = !_stack.any((s) => s.freezeGame);
  }

  // ----------------------------------------------------------------- building

  PositionComponent _buildScreen(ObjectGroup layer) {
    final root = PositionComponent(size: size.clone());
    if (layer.properties.getValue<bool>('modal') ?? false) {
      root.add(UiBackdrop(size: size.clone()));
    }
    _fill(root, layer.name, <String>{});
    return root;
  }

  /// Adds the components for layer [name] to [root], after any layers it
  /// includes. [visited] stops include loops.
  void _fill(PositionComponent root, String name, Set<String> visited) {
    if (!visited.add(name)) return;

    final layer = _layer(name);
    if (layer == null) {
      debugPrint('UI: no layer named "$name".');
      return;
    }

    final includes = layer.properties.getValue<String>('include') ?? '';
    for (final other in includes.split(',')) {
      final trimmed = other.trim();
      if (trimmed.isNotEmpty) _fill(root, trimmed, visited);
    }

    // Everything in this layer sits in a group shifted by the layer's
    // Offset X / Y from Tiled, so a whole screen can be nudged without
    // touching its objects.
    final group = PositionComponent(
      position: Vector2(
        layer.offsetX.roundToDouble(),
        layer.offsetY.roundToDouble(),
      ),
      size: size.clone(),
    );
    root.add(group);

    var unclassified = 0;
    var added = 0;
    for (final o in layer.objects) {
      if (o.class_.isEmpty) {
        unclassified++;
        continue;
      }
      final built = _buildObject(o);
      if (built == null) {
        debugPrint('UI: unknown class "${o.class_}" on "${o.name}" in $name.');
        continue;
      }
      group.addAll(built);
      added += built.length;
    }
    debugPrint(
      'UI: "$name": $added component(s), $unclassified without a class.',
    );
  }

  List<Component>? _buildObject(TiledObject o) {
    switch (o.class_) {
      case 'Panel':
      case 'Image':
        return _image(o);
      case 'Button':
        return _button(o);
      case 'Label':
        return _label(o);
      case 'Box':
        return [
          UiBox(
            color: parseUiColor(o.str('color'), const Color(0x99000000)),
            position: o.uiPosition,
            size: o.uiSize,
          ),
        ];
      case 'Slot':
        return [
          _makeSlot(
            o.str('kind', 'item'),
            o.integer('slot'),
            o.uiPosition,
            o.uiSize,
            o.str('sprite'),
            o.integer('item_scale', 1),
          ),
        ];
      case 'Grid':
        return _grid(o);
      default:
        return null;
    }
  }

  ValueListenable<Object?>? _binding(String key, TiledObject o) {
    final binding = delegate.bindings[key];
    if (binding == null) {
      debugPrint('UI: "${o.name}" binds to unknown key "$key".');
    }
    return binding;
  }

  List<Component> _image(TiledObject o) {
    final bindKey = o.str('bind');
    final showKey = o.str('show_bind');
    final name = o.str('sprite');
    if (name.isEmpty && bindKey.isEmpty) {
      debugPrint('UI: image "${o.name}" has neither "sprite" nor "bind".');
      return const [];
    }

    return [
      UiImage(
        loadSprite: (n) => loadUiSprite(game, n),
        spriteName: name,
        spriteBinding: bindKey.isEmpty ? null : _binding(bindKey, o),
        levelBinding: showKey.isEmpty ? null : _binding(showKey, o),
        minLevel: o.integer('show_min', 0),
        position: o.uiPosition,
        size: o.uiSize,
      ),
    ];
  }

  List<Component> _button(TiledObject o) {
    final name = o.str('sprite');
    final up = loadUiSprite(game, '${name}_unpressed');
    final down = loadUiSprite(game, '${name}_pressed');
    final VoidCallback? onPressed = o.flag('enabled', true)
        ? () => _runAction(o)
        : null;

    // No art yet: fall back to a flat button, if it has text to show.
    if (up == null || down == null) {
      final text = o.str('text');
      if (text.isEmpty) return const [];
      return [
        UiTextButton(
          label: text,
          onPressed: onPressed,
          position: o.uiPosition,
          size: o.uiSize,
        ),
      ];
    }

    return [
      SpriteButtonComponent(
        button: up,
        buttonDown: down,
        position: o.uiPosition,
        size: o.uiSize,
        onPressed: onPressed,
      ),
    ];
  }

  List<Component> _label(TiledObject o) {
    final key = o.str('bind');
    return [
      UiLabel(
        position: o.uiPosition,
        size: o.uiSize,
        text: o.str('text'),
        style: TextStyle(
          fontSize: o.integer('size', 10).toDouble(),
          color: parseUiColor(o.str('color'), const Color(0xFFFFFFFF)),
        ),
        align: o.str('align', 'left'),
        binding: key.isEmpty ? null : _binding(key, o),
        wrap: o.flag('wrap'),
      ),
    ];
  }

  /// One Grid object becomes columns x rows slots, numbered row by row from 0.
  List<Component> _grid(TiledObject o) {
    final columns = math.max(1, o.integer('columns', 1));
    final rows = math.max(1, o.integer('rows', 1));
    final kind = o.str('kind', 'item');
    final sprite = o.str('sprite');
    final itemScale = o.integer('item_scale', 1);

    final origin = o.uiPosition;
    final cellWidth = (o.width / columns).roundToDouble();
    final cellHeight = (o.height / rows).roundToDouble();

    return [
      for (var i = 0; i < columns * rows; i++)
        _makeSlot(
          kind,
          i,
          Vector2(
            origin.x + (i % columns) * cellWidth,
            origin.y + (i ~/ columns) * cellHeight,
          ),
          Vector2(cellWidth, cellHeight),
          sprite,
          itemScale,
        ),
    ];
  }

  UiSlot _makeSlot(
    String kind,
    int index,
    Vector2 position,
    Vector2 size,
    String spriteName,
    int itemScale,
  ) {
    final name = spriteName.isNotEmpty
        ? spriteName
        : (kind == 'equipment' ? 'equipment_slot' : 'inventory_slot');

    return UiSlot(
      kind: kind,
      index: index,
      selection: delegate.selection,
      source: delegate.slotSources[kind],
      onTap: delegate.onSlotTapped,
      loadSprite: (n) => loadUiSprite(game, n),
      itemScale: itemScale,
      sprite: loadUiSprite(game, name),
      position: position,
      size: size,
    );
  }

  // ------------------------------------------------------------------ actions

  void _runAction(TiledObject o) {
    final target = o.str('target');
    final action = o.str('action');
    switch (action) {
      case 'open_screen':
        toggle(target); // Pressing a screen's own button closes it.
      case 'switch_screen':
        switchTo(target);
      case 'close_screen':
        close();
      case 'exit_game':
        unawaited(game.quitGame());
      default:
        if (!delegate.onAction(action)) {
          debugPrint('UI: button "${o.name}" has unknown action "$action".');
        }
    }
  }
}

class _OpenScreen {
  _OpenScreen(this.name, this.root, {required this.freezeGame});

  final String name;
  final PositionComponent root;
  final bool freezeGame;
}
