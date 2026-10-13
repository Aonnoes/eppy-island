

/// Everything that goes in the save file.
///
/// ```json
/// {
///   "version": 1,
///   "player": { "username": ..., "coins": ..., "luck": ..., "inventory": [...] },
///   "world":  { "level": "Level-01", "x": 120.0, "y": 64.0 }
/// }
/// ```
class SaveData {
  SaveData({
    required this.player,
    required this.level,
    this.farm,
    this.x,
    this.y,
  });

  static const int version = 1;
  static const String defaultLevel = 'Level-01';

  /// The player's profile, as written by `PlayerProfile.toJson()`.
  final Map<String, dynamic> player;

  /// The farm, as written by `Farm.toJson()`. Null for saves made before
  /// farming existed (an empty farm is used).
  final Map<String, dynamic>? farm;

  /// Name of the level the player is in, e.g. `Level-01`.
  final String level;

  /// Where the player stands in [level]. Null means "use the spawn point".
  final double? x;
  final double? y;

  bool get hasPosition => x != null && y != null;

  factory SaveData.fromJson(Map<String, dynamic> json) {
    final player = json['player'];
    if (player is! Map) {
      throw const FormatException('Save file has no "player" section.');
    }

    final farm = json['farm'];
    final world = json['world'];
    final worldMap = world is Map ? world.cast<String, dynamic>() : const {};
    final level = worldMap['level'];

    return SaveData(
      player: player.cast<String, dynamic>(),
      farm: farm is Map ? farm.cast<String, dynamic>() : null,
      level: level is String && level.isNotEmpty ? level : defaultLevel,
      x: (worldMap['x'] as num?)?.toDouble(),
      y: (worldMap['y'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'player': player,
    if (farm != null) 'farm': farm,
    'world': {'level': level, if (hasPosition) 'x': x, if (hasPosition) 'y': y},
  };
}
