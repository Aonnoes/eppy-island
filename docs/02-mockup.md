# Mockup and wireframes

The visual plan for Eppy Island. The wireframes show what goes where; the mockups show what it looks like.

## Mockup

### Title screen

![Title mockup](assets/Mockups/mockupTitle/title_00.png)

### Farm (Home Island)

| | |
| --- | --- |
| ![Farm mockup 0](assets/Mockups/mockupFarm/farm_00.png) | ![Farm mockup 1](assets/Mockups/mockupFarm/farm_01.png) |
| ![Farm mockup 2](assets/Mockups/mockupFarm/farm_02.png) | ![Farm mockup 3](assets/Mockups/mockupFarm/farm_03.png) |
| ![Farm mockup 4](assets/Mockups/mockupFarm/farm_04.png) | ![Farm mockup 5](assets/Mockups/mockupFarm/farm_05.png) |

### Town (Town Island)

| | |
| --- | --- |
| ![Town mockup 0](assets/Mockups/mockupTown/town_00.png) | ![Town mockup 1](assets/Mockups/mockupTown/town_01.png) |
| ![Town mockup 2](assets/Mockups/mockupTown/town_02.png) | ![Town mockup 3](assets/Mockups/mockupTown/town_03.png) |

### Dungeon

| | |
| --- | --- |
| ![Dungeon mockup 0](assets/Mockups/mockupDungeon/dungeon_00.png) | ![Dungeon mockup 2](assets/Mockups/mockupDungeon/dungeon_02.png) |
| ![Dungeon mockup 3](assets/Mockups/mockupDungeon/dungeon_03.png) | ![Dungeon mockup 4](assets/Mockups/mockupDungeon/dungeon_04.png) |
| ![Dungeon mockup 5](assets/Mockups/mockupDungeon/dungeon_05.png) | ![Dungeon mockup 6](assets/Mockups/mockupDungeon/dungeon_06.png) |

## Wireframes

### Screen flow

How the player moves between screens: the game opens on the title screen, then the player moves between the farm, the town, and the dungeon through warp blocks.

![Screen flow](assets/Wireframes/screenflow.png)

### Screen sketches

| Title | Farm |
| --- | --- |
| ![Title wireframe](assets/Wireframes/title.png) | ![Farm wireframe](assets/Wireframes/farm.png) |

| Town | Dungeon |
| --- | --- |
| ![Town wireframe](assets/Wireframes/town.png) | ![Dungeon wireframe](assets/Wireframes/dungeon.png) |

### Player menus

| Stats | Inventory | Equipment |
| --- | --- | --- |
| ![User stats wireframe](assets/Wireframes/user_stats.png) | ![User inventory wireframe](assets/Wireframes/user_inventory.png) | ![User equipment wireframe](assets/Wireframes/user_equipments.png) |

## Screens

### Title screen

- **On it:** the game name and the entry point into the game.
- **The user does:** starts the game.
- **Goes to:** the farm (Home Island).

### Farm (Home Island)

- **On it:** the player, the farm plots, and the always-on HUD (coin counter, pause button, and buttons for the player menus).
- **The user does:** moves around, plants seeds, grows and harvests crops, and opens the player menus.
- **Goes to:** the town, through a warp block. Planting and harvesting stay on this screen.

### Town (Town Island)

- **On it:** the shop and the same HUD.
- **The user does:** buys seeds, equipment, and useful items, and sells items they no longer need.
- **Goes to:** back to the farm, or to the dungeon, through warp blocks.

### Dungeon

- **On it:** monsters, the gambling mini-games (Rock-paper-scissors, Roll the dice, High Low), and the HUD.
- **The user does:** picks a game, plays against a monster, and wins or loses coins and items. Luck affects the outcome.
- **Goes to:** back to the town or farm through a warp block.

### Player menus (Stats, Inventory, Equipment)

- **On them:** Stats shows the player name and picture, coins, and luck as four stars. Inventory lists items (everything that is not equipment) in a grid of 9 slots, with a count when there is more than one. Equipment lists the equipment the player owns and shows the single worn item and its effect.
- **The user does:** taps a slot to see the item's name, effect, and description, taps an equipment slot to wear or remove it (one at a time, and the worn item gets a gold border), uses previous and next buttons to move between menus, and closes the panel.
- **Goes to:** back to the screen the player opened it from.

### Shop (Buy and Sell)

- **On them:** Buy shows 9 items the shop has in stock, with a countdown to the next restock (the stock changes every hour). Sell shows what the player owns. Both show the selected item, its price, a quantity, the total price, and a message line.
- **The user does:** taps an item, changes the quantity with the minus and plus buttons, and confirms. The message line explains a failed deal, such as not enough coins or a full inventory.
- **Goes to:** back to the town when closed.

### Pause menu

- **On it:** resume, settings, and exit buttons. It opens with the pause button or the Escape key and dims the game behind it.
- **The user does:** pauses the game (the player cannot move while it is open), resumes, or exits. Exiting saves the game first.
- **Goes to:** back to the game on resume, or out of the game on exit.
