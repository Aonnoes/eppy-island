import 'dart:math';

import 'package:eppy_island/dungeon/enemy.dart';
import 'package:eppy_island/dungeon/minigame.dart';
import 'package:eppy_island/items/item.dart';
import 'package:eppy_island/profile/player_profile.dart';
import 'package:flutter/foundation.dart';

/// Where an encounter is. These are the states of ONE reusable panel, not
/// separate screens.
enum EncounterPhase {
  /// No encounter is running.
  inactive,

  /// "You encountered X!" with Yes, No and Consume.
  intro,

  /// The minigame's question and its controls.
  prompt,

  /// A short beat before the result is shown.
  reveal,

  /// Win, lose or tie, with the reward or penalty.
  result,
}

/// The rules of one dungeon encounter, with no drawing in it (the panel just
/// shows whatever state this is in).
///
/// Flow: [start] -> intro -> [yes] -> prompt -> [yes] or [no] -> reveal -> result,
/// then either the next round (prompt again) or [end]. From the intro, [no]
/// ends it straight away and [consume] uses the equipped consumable.
///
/// Lives: both sides start with the same number of lives (3 by default, set
/// by the dungeon level in Tiled). Winning a round costs the enemy a life,
/// losing one costs the player a life, a tie costs nobody. The encounter is
/// over when either side has none left; the enemy's reward or penalty is paid
/// once, at that point.
///
/// Luck is only ever shown as the luck stars, never in the dialogue text.
///
/// Rounds with several actions (rock paper scissors, high or low): the
/// encounter offers ONE action, asked as a single word ("HIGH?"). Yes plays
/// it, No lets the encounter pick at random among all the actions. The
/// offered action is the winning one with a chance equal to the player's luck
/// (out of 100, including consumables used this encounter), and a random one
/// otherwise, so luck only helps whoever says Yes.
///
/// Rounds with a single action (dice): Yes plays it, and a lost round has a
/// chance equal to the player's luck of being replayed once, silently, with
/// the replay kept.
class Encounter extends ChangeNotifier {
  Encounter({
    required this.catalog,
    required this.profile,
    Random? random,
  }) : _random = random ?? Random();

  /// Lives each side starts with when the level doesn't say otherwise.
  static const int defaultLives = 3;

  /// Seconds of "AND THE RESULT IS..." before the result appears.
  static const double _revealSeconds = 0.2;

  /// After every change, input is ignored for this long, so one press or tap
  /// can never run through two states.
  static const double _inputLockSeconds = 0.3;

  final EnemyCatalog catalog;
  final PlayerProfile profile;
  final Random _random;

  EncounterPhase _phase = EncounterPhase.inactive;
  Enemy? _enemy;
  Minigame? _minigame;
  List<MinigameChoice> _choices = const [];

  /// The one action offered this round (null outside a round).
  MinigameChoice? _offered;

  /// Consumables used in this encounter. They are what [PlayerProfile.runLuck]
  /// multiplies by, and they are forgotten when the encounter ends.
  final List<Consumable> _used = [];

  MinigameResult? _pending;

  int _maxLives = defaultLives;
  int _playerLives = defaultLives;
  int _enemyLives = defaultLives;

  /// True once one side is out of lives (the result on screen is the last).
  bool _over = false;

  /// How the round on screen ended. Only set while its result is showing.
  Outcome? _lastOutcome;
  double _timer = 0;
  double _lock = 0;

  String _message = '';
  String _detail = '';

  // ----------------------------------------------------------------- queries

  EncounterPhase get phase => _phase;
  bool get isActive => _phase != EncounterPhase.inactive;
  Enemy? get enemy => _enemy;
  List<MinigameChoice> get choices => _choices;

  /// The action on offer this round, or null outside a round.
  MinigameChoice? get offered => _offered;

  /// True when the minigame has more than one action, so No is a real
  /// answer (the encounter picks for the player).
  bool get canDecline => _choices.length > 1;

  /// The offered action as a one-word question ("HIGH?"), or '' when there
  /// is none.
  String get question => _offered == null ? '' : '${_offered!.label}?';

  /// The big line in the dialogue panel.
  String get message => _message;

