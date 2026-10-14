import 'dart:convert';
import 'dart:math';

import 'package:eppy_island/dungeon/minigame.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One monster the player can meet in the dungeon. Built from
/// assets/data/enemies.json.
@immutable
class Enemy {
  const Enemy({
    required this.id,
    required this.name,
    required this.minigame,
    this.portrait = '',
    this.stars = 1,
    this.reward = 0,
    this.penalty = 0,
  });

  /// The most stars the encounter screen shows (the same 4 as the luck stars).
  static const int maxStars = 4;

  final String id;
  final String name;

  /// Which minigame this enemy plays: `rock_paper_scissors`, `high_low` or
  /// `dice` (see [createMinigame]).
  final String minigame;

  /// Portrait, without .png. A name with a folder in it (`dungeon/sauesta`) is
  /// a path under assets/images/. Missing art shows the enemy's first letter.
  final String portrait;

  /// Difficulty shown under the portrait, 1 to [maxStars].
  final int stars;

  /// Coins won for beating this enemy.
  final int reward;

  /// Coins lost for losing to it (never more than the player has).
  final int penalty;
}

/// Every enemy in the game, loaded from assets/data/enemies.json:
///
/// ```json
/// { "enemies": [
///   { "id": "sauesta", "name": "Sauesta", "portrait": "dungeon/sauesta",
///     "minigame": "high_low", "stars": 2, "reward": 30, "penalty": 10 }
/// ] }
/// ```
class EnemyCatalog {
  EnemyCatalog(Iterable<Enemy> enemies) : enemies = List.unmodifiable(enemies);

  static const String assetPath = 'assets/data/enemies.json';

  final List<Enemy> enemies;

  bool get isEmpty => enemies.isEmpty;

  /// Reads the file. A missing or broken file gives an empty catalog (and a
  /// log line) so the rest of the game still runs.
  static Future<EnemyCatalog> load([AssetBundle? bundle]) async {
    final enemies = <Enemy>[];
    try {
      final raw = await (bundle ?? rootBundle).loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in (json['enemies'] as List<dynamic>? ?? const [])) {
        try {
          final map = (entry as Map).cast<String, dynamic>();
          final id = map['id'] as String;
          final minigame = map['minigame'] as String;
          if (createMinigame(minigame) == null) {
            debugPrint('enemies.json: "$id" has unknown minigame "$minigame".');
            continue;
          }
          enemies.add(
            Enemy(
              id: id,
              name: map['name'] as String? ?? id,
              minigame: minigame,
              portrait: map['portrait'] as String? ?? '',
              stars: ((map['stars'] as num?)?.toInt() ?? 1).clamp(
                1,
                Enemy.maxStars,
              ),
              reward: max(0, (map['reward'] as num?)?.toInt() ?? 0),
              penalty: max(0, (map['penalty'] as num?)?.toInt() ?? 0),
            ),
          );
        } catch (error) {
          debugPrint('enemies.json: skipping bad entry $entry ($error)');
        }
      }
    } catch (error) {
      debugPrint('Dungeon: could not load $assetPath ($error).');
    }
    return EnemyCatalog(enemies);
  }

  /// A random enemy, or null if there are none.
  Enemy? pick(Random random) =>
      enemies.isEmpty ? null : enemies[random.nextInt(enemies.length)];
}
