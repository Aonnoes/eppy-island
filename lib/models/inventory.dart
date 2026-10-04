import 'dart:collection';

import 'package:eppy_island/models/item.dart';
import 'package:eppy_island/models/item_catalog.dart';
import 'package:flutter/foundation.dart';

/// What the player owns: up to [slotCount] different items, [maxStack] of each.
///
/// Notifies whenever something is added or removed, so the UI and the autosave
/// can follow it.
class Inventory extends ChangeNotifier {
  /// How many different items fit (matches the 3 x 3 grids in UI.tmx).
  static const int slotCount = 9;

  /// The most of one item that can be held.
  static const int maxStack = 99;

  final List<ItemStack> _stacks = [];

  /// The stacks in the order they were first acquired.
  UnmodifiableListView<ItemStack> get stacks => UnmodifiableListView(_stacks);

  int _indexOf(Item item) => _stacks.indexWhere((s) => s.item == item);

  int countOf(Item item) {
    final i = _indexOf(item);
    return i < 0 ? 0 : _stacks[i].quantity;
  }

  /// How many more of [item] would fit right now.
  int roomFor(Item item) {
    final i = _indexOf(item);
    if (i >= 0) return maxStack - _stacks[i].quantity;
    return _stacks.length < slotCount ? maxStack : 0;
  }

  bool canAdd(Item item, [int quantity = 1]) =>
      quantity > 0 && roomFor(item) >= quantity;

  /// Adds [quantity] of [item]. Returns false (and changes nothing) if it
  /// doesn't all fit.
  bool add(Item item, [int quantity = 1]) {
    if (!canAdd(item, quantity)) return false;

    final i = _indexOf(item);
    if (i >= 0) {
      _stacks[i] = ItemStack(item, _stacks[i].quantity + quantity);
    } else {
      _stacks.add(ItemStack(item, quantity));
    }
    notifyListeners();
    return true;
  }

  /// Removes [quantity] of [item]. Returns false (and changes nothing) if the
  /// player doesn't have that many.
  bool remove(Item item, [int quantity = 1]) {
    final i = _indexOf(item);
    if (i < 0 || quantity <= 0 || _stacks[i].quantity < quantity) return false;

    final left = _stacks[i].quantity - quantity;
    if (left == 0) {
      _stacks.removeAt(i);
    } else {
      _stacks[i] = ItemStack(item, left);
    }
    notifyListeners();
    return true;
  }

  // -------------------------------------------------------------------- json

  List<Map<String, Object>> toJson() => [
    for (final s in _stacks) {'id': s.item.id, 'quantity': s.quantity},
  ];

  /// Replaces the contents with the saved list. Unknown ids are skipped.
  void loadJson(Object? json, ItemCatalog catalog) {
    _stacks.clear();
    if (json is List) {
      for (final entry in json) {
        if (entry is! Map) continue;
        final item = catalog.byId('${entry['id']}');
        final quantity = (entry['quantity'] as num?)?.toInt() ?? 1;
        if (item == null) {
          debugPrint('Save: unknown item "${entry['id']}", skipped.');
          continue;
        }
        add(item, quantity.clamp(1, maxStack).toInt());
      }
    }
    notifyListeners();
  }
}