  /// The small line under it (what each side picked, the player's luck...).
  String get detail => _detail;

  /// The player's luck for this encounter, consumables included.
  int get runLuck => profile.runLuck(_used);

  /// Lives each side started with, and what they have left.
  int get maxLives => _maxLives;
  int get playerLives => _playerLives;
  int get enemyLives => _enemyLives;

  /// How the round on screen ended, or null before its result is shown.
  Outcome? get lastOutcome => _lastOutcome;

  /// The name of the minigame being played ("" when none is).
  String get minigameTitle => _minigame?.title ?? '';

  /// Whether [start] would succeed right now.
  bool get canStart => !isActive && !catalog.isEmpty;

  bool get _locked => _lock > 0;

  // ----------------------------------------------------------------- control

  /// Starts an encounter with a random enemy, with [lives] lives per side.
  /// Returns false if there is nothing to meet (no enemies loaded) or one is
  /// already running.
  bool start({int lives = defaultLives}) {
    if (isActive) return false;

    final enemy = catalog.pick(_random);
    final minigame = enemy == null ? null : createMinigame(enemy.minigame);
    if (enemy == null || minigame == null) {
      debugPrint('Dungeon: no enemies to meet (${EnemyCatalog.assetPath}).');
      return false;
    }

    _enemy = enemy;
    _minigame = minigame;
    _choices = const [];
    _offered = null;
    _used.clear();
    _pending = null;
    _maxLives = max(1, lives);
    _playerLives = _maxLives;
    _enemyLives = _maxLives;
    _over = false;
    _lastOutcome = null;
    _enter(
      EncounterPhase.intro,
      'YOU ENCOUNTERED A ${enemy.name.toUpperCase()}!',
    );
    return true;
  }

  /// Intro: accept the challenge and start the minigame.
  /// Prompt: play the offered action.
  /// Result: proceed (the next round, or the end of the encounter). A result
  /// never closes by itself, so it can be read at the player's own pace.
  void yes() {
    if (_locked) return;
    if (_phase == EncounterPhase.intro) {
      _beginRound();
    } else if (_phase == EncounterPhase.prompt && _offered != null) {
      _play(_offered!.id);
    } else if (_phase == EncounterPhase.result) {
      _finishResult(); // Proceed, whenever the player has read the result.
    }
  }

  /// Intro: decline. The encounter ends with no reward and no penalty.
  /// Prompt: refuse the offered action; the encounter picks at random among
  /// all the actions instead (does nothing when there is only one action).
  void no() {
    if (_locked) return;
    if (_phase == EncounterPhase.intro) {
      end();
    } else if (_phase == EncounterPhase.prompt && canDecline) {
      _play(_choices[_random.nextInt(_choices.length)].id);
    }
  }

  /// Intro: use the equipped consumable. The player stays in the encounter.
  void consume() {
    if (_phase != EncounterPhase.intro || _locked) return;

    final item = profile.equippedConsumable.value;
    if (item == null) {
      _show('NO ITEM EQUIPPED');
      return;
    }
    if (!profile.consume(item)) {
      _show('NO ${item.name.toUpperCase()} LEFT');
      return;
    }

    _used.add(item);
    _show('${item.name.toUpperCase()} USED!');
  }

  /// Plays a specific action, ignoring the offer. Nothing in the dungeon
  /// screen uses it any more (it has Yes and No); the old EncounterPanel does.
  void choose(String id) => _play(id);

  /// Plays [id] for the round on screen (the offered action, or the
  /// encounter's random pick).
  void _play(String id) {
    if (_phase != EncounterPhase.prompt || _locked) return;
    if (!_choices.any((c) => c.id == id)) return;

    final minigame = _minigame!;
    var result = minigame.play(id, _random);
    // Luck for a several-action game was spent on the offer. A single-action
    // game has no offer, so a lost round may be silently replayed instead.
    if (!canDecline &&
        result.outcome == Outcome.lose &&
        _random.nextInt(100) < runLuck) {
      result = minigame.play(id, _random); // Lucky replay, and it is kept.
    }

    _pending = result;
    _timer = _revealSeconds;
    _enter(EncounterPhase.reveal, 'AND THE RESULT IS...');
  }

