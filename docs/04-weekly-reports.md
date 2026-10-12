# Weekly reports

One entry per week, newest at the top. Reports were due every Sunday. Week 1 began when the repository was created on Sunday, Sep 20.

---

## Week 3 (Oct 5 to Oct 11)

**Done this week**
- Wrote the project documents: proposal, mockup and wireframes, design system, security and privacy, security checklist, and this weekly report log
- Updated the README with the current storage, status, privacy, and documentation sections

**In progress**
- Weekly reports, demo video, and AI usage document
- Farming and the dungeon games

**Blocked or stuck on**
- Still figuring out how to approach farming and dungeon mechanics without making the existing code harder to maintain. It is easy to plan features on paper, but turning them into working game systems requires breaking them down into smaller parts first.

**Decisions made, and why**
- Documented the web demo's save limitation. The browser cannot write the local save file, so the demo starts from the default save each visit.
- Prioritized documenting the current features and limitations before adding more mechanics, so the project stays understandable and easier to continue developing.

**Hours spent, roughly:** 6–8 hours

**Next week I will:**
- Do the forreal final revisions

---

## Week 2 (Sep 28 to Oct 4)

**Done this week**
- Cleaned up the code and the player sprites
- Had Claude rewrite most of the modules and refactor across the files
- Added level transitions with a screen fade when moving between maps
- Made a house room map
- Built the game UI from a single Tiled map (`UI.tmx`): HUD, pause menu, inventory, equipment, buy, and sell screens
- Added the player profile (name, coins, luck) with luck shown as four stars
- Added the inventory (9 slots, up to 99 of each item) and equipment (one worn at a time, adds luck)
- Added item and shop data in JSON (`items.json`, `shop.json`) and a shop with buying, selling, and an hourly restock
- Added saving and loading to a local JSON save file
- Added the UI sprites and other assets, and revised the README format

**In progress**
- Farming
- Dungeon games

**Blocked or stuck on**
- The September 30 refactor was harder than expected because changing the structure of several modules at once made it difficult to tell whether a problem came from the original logic or the new implementation. Fixing one issue sometimes exposed another, and I had to spend time understanding how the classes interacted instead of simply adding features.
- The October 4 changes were another frustrating debugging session. Getting the UI, inventory, shop, and player data to work together meant dealing with small inconsistencies that were not always obvious at first. It was a reminder that a feature can look finished on screen while its underlying logic still needs work.

**Decisions made, and why**
- Used Claude to refactor the code to be fully object-oriented, so each part of the game (player, level, collisions, warps) is its own class. This makes responsibilities easier to separate and should make it easier to add more mechanics without putting everything into one large file.
- Moved between maps through warp blocks with a fade, so changing maps feels smooth instead of a hard cut.
- One Tiled map for every screen, with each screen as a layer, so the layout can be changed in Tiled without changing the code.
- Only one piece of equipment can be worn at a time, and each one adds luck, which is the stat the dungeon gambling will use.
- The shop's stock is calculated from the clock instead of being random each time, so everyone gets the same stock in the same hour and nothing about the stock needs to be saved.
- The save file is written to a temporary file and then renamed, so a crash cannot leave a half-written save.

**Hours spent, roughly:** 15–20 hours

**Next week I will:**
- Start farming and the dungeon games, the next items in the README

---

## Week 1 (Sep 20 to Sep 27)

**Done this week**
- Created the repository and the project from the course template
- Added the art assets and the Flame and Flame Tiled packages
- Got the map showing and the camera working
- Added integer scaling so the pixel art stays sharp
- Reorganized the file structure and made the spritesheets work as sequences
- Rewrote the README with the project description, features, and setup instructions
- Added the home screenshot and mockups, and updated the README for Week #1
- Added a second map and fixed level selection
- Added character movement, keyboard controls, and mobile joystick controls (the joystick is currently switched off in the game)
- Added collisions between the player and the world
- Fixed a possible crash with null safety

**In progress**
- Code cleanup
- Moving between maps

**Blocked or stuck on**
- Collisions took several commits on Sep 27 to get working. It was frustrating because the player could appear to move correctly but still pass through objects or get blocked in the wrong places. Aligning collision shapes with the tilemap and understanding how Flame handled movement and collision detection took more trial and error than expected.
- Initial setup and tooling also slowed things down. Missing imports, figuring out which files belonged in `.gitignore`, and understanding how the different packages worked together were small issues individually, but they interrupted development while I was still getting familiar with the framework.

**Decisions made, and why**
- Used Flutter with Flame and `flame_tiled`, so the maps can be drawn in Tiled and loaded into the game.
- Used integer scaling and no image smoothing, because blurry or uneven pixels look wrong in pixel art.
- Picked the Sprout Lands art pack because its cozy, colorful style fits the farming and exploration concept. Using a consistent asset pack also helped the game look more cohesive without having to create every sprite from scratch.

**Hours spent, roughly:** 12–16 hours

**Next week I will:**
- Clean up the code
- Add transitions between maps
