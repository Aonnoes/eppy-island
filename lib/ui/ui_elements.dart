import 'dart:ui';

import 'package:eppy_island/eppy_island.dart';
import 'package:eppy_island/ui/ui_contracts.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Where the UI sprites live, under assets/images/.
const String uiImageDir = 'hud/';

/// Typed reads of a Tiled object's custom properties, with defaults for when
/// a property is missing from the map.
extension UiProps on TiledObject {
  String str(String key, [String fallback = '']) =>
      properties.getValue<String>(key) ?? fallback;

  bool flag(String key, [bool fallback = false]) =>
      properties.getValue<bool>(key) ?? fallback;

  int integer(String key, [int fallback = 0]) =>
      properties.getValue<int>(key) ?? fallback;

  /// Position snapped to whole pixels, so pixel art stays crisp even if the
  /// object in Tiled sits on a fractional coordinate.
  Vector2 get uiPosition => Vector2(x.roundToDouble(), y.roundToDouble());

  /// Size snapped to whole pixels.
  Vector2 get uiSize => Vector2(width.roundToDouble(), height.roundToDouble());
}

final Map<String, Sprite?> _spriteCache = {};

/// Loads `hud/[name].png`, or returns null if it is missing. A missing
/// sprite is logged once, so one missing image doesn't take the UI down.
Sprite? loadUiSprite(EppyIsland game, String name) {
  if (name.isEmpty) return null;
  return _spriteCache.putIfAbsent(name, () {
    try {
      final sprite = Sprite(game.images.fromCache('$uiImageDir$name.png'));
      sprite.paint
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false;
      return sprite;
    } catch (_) {
      debugPrint('UI: missing sprite "$name" ($uiImageDir$name.png)');
      return null;
    }
  });
}

/// Parses `#RRGGBB` or `#AARRGGBB` (Tiled writes the latter for colors).
Color parseUiColor(String value, Color fallback) {
  var hex = value.replaceFirst('#', '');
  if (hex.length == 6) hex = 'ff$hex';
  final parsed = int.tryParse(hex, radix: 16);
  return (hex.length == 8 && parsed != null) ? Color(parsed) : fallback;
}

/// Text inside a rectangle from the map. Shows fixed text, or follows a bound
/// game value (such as the coin count) and updates when it changes.
///
/// With [wrap] the text is broken into lines that fit the rectangle's width
/// and is pinned to its top edge; otherwise it sits on one line, centred
/// vertically.
class UiLabel extends TextComponent {
  UiLabel({
    required Vector2 position,
    required Vector2 size,
    required String text,
    required TextStyle style,
    required String align,
    this.binding,
    bool wrap = false,
  }) : _style = style,
       _wrapWidth = wrap ? size.x : null,
       super(
         text: _wrapText(text, style, wrap ? size.x : null),
         position: _anchorPoint(position, size, align, wrap),
         anchor: _anchorFor(align, wrap),
         textRenderer: TextPaint(style: style),
       );

  final ValueListenable<Object?>? binding;
  final TextStyle _style;
  final double? _wrapWidth;

  static Vector2 _anchorPoint(Vector2 p, Vector2 s, String align, bool wrap) {
    final y = wrap ? p.y : p.y + s.y / 2;
    return switch (align) {
      'left' => Vector2(p.x, y),
      'right' => Vector2(p.x + s.x, y),
      _ => Vector2(p.x + s.x / 2, y),
    };
  }

  static Anchor _anchorFor(String align, bool wrap) => switch (align) {
    'left' => wrap ? Anchor.topLeft : Anchor.centerLeft,
    'right' => wrap ? Anchor.topRight : Anchor.centerRight,
    _ => wrap ? Anchor.topCenter : Anchor.center,
  };

