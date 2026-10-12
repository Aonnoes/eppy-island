import 'package:eppy_island/models/items.dart';
import 'package:eppy_island/models/player_profile.dart';
import 'package:eppy_island/models/shop.dart';
import 'package:flutter/foundation.dart';

/// Where a grid of slots gets its items from.
abstract class SlotSource {
  /// Notifies when what the slots should show may have changed.
  Listenable get changes;

  /// The stack shown in slot [index], or null if the slot is empty.
  ItemStack? stackAt(int index);

  /// Whether slot [index] holds the currently equipped item.
  bool isEquipped(int index) => false;
}

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

/// Which slot is selected on the open screen, and how many to buy or sell.
class UiSelection extends ChangeNotifier {
  String? _kind;
  int? _index;
  Item? _item;
  int _quantity = 1;

  String? get kind => _kind;
  int? get index => _index;
  Item? get item => _item;
  int get quantity => _quantity;
  bool get hasSelection => _item != null;

  bool isSelected(String kind, int index) =>
      _item != null && _kind == kind && _index == index;

  void select(String kind, int index, Item item) {
    _kind = kind;
    _index = index;
    _item = item;
    _quantity = 1;
    notifyListeners();
  }

  void setQuantity(int value) {
    if (_item == null || value == _quantity) return;
    _quantity = value;
    notifyListeners();
  }

  void clear() {
    if (_item == null) return;
    _kind = null;
    _index = null;
    _item = null;
    _quantity = 1;
    notifyListeners();
  }
}

/// What the UI needs from the game. Implemented by UiController.
abstract class UiDelegate {
  /// Live values labels and images can follow with `bind`.
  Map<String, ValueListenable<Object?>> get bindings;

  /// Item sources for slots, keyed by the slot's `kind`.
  Map<String, SlotSource> get slotSources;

  UiSelection get selection;

  void onSlotTapped(String kind, int index);

  /// Handles a button action the UI doesn't know. Returns true if handled.
  bool onAction(String action);

  /// Called when a screen opens or closes: forget the selection and message.
  void reset();
}
