import 'package:flame/components.dart';

/// Axis-aligned bounding box overlap test between two components.
bool checkCollision(PositionComponent a, PositionComponent b) {
  return a.x < b.x + b.width &&
      a.x + a.width > b.x &&
      a.y < b.y + b.height &&
      a.y + a.height > b.y;
}
