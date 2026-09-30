import 'package:eppy_island/components/utils.dart';
import 'package:flame/components.dart';

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
