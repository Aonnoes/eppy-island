import 'package:flame/components.dart';

class CollisionBlock extends PositionComponent {
  CollisionBlock({position, size}) : super(position: position, size: size) {
    debugMode = true;
  }
}
