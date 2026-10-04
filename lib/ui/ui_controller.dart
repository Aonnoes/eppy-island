import 'dart:math' as math;

import 'package:eppy_island/models/inventory.dart';
import 'package:eppy_island/models/item.dart';
import 'package:eppy_island/models/player_profile.dart';
import 'package:eppy_island/models/shop.dart';
import 'package:eppy_island/ui/slot_sources.dart';
import 'package:eppy_island/ui/ui_contracts.dart';
import 'package:flutter/foundation.dart';

/// The game rules behind the UI: what each slot shows, what tapping it does,
/// and what the buy / sell / quantity buttons do.
///
/// Values labels can `bind` to:
///
///   username, user_image, coins, luck, equipped_name,
///   item_name, item_effect, item_description, item_sprite,
///   item_price (one), total_price (quantity x one), quantity, message,
///   restock (countdown to the shop's next restock),
///   star1 .. star4 (sprite name for each luck star)
///
/// Button actions handled here: qty_up, qty_down, confirm.
class UiController implements UiDelegate {
  UiController({required this.profile, required this.shop}) {
    profile.inventory.addListener(_revalidate);
    profile.coins.addListener(_revalidate);
    profile.equipped.addListener(_updateEquippedName);
    profile.luck.addListener(_updateStars);
    shop.addListener(_onRestock);
    selection.addListener(_publish);
    _updateEquippedName();
    _updateStars();
    _publish();
  }

  /// Luck 1-100 is shown as 4 stars: each star is worth 25 luck, and gets a
  /// half star at 12.5.
  static const int starCount = 4;
  static const double _luckPerStar = 25;

  final PlayerProfile profile;
  final Shop shop;

  @override
  final UiSelection selection = UiSelection();

  final ValueNotifier<String> _equippedName = ValueNotifier<String>('');
  final ValueNotifier<String> _itemName = ValueNotifier<String>('');
  final ValueNotifier<String> _itemEffect = ValueNotifier<String>('');
  final ValueNotifier<String> _itemDescription = ValueNotifier<String>('');
  final ValueNotifier<String> _itemSprite = ValueNotifier<String>('');
  final ValueNotifier<String> _itemPrice = ValueNotifier<String>('');
  final ValueNotifier<String> _totalPrice = ValueNotifier<String>('');
  final ValueNotifier<String> _quantity = ValueNotifier<String>('');
  final ValueNotifier<String> _message = ValueNotifier<String>('');
  final List<ValueNotifier<String>> _stars = List.generate(
    starCount,
    (_) => ValueNotifier<String>('star_empty'),
  );

  @override
  late final Map<String, ValueListenable<Object?>> bindings = {
    'username': profile.username,
    'user_image': profile.userImage,
    'coins': profile.coins,
    'luck': profile.luck,
    'equipped_name': _equippedName,
    'item_name': _itemName,
    'item_effect': _itemEffect,
    'item_description': _itemDescription,
    'item_sprite': _itemSprite,
    'item_price': _itemPrice,
    'total_price': _totalPrice,
    'quantity': _quantity,
    'message': _message,
    'restock': shop.restockText,
    for (var i = 0; i < starCount; i++) 'star${i + 1}': _stars[i],
  };

  @override
  late final Map<String, SlotSource> slotSources = {
    // Inventory screen: everything that isn't equipment.
    'item': InventorySlotSource(profile, accepts: (i) => i is! Equipment),
    // Equipment screen: owned equipment, with the equipped one highlighted.
    'equipment': InventorySlotSource(profile, accepts: (i) => i is Equipment),
    // Sell screen: anything the player owns.
    'sell': InventorySlotSource(profile, accepts: (_) => true),
    // Buy screen: the shop's stock.
    'buy': ShopSlotSource(shop),
  };

  // ------------------------------------------------------------------ input

  @override
  void reset() {
    selection.clear();
    _message.value = '';
  }

  @override
  void onSlotTapped(String kind, int index) {
    final stack = slotSources[kind]?.stackAt(index);
    if (stack == null) {
      selection.clear();
      return;
    }

    _message.value = '';
    selection.select(kind, index, stack.item);

    if (kind == 'equipment') _toggleEquip(stack.item);
  }

