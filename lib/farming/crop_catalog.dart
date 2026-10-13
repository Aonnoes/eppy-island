import 'dart:convert';
import 'dart:math';

import 'package:eppy_island/farming/crop.dart';
import 'package:eppy_island/items/item.dart';
import 'package:eppy_island/items/item_catalog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Every crop in the game, loaded from assets/data/crops.json:
///
/// ```json
/// { "waterMinutes": 20,
///   "crops": [
///     { "id": "tomato", "seed": "tomato_seed", "harvest": "tomato_plant",
///       "growMinutes": 40, "regrowMinutes": 15, "stages": 4, "amount": 1 }
/// ] }
/// ```
///
/// `waterMinutes` is how long one watering lasts. `regrowMinutes` is optional.
class CropCatalog {
  CropCatalog(
    Iterable<Crop> crops, {
    this.waterTime = const Duration(minutes: 20),
  }) : _byId = {for (final c in crops) c.id: c},
       _bySeed = {for (final c in crops) c.seed.id: c};

  static const String assetPath = 'assets/data/crops.json';

  /// How long one watering keeps a plant growing.
  final Duration waterTime;

  final Map<String, Crop> _byId;
  final Map<String, Crop> _bySeed;

  static Future<CropCatalog> load(
    ItemCatalog items, [
    AssetBundle? bundle,
  ]) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    Duration minutes(num? value, num fallback) => Duration(
      milliseconds: max(1000, ((value ?? fallback) * 60000).round()),
    );

    final crops = <Crop>[];
    for (final entry in (json['crops'] as List<dynamic>? ?? const [])) {
      try {
        final map = (entry as Map).cast<String, dynamic>();
        final id = map['id'] as String;
        final seed = items.byId(map['seed'] as String);
        final harvest = items.byId(map['harvest'] as String);
        if (seed == null || harvest == null) {
          debugPrint('crops.json: "$id" uses an unknown item, skipped.');
          continue;
        }

        final grow = minutes(map['growMinutes'] as num?, 30);
        final regrowValue = map['regrowMinutes'] as num?;
        var regrow = regrowValue == null ? null : minutes(regrowValue, 0);
        if (regrow != null && regrow >= grow) regrow = grow; // Can't exceed it.

        crops.add(
          Crop(
            id: id,
            seed: seed,
            harvest: harvest,
            growTime: grow,
            regrowTime: regrow,
            stages: max(2, (map['stages'] as num?)?.toInt() ?? 4),
            amount: max(1, (map['amount'] as num?)?.toInt() ?? 1),
            sprite: map['sprite'] as String?,
          ),
        );
      } catch (error) {
        debugPrint('crops.json: skipping bad entry $entry ($error)');
      }
    }
    return CropCatalog(
      crops,
      waterTime: minutes(json['waterMinutes'] as num?, 20),
    );
  }

  Crop? byId(String id) => _byId[id];

  /// The crop this seed grows, or null if the item isn't a seed.
  Crop? forSeed(Item item) => _bySeed[item.id];
}

