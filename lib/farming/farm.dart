import 'dart:math';

import 'package:eppy_island/farming/crop.dart';
import 'package:eppy_island/farming/crop_catalog.dart';
import 'package:eppy_island/farming/planted_crop.dart';
import 'package:eppy_island/items/item.dart';
import 'package:eppy_island/items/item_catalog.dart';
import 'package:eppy_island/profile/player_profile.dart';
import 'package:eppy_island/utils/time_format.dart';
import 'package:flutter/foundation.dart';

/// All the farmland: which plots are tilled, what is growing in them, and the
/// rules for tilling, planting, watering and harvesting.
///
/// Plots are identified by a string key (made by Level, e.g.
/// "Level-01:12:0,1"), so crops stay in the level they were planted in.
///
/// Pressing the action key on a plot ([interact]) does the next thing it
/// needs: till -> plant -> water -> (wait) -> harvest. Crops that regrow go
/// back to being watered after a harvest; the others leave tilled soil.
///
/// Growth follows the clock, so it carries on while the game is closed. Only
/// small timestamps are saved.
class Farm extends ChangeNotifier {
  Farm({required this.crops, DateTime Function()? clock, Random? random})
    : _clock = clock ?? DateTime.now,
      _random = random ?? Random();

  final CropCatalog crops;
  final DateTime Function() _clock;
  final Random _random;

  /// The seed the player plants next (picked on the Seeds screen). If it is
  /// null or used up, the first seed in the inventory is used.
  final ValueNotifier<Item?> activeSeed = ValueNotifier<Item?>(null);

  /// Short feedback line ("Planted Corn Seed"), clears itself.
  final ValueNotifier<String> notice = ValueNotifier<String>('');

  final Set<String> _tilled = {};
  final Map<String, PlantedCrop> _planted = {};
  int _noticeToken = 0;

  /// Fires when anything worth saving changes.
  late final Listenable changes = Listenable.merge([this, activeSeed]);

  // ----------------------------------------------------------------- queries

  PlantedCrop? plantedAt(String plotKey) => _planted[plotKey];

  bool isTilled(String plotKey) =>
      _tilled.contains(plotKey) || _planted.containsKey(plotKey);

  bool isWatered(String plotKey) =>
      _planted[plotKey]?.isWatered(_clock()) ?? false;

  /// Picture index to show for the plot, or null if nothing is planted.
  int? stageOf(String plotKey) {
    final p = _planted[plotKey];
    return p?.crop.stageAfter(p.growthAt(_clock()));
  }

  bool isReady(String plotKey) {
    final p = _planted[plotKey];
    return p != null && p.crop.isReady(p.growthAt(_clock()));
  }

  // ------------------------------------------------------------------- seeds

  void selectSeed(Item item) {
    if (crops.forSeed(item) == null) return;
    activeSeed.value = item;
  }

  /// The seed that would be planted now, or null if the player has none.
  Item? seedToPlant(PlayerProfile profile) {
    final active = activeSeed.value;
    if (active != null && profile.inventory.countOf(active) > 0) return active;
    for (final stack in profile.inventory.stacks) {
      if (crops.forSeed(stack.item) != null) return stack.item;
    }
    return null;
  }

  // ------------------------------------------------------------- interaction

  /// Does the next needed thing for this plot, shows the result in [notice]
  /// and returns it.
  String interact(PlayerProfile profile, String plotKey) {
    final planted = _planted[plotKey];
    final String message;

    if (planted == null) {
      message = isTilled(plotKey) ? _plant(profile, plotKey) : _till(plotKey);
    } else if (planted.crop.isReady(planted.growthAt(_clock()))) {
      message = _harvest(profile, plotKey, planted);
    } else {
      message = _tend(plotKey, planted);
    }

    say(message);
    return message;
  }

  String _till(String plotKey) {
    _tilled.add(plotKey);
    notifyListeners();
    return 'Tilled the soil';
  }

