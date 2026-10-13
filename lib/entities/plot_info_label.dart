import 'dart:ui';

import 'package:eppy_island/entities/player.dart';
import 'package:eppy_island/entities/plot_component.dart';
import 'package:eppy_island/game/eppy_island.dart';
import 'package:eppy_island/ui/ui_elements.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// A small panel above the plot the player is standing on, showing its crop,
/// state and the time until the next action (see Farm.describePlot).
///
/// "Standing on" means the player's centre is inside the plot. Nothing is drawn
/// when the player is not on a plot.
class PlotInfoLabel extends PositionComponent with HasGameRef<EppyIsland> {
  PlotInfoLabel({
    required this.player,
    required this.plots,
    required this.mapSize,
  }) : super(priority: 100); // Above the map, plots and player.

  static const double _padding = 3;
  static const double _gap = 1;
  static const double _margin = 2;
  static const double _refreshEvery = 0.25;

  final Player player;
  final List<PlotComponent> plots;

  /// Size of the level in pixels, used to keep the panel on screen.
  final Vector2 mapSize;

  PlotComponent? _current;
  List<TextPainter> _lines = const [];
  Size _panel = Size.zero;
  double _since = 0;

  final Paint _background = Paint()..color = const Color(0xCC1B1B1B);

  @override
  void update(double dt) {
    super.update(dt);

    final plot = _plotUnderPlayer();
    if (plot == null) {
      if (_current != null) _clear();
      return;
    }

    // The countdown follows the clock, so rebuild the text now and then.
    _since += dt;
    if (plot != _current || _since >= _refreshEvery) {
      _since = 0;
      _current = plot;
      _rebuild(plot);
    }
  }

  PlotComponent? _plotUnderPlayer() {
    final point = player.center.toOffset();
    for (final plot in plots) {
      if (plot.toRect().contains(point)) return plot;
    }
    return null;
  }

  void _clear() {
    for (final line in _lines) {
      line.dispose();
    }
    _lines = const [];
    _current = null;
    _panel = Size.zero;
  }

  void _rebuild(PlotComponent plot) {
    final text = game.farm.describePlot(plot.plotKey);

    final painters = <TextPainter>[];
    var width = 0.0;
    var height = 0.0;
    for (var i = 0; i < text.length; i++) {
      final painter = TextPainter(
        text: TextSpan(
          text: text[i],
          // The same pixel font as the menus. It has no bold, so the title is
          // set apart by colour instead.
          style: uiTextStyle(
            color: i == 0 ? const Color(0xFFFFD54F) : const Color(0xFFFFFFFF),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painters.add(painter);
      if (painter.width > width) width = painter.width;
      height += painter.height.roundToDouble() + (i == 0 ? 0 : _gap);
    }

    for (final old in _lines) {
      old.dispose();
    }
    _lines = painters;
    _panel = Size(
      (width + _padding * 2).ceilToDouble(),
      (height + _padding * 2).ceilToDouble(),
    );
  }

  @override
  void render(Canvas canvas) {
    final plot = _current;
    if (plot == null || _lines.isEmpty) return;

    // Centred above the plot; below it if there is no room at the top.
    var y = (plot.y - _panel.height - 2).roundToDouble();
    if (y < _margin) y = plot.y + plot.height + 2;

    final maxX = mapSize.x - _panel.width - _margin;
    final x = (plot.center.x - _panel.width / 2)
        .clamp(_margin, maxX < _margin ? _margin : maxX)
        .roundToDouble(); // Whole pixels keep the pixel font crisp.

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, _panel.width, _panel.height),
        const Radius.circular(2),
      ),
      _background,
    );

    var textY = y + _padding;
    for (final line in _lines) {
      line.paint(canvas, Offset(x + _padding, textY));
      textY += line.height.roundToDouble() + _gap;
    }
  }
}
