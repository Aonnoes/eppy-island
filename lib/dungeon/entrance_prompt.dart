import 'dart:ui';

import 'package:eppy_island/entities/player.dart';
import 'package:eppy_island/ui/ui_elements.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// "ENTER DUNGEON - PRESS SPACE", shown above the player while they stand on
/// the dungeon entrance. The level turns [shown] on and off.
class EntrancePrompt extends PositionComponent {
  EntrancePrompt({required this.player, required this.mapSize})
    : super(priority: 100) {
    _text = TextPainter(
      text: TextSpan(text: label, style: uiTextStyle()),
      textDirection: TextDirection.ltr,
    )..layout();
    _panel = Size(
      (_text.width + _padding * 2).ceilToDouble(),
      (_text.height + _padding * 2).ceilToDouble(),
    );
  }

  static const String label = 'ENTER DUNGEON - PRESS SPACE';

  static const double _padding = 3;
  static const double _margin = 2;

  final Player player;

  /// Size of the level in pixels, used to keep the prompt on screen.
  final Vector2 mapSize;

  /// Whether the prompt is visible.
  bool shown = false;

  late final TextPainter _text;
  late final Size _panel;
  final Paint _background = Paint()..color = const Color(0xCC1B1B1B);

  @override
  void render(Canvas canvas) {
    if (!shown) return;

    // Centred above the player; below them if there is no room at the top.
    var y = (player.y - _panel.height - 3).roundToDouble();
    if (y < _margin) y = (player.y + player.height + 3).roundToDouble();

    final maxX = mapSize.x - _panel.width - _margin;
    final x = (player.center.x - _panel.width / 2)
        .clamp(_margin, maxX < _margin ? _margin : maxX)
        .roundToDouble();

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, _panel.width, _panel.height),
        const Radius.circular(2),
      ),
      _background,
    );
    _text.paint(canvas, Offset(x + _padding, y + _padding));
  }
}
