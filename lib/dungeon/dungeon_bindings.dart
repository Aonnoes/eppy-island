import 'dart:ui';

import 'package:eppy_island/dungeon/encounter.dart';
import 'package:eppy_island/dungeon/enemy.dart';
import 'package:eppy_island/dungeon/minigame.dart';
import 'package:eppy_island/game/eppy_island.dart';
import 'package:eppy_island/ui/ui_controller.dart';
import 'package:eppy_island/ui/ui_elements.dart';
import 'package:flutter/foundation.dart';

/// The live values the dungeon level's objects can `bind` to, kept up to date
/// from the [Encounter] by [sync].
///
///   user_image                 the player's picture
///   enemy_image                the enemy's portrait (a sprite name)
///   enemy_initial              the enemy's first letter, only while its
///                              portrait art is missing
///   player_star1 .. 4          luck stars (luck for this encounter)
///   enemy_star1 .. 4           the enemy's difficulty stars
///   player_life, enemy_life    `player_3-3`, `player_2-3`, `player_1-3` (or
///                              `enemy_...`) for that many lives left out of
///                              3, and the shared `life_0-3` at none left
///   player_flash, enemy_flash  count up whenever a round's result appears;
///                              the reaction boxes show for 1.5 s on their
///                              own timer, however soon the player moves on
///   player_reaction,
///   enemy_reaction             `reaction_happy`, `reaction_sad` or
///                              `reaction_neutral`
///   game_title                 name of the minigame
///   message                    what the context box says (never the luck;
///                              luck is only the player stars)
///   action                     the one-word question above Yes / No, e.g.
///                              `HIGH?` while a round is being played
///   action_color               colour for the action label (`color_bind`):
///                              yellow for a question, green for a win,
///                              red for a loss, white otherwise
///   consumable_sprite,
///   consumable_count           the equipped consumable and "x3"
class DungeonBindings {
  DungeonBindings(this.game);

  final EppyIsland game;

  final ValueNotifier<String> _enemyImage = ValueNotifier('');
  final ValueNotifier<String> _enemyInitial = ValueNotifier('');
  final ValueNotifier<String> _gameTitle = ValueNotifier('');
  final ValueNotifier<String> _message = ValueNotifier('');
  final ValueNotifier<String> _action = ValueNotifier('');
  final ValueNotifier<Color> _actionColor = ValueNotifier(_white);
  final ValueNotifier<String> _playerLife = ValueNotifier('');
  final ValueNotifier<String> _enemyLife = ValueNotifier('');
  final ValueNotifier<String> _playerReaction = ValueNotifier(_neutral);
  final ValueNotifier<String> _enemyReaction = ValueNotifier(_neutral);
  final ValueNotifier<int> _playerFlash = ValueNotifier(0);
  final ValueNotifier<int> _enemyFlash = ValueNotifier(0);
  bool _resultShown = false;
  final ValueNotifier<String> _consumableSprite = ValueNotifier('');
  final ValueNotifier<String> _consumableCount = ValueNotifier('');
  final List<ValueNotifier<String>> _playerStars = List.generate(
    UiController.starCount,
    (_) => ValueNotifier('star_empty'),
  );
  final List<ValueNotifier<String>> _enemyStars = List.generate(
    Enemy.maxStars,
    (_) => ValueNotifier('star_empty'),
  );

  static const Color _yellow = Color(0xFFFFE04A);
  static const Color _green = Color(0xFF5DDC5D);
  static const Color _red = Color(0xFFFF5A5A);
  static const Color _white = Color(0xFFFFFFFF);

  static const String _happy = 'reaction_happy';
  static const String _sad = 'reaction_sad';
  static const String _neutral = 'reaction_neutral';

  late final Map<String, ValueListenable<Object?>> values = {
    'user_image': game.profile.userImage,
    'enemy_image': _enemyImage,
    'enemy_initial': _enemyInitial,
    'game_title': _gameTitle,
    'message': _message,
    'action': _action,
    'action_color': _actionColor,
    'player_life': _playerLife,
    'enemy_life': _enemyLife,
    'player_reaction': _playerReaction,
    'enemy_reaction': _enemyReaction,
    'player_flash': _playerFlash,
    'enemy_flash': _enemyFlash,
    'consumable_sprite': _consumableSprite,
    'consumable_count': _consumableCount,
    for (var i = 0; i < _playerStars.length; i++)
      'player_star${i + 1}': _playerStars[i],
    for (var i = 0; i < _enemyStars.length; i++)
      'enemy_star${i + 1}': _enemyStars[i],
  };

