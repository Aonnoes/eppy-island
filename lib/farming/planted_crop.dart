import 'package:eppy_island/farming/crop.dart';
import 'package:flutter/foundation.dart';

/// A crop growing in one plot.
///
/// A crop only grows while it is watered. To work that out from the clock
/// without ticking, it keeps [banked] growth up to [checkedAt], plus the
/// stretch of [wateredUntil] that has passed since.
@immutable
class PlantedCrop {
  const PlantedCrop(
    this.crop, {
    required this.banked,
    required this.checkedAt,
    this.wateredUntil,
  });

  final Crop crop;
  final Duration banked;
  final DateTime checkedAt;
  final DateTime? wateredUntil;

  /// Total watered growth at [now], never more than the crop needs.
  Duration growthAt(DateTime now) {
    var total = banked;
    final until = wateredUntil;
    if (until != null && until.isAfter(checkedAt)) {
      final end = now.isBefore(until) ? now : until;
      if (end.isAfter(checkedAt)) total += end.difference(checkedAt);
    }
    return total > crop.growTime ? crop.growTime : total;
  }

  /// How much water is left at [now] (zero when dry).
  Duration waterLeft(DateTime now) {
    final until = wateredUntil;
    return (until == null || !until.isAfter(now))
        ? Duration.zero
        : until.difference(now);
  }

  bool isWatered(DateTime now) => waterLeft(now) > Duration.zero;

  /// The same plant, watered at [now] for [length].
  PlantedCrop watered(DateTime now, Duration length) => PlantedCrop(
    crop,
    banked: growthAt(now),
    checkedAt: now,
    wateredUntil: now.add(length),
  );
}