  String _plant(PlayerProfile profile, String plotKey) {
    final seed = seedToPlant(profile);
    if (seed == null) return 'You have no seeds';
    final crop = crops.forSeed(seed)!;

    profile.inventory.remove(seed, 1);
    _tilled.add(plotKey);
    _planted[plotKey] = PlantedCrop(
      crop,
      banked: Duration.zero,
      checkedAt: _clock(),
    );
    notifyListeners();
    return 'Planted ${seed.name}';
  }

  /// A growing crop: water it if it is dry (or nearly), else show progress.
  String _tend(String plotKey, PlantedCrop planted) {
    final now = _clock();
    final crop = planted.crop;

    if (planted.waterLeft(now) < crops.waterTime ~/ 2) {
      _planted[plotKey] = planted.watered(now, crops.waterTime);
      notifyListeners();
      return 'Watered the ${crop.harvest.name}';
    }
    final left = crop.growTime - planted.growthAt(now);
    return '${crop.harvest.name}: ${formatCountdown(left)} to go';
  }

  String _harvest(PlayerProfile profile, String plotKey, PlantedCrop planted) {
    final crop = planted.crop;

    // Luck is a percentage chance (1-100) of one extra crop.
    var lucky = _random.nextInt(100) < profile.luck.value;
    var amount = crop.amount + (lucky ? 1 : 0);

    if (!profile.inventory.canAdd(crop.harvest, amount)) {
      lucky = false;
      amount = crop.amount;
      if (!profile.inventory.canAdd(crop.harvest, amount)) {
        return 'Inventory full';
      }
    }

    if (crop.regrows) {
      // Stays planted, dry, part-way back to ripe.
      _planted[plotKey] = PlantedCrop(
        crop,
        banked: crop.growthAfterHarvest,
        checkedAt: _clock(),
      );
    } else {
      _planted.remove(plotKey); // The soil stays tilled.
    }
    profile.inventory.add(crop.harvest, amount);
    notifyListeners();
    return 'Harvested $amount ${crop.harvest.name}${lucky ? ' (lucky!)' : ''}';
  }

  /// Shows [message] on the HUD for a couple of seconds.
  void say(String message) {
    final token = ++_noticeToken;
    notice.value = message;
    Future<void>.delayed(const Duration(milliseconds: 2500), () {
      if (token == _noticeToken) notice.value = '';
    });
  }

  // -------------------------------------------------------------------- json

  Map<String, dynamic> toJson() => {
    'seed': activeSeed.value?.id,
    'tilled': [..._tilled],
    'plots': {
      for (final e in _planted.entries)
        e.key: {
          'crop': e.value.crop.id,
          'banked': e.value.banked.inMilliseconds,
          'checkedAt': e.value.checkedAt.millisecondsSinceEpoch,
          if (e.value.wateredUntil != null)
            'wateredUntil': e.value.wateredUntil!.millisecondsSinceEpoch,
        },
    },
  };

  /// Replaces the farm with the saved one. Unknown crops are skipped.
  void loadJson(Object? json, ItemCatalog items) {
    _tilled.clear();
    _planted.clear();

    if (json is Map) {
      final seedId = json['seed'];
      if (seedId is String) activeSeed.value = items.byId(seedId);

      final tilled = json['tilled'];
      if (tilled is List) _tilled.addAll(tilled.map((e) => '$e'));

      final plots = json['plots'];
      if (plots is Map) {
        plots.forEach((key, value) {
          if (value is! Map) return;
          final crop = crops.byId('${value['crop']}');
          final checked = (value['checkedAt'] as num?)?.toInt();
          if (crop == null || checked == null) {
            debugPrint('Save: bad plot "$key", skipped.');
            return;
          }
          final until = (value['wateredUntil'] as num?)?.toInt();
          _planted['$key'] = PlantedCrop(
            crop,
            banked: Duration(
              milliseconds: (value['banked'] as num?)?.toInt() ?? 0,
            ),
            checkedAt: DateTime.fromMillisecondsSinceEpoch(checked),
            wateredUntil: until == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(until),
          );
        });
      }
    }
    notifyListeners();
  }
}

