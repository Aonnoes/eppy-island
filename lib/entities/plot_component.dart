import 'dart:ui';

import 'package:eppy_island/game/level.dart';
import 'package:eppy_island/game/eppy_island.dart';
import 'package:eppy_island/farming/crop.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';

/// One 16x16 square of farmland. It never blocks movement; it draws its soil
/// (once tilled) and whatever is growing in it, all read from
/// [EppyIsland.farm], and can be tapped. A watered plot gets a thin blue
/// outline.
///
/// Sprites, all under `assets/images/crops/` and all optional:
///   `<crop>_stage_1.png`    planted seed
///   `<crop>_stage_2.png`    sprout
///   `<crop>_stage_3.png`    ripe plant
///   `soil_tilled.png`              the soil
/// A plant sprite taller than the plot grows upwards from the plot's bottom
/// edge. Anything missing is drawn as simple coloured shapes.
class PlotComponent extends PositionComponent
    with HasGameRef<EppyIsland>, TapCallbacks {
  PlotComponent({
    required this.plotKey,
    required super.position,
    required super.size,
  });

  static const String _soilTilled = 'crops/soil_tilled';

  /// Unique key used by the farm and the save file.
  final String plotKey;

  Crop? _crop;
  int? _stage;
  bool _tilled = false;
  bool _watered = false;
  bool _ready = false;
  double _sinceCheck = 0;

  final Map<String, Sprite?> _sprites = {};
  final Paint _paint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;
  final Paint _dry = Paint()..color = const Color(0x998B5E3C);
  final Paint _waterOutline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..isAntiAlias = false
    ..color = const Color(0xFF3FA9F5);
  final Paint _growing = Paint()..color = const Color(0xFF6DBE45);
  final Paint _ripe = Paint()..color = const Color(0xFFFFD54F);

  @override
  void onMount() {
    super.onMount();
    game.farm.addListener(_refresh);
    _refresh();
  }

  @override
  void onRemove() {
    game.farm.removeListener(_refresh);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Growth and water follow the clock, so look again now and then.
    _sinceCheck += dt;
    if (_sinceCheck >= 0.5) {
      _sinceCheck = 0;
      _refresh();
    }
  }

  void _refresh() {
    final farm = game.farm;
    _crop = farm.plantedAt(plotKey)?.crop;
    _stage = farm.stageOf(plotKey);
    _tilled = farm.isTilled(plotKey);
    _watered = farm.isWatered(plotKey);
    _ready = farm.isReady(plotKey);
  }

  @override
  void onTapUp(TapUpEvent event) {
    findParent<Level>()?.interactWith(this);
  }

  @override
  void render(Canvas canvas) {
    if (!_tilled) return;

    _drawSoil(canvas);
    _drawPlant(canvas);

    if (_watered) {
      canvas.drawRect(
        Rect.fromLTWH(0.5, 0.5, size.x - 1, size.y - 1),
        _waterOutline,
      );
    }
  }

  void _drawPlant(Canvas canvas) {
    final crop = _crop;
    final stage = _stage;
    if (crop == null || stage == null) return;

    final sprite = _spriteAt(crop.stageSpritePath(stage));
    if (sprite != null) {
      final s = sprite.srcSize;
      sprite.render(
        canvas,
        position: Vector2(((size.x - s.x) / 2).roundToDouble(), size.y - s.y),
        size: s,
        overridePaint: _paint,
      );
      return;
    }

    // Placeholder: a bar that grows with the crop.
    final h = (size.y - 4) * (stage + 1) / crop.stages;
    canvas.drawRect(
      Rect.fromLTWH(size.x / 2 - 2, size.y - 2 - h, 4, h),
      _ready ? _ripe : _growing,
    );
  }

  void _drawSoil(Canvas canvas) {
    final sprite = _spriteAt(_soilTilled);
    if (sprite != null) {
      sprite.render(canvas, size: size, overridePaint: _paint);
      return;
    }
    canvas.drawRect(
      Rect.fromLTWH(1, 1, size.x - 2, size.y - 2),
      _dry,
    );
  }

  /// [path] is relative to assets/images/, without `.png`.
  Sprite? _spriteAt(String path) {
    return _sprites.putIfAbsent(path, () {
      try {
        return Sprite(game.images.fromCache('$path.png'));
      } catch (_) {
        debugPrint('Farm: no sprite $path.png (using a placeholder)');
        return null;
      }
    });
  }
}
