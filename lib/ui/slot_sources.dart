import 'package:eppy_island/models/item.dart';
import 'package:eppy_island/models/player_profile.dart';
import 'package:eppy_island/models/shop.dart';
import 'package:eppy_island/ui/ui_contracts.dart';
import 'package:flutter/foundation.dart';

/// Slots that show the player's own items, filtered by [accepts].
class InventorySlotSource implements SlotSource {
  InventorySlotSource(this.profile, {required this.accepts});

  final PlayerProfile profile;
  final bool Function(Item item) accepts;

  @override
  late final Listenable changes = Listenable.merge([
    profile.inventory,
    profile.equipped,
  ]);

  List<ItemStack> get _visible => [
    for (final stack in profile.inventory.stacks)
      if (accepts(stack.item)) stack,
  ];

  @override
  ItemStack? stackAt(int index) {
    final visible = _visible;
    return (index >= 0 && index < visible.length) ? visible[index] : null;
  }

  @override
  bool isEquipped(int index) {
    final item = stackAt(index)?.item;
    return item != null && item == profile.equipped.value;
  }
}

/// Slots that show what the shop sells right now, one of each. They update
/// when the shop restocks.
class ShopSlotSource implements SlotSource {
  ShopSlotSource(this.shop);

  final Shop shop;

  @override
  Listenable get changes => shop;

  @override
  ItemStack? stackAt(int index) {
    return (index >= 0 && index < shop.stock.length)
        ? ItemStack(shop.stock[index], 1)
        : null;
  }

  @override
  bool isEquipped(int index) => false;
}
