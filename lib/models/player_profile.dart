import 'dart:collection';

import 'package:eppy_island/models/items.dart';
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

/// Who the player is: name, picture, coins, luck, inventory and equipment.
///
/// Every value a label can show is a [ValueNotifier], so the UI updates by
/// itself. [toJson] / [PlayerProfile.fromJson] are what the save file uses.
class PlayerProfile {
  PlayerProfile({
    required String username,
    String userImage = defaultUserImage,
    this.character = 'Teemo',
    int coins = 0,
    int baseLuck = 1,
  }) : username = ValueNotifier<String>(username),
       userImage = ValueNotifier<String>(userImage),
       coins = ValueNotifier<int>(coins),
       _baseLuck = baseLuck,
       luck = ValueNotifier<int>(baseLuck) {
    equipped.addListener(_updateLuck);
    inventory.addListener(_dropEquippedIfGone);
    _updateLuck();
  }

  /// Reads the `player` part of a save file. Anything missing gets a default.
  factory PlayerProfile.fromJson(
    Map<String, dynamic> json,
    ItemCatalog catalog,
  ) {
    final profile = PlayerProfile(
      username: json['username'] as String? ?? 'Player',
      userImage: json['userImage'] as String? ?? defaultUserImage,
      character: json['character'] as String? ?? 'Teemo',
      coins: _atLeastZero((json['coins'] as num?)?.toInt() ?? 0),
      baseLuck: (json['luck'] as num?)?.toInt() ?? minLuck,
    );

    profile.inventory.loadJson(json['inventory'], catalog);

    final equippedId = json['equipped'] as String?;
    if (equippedId != null) {
      final item = catalog.byId(equippedId);
      if (item is Equipment) profile.equip(item);
    }
    return profile;
  }

  /// Sprite name of the profile picture when none is chosen.
  static const String defaultUserImage = 'userimage';

  /// Luck always stays between these two values.
  static const int minLuck = 1;
  static const int maxLuck = 100;

  /// Which sprite sheet folder the player character uses.
  final String character;

  final ValueNotifier<String> username;

  /// Sprite name under assets/images/hud/.
  final ValueNotifier<String> userImage;
  final ValueNotifier<int> coins;

  /// Luck shown in the UI: the base luck plus the equipped item's bonus,
  /// kept between [minLuck] and [maxLuck].
  final ValueNotifier<int> luck;

  final Inventory inventory = Inventory();
  final ValueNotifier<Equipment?> equipped = ValueNotifier<Equipment?>(null);

  int _baseLuck;

  /// Luck without equipment. This is what gets saved.
  int get baseLuck => _baseLuck;
  set baseLuck(int value) {
    _baseLuck = value;
    _updateLuck();
  }

  /// Fires when anything worth saving changes.
  late final Listenable changes = Listenable.merge([
    username,
    userImage,
    coins,
    luck,
    inventory,
    equipped,
  ]);

  // ------------------------------------------------------------------- coins

  void addCoins(int amount) => coins.value += amount;

  /// Takes [amount] coins if the player has them. Returns false otherwise.
  bool spendCoins(int amount) {
    if (amount < 0 || coins.value < amount) return false;
    coins.value -= amount;
    return true;
  }

  // --------------------------------------------------------------- equipment

  /// Wears [item]. Fails if the player doesn't own it.
  bool equip(Equipment item) {
    if (inventory.countOf(item) < 1) return false;
    equipped.value = item;
    return true;
  }

  void unequip() => equipped.value = null;

  void _updateLuck() {
    luck.value = (_baseLuck + (equipped.value?.luckBonus ?? 0))
        .clamp(minLuck, maxLuck)
        .toInt();
  }

  /// Selling the worn item takes it off.
  void _dropEquippedIfGone() {
    final item = equipped.value;
    if (item != null && inventory.countOf(item) < 1) unequip();
  }

  // -------------------------------------------------------------------- json

  Map<String, dynamic> toJson() => {
    'username': username.value,
    'userImage': userImage.value,
    'character': character,
    'coins': coins.value,
    'luck': _baseLuck,
    'equipped': equipped.value?.id,
    'inventory': inventory.toJson(),
  };
}

int _atLeastZero(int value) => value < 0 ? 0 : value;
