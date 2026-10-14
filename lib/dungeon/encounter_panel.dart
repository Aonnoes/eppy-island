import 'dart:ui';

import 'package:eppy_island/dungeon/encounter.dart';
import 'package:eppy_island/dungeon/enemy.dart';
import 'package:eppy_island/game/eppy_island.dart';
import 'package:eppy_island/ui/ui_elements.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/painting.dart';

/// The encounter screen: an enemy frame on top, a dialogue panel below and a
/// row of buttons. It is ONE panel; it rebuilds its contents whenever the
/// [Encounter] changes state, and shows nothing while no encounter is running.
///
/// Built from the same pieces as the rest of the UI (UiBox, UiLabel,
/// UiTextButton, the pixel font, the luck stars), so it matches the menus.
/// Everything is drawn from flat colours, so it works before any art exists;
/// the colours are constants below.
///
/// Add it to `cam.viewport`, on top of the UI.
class EncounterPanel extends PositionComponent with HasGameRef<EppyIsland> {
  EncounterPanel({required this.encounter, required Vector2 size})
    : super(size: size, priority: 20);

  final Encounter encounter;

  // Colours.
  static const Color _dim = Color(0x88000000);
  static const Color _stoneDark = Color(0xFF3F3D42);
  static const Color _stone = Color(0xFF6C6A6E);
  static const Color _rose = Color(0xFF9A6B7B);
  static const Color _cardBorder = Color(0xFF3E2A1A);
  static const Color _cardFill = Color(0xFF6B4A5A);
  static const Color _parchmentBorder = Color(0xFF63452C);
  static const Color _parchment = Color(0xFF9C7A4B);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _detailText = Color(0xFFFFE9B0);

  // Layout, in the 480 x 283 view.
  static const double _frameX = 60;
  static const double _frameY = 14;
  static const double _frameW = 360;
  static const double _frameH = 118;
  static const double _cardSize = 72;
  static const double _dialogueX = 40;
  static const double _dialogueY = 142;
  static const double _dialogueW = 400;
  static const double _dialogueH = 108;
  static const double _buttonY = 208;
  static const double _buttonH = 32;
  static const double _iconSize = 16;

  @override
  void onMount() {
    super.onMount();
    encounter.addListener(_rebuild);
    _rebuild();
  }

  @override
  void onRemove() {
    encounter.removeListener(_rebuild);
    super.onRemove();
  }

  void _rebuild() {
    removeAll(children.toList());
    final enemy = encounter.enemy;
    if (!encounter.isActive || enemy == null) return;

    add(UiBackdrop(size: size.clone())); // Also stops taps reaching the game.
    add(UiBox(color: _dim, size: size.clone()));
    _addEnemy(enemy);
    _addDialogue();
    _addButtons();
  }

  // ------------------------------------------------------------------- enemy

  void _addEnemy(Enemy enemy) {
    _box(_stoneDark, _frameX, _frameY, _frameW, _frameH);
    _box(_stone, _frameX + 2, _frameY + 2, _frameW - 4, _frameH - 4);
    _box(_rose, _frameX + 8, _frameY + 8, _frameW - 16, _frameH - 16);

    add(
      UiLabel(
        position: Vector2(_frameX, _frameY + 6),
        size: Vector2(_frameW, 16),
        text: enemy.name.toUpperCase(),
        style: uiTextStyle(size: 14),
        align: 'center',
      ),
    );

    // The portrait card.
    final cardX = ((size.x - _cardSize) / 2).roundToDouble();
    const cardY = _frameY + 26;
    _box(_cardBorder, cardX, cardY, _cardSize, _cardSize);
    _box(_cardFill, cardX + 2, cardY + 2, _cardSize - 4, _cardSize - 4);

    final portrait = loadUiSprite(game, enemy.portrait);
    if (portrait != null) {
      add(
        UiSprite(
          sprite: portrait,
          position: Vector2(cardX + 4, cardY + 4),
          size: Vector2.all(_cardSize - 8),
        ),
      );
    } else {
      // No art yet: the enemy's first letter.
      add(
        UiLabel(
          position: Vector2(cardX, cardY),
          size: Vector2.all(_cardSize),
          text: enemy.name.isEmpty ? '?' : enemy.name[0].toUpperCase(),
          style: uiTextStyle(size: 28),
          align: 'center',
        ),
      );
    }

    // Difficulty stars, the same pictures as the luck stars.
    const starSize = 12.0;
    const starGap = 2.0;
    const starsWidth = Enemy.maxStars * starSize + (Enemy.maxStars - 1) * starGap;
    final starsX = ((size.x - starsWidth) / 2).roundToDouble();
    for (var i = 0; i < Enemy.maxStars; i++) {
      add(
        UiSprite(
          sprite: loadUiSprite(game, i < enemy.stars ? 'star_full' : 'star_empty'),
          position: Vector2(starsX + i * (starSize + starGap), cardY + _cardSize + 4),
          size: Vector2.all(starSize),
        ),
      );
    }
  }

