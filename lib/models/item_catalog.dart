import 'dart:convert';

import 'package:eppy_island/models/item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Every item in the game, loaded from assets/data/items.json.
///
/// Save files and the shop refer to items by id; this turns an id back into
/// the [Item].
class ItemCatalog {
  ItemCatalog(Iterable<Item> items) : _byId = {for (final i in items) i.id: i};

  static const String assetPath = 'assets/data/items.json';

  final Map<String, Item> _byId;

  static Future<ItemCatalog> load([AssetBundle? bundle]) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final items = <Item>[];
    for (final entry in (json['items'] as List<dynamic>? ?? const [])) {
      try {
        items.add(Item.fromJson((entry as Map).cast<String, dynamic>()));
      } catch (error) {
        debugPrint('items.json: skipping bad entry $entry ($error)');
      }
    }
    return ItemCatalog(items);
  }

  /// The item with this id, or null if there is none.
  Item? byId(String id) => _byId[id];

  Iterable<Item> get all => _byId.values;
}
