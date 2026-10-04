import 'dart:convert';
import 'dart:math';

import 'package:eppy_island/models/item.dart';
import 'package:eppy_island/models/item_catalog.dart';
import 'package:eppy_island/models/player_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// An item the shop can stock, and how likely it is to be picked.
/// A [weight] of 10 turns up about ten times as often as a weight of 1.
class ShopEntry {
  const ShopEntry(this.item, [this.weight = 1]);

  final Item item;
  final int weight;
}

/// The shop. Its [slots] items are re-rolled from a [pool] every
/// [refreshInterval] (one hour by default).
///
/// The roll is seeded by the clock, not by chance: everyone gets the same
/// stock during the same hour, and closing and reopening the game doesn't
/// change it. Nothing about the stock needs saving.
///
/// Call [refreshIfDue] regularly (the game does it once a second). It
/// notifies listeners when the stock changes, and keeps [restockText] up to
/// date for the countdown label.
///
/// [buy] and [sell] return null on success, or the reason the deal failed
/// (shown to the player as-is).
class Shop extends ChangeNotifier {
  Shop({
    required this.pool,
    this.slots = 9,
    this.refreshInterval = const Duration(hours: 1),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const String assetPath = 'assets/data/shop.json';

  /// Everything the shop might stock.
  final List<ShopEntry> pool;

  /// How many items are for sale at once (the Buy screen has 9 slots).
  final int slots;

  final Duration refreshInterval;
  final DateTime Function() _clock;

  /// e.g. "Restocks in 42:10", for a label bound to `restock`.
  final ValueNotifier<String> restockText = ValueNotifier<String>('');

  List<Item> _stock = const [];
  int _period = -1;

  /// What is for sale right now, in the order shown on the Buy screen.
  List<Item> get stock => _stock;

  /// Reads assets/data/shop.json:
  ///
  /// ```json
  /// { "slots": 9, "refreshMinutes": 60,
  ///   "pool": [ { "id": "turnip_seed", "weight": 10 }, "carrot_seed" ] }
  /// ```
  static Future<Shop> load(
    ItemCatalog catalog, {
    AssetBundle? bundle,
    DateTime Function()? clock,
  }) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final pool = <ShopEntry>[];
    for (final entry in (json['pool'] as List<dynamic>? ?? const [])) {
      final id = entry is Map ? '${entry['id']}' : '$entry';
      final weight = entry is Map ? (entry['weight'] as num?)?.toInt() ?? 1 : 1;

      final item = catalog.byId(id);
      if (item == null) {
        debugPrint('shop.json: unknown item "$id", skipped.');
      } else if (item.buyPrice <= 0) {
        debugPrint('shop.json: "$id" has no buyPrice, skipped.');
      } else {
        pool.add(ShopEntry(item, max(1, weight)));
      }
    }

    final shop = Shop(
      pool: pool,
      slots: (json['slots'] as num?)?.toInt() ?? 9,
      refreshInterval: Duration(
        minutes: max(1, (json['refreshMinutes'] as num?)?.toInt() ?? 60),
      ),
      clock: clock,
    );
    shop.refreshIfDue();
    return shop;
  }

  // ----------------------------------------------------------------- restock

  /// Re-rolls the stock if a new period has started, and updates
  /// [restockText]. Returns true if the stock changed.
  bool refreshIfDue([DateTime? now]) {
    now ??= _clock();
    final interval = refreshInterval.inMilliseconds;

    // Local time, so a one-hour shop restocks on the hour on the clock.
    final local = now.millisecondsSinceEpoch + now.timeZoneOffset.inMilliseconds;
    final period = local ~/ interval;

    restockText.value =
        'Restocks in ${_format(Duration(milliseconds: (period + 1) * interval - local))}';

    if (period == _period) return false;
    _period = period;
    _stock = _roll(period);
    notifyListeners();
    return true;
  }

  /// Picks [slots] different items from the pool, weighted, using a random
  /// generator seeded with [period] so the same period always gives the same
  /// stock.
  List<Item> _roll(int period) {
    final random = Random(period);
    final left = [...pool];
    final picked = <Item>[];

    while (picked.length < slots && left.isNotEmpty) {
      final total = left.fold<int>(0, (sum, e) => sum + e.weight);
      var roll = random.nextInt(total);
      for (var i = 0; i < left.length; i++) {
        roll -= left[i].weight;
        if (roll < 0) {
          picked.add(left.removeAt(i).item);
          break;
        }
      }
    }
    return picked;
  }

  static String _format(Duration d) {
    final total = d.isNegative ? 0 : d.inSeconds;
    final h = total ~/ 3600;
    final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // ------------------------------------------------------------ transactions

  String? buy(PlayerProfile profile, Item item, int quantity) {
    if (quantity < 1) return 'Pick a quantity';
    if (!_stock.contains(item)) return 'No longer in stock';

    final total = item.buyPrice * quantity;
    if (profile.coins.value < total) return 'Not enough coins';
    if (!profile.inventory.canAdd(item, quantity)) {
      return profile.inventory.countOf(item) > 0
          ? 'You can\'t carry that many'
          : 'Inventory full';
    }

    profile.spendCoins(total);
    profile.inventory.add(item, quantity);
    return null;
  }

  String? sell(PlayerProfile profile, Item item, int quantity) {
    if (quantity < 1) return 'Pick a quantity';
    if (item.sellPrice <= 0) return 'Can\'t be sold';
    if (profile.inventory.countOf(item) < quantity) {
      return 'You don\'t have enough';
    }

    profile.inventory.remove(item, quantity);
    profile.addCoins(item.sellPrice * quantity);
    return null;
  }
}
