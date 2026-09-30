import 'dart:async';
import 'dart:ui';

import 'package:eppy_island/components/collision_block.dart';
import 'package:eppy_island/components/player.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

class Level extends World {
  Level({required this.levelName, required this.player});

  static const double _tileSize = 16;
  static const String _spawnLayer = 'Spawnpoints';
  static const String _collisionLayer = 'Collisions';

  final String levelName;
  final Player player;

  late final TiledComponent _map;
  final List<CollisionBlock> _collisionBlocks = [];

  @override
  FutureOr<void> onLoad() async {
    await _loadMap();
    _placeSpawnPoints();
    _buildCollisionBlocks();

    player.bindCollisionBlocks(_collisionBlocks);
    add(player);

    return super.onLoad();
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

    for (final spawnPoint in layer.objects) {
      switch (spawnPoint.class_) {
        case 'Player':
          player.position = Vector2(spawnPoint.x, spawnPoint.y);
          break;
        default:
          break;
      }
    }
  }

  void _buildCollisionBlocks() {
    final layer = _map.tileMap.getLayer<ObjectGroup>(_collisionLayer);
    if (layer == null) return;

    for (final collision in layer.objects) {
      switch (collision.class_) {
        case 'Warp':
          break;
        default:
          final block = CollisionBlock(
            position: Vector2(collision.x, collision.y),
            size: Vector2(collision.width, collision.height),
          );
          _collisionBlocks.add(block);
          add(block);
          break;
      }
    }
  }
}
