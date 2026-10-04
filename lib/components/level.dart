import 'dart:async';
import 'dart:ui';

import 'package:eppy_island/components/blocks.dart';
import 'package:eppy_island/components/player.dart';
import 'package:eppy_island/eppy_island.dart';
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

  /// Tiled object class for warp blocks. Set the custom properties
  /// 'targetLevel' (required) and 'targetSpawn' (optional) on the object.
  static const String _warpClass = 'Warp';

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
  bool _isWarping = false;

  /// Warps only fire once the player has stepped off every warp block since
  /// arriving. This stops a player who spawns on top of a warp block from being
  /// bounced straight back, or from silently disabling the warp.
  bool _warpsArmed = false;

  @override
  FutureOr<void> onLoad() async {
    await _loadMap();
    _placeSpawnPoints();
    if (startPosition != null) player.position = startPosition!.clone();
    _buildCollisionBlocksAndWarps();

    player.bindCollisionBlocks(_collisionBlocks);
    add(player);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _checkWarps();
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
      } else {
        final block = CollisionBlock(position: position, size: size);
        _collisionBlocks.add(block);
        add(block);
      }
    }
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
}