  /// Space: skips the reveal, or leaves the result (for the next round, or
  /// to end the encounter after the last one). Does nothing in the intro or
  /// the prompt, where a choice has to be made.
  void advance() {
    if (_locked) return;
    if (_phase == EncounterPhase.reveal) {
      _showResult();
    } else if (_phase == EncounterPhase.result) {
      _finishResult();
    }
  }

  /// Ends the encounter and forgets everything temporary about it.
  void end() {
    _phase = EncounterPhase.inactive;
    _enemy = null;
    _minigame = null;
    _choices = const [];
    _offered = null;
    _pending = null;
    _over = false;
    _lastOutcome = null;
    _used.clear();
    _lock = 0;
    _message = '';
    _detail = '';
    notifyListeners();
  }

  /// Call every frame: runs the reveal beat, the result's auto-close and the
  /// input lock.
  void tick(double dt) {
    if (!isActive) return;
    if (_lock > 0) _lock -= dt;

    if (_phase == EncounterPhase.reveal) {
      _timer -= dt;
      if (_timer <= 0) _showResult();
    }
  }

  // --------------------------------------------------------------- outcomes

  void _showResult() {
    final result = _pending;
    final enemy = _enemy;
    if (result == null || enemy == null) return;

    // The one place where a round's result is applied.
    switch (result.outcome) {
      case Outcome.win:
        _enemyLives = max(0, _enemyLives - 1);
      case Outcome.lose:
        _playerLives = max(0, _playerLives - 1);
      case Outcome.tie:
        break;
    }
    _lastOutcome = result.outcome;
    _over = _playerLives == 0 || _enemyLives == 0;

    final String headline;
    if (!_over) {
      headline = switch (result.outcome) {
        Outcome.win => 'YOU WIN THE ROUND!',
        Outcome.lose => 'YOU LOSE THE ROUND!',
        Outcome.tie => "IT'S A TIE!",
      };
    } else if (_enemyLives == 0) {
      profile.addCoins(enemy.reward);
      headline = enemy.reward > 0
          ? 'YOU WIN! +${enemy.reward} COINS'
          : 'YOU WIN!';
    } else {
      final lost = min(enemy.penalty, profile.coins.value);
      if (lost > 0) profile.spendCoins(lost);
      headline = lost > 0 ? 'YOU LOSE! -$lost COINS' : 'YOU LOSE!';
    }

    _pending = null;
    _enter(
      EncounterPhase.result,
      headline,
      detail: result.summary,
    );
  }

  /// Leaves the result: the encounter ends if a side is out of lives,
  /// otherwise the next round starts.
  void _finishResult() {
    if (_over) {
      end();
    } else {
      _beginRound();
    }
  }

  /// Shows the minigame's question and its controls.
  void _beginRound({double lock = _inputLockSeconds}) {
    final minigame = _minigame!;
    _choices = minigame.choices;
    _lastOutcome = null;
    final intro = minigame.begin(_random).toUpperCase();
    _offered = _chooseOffer(minigame);
    _enter(EncounterPhase.prompt, intro, lock: lock);
  }

  /// Picks the one action to offer. With luck out of 100 it is the action
  /// that wins this round; otherwise (or if no action wins) it is random.
  MinigameChoice _chooseOffer(Minigame minigame) {
    final choices = minigame.choices;
    if (choices.length > 1 && _random.nextInt(100) < runLuck) {
      final winning = minigame.winningChoice();
      for (final choice in choices) {
        if (choice.id == winning) return choice;
      }
    }
    return choices[_random.nextInt(choices.length)];
  }

  // ---------------------------------------------------------------- helpers

  void _enter(
    EncounterPhase phase,
    String message, {
    String detail = '',
    double lock = _inputLockSeconds,
  }) {
    _phase = phase;
    _show(message, detail: detail, lock: lock);
  }

  /// Shows [message], and locks input for a moment (so a double tap can't use
  /// two potions or skip a result).
  void _show(
    String message, {
    String detail = '',
    double lock = _inputLockSeconds,
  }) {
    _message = message;
    _detail = detail;
    _lock = lock;
    notifyListeners();
  }
}