  /// Copies the encounter's current state into the bound values.
  void sync(Encounter encounter) {
    final enemy = encounter.enemy;
    if (enemy != null) {
      _enemyImage.value = enemy.portrait;
      final hasArt = loadUiSprite(game, enemy.portrait) != null;
      _enemyInitial.value = hasArt || enemy.name.isEmpty
          ? ''
          : enemy.name[0].toUpperCase();
      for (var i = 0; i < _enemyStars.length; i++) {
        _enemyStars[i].value = i < enemy.stars ? 'star_full' : 'star_empty';
      }
    }

    for (var i = 0; i < _playerStars.length; i++) {
      _playerStars[i].value = UiController.starSprite(encounter.runLuck, i + 1);
    }

    _gameTitle.value = encounter.minigameTitle;
    _message.value = [
      encounter.message,
      encounter.detail,
    ].where((line) => line.isNotEmpty).join('\n');
    _action.value = _actionWord(encounter);
    _actionColor.value = _actionTint(encounter);

    final max = encounter.maxLives;
    _playerLife.value = _lifeBar('player', encounter.playerLives, max);
    _enemyLife.value = _lifeBar('enemy', encounter.enemyLives, max);

    // The reactions keep their face after the result is left, so their own
    // timer (see UiFlashImage) decides how long they are seen, not the
    // encounter. They go back to neutral only when a new encounter starts.
    final outcome = encounter.lastOutcome;
    if (encounter.phase == EncounterPhase.intro) {
      _playerReaction.value = _neutral;
      _enemyReaction.value = _neutral;
    } else if (outcome != null) {
      _playerReaction.value = switch (outcome) {
        Outcome.win => _happy,
        Outcome.lose => _sad,
        Outcome.tie => _neutral,
      };
      _enemyReaction.value = switch (outcome) {
        Outcome.win => _sad,
        Outcome.lose => _happy,
        Outcome.tie => _neutral,
      };
    }

    final item = encounter.profile.equippedConsumable.value;
    _consumableSprite.value = item?.sprite ?? '';
    _consumableCount.value = item == null
        ? ''
        : 'x${encounter.profile.inventory.countOf(item)}';

    // A round's result just appeared: show both reaction boxes.
    final showing = encounter.phase == EncounterPhase.result;
    if (showing && !_resultShown) {
      _playerFlash.value++;
      _enemyFlash.value++;
    }
    _resultShown = showing;
  }

  /// The art for [lives] lives left out of [max]: `player_3-3`, `enemy_2-3`,
  /// ... and the empty bar `life_0-3` (shared by both sides).
  static String _lifeBar(String side, int lives, int max) =>
      lives <= 0 ? 'life_0-$max' : '${side}_$lives-$max';

  /// Questions (FIGHT?, HIGH?...) are yellow, a won round green, a lost one
  /// red. Everything else stays white.
  static Color _actionTint(Encounter encounter) {
    switch (encounter.phase) {
      case EncounterPhase.intro:
      case EncounterPhase.prompt:
        return _yellow;
      case EncounterPhase.result:
        return switch (encounter.lastOutcome) {
          Outcome.win => _green,
          Outcome.lose => _red,
          _ => _white,
        };
      case EncounterPhase.reveal:
      case EncounterPhase.inactive:
        return _white;
    }
  }

  static String _actionWord(Encounter encounter) {
    switch (encounter.phase) {
      case EncounterPhase.intro:
        return 'FIGHT?';
      case EncounterPhase.prompt:
        return encounter.question;
      case EncounterPhase.reveal:
        return '...';
      case EncounterPhase.result:
        return switch (encounter.lastOutcome) {
          Outcome.win => 'WIN!',
          Outcome.lose => 'LOSE!',
          _ => 'TIE',
        };
      case EncounterPhase.inactive:
        return '';
    }
  }
}
