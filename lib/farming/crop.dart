import 'package:eppy_island/items/item.dart';
import 'package:flutter/foundation.dart';

/// Something that can be planted: which seed grows it, what it gives, and how
/// long it takes. Built from assets/data/crops.json.
@immutable
class Crop {
  const Crop({
    required this.id,
    required this.seed,
    required this.harvest,
    required this.growTime,
    this.regrowTime,
    this.stages = 4,
    this.amount = 1,
    String? sprite,
  }) : sprite = sprite ?? id;

  final String id;

  /// The item that is used up when planting.
  final Item seed;

  /// The item the player receives when harvesting.
  final Item harvest;

  /// Time spent *watered* from planting until the crop can be harvested.
  final Duration growTime;

  /// If set, harvesting leaves the plant in the ground and it ripens again
  /// after this much watered time. Null means a one-time crop.
  final Duration? regrowTime;

  /// Number of pictures: `crops/<sprite>_0.png` .. `_<stages-1>.png`.
  /// The last one is the ripe crop.
  final int stages;

  /// How many [harvest] items one harvest gives (before luck).
  final int amount;

  /// Sprite name prefix under assets/images/crops/.
  final String sprite;

  bool get regrows => regrowTime != null;

  /// Growth to start from after a harvest of a regrowing crop.
  Duration get growthAfterHarvest =>
      regrowTime == null ? Duration.zero : growTime - regrowTime!;

  bool isReady(Duration grown) => grown >= growTime;

  /// Which picture to show after [grown] watered time: 0 .. stages - 1.
  int stageAfter(Duration grown) {
    if (grown >= growTime) return stages - 1;
    if (grown <= Duration.zero) return 0;
    final progress = grown.inMilliseconds / growTime.inMilliseconds;
    return (progress * (stages - 1)).floor();
  }
}
