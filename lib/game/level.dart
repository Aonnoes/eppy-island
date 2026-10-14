import 'dart:async';
import 'dart:ui';

import 'package:eppy_island/dungeon/entrance_prompt.dart';
import 'package:eppy_island/entities/blocks.dart';
import 'package:eppy_island/entities/player.dart';
import 'package:eppy_island/entities/plot_component.dart';
import 'package:eppy_island/entities/plot_info_label.dart';
import 'package:eppy_island/game/eppy_island.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';

class Level extends World with HasGameRef<EppyIsland> {
  Level({
    required this.levelName,
    required this.player,
    this.spawnName,
    this.startPosition,
  });

  static const double _tileSize = 16;
  static const String _spawnLayer = 'Spawnpoints';
  static const String _collisionLayer = 'Collisions';

  /// Object layer holding farmland. Draw a rectangle (class 'Plot') over any
  /// area; it is split into 16x16 plots, so a 48x32 rectangle makes 3x2 plots.
  static const String _farmLayer = 'Farmland';
  static const String _plotClass = 'Plot';

  /// How close (in pixels, centre to centre) the player must be to a plot to
  /// work it.
  static const double _reach = 20;

  /// Tiled object class for warp blocks. Set the custom properties
  /// 'targetLevel' (required) and 'targetSpawn' (optional) on the object.
  static const String _warpClass = 'Warp';

  /// Collision objects with these names are not solid: walking into one opens
  /// the UI screen named here (see ShopBlock). Name them in Tiled's
  /// 'Collisions' layer.
  static const Map<String, String> _shopScreens = {
    'buying': 'Buy',
    'selling': 'Sell',
  };

  /// A collision object with this name marks the dungeon entrance. It is not
  /// solid: standing on it shows the prompt, and Space enters the dungeon.
  /// Give it a string property 'level' to pick another dungeon level than
  /// [DungeonBlock.defaultLevel].
  static const String _dungeonName = 'dungeon';

  final String levelName;
  final Player player;

  /// Name of the Tiled spawn object to place the player at. When null (or not
  /// found), the level's default 'Player' spawn is used.
  final String? spawnName;

  /// Exact position to start at (used when loading a save). Wins over the
  /// spawn points.
  final Vector2? startPosition;

  late final TiledComponent _map;
  final List<CollisionBlock> _collisionBlocks = [];
  final List<WarpBlock> _warpBlocks = [];
  final List<ShopBlock> _shopBlocks = [];
  final List<DungeonBlock> _dungeonBlocks = [];
  EntrancePrompt? _prompt;
  final List<PlotComponent> _plots = [];
  bool _isWarping = false;

  /// Warps only fire once the player has stepped off every warp block since
  /// arriving. This stops a player who spawns on top of a warp block from being
  /// bounced straight back, or from silently disabling the warp.
  bool _warpsArmed = false;

  /// Same idea for shops: after a shop screen is closed the player is still
  /// standing on its block, so it only opens again once they step off first.
  bool _shopsArmed = false;

  /// The entrance only works again after the player has stepped off it, so
  /// coming back from the dungeon can't send them straight in again.
  bool _dungeonArmed = false;

  @override
  FutureOr<void> onLoad() async {
    await _loadMap();
    _map.priority = -2; // Map at the very back, plots above it.
    _placeSpawnPoints();
    if (startPosition != null) player.position = startPosition!.clone();
    _buildCollisionBlocksAndWarps();
    _buildPlots();
    _buildDungeonPrompt();

    player.bindCollisionBlocks(_collisionBlocks);
    add(player);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _checkWarps();
    _checkShops();
    _checkDungeon();
  }

  Future<void> _loadMap() async {
    _map = await TiledComponent.load(
      '$levelName.tmx',
      Vector2.all(_tileSize),
      layerPaintFactory: (opacity) => Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false
        ..color = Color.fromRGBO(255, 255, 255, opacity),
      useAtlas: false,
    );
    add(_map);
  }

