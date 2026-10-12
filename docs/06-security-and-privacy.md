# Security and privacy

Eppy Island is an offline single-player game. It has no accounts, no server, and no network code in `lib/`, so there is very little data to protect. This document says what the game stores, where it goes, and what could go wrong.

## What data the game handles

| Data | Where it comes from | Where it is kept | Leaves the device? |
| --- | --- | --- | --- |
| Player name, profile picture name, character | `assets/data/default_save.json`, then the save file | Save file | No |
| Coins, luck, inventory, equipped item | Gameplay | Save file | No |
| Current map and position | Gameplay | Save file | No |
| Shop stock | Calculated from the clock and `assets/data/shop.json` | Not stored | No |
| Item and shop definitions | `assets/data/items.json`, `shop.json` | Bundled with the app | No |

The save file contains no personal information beyond the player name, which is a game name and not an email or real identity.

## The save file

- **Name and place:** `eppy_island_save.json`, in the app's documents folder (found with the `path_provider` package). It is a plain JSON file and is not encrypted.
- **Format:** a `version`, a `player` section (name, picture, character, coins, base luck, equipped item id, inventory as item ids and quantities), and a `world` section (level name and position).
- **Safe writing:** the game writes to a temporary file and renames it over the real one, so a crash during a save cannot leave a half-written file. Saves are queued so two never run at once, and a failed save is logged without crashing the game.
- **Bad files:** if the save cannot be read, it is renamed to `.corrupt` and the game starts from `default_save.json` instead of discarding it.
- **Validation on load:** a save without a `player` section is rejected. Unknown item ids are skipped, quantities are limited to 1 to 99, coins cannot be negative, and luck is kept between 1 and 100.
- **Reset:** `SaveService.reset()` deletes the save so the next start is a new game.
- **Web demo:** the live demo runs in a browser, where the game cannot write a local file. The save code catches that error and starts from the default save, so progress is not kept between visits.

## Secrets

The game uses no API keys, tokens, or passwords, and has no environment variables. There is nothing secret to leak from the code. Local machine files such as `android/local.properties` (which holds a local SDK path) and the `build/` folder are not part of the project and should stay out of the repository through `.gitignore`.

## Third-party code and assets

- **Packages:** Flutter, Flame, `flame_tiled`, and `path_provider`. The full list with versions is in `pubspec.yaml` and `pubspec.lock`.
- **Art and fonts:** Sprout Lands asset packs by Cup Nooble. They have their own license and are not covered by the project's MIT license (see the README credits).
- **Sound effects:** the `.wav` files in `assets/images/audio/` came with the Sprout Lands asset pack and are credited with it in the README.

## Risks and how they are handled

| Risk | Impact | How it is handled |
| --- | --- | --- |
| Player edits the save file to get coins or items | Cheating in a single-player game only. Nothing else is affected | Loading limits quantities, coins, and luck to valid ranges, but edits within those ranges are accepted. This is acceptable because there is no multiplayer or leaderboard |
| Corrupt or half-written save | Lost progress | Atomic writes and a `.corrupt` backup |
| Missing or wrong assets | Crash or blank screen | Missing UI sprites are logged and skipped, bad items in `items.json` and `shop.json` are skipped, and a failed map load keeps the player in the current map |
| Committing machine-specific files or secrets | Leaking a local path or a future key | `.gitignore` for `local.properties` and `build/`, and keeping any future secrets out of the repository |
| Unlicensed assets | License violation | Art, fonts, and sound effects are credited in the README, and each pack's license is checked before submitting |
| Future network features | New privacy exposure | Out of scope for now. If added, update this document before shipping |

## Privacy summary

The game does not collect, send, or share any personal data. Everything it saves stays on the player's own device in one JSON file, and deleting that file removes all of it.
