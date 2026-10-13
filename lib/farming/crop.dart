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
    this.stages = defaultStages,
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

  /// Number of growth pictures (see [stageSpritePath]). The last one is the
  /// ripe crop. Every crop has 3, all its own: planted seed, sprout, ripe.
  final int stages;

  /// Growth pictures every crop has: planted seed, sprout, ripe.
  static const int defaultStages = 3;

  /// How many [harvest] items one harvest gives (before luck).
  final int amount;

  /// File name prefix under assets/images/crops/, e.g. `corn`.
  final String sprite;

  /// Picture for a growth [stage] (0-based, as from [stageAfter]), as a path
  /// under assets/images/. For corn: `crops/corn_stage_1` (planted seed),
  /// `crops/corn_stage_2` (sprout), `crops/corn_stage_3` (ripe).
  String stageSpritePath(int stage) => 'crops/${sprite}_stage_${stage + 1}';

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
