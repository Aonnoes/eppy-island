import 'package:flame/components.dart';

/// An invisible trigger block. When the player overlaps it, the game loads
/// [targetLevel] and (optionally) places the player at the spawn point named
/// [targetSpawn] in that level.
///
/// Unlike a [CollisionBlock], a warp block never blocks movement.
class WarpBlock extends PositionComponent {
  WarpBlock({
    required Vector2 position,
    required Vector2 size,
    required this.targetLevel,
    this.targetSpawn,
  }) : super(position: position, size: size);

  final String targetLevel;
  final String? targetSpawn;
}