  /// Inserts line breaks so no line is wider than [maxWidth].
  static String _wrapText(String text, TextStyle style, double? maxWidth) {
    if (maxWidth == null || text.isEmpty) return text;

    final painter = TextPainter(textDirection: TextDirection.ltr);
    final lines = <String>[];
    var line = '';
    for (final word in text.split(' ')) {
      final candidate = line.isEmpty ? word : '$line $word';
      painter
        ..text = TextSpan(text: candidate, style: style)
        ..layout();
      if (painter.width > maxWidth && line.isNotEmpty) {
        lines.add(line);
        line = word;
      } else {
        line = candidate;
      }
    }
    lines.add(line);
    painter.dispose();
    return lines.join('\n');
  }

  @override
  void onMount() {
    super.onMount();
    binding?.addListener(_sync);
    _sync();
  }

  @override
  void onRemove() {
    binding?.removeListener(_sync);
    super.onRemove();
  }

  void _sync() {
    final b = binding;
    if (b != null) text = _wrapText('${b.value}', _style, _wrapWidth);
  }
}

/// A sprite that may be missing: with no sprite it simply draws nothing.
///
/// Flame's own SpriteComponent asserts (and crashes in debug mode) when its
/// sprite is null, which happens for an empty slot, an item icon with nothing
/// selected, or an image file that doesn't exist yet.
class UiSprite extends PositionComponent {
  UiSprite({this.sprite, super.position, super.size});

  Sprite? sprite;

  double _opacity = 1;
  final Paint _paint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  double get opacity => _opacity;
  set opacity(double value) {
    _opacity = value;
    _paint.color = Color.fromRGBO(255, 255, 255, value);
  }

  @override
  void render(Canvas canvas) {
    sprite?.render(canvas, size: size, overridePaint: _paint);
  }
}

/// A picture from the map. It can be fixed (`sprite`), follow a bound sprite
/// name (`bind`, e.g. the player's picture), and be dimmed unless a bound
/// number is high enough (`show_bind` + `show_min`, e.g. luck stars).
class UiImage extends UiSprite {
  UiImage({
    required Sprite? Function(String name) loadSprite,
    required String spriteName,
    this.spriteBinding,
    this.levelBinding,
    this.minLevel = 0,
    super.position,
    super.size,
  }) : _loadSprite = loadSprite,
       super(sprite: loadSprite(spriteName));

  static const double _dimmedOpacity = 0.3;

  final Sprite? Function(String name) _loadSprite;
  final ValueListenable<Object?>? spriteBinding;
  final ValueListenable<Object?>? levelBinding;
  final int minLevel;

  @override
  void onMount() {
    super.onMount();
    spriteBinding?.addListener(_sync);
    levelBinding?.addListener(_sync);
    _sync();
  }

  @override
  void onRemove() {
    spriteBinding?.removeListener(_sync);
    levelBinding?.removeListener(_sync);
    super.onRemove();
  }

  void _sync() {
    final bound = spriteBinding;
    if (bound != null) sprite = _loadSprite('${bound.value}');

    final level = levelBinding;
    if (level != null) {
      final value = num.tryParse('${level.value}') ?? 0;
      opacity = value >= minLevel ? 1 : _dimmedOpacity;
    }
  }
}

/// A plain coloured rectangle (`Box` in Tiled), for card backgrounds.
class UiBox extends RectangleComponent {
  UiBox({required Color color, super.position, super.size})
    : super(paint: Paint()..color = color);
}

/// A button drawn with a colour and text, used when the button's sprites
/// (`[sprite]_unpressed.png` / `[sprite]_pressed.png`) don't exist yet.
class UiTextButton extends PositionComponent with TapCallbacks {
  UiTextButton({
    required this.label,
    required this.onPressed,
    super.position,
    super.size,
  });

  static const Color _upColor = Color(0xFF8B5E3C);
  static const Color _downColor = Color(0xFF63452C);
  static const Color _disabledColor = Color(0xFF8A8A8A);
  static const Color _borderColor = Color(0xFF3E2A1A);

  final String label;

  /// Null means the button is disabled.
  final VoidCallback? onPressed;

  final Paint _fill = Paint();
  final Paint _border = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = _borderColor;
  final TextPaint _text = TextPaint(
    style: const TextStyle(fontSize: 10, color: Color(0xFFFFFFFF)),
  );

  bool _down = false;