  @override
  bool onAction(String action) {
    switch (action) {
      case 'qty_up':
        _changeQuantity(1);
        return true;
      case 'qty_down':
        _changeQuantity(-1);
        return true;
      case 'confirm':
        _confirm();
        return true;
      default:
        return false;
    }
  }

  void _toggleEquip(Item item) {
    if (item is! Equipment) return;
    if (profile.equipped.value == item) {
      profile.unequip();
      _message.value = 'Unequipped ${item.name}';
    } else if (profile.equip(item)) {
      _message.value = 'Equipped ${item.name}';
    }
  }

  void _changeQuantity(int delta) {
    if (!selection.hasSelection) return;
    final wanted = selection.quantity + delta;
    selection.setQuantity(math.max(1, math.min(_maxQuantity(), wanted)));
  }

  /// The most the player can buy (coins and room permitting) or sell (what
  /// they own). Never less than 1, so the counter always shows something.
  int _maxQuantity() {
    final item = selection.item;
    if (item == null) return 1;

    switch (selection.kind) {
      case 'sell':
        return math.max(1, profile.inventory.countOf(item));
      case 'buy':
        final affordable = item.buyPrice <= 0
            ? Inventory.maxStack
            : profile.coins.value ~/ item.buyPrice;
        final room = profile.inventory.roomFor(item);
        return math.max(1, math.min(affordable, room));
      default:
        return 1;
    }
  }

  void _confirm() {
    final item = selection.item;
    if (item == null) {
      _message.value = 'Pick an item first';
      return;
    }

    final quantity = selection.quantity;
    final kind = selection.kind;
    final String? error = switch (kind) {
      'buy' => shop.buy(profile, item, quantity),
      'sell' => shop.sell(profile, item, quantity),
      _ => 'Nothing to confirm here',
    };

    if (error != null) {
      _message.value = error;
      return;
    }
    _message.value = kind == 'buy'
        ? 'Bought $quantity ${item.name}'
        : 'Sold $quantity ${item.name}';
  }

  // ---------------------------------------------------------------- derived

  /// Keeps the selection valid when coins or the inventory change: a sold-out
  /// item is deselected, and the quantity never exceeds what's possible.
  void _revalidate() {
    final kind = selection.kind;
    final index = selection.index;
    if (kind == null || index == null) return;

    final stack = slotSources[kind]?.stackAt(index);
    if (stack == null || stack.item != selection.item) {
      selection.clear();
      return;
    }
    selection.setQuantity(math.min(selection.quantity, _maxQuantity()));
  }

  /// The shop re-rolled its stock while a Buy item was selected.
  void _onRestock() {
    if (selection.kind != 'buy' || !selection.hasSelection) return;
    _revalidate();
    if (!selection.hasSelection) _message.value = 'The shop restocked';
  }

  /// Sprite for the [star]th star (1-based) at this luck.
  static String starSprite(int luck, int star) {
    final start = (star - 1) * _luckPerStar;
    if (luck >= start + _luckPerStar) return 'star_full';
    if (luck >= start + _luckPerStar / 2) return 'star_half';
    return 'star_empty';
  }

  void _updateStars() {
    for (var i = 0; i < starCount; i++) {
      _stars[i].value = starSprite(profile.luck.value, i + 1);
    }
  }

  void _updateEquippedName() {
    _equippedName.value = profile.equipped.value?.name ?? '';
  }

  /// Copies the selection into the values labels are bound to.
  void _publish() {
    final item = selection.item;
    _itemName.value = item?.name ?? '';
    _itemEffect.value = item?.effectText ?? '';
    _itemDescription.value = item?.description ?? '';
    _itemSprite.value = item?.sprite ?? '';

    if (item == null) {
      _itemPrice.value = '';
      _totalPrice.value = '';
      _quantity.value = '';
      return;
    }
    final unit = selection.kind == 'buy' ? item.buyPrice : item.sellPrice;
    _itemPrice.value = '$unit';
    _totalPrice.value = '${unit * selection.quantity}';
    _quantity.value = '${selection.quantity}';
  }
}
