import 'package:flame/components.dart';

/// Axis-aligned bounding box overlap test between two components.
bool checkCollision(PositionComponent a, PositionComponent b) {
  return a.x < b.x + b.width &&
      a.x + a.width > b.x &&
      a.y < b.y + b.height &&
      a.y + a.height > b.y;
}

/// A solid rectangle that other components cannot walk through.
class CollisionBlock extends PositionComponent {
  CollisionBlock({required Vector2 position, required Vector2 size})
    : super(position: position, size: size) {
    debugMode = false; // set to true to show collisions
  }

  /// Whether [other]'s bounding box overlaps this block.
  bool intersects(PositionComponent other) => checkCollision(other, this);

  /// Pushes [other] out of this block along the X axis, based on the
  /// direction it was moving ([velocityX]).
  void resolveHorizontal(PositionComponent other, double velocityX) {
    if (!intersects(other)) return;

    if (velocityX > 0) {
      other.x = x - other.width;
    } else if (velocityX < 0) {
      other.x = x + width;
    }
  }

  /// Pushes [other] out of this block along the Y axis, based on the
  /// direction it was moving ([velocityY]).
  void resolveVertical(PositionComponent other, double velocityY) {
    if (!intersects(other)) return;

    if (velocityY > 0) {
      other.y = y - other.height;
    } else if (velocityY < 0) {
      other.y = y + height;
    }
  }
}

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