  void _placeSpawnPoints() {
    final layer = _map.tileMap.getLayer<ObjectGroup>(_spawnLayer);
    if (layer == null) return;

    Vector2? requestedSpawn; // Object whose Name matches [spawnName].
    Vector2? defaultSpawn; // Object with class 'Player'.

    for (final spawnPoint in layer.objects) {
      final point = Vector2(spawnPoint.x, spawnPoint.y);

      if (spawnName != null && spawnPoint.name == spawnName) {
        requestedSpawn = point;
        break;
      }
      if (spawnPoint.class_ == 'Player') {
        defaultSpawn = point;
      }
    }

    if (spawnName != null && requestedSpawn == null) {
      debugPrint(
        'No spawn named "$spawnName" in $levelName; using the default spawn.',
      );
    }

    final spawn = requestedSpawn ?? defaultSpawn;
    if (spawn != null) {
      player.position = spawn;
    }
  }

  void _buildCollisionBlocksAndWarps() {
    final layer = _map.tileMap.getLayer<ObjectGroup>(_collisionLayer);
    if (layer == null) return;

    for (final object in layer.objects) {
      final position = Vector2(object.x, object.y);
      final size = Vector2(object.width, object.height);

      if (object.class_ == _warpClass) {
        final target = object.properties.getValue<String>('targetLevel');
        if (target == null || target.isEmpty) {
          debugPrint('Warp in $levelName has no "targetLevel" property.');
          continue; // Not solid, not a trigger.
        }

        final warp = WarpBlock(
          position: position,
          size: size,
          targetLevel: target,
          // If no 'targetSpawn' is set, look for a spawn named after the level
          // the player is leaving. Falls back to the default spawn.
          targetSpawn:
              object.properties.getValue<String>('targetSpawn') ?? levelName,
        );
        _warpBlocks.add(warp);
        add(warp);
      } else if (_shopScreens[object.name] case final screen?) {
        final shop = ShopBlock(position: position, size: size, screen: screen);
        _shopBlocks.add(shop);
        add(shop);
      } else if (object.name == _dungeonName) {
        final entrance = DungeonBlock(
          position: position,
          size: size,
          level:
              object.properties.getValue<String>('level') ??
              DungeonBlock.defaultLevel,
        );
        _dungeonBlocks.add(entrance);
        add(entrance);
      } else {
        final block = CollisionBlock(position: position, size: size);
        _collisionBlocks.add(block);
        add(block);
      }
    }
  }

  // -------------------------------------------------------------------- farm

  void _buildPlots() {
    final layer = _map.tileMap.getLayer<ObjectGroup>(_farmLayer);
    if (layer == null) {
      debugPrint('Farm: $levelName has no "$_farmLayer" object layer.');
      return;
    }

    for (final object in layer.objects) {
      if (object.class_ != _plotClass) continue;

      // A Tiled "point" has no size: make it one plot on the tile it sits in.
      final isPoint = object.width < 1 || object.height < 1;
      final originX = isPoint ? (object.x / _tileSize).floor() * _tileSize : object.x;
      final originY = isPoint ? (object.y / _tileSize).floor() * _tileSize : object.y;
      final columns = isPoint ? 1 : (object.width / _tileSize).round();
      final rows = isPoint ? 1 : (object.height / _tileSize).round();
      for (var row = 0; row < rows; row++) {
        for (var col = 0; col < columns; col++) {
          final plot = PlotComponent(
            // Stable across launches, so crops stay in the plot they were
            // planted in. Includes the level so levels never share plots.
            plotKey: '$levelName:${object.id}:$col,$row',
            position: Vector2(
              originX + col * _tileSize,
              originY + row * _tileSize,
            ),
            size: Vector2.all(_tileSize),
          )..priority = -1; // Under the player.
          _plots.add(plot);
          add(plot);
        }
      }
    }
    if (_plots.isNotEmpty) {
      add(PlotInfoLabel(player: player, plots: _plots, mapSize: _map.size));
    }
    debugPrint('Farm: $levelName has ${_plots.length} plot(s).');
  }

