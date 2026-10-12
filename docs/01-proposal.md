# Proposal

## The problem, in one sentence

Farming games can feel slow and gambling-style games can feel empty, so Eppy Island combines the two in a short, silly loop: grow crops on the surface, gamble against monsters underground, and spend the winnings on the next run.

## Who it is for

Casual players who enjoy cozy pixel-art games and quick, low-stakes mini-games, and who do not want a long tutorial or a punishing difficulty curve. It is also built for my 6ADET course (Holy Angel University), so the instructor is a second audience.

## Core features

- **Farming:** plant seeds, grow crops, and harvest them as a steady source of income.
- **Dungeon gambling:** go underground and play mini-games against monsters for rewards and items. Planned games are Rock-paper-scissors, Roll the dice, and High Low.
- **Shop:** buy seeds, equipment, and useful items, and sell the things you no longer need.
- **Inventory and equipment:** items cover anything sellable, seeds, and crops. The player can equip one piece of equipment at a time, and each piece has a fixed effect, such as boosting luck or allowing certain actions.
- **Player stats:** money and luck. Luck influences the dungeon games.
- **Maps and warps:** Home Island and Town Island, connected by warp blocks with a transition effect between maps.
- **HUD:** an always-on interface with pause, inventory, equipment, and a coin counter, built as Tiled maps.

## Out of scope, and why

- **Real money, online play, or accounts:** the gambling is entirely in-game and uses fictional coins. Nothing is purchased, and there is no server or login.
- **Multiplayer or leaderboards:** this would need a backend that the course timeline does not allow.
- **More than three dungeon games:** additional games are a stretch goal and only happen if time allows.
- **Original art:** the game uses the Sprout Lands asset packs (Cup Nooble) instead of custom artwork, so the time goes into gameplay.
- **Heavy state-management or storage packages:** the game uses Flame component state and Tiled map data only.

## Data the app remembers, and where it is saved

Game progress (such as money, luck, inventory, equipment, and farm state) is saved to a local file, `eppy_island_save.json`, when the game is run on a device. It stays on the player's own device. Static game data (maps, object layers, UI layout) is loaded from the bundled assets and Tiled maps and is not saved. The live web demo cannot write that file, so it starts from the default save each visit. The app does not collect any personal information and has no way to send data anywhere.

## Risks

- **Scope:** inventory, equipment, shop, farming, and three dungeon games is a lot for one person in one term. Mitigation: build inventory and equipment first, and treat extra dungeon games as optional.
- **Learning curve:** Flame and flame_tiled are new to me. Mitigation: follow tutorials (Spellthorn) and keep the code object-oriented so features stay isolated.
- **Asset licensing:** third-party art has its own license and is not covered by the MIT license. Mitigation: credit the artist and keep the license terms in the README.
- **Gambling theme:** it must stay clearly fictional and non-monetary, with no real-money mechanics.
- **Cross-platform behavior:** the game should run on Chrome, Linux, Windows, and macOS, but I mainly test on one.

## Changes since the last version

This is the first version, so there are no changes yet.



Eppy Island v1.0