  @override
  void render(Canvas canvas) {
    _fill.color = onPressed == null
        ? _disabledColor
        : (_down ? _downColor : _upColor);
    canvas.drawRect(size.toRect(), _fill);
    canvas.drawRect(Rect.fromLTWH(0.5, 0.5, size.x - 1, size.y - 1), _border);
    _text.render(canvas, label, size / 2, anchor: Anchor.center);
  }

  @override
  void onTapDown(TapDownEvent event) => _down = true;

  @override
  void onTapCancel(TapCancelEvent event) => _down = false;

  @override
  void onTapUp(TapUpEvent event) {
    _down = false;
    onPressed?.call();
  }
}

/// One tappable square in a grid. Draws its background, the item it holds
/// centred on top of it, and a quantity when there is more than one.
class UiSlot extends UiSprite with TapCallbacks {
  UiSlot({
    required this.kind,
    required this.index,
    required this.selection,
    required this.onTap,
    required Sprite? Function(String name) loadSprite,
    this.source,
    this.itemScale = 1,
    super.sprite,
    super.position,
    super.size,
  }) : _loadSprite = loadSprite;

  /// `item`, `equipment`, `buy` or `sell`.
  final String kind;

  /// Zero-based position within its screen.
  final int index;

  final SlotSource? source;
  final UiSelection selection;

  /// Whole-number scale for the item sprite (1 = its own size).
  final int itemScale;

  final void Function(String kind, int index) onTap;
  final Sprite? Function(String name) _loadSprite;

  final UiSprite _item = UiSprite();
  final TextComponent _count = TextComponent(
    anchor: Anchor.bottomRight,
    textRenderer: TextPaint(
      style: const TextStyle(fontSize: 8, color: Color(0xFFFFFFFF)),
    ),
  );

  final Paint _equippedPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFFFFD54F);
  final Paint _selectedPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFFFFFFFF);

  final Paint _fallbackPaint = Paint()..color = const Color(0x55000000);

  bool _equipped = false;
  bool _selected = false;

  @override
  Future<void> onLoad() async {
    _count.position = Vector2(size.x - 3, size.y - 2);
    addAll([_item, _count]);
  }

  @override
  void onMount() {
    super.onMount();
    source?.changes.addListener(_refresh);
    selection.addListener(_refresh);
    _refresh();
  }

  @override
  void onRemove() {
    source?.changes.removeListener(_refresh);
    selection.removeListener(_refresh);
    super.onRemove();
  }

  @override
  void onTapUp(TapUpEvent event) => onTap(kind, index);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (sprite == null) canvas.drawRect(size.toRect(), _fallbackPaint);
    if (_equipped) {
      canvas.drawRect(
        Rect.fromLTWH(0.5, 0.5, size.x - 1, size.y - 1),
        _equippedPaint,
      );
    }
    if (_selected) {
      canvas.drawRect(
        Rect.fromLTWH(2.5, 2.5, size.x - 5, size.y - 5),
        _selectedPaint,
      );
    }
  }

  void _refresh() {
    final stack = source?.stackAt(index);
    final itemSprite = stack == null ? null : _loadSprite(stack.item.sprite);

    _item.sprite = itemSprite;
    if (itemSprite != null) {
      // Centre the item in the slot, on whole pixels.
      _item.size = itemSprite.srcSize * itemScale.toDouble();
      _item.position = Vector2(
        ((size.x - _item.size.x) / 2).roundToDouble(),
        ((size.y - _item.size.y) / 2).roundToDouble(),
      );
    }

    _count.text = (stack != null && stack.quantity > 1)
        ? '${stack.quantity}'
        : '';
    _selected = selection.isSelected(kind, index);
    _equipped = source?.isEquipped(index) ?? false;
  }
}

/// Dims the screen behind a modal screen and swallows taps, so nothing
/// underneath can be clicked.
class UiBackdrop extends RectangleComponent with TapCallbacks {
  UiBackdrop({required super.size})
    : super(paint: Paint()..color = const Color(0x99000000));

  @override
  void onTapDown(TapDownEvent event) {}
}
