import 'dart:math';

/// How a round ended, from the player's side.
enum Outcome { win, lose, tie }

/// One button the player can press while a minigame is running.
class MinigameChoice {
  const MinigameChoice(this.id, this.label, [String? short])
    : short = short ?? label;

  final String id;
  final String label;

  /// What fits on a 32 px wide button (about 5 letters). Defaults to [label].
  final String short;
}

/// What happened in one round: who won, and a short line saying how.
class MinigameResult {
  const MinigameResult(this.outcome, this.summary);

  final Outcome outcome;
  final String summary;
}

/// The rules of one minigame. The encounter only ever calls these three
/// members, so a new minigame is one new class plus a line in
/// [createMinigame].
///
/// An instance is used for a single encounter.
abstract class Minigame {
  /// The name shown at the top of the dungeon screen.
  String get title;

  /// The buttons to show. Fixed for the whole game.
  List<MinigameChoice> get choices;

  /// Sets the game up and returns the line that explains it (this is where
  /// anything visible from the start, like the first card, gets decided).
  String begin(Random random);

  /// The choice that would win the current round, or null when no choice
  /// can (a tie, or a game with a single action). The hidden part of the
  /// round is decided in [begin], so this is known before anything is
  /// offered. The encounter uses it to make the offered action lucky.
  String? winningChoice();

  /// Plays the round for the pressed [choiceId]. It may be called again for
  /// the same round (a lucky replay of a single-action game): only the
  /// hidden part, such as the enemy's pick, is drawn again there.
  MinigameResult play(String choiceId, Random random);
}

/// Makes the minigame for an enemy's `minigame` value, or null if unknown.
Minigame? createMinigame(String type) => switch (type) {
  'rock_paper_scissors' => RockPaperScissors(),
  'high_low' => HighLow(),
  'dice' => DiceRoll(),
  _ => null,
};

/// Standard rules: rock beats scissors, scissors beat paper, paper beats rock.
class RockPaperScissors implements Minigame {
  static const List<String> _moves = ['rock', 'paper', 'scissors'];

  @override
  String get title => 'ROCK PAPER SCISSORS';

  @override
  final List<MinigameChoice> choices = const [
    MinigameChoice('rock', 'ROCK'),
    MinigameChoice('paper', 'PAPER'),
    MinigameChoice('scissors', 'SCISSORS', 'SCIS'),
  ];

  /// The enemy's move, decided when the round begins.
  int _enemy = 0;

  @override
  String begin(Random random) {
    _enemy = random.nextInt(_moves.length);
    return 'ROCK, PAPER OR SCISSORS?';
  }

  @override
  String? winningChoice() =>
      // With the moves in this order, the move after the enemy's beats it.
      _moves[(_enemy + 1) % _moves.length];

  @override
  MinigameResult play(String choiceId, Random random) {
    final player = _moves.indexOf(choiceId);
    final enemy = _enemy;

    // With the moves in this order, +1 (wrapping) beats the move before it.
    final step = (player - enemy + _moves.length) % _moves.length;
    final outcome = switch (step) {
      0 => Outcome.tie,
      1 => Outcome.win,
      _ => Outcome.lose,
    };
    return MinigameResult(
      outcome,
      'YOU: ${_moves[player].toUpperCase()}   '
      'ENEMY: ${_moves[enemy].toUpperCase()}',
    );
  }
}

/// A card from 1 to 13 is shown. The player guesses whether the next one is
/// higher or lower. An equal card is a tie.
class HighLow implements Minigame {
  static const int _highest = 13;

  int _card = 1;

  /// The next card, decided when the round begins.
  int _next = 1;

  @override
  String get title => 'HIGH OR LOW';

  @override
  final List<MinigameChoice> choices = const [
    MinigameChoice('higher', 'HIGH'),
    MinigameChoice('lower', 'LOW'),
  ];

  @override
  String begin(Random random) {
    _card = random.nextInt(_highest) + 1;
    _next = random.nextInt(_highest) + 1;
    return 'YOUR CARD IS $_card. WILL THE NEXT ONE BE HIGHER OR LOWER?';
  }

  @override
  String? winningChoice() {
    if (_next == _card) return null;
    return _next > _card ? 'higher' : 'lower';
  }

  @override
  MinigameResult play(String choiceId, Random random) {
    final next = _next;
    final guessedHigher = choiceId == 'higher';

    final Outcome outcome;
    if (next == _card) {
      outcome = Outcome.tie;
    } else if ((next > _card) == guessedHigher) {
      outcome = Outcome.win;
    } else {
      outcome = Outcome.lose;
    }
    return MinigameResult(outcome, 'CARD: $_card   NEXT: $next');
  }
}

/// The player and the enemy each roll a six-sided die. The higher roll wins
/// and equal rolls are a tie.
class DiceRoll implements Minigame {
  @override
  String get title => 'DICE ROLL';

  @override
  final List<MinigameChoice> choices = const [MinigameChoice('roll', 'ROLL')];

  @override
  String begin(Random random) => 'ROLL THE DICE! THE HIGHER ROLL WINS.';

  @override
  String? winningChoice() => null; // One action only; nothing to offer.

  @override
  MinigameResult play(String choiceId, Random random) {
    final player = random.nextInt(6) + 1;
    final enemy = random.nextInt(6) + 1;
    final outcome = player == enemy
        ? Outcome.tie
        : (player > enemy ? Outcome.win : Outcome.lose);
    return MinigameResult(outcome, 'YOU ROLLED $player   ENEMY ROLLED $enemy');
  }
}