  /// Works [plot] (tap or action key) if the player is close enough.
  void interactWith(PlotComponent plot) {
    if (game.isTransitioning || !player.canMove) return;
    if (player.center.distanceTo(plot.center) > _reach) {
      game.farm.say('Too far away');
      return;
    }
    game.farm.interact(game.profile, plot.plotKey);
  }

  /// Works the plot closest to the player, if any is in reach.
  void interactNearest() {
    if (game.isTransitioning || !player.canMove) {
      debugPrint('Farm: action ignored (transitioning or player frozen).');
      return;
    }

    PlotComponent? nearest;
    var best = _reach;
    for (final plot in _plots) {
      final d = player.center.distanceTo(plot.center);
      if (d <= best) {
        best = d;
        nearest = plot;
      }
    }
    if (nearest == null) {
      debugPrint(
        'Farm: no plot within $_reach px of the player at ${player.center} '
        '(${_plots.length} plots in this level).',
      );
      return;
    }
    interactWith(nearest);
  }

  /// Lets the player use warps again, after they have stepped off them first.
  /// Called by the game if a level change fails.
  void rearmWarps() {
    _isWarping = false;
    _warpsArmed = false;
  }

  void _checkWarps() {
    if (_isWarping) return;

    final warp = _warpUnderPlayer();
    if (warp == null) {
      _warpsArmed = true; // Player is clear of all warps.
      return;
    }

    // Standing on a warp they arrived on, or a level change is in progress:
    // don't trigger, and don't use up this level's one chance to warp.
    if (!_warpsArmed || game.isTransitioning) return;

    _isWarping = true;
    game.loadLevel(warp.targetLevel, spawnName: warp.targetSpawn);
  }

  WarpBlock? _warpUnderPlayer() {
    for (final warp in _warpBlocks) {
      if (checkCollision(player, warp)) return warp;
    }
    return null;
  }

  /// Opens the Buy / Sell screen when the player walks into its block.
  void _checkShops() {
    final shop = _shopUnderPlayer();
    if (shop == null) {
      _shopsArmed = true; // Player is clear of all shops.
      return;
    }

    final ui = game.ui;
    if (!_shopsArmed || game.isTransitioning || ui == null) return;
    if (ui.hasOpenScreen) return;

    _shopsArmed = false;
    ui.open(shop.screen);
  }

  ShopBlock? _shopUnderPlayer() {
    for (final shop in _shopBlocks) {
      if (checkCollision(player, shop)) return shop;
    }
    return null;
  }

  // ----------------------------------------------------------------- dungeon

  void _buildDungeonPrompt() {
    if (_dungeonBlocks.isEmpty) return;
    final prompt = EntrancePrompt(player: player, mapSize: _map.size);
    _prompt = prompt;
    add(prompt);
  }

  /// Shows the entrance prompt while the player is on the (armed) entrance.
  void _checkDungeon() {
    final prompt = _prompt;
    if (prompt == null) return;

    final onEntrance = _entranceUnderPlayer() != null;
    if (!onEntrance) _dungeonArmed = true;

    prompt.shown =
        onEntrance &&
        _dungeonArmed &&
        !game.isTransitioning &&
        game.encounter.canStart &&
        !(game.ui?.hasOpenScreen ?? false);
  }

  DungeonBlock? _entranceUnderPlayer() {
    for (final block in _dungeonBlocks) {
      if (checkCollision(player, block)) return block;
    }
    return null;
  }

  /// Space: takes the player into the dungeon level if the entrance prompt is
  /// showing. Returns true if it did, so the key press isn't also used for
  /// farming.
  bool tryEnterDungeon() {
    final prompt = _prompt;
    final entrance = _entranceUnderPlayer();
    if (prompt == null || !prompt.shown || entrance == null) return false;
    if (!game.enterDungeon(entrance.level)) return false;

    _dungeonArmed = false;
    prompt.shown = false;
    return true;
  }
}
