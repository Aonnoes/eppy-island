import 'package:flutter/foundation.dart';

/// Something the player can own. Built from assets/data/items.json.
///
/// Two items are the same item if they have the same [id].
@immutable
class Item {
  const Item({
    required this.id,
    required this.name,
    required this.sprite,
    this.description = '',
    this.effectText = '',
    this.buyPrice = 0,
    this.sellPrice = 0,
  });

  /// Reads one entry of items.json. `"type": "equipment"` makes an
  /// [Equipment]; any other type is a plain item.
  factory Item.fromJson(Map<String, dynamic> json) {
    return json['type'] == 'equipment'
        ? Equipment.fromJson(json)
        : Item._fromJson(json);
  }

  Item._fromJson(Map<String, dynamic> json)
    : this(
        id: json['id'] as String,
        name: json['name'] as String,
        sprite: json['sprite'] as String? ?? json['id'] as String,
        description: json['description'] as String? ?? '',
        effectText: json['effect'] as String? ?? '',
        buyPrice: (json['buyPrice'] as num?)?.toInt() ?? 0,
        sellPrice: (json['sellPrice'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String name;

  /// File name (without .png) of the icon under assets/images/hud/.
  final String sprite;
  final String description;

  /// Short line shown under the name, e.g. "+1 luck".
  final String effectText;

  /// What the shop charges. 0 means the shop doesn't sell it.
  final int buyPrice;

  /// What the shop pays. 0 means it can't be sold.
  final int sellPrice;

  @override
  bool operator ==(Object other) => other is Item && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Item($id)';
}

/// An item that can be worn. Wearing it adds [luckBonus] to the player's luck.
@immutable
class Equipment extends Item {
  const Equipment({
    required super.id,
    required super.name,
    required super.sprite,
    super.description,
    super.effectText,
    super.buyPrice,
    super.sellPrice,
    this.luckBonus = 0,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    final luck = (json['luck'] as num?)?.toInt() ?? 0;
    return Equipment(
      id: json['id'] as String,
      name: json['name'] as String,
      sprite: json['sprite'] as String? ?? json['id'] as String,
      description: json['description'] as String? ?? '',
      effectText:
          json['effect'] as String? ?? (luck != 0 ? '+$luck luck' : ''),
      buyPrice: (json['buyPrice'] as num?)?.toInt() ?? 0,
      sellPrice: (json['sellPrice'] as num?)?.toInt() ?? 0,
      luckBonus: luck,
    );
  }

  final int luckBonus;
}

/// [quantity] of one [item], as held in an inventory slot.
@immutable
class ItemStack {
  const ItemStack(this.item, this.quantity);

  final Item item;
  final int quantity;
}