  // ---------------------------------------------------------------- dialogue

  void _addDialogue() {
    _box(_parchmentBorder, _dialogueX, _dialogueY, _dialogueW, _dialogueH);
    _box(
      _parchment,
      _dialogueX + 2,
      _dialogueY + 2,
      _dialogueW - 4,
      _dialogueH - 4,
    );

    add(
      UiLabel(
        position: Vector2(_dialogueX + 12, _dialogueY + 10),
        size: Vector2(_dialogueW - 24, 36),
        text: encounter.message,
        style: uiTextStyle(size: 14, color: _white),
        align: 'left',
        wrap: true,
      ),
    );
    add(
      UiLabel(
        position: Vector2(_dialogueX + 12, _dialogueY + 50),
        size: Vector2(_dialogueW - 24, 12),
        text: encounter.detail,
        style: uiTextStyle(color: _detailText),
        align: 'left',
      ),
    );
  }

  // ----------------------------------------------------------------- buttons

  void _addButtons() {
    switch (encounter.phase) {
      case EncounterPhase.intro:
        final item = encounter.profile.equippedConsumable.value;
        _buttonRow([
          _Action('YES', encounter.yes),
          _Action('NO', encounter.no),
          _Action(
            item == null ? 'ITEM' : '',
            encounter.consume,
            icon: item?.sprite,
            count: item == null
                ? ''
                : 'x${encounter.profile.inventory.countOf(item)}',
          ),
        ]);
      case EncounterPhase.prompt:
        _buttonRow([
          for (final choice in encounter.choices)
            _Action(choice.label, () => encounter.choose(choice.id)),
        ]);
        _addItemBadge();
      case EncounterPhase.reveal:
        _addItemBadge();
      case EncounterPhase.result:
        _buttonRow([_Action('OK', encounter.advance)]);
        _addItemBadge();
      case EncounterPhase.inactive:
        break;
    }
  }

  void _buttonRow(List<_Action> actions) {
    const width = 84.0;
    const gap = 12.0;
    final total = actions.length * width + (actions.length - 1) * gap;
    var x = ((size.x - total) / 2).roundToDouble();

    for (final action in actions) {
      final button = UiTextButton(
        label: action.label,
        onPressed: action.onPressed,
        position: Vector2(x, _buttonY),
        size: Vector2(width, _buttonH),
      );

      final icon = action.icon == null ? null : loadUiSprite(game, action.icon!);
      if (icon != null) {
        button.add(
          UiSprite(
            sprite: icon,
            position: Vector2(((width - _iconSize) / 2).roundToDouble(), 3),
            size: Vector2.all(_iconSize),
          ),
        );
        button.add(
          TextComponent(
            text: action.count,
            textRenderer: TextPaint(style: uiTextStyle()),
            position: Vector2((width / 2).roundToDouble(), 21),
            anchor: Anchor.topCenter,
          ),
        );
      }

      add(button);
      x += width + gap;
    }
  }

  /// After the intro the consumable can't be used any more, but its icon
  /// stays in the corner of the dialogue panel.
  void _addItemBadge() {
    final item = encounter.profile.equippedConsumable.value;
    final icon = item == null ? null : loadUiSprite(game, item.sprite);
    if (item == null || icon == null) return;

    add(
      UiSprite(
        sprite: icon,
        position: Vector2(_dialogueX + 12, _dialogueY + _dialogueH - _iconSize - 8),
        size: Vector2.all(_iconSize),
      ),
    );
    add(
      TextComponent(
        text: 'x${encounter.profile.inventory.countOf(item)}',
        textRenderer: TextPaint(style: uiTextStyle(color: _white)),
        position: Vector2(
          _dialogueX + 12 + _iconSize + 4,
          _dialogueY + _dialogueH - _iconSize - 4,
        ),
      ),
    );
  }

  void _box(Color color, double x, double y, double w, double h) {
    add(UiBox(color: color, position: Vector2(x, y), size: Vector2(w, h)));
  }
}

class _Action {
  const _Action(this.label, this.onPressed, {this.icon, this.count = ''});

  final String label;
  final VoidCallback onPressed;

  /// Item sprite drawn on the button instead of text (the Consume button).
  final String? icon;
  final String count;
}
