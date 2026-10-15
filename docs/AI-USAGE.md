# AI usage

> **Note:** I used ChatGPT to help write and organize this AI usage document too. That is part of my AI usage, not something I want to hide: my first thoughts are often messy, fragmented, or poorly worded, and I use AI to turn that rough material into something organized and understandable. I still need to check that the final wording is accurate and actually reflects what I did.

## 1. How I used AI

### Background — learning Dart, Flutter, and Flame through a tutorial

Before relying heavily on AI, I followed a YouTube tutorial about making games with Dart, Flutter, and the Flame engine. The tutorial was building a 2D platformer, while Eppy Island was meant to be a different kind of game with a broader set of features. I therefore could not use the tutorial's code unchanged: I repeatedly rewrote and adapted its ideas to fit my own game's structure and intended gameplay.

At first, the tutorial helped me get started with the framework and understand the basic pieces of a Flame game. However, as Eppy Island grew beyond the tutorial's scope, I found it difficult to connect those pieces into a larger project with multiple systems. After the video, I was often unsure how to move from the tutorial's platformer structure to the game I actually wanted to build. This was an important reason I began using AI for help with understanding unfamiliar code, adapting existing systems, refactoring, debugging, and documenting the project.

The tutorial and AI played different roles. The tutorial was an early learning resource; AI became a tool I used while trying to adapt, extend, and understand the project. As the project became more complicated, I often had a clear idea of what I wanted the game to do but struggled to explain the idea in precise technical language. My requests could start out as rough notes, fragments, or what I would honestly call gibberish. I used AI both to help work through the code and to organize those thoughts into clearer requirements, explanations, and documentation. It often helped me express what I was trying to say better than I could on my first attempt. That does not mean every generated change was correct or that I understood everything immediately; I still had to compare the result with the game I was trying to make, correct mistakes, and ask for revisions. The presence of tutorial-inspired code does not mean every later implementation was copied directly from the video, just as AI assistance does not mean every generated change was accepted unchanged.

### Documenting the project in the README

- **Tool:** ChatGPT
- **What I asked for:** Help organize the README around the game's purpose, current features, required packages, setup instructions, screenshots, and mockups. I often knew the information I wanted to communicate but did not have a clean first draft, so I used ChatGPT to turn rough thoughts into a readable explanation for someone opening the repository for the first time.
- **What it gave back:** A more structured README with a project description, a feature overview, setup guidance, and sections for screenshots and project resources. Follow-up edits added more feature and setup detail and updated screenshot references. ChatGPT was not only correcting grammar; it also helped me decide how to arrange information and explain the project clearly.
- **What I kept, what I changed, and why:** I kept the clearer structure and many of the explanations, but revised wording, image paths, screenshots, and the status description as the game changed. I checked whether the README matched the files and the actual implementation rather than treating polished writing as proof that its claims were correct. I did not want it to claim that unfinished features already worked, and I had to keep links consistent with the files in the repository.
- **Commit:** [4c4a6d9 — Refactor README for project details and clarity](https://github.com/Aonnoes/eppy-island/commit/4c4a6d90dcdd39a543353d36e6b91639731b9084); follow-up [07aca89 — Enhance README with new features and setup instructions](https://github.com/Aonnoes/eppy-island/commit/07aca894de549d9edd95ef0bf924bb0cea3fc0d9); later progress revision [3347d42](https://github.com/Aonnoes/eppy-island/commit/3347d42c63926ef8964ae3337754ed73dd95d0e2).

### 2026-09-27 — Movement controls and collision debugging

- **Tool:** ChatGPT
- **What I asked for:** Help with the early player controls: directional movement and animations, keyboard input, a mobile joystick, and collisions so the character could move through the world without walking through map obstacles. This is a summary of the work shown by the diffs; adjust it if the original request was different.
- **What it gave back:** An implementation approach for handling eight movement directions, mapping keyboard and joystick input to a direction, and resolving collisions against blocks defined in the Tiled maps. The early code updates the player's position one axis at a time, then checks collisions on that axis.
- **What I kept, what I changed, and why:** I kept the idea of separating input from collision handling and using Tiled object layers to describe collision areas. I adjusted the map collision objects and collision response across several commits because the player could still get blocked in the wrong places or pass through parts of the world. The on-screen joystick was added, although it was switched off in the game at that stage. These early modules were later substantially refactored with Claude, so this entry refers to the early implementation rather than claiming that every line survives in the current version.
- **Commit:** [3f727c5 — Keyboard controls](https://github.com/Aonnoes/eppy-island/commit/3f727c5d8c00f8d7b2afd553bfbef3883903dd09); [847be37 — Mobile joystick controls](https://github.com/Aonnoes/eppy-island/commit/847be378c831874c45c3bf50ead88d3c2f13baf2); [0d34534 — Collisions](https://github.com/Aonnoes/eppy-island/commit/0d34534b492095b809aeeca99b5e3ca77b620146); [d75d3bf — Collision adjustments](https://github.com/Aonnoes/eppy-island/commit/d75d3bfee3ba39d0590fff90f1b8d6c874e6d0af).

### 2026-10-12 — Revising the project documentation

- **Tool:** ChatGPT
- **What I asked for:** Help turn the course-document templates and my rough notes into project-specific documents, and make the README, proposal, mockups, design system, weekly reports, and security documents tell a consistent story about Eppy Island. I also used ChatGPT to organize and phrase ideas I struggled to express clearly on my own.
- **What it gave back:** Rewritten and reorganized Markdown sections describing the project's target players and features, the game's save data, dependencies, privacy limits, and current development status. It also helped connect the README and supporting documents and made my notes sound more coherent and presentable.
- **What I kept, what I changed, and why:** I relied on AI quite heavily for the wording and organization, rather than pretending these documents were all polished from my own first drafts. I kept explanations that matched what I meant, then reviewed and changed details that needed to match the implementation. In particular, I documented that the native game saves progress to a local JSON file while the web demo starts fresh because that file-based save approach does not persist in the browser. I left personal fields such as hours spent for me to fill in rather than inventing them. The status was updated again after farming and dungeon features were added on October 14.
- **Commit:** [fb182ae — Revisions: documentation and README](https://github.com/Aonnoes/eppy-island/commit/fb182ae5f9bc46d82cc58649b2340180d0cab7d4); follow-up [646bd23 — Revisions: reflections, clarity, formatting](https://github.com/Aonnoes/eppy-island/commit/646bd236b42d2764acd5b248d52c3d28004812bc).

### Also documenting — current gameplay and instructions

- **Tool:** Claude
- **What I asked for:** Help document the version of the game that now had farming, shops, inventory, equipment, and a dungeon, including what the player does, how the controls work, the rules of the minigames, and how to run the project.
- **What it gave back:** A much more detailed player-facing README. It explains the farming loop, watering and regrowth, selling and buying items, equipment and luck, the dungeon entrance prompt, encounter rounds, the Rock Paper Scissors / High or Low / Dice Roll games, and the project's current status and limitations.
- **What I kept, what I changed, and why:** I kept the step-by-step gameplay explanation because it makes a fairly unusual game loop understandable without reading the source code. This was another case where AI helped me present the game more clearly than my own rough explanation would have. I still needed to align the guide with the actual implementation—for example, the encounter's Yes/No choices, the use of a consumable before fighting, the three-life default, hourly shop restocking, and the browser save limitation. I also updated screenshots and project status so the README described the version in the repository rather than an earlier plan.
- **Commit:** [d890fce — Update status, how to run, and screenshots](https://github.com/Aonnoes/eppy-island/commit/d890fce45a25d90bbec7d2122ac2bb34699307d6). Earlier feature documentation was revised in [fb182ae](https://github.com/Aonnoes/eppy-island/commit/fb182ae5f9bc46d82cc58649b2340180d0cab7d4).

### Refactoring the early game modules

- **Tool:** Claude
- **What I asked for:** Rewrite and refactor most of the existing game modules so the player, level loading, collisions, and game coordination would be easier to maintain and extend.
- **What it gave back:** A broad rewrite of `lib/components/player.dart`, `lib/components/level.dart`, `lib/components/collision_block.dart`, `lib/components/utils.dart`, `lib/eppy_island.dart`, and `lib/main.dart`. It extracted map loading, spawn-point placement, and collision-block setup into smaller methods; made more implementation details private; and centralized the direction model in a new `Direction` enum in the following commit. The rewritten player uses that direction model for keyboard and joystick movement and resolves movement separately on each axis.
- **What I kept, what I changed, and why:** I kept the move toward clearer responsibilities and less duplicated direction/movement logic. I did not treat the rewrite as automatically correct: changing several modules at once made it harder to identify which change introduced a problem, as noted in the weekly report. I continued making adjustments afterward, including transitions, warps, and the interior map. The goal was to make later features easier to add without putting every responsibility into one large class, but I still needed to understand how the pieces interacted.
- **Commit:** [86e3bc2 — Claude rewrote most modules and refactored across files](https://github.com/Aonnoes/eppy-island/commit/86e3bc2f7e9d745f2336e349a18f2f9962a83752); follow-up [4afeaff — Direction abstraction](https://github.com/Aonnoes/eppy-island/commit/4afeafff0d0706bc4bf91b83599fd9eece81339a); later transitions [a13a29b](https://github.com/Aonnoes/eppy-island/commit/a13a29b610df01e822449db903e4dc22d9990c0b).

### Doing what I could not work out alone — farming and dungeon mechanics

- **Tool:** Claude
- **What I asked for:** Help break the farming and dungeon ideas into working systems that would fit the existing Flutter, Flame, and Tiled project. I needed more than a screen mockup: the data, state changes, interaction rules, and UI all had to connect.
- **What it gave back:** The farming implementation introduced crop definitions and catalogs, planted-crop growth state, a farm model, plot components, and links to inventory and the UI. The dungeon implementation introduced enemy data, an encounter state machine, reusable minigame rules, a dungeon level and entrance prompt, and a panel for displaying the encounter. The three minigames are Rock Paper Scissors, High or Low, and Dice Roll. The encounter model tracks its phase and lives, decides round outcomes, applies rewards or penalties, and accounts for luck and consumables.
- **What I kept, what I changed, and why:** I kept the separation between rules and presentation: farming rules belong in the farm/crop classes, while plot components draw the world state; similarly, the encounter model decides what happens while the dungeon UI displays the current phase. I then made or requested follow-up corrections rather than accepting the first version as finished. The history shows plot-mechanic fixes, save-data adjustments, a corrected asset path, completion of plot information labels and shop interaction, and a final dungeon color adjustment. That iteration mattered because a feature can appear on screen while its underlying state or data is still wrong.
- **Commit:** Farming and structure: [aa07942](https://github.com/Aonnoes/eppy-island/commit/aa079425d7f98ac10594c025861f366547ed7de2); plot-mechanic corrections [7a18c39](https://github.com/Aonnoes/eppy-island/commit/7a18c398ca0a15ff2c6aab533f25db509f53cddd) and farming/shop completion [2471811](https://github.com/Aonnoes/eppy-island/commit/2471811b924159e31b71cca4b3b32bf0648392d4); dungeon implementation [a671d4b](https://github.com/Aonnoes/eppy-island/commit/a671d4b49dee10b5b2e52bb913e648fe7e89ace8); visual correction [29f1934](https://github.com/Aonnoes/eppy-island/commit/29f19344a39ab6c31247d55d102817595138f3b0).

## 2. Where the AI got it wrong

### Case 1 — Sprite files had the wrong names

- **What it gave me:** A set of separated crop sprites with filenames intended to describe what each image contained.
- **What was wrong with it:** Some filenames did not match the actual sprite. For example, a file named as a plant contained a seed image. That would make it easy for the game to show the wrong sprite even if the path existed and loaded successfully.
- **What I did instead:** I checked each output against the original spritesheet, compared the visual content with its intended filename, and corrected the mappings before using the assets. I did not rely on the filename alone as proof that the crop was correct.
- **Commit:** There wasn't a commit for this; I caught it before committing and pushing.

### Case 2 — Sprite crops included or cut off the wrong pixels

- **What it gave me:** Cropped sprites from the farming spritesheet, including a separate pass for the watered variants.
- **What was wrong with it:** Some crops cut off part of the intended plant, while others included neighboring or unrelated plant pixels. A crop can have a clean border and still be wrong if it uses the wrong source region.
- **What I did instead:** I rechecked the source spritesheet and the crop boundaries, made sure each output matched one intended sprite, and treated the watered variants as a separate verification pass. I checked both the crop's outline and its actual content.
- **Commit:** There wasn't a commit for this; I caught it before committing and pushing.

### Case 3 — The README screenshot Markdown was malformed

- **What it gave me:** Markdown for arranging the project screenshots in the README.
- **What was wrong with it:** The formatting did not preserve the intended image layout; the table or image entries ended up separated by hyphen-like lines instead of rendering as proper Markdown image links.
- **What I did instead:** I asked for actual Markdown syntax and used image links in the expected form, for example `[![Eppy Island screenshot](docs/assets/Screenshots/Screenshot-1.png)](docs/assets/Screenshots/Screenshot-1.png)`. I also checked the filenames and paths rather than assuming the generated Markdown would resolve them correctly.
- **Commit:** There wasn't a commit for this; I caught it before committing and pushing.

## 3. Who wrote what

### Written by me

- **File:** The early player implementation in `lib/actors/player.dart`, later moved and refactored into `lib/components/player.dart`, along with related movement and collision work in `lib/eppy_island.dart` and the map/collision components.
- **Commit:** [6965248 — Character movement](https://github.com/Aonnoes/eppy-island/commit/6965248a8e11742fdbddb5b357968b991b6a2a2a); [3f727c5 — Keyboard controls](https://github.com/Aonnoes/eppy-island/commit/3f727c5d8c00f8d7b2afd553bfbef3883903dd09); [847be37 — Mobile joystick controls](https://github.com/Aonnoes/eppy-island/commit/847be378c831874c45c3bf50ead88d3c2f13baf2); [0d34534 — Collisions](https://github.com/Aonnoes/eppy-island/commit/0d34534b492095b809aeeca99b5e3ca77b620146).
- **What it does and why it is built this way:** This early code handles player movement, chooses the appropriate walking animation, and checks the player against collision blocks placed on the map. Movement is resolved along separate axes so the player can move around obstacles without simply passing through them. The keyboard and joystick feed into the same general movement behavior.

  I want to be careful about what I mean when I say this part was written by me. I learned the basics by following a YouTube tutorial on Dart, Flutter, and Flame. The tutorial was making a 2D platformer, though, and Eppy Island was not meant to be that kind of game. I used the tutorial as a starting point, then rewrote and adapted its ideas to fit the movement and map setup I wanted. So I did not invent the whole approach from scratch, and I would not describe every line as completely original. My contribution was working out how the tutorial's ideas needed to change for my project, trying those changes, and revisiting the code when the behavior did not match what I had in mind.

  This was also one of the first points where I realized that getting something to work once is different from understanding how to build a whole game. I could make progress by following an example, but as I added more features I struggled to see how all the separate systems should fit together. I often knew what I wanted the player to do but had trouble explaining it in technical terms or figuring out the right implementation alone. Later, Claude substantially rewrote these modules, so this entry describes my early, tutorial-informed work—not a claim that the current player system is entirely mine or that it has stayed unchanged. I am most comfortable claiming the adaptation, direction, and iteration I contributed, while being upfront about where I learned from a tutorial and later relied on AI.

### The AI-written part I understand best

I chose the dungeon encounter system because it is a clear example of both how much I relied on AI and what I learned from working with its output. Claude helped create much of the structure, and I do not want to make it sound as though I independently wrote the system line by line. I had the game idea and the desired flow, but I needed help turning it into code with distinct responsibilities. I used AI to get a workable starting point, then reviewed the result, made follow-up changes, and compared the behavior with the encounter I wanted in the game.

- **File:** `lib/dungeon/encounter.dart` and `lib/dungeon/minigame.dart`.
- **Commit:** [a671d4b — Dungeon implementation](https://github.com/Aonnoes/eppy-island/commit/a671d4b49dee10b5b2e52bb913e648fe7e89ace8).
- **What it does and why we kept it:** `Encounter` manages the fight's state and rules without being responsible for drawing the whole interface. It moves through phases such as the intro, prompt, reveal, and result; tracks the participants' lives; applies the result of each minigame; and handles the rewards or penalties when an encounter ends. `Minigame` and its implementations hold the rules for Rock Paper Scissors, High or Low, and Dice Roll. Keeping these responsibilities separate means the interface can show the current phase while the encounter logic decides what that phase means.

  The part I understand best is the overall separation of responsibilities: the encounter controls the flow of a fight, each minigame determines its own outcome, and the UI presents the current state to the player. This structure makes more sense to me than putting all the rules and visuals into one large class, because it gives me a clearer place to look when something needs to change. Working with this code also showed me that an AI-generated system can look organized while still needing careful review; the transitions, edge cases, balance, and connection to the UI all matter. I am not claiming that I could have produced this implementation independently from a blank file, or that I know every line equally well. I can explain the main flow and why the pieces are separated, and I am still learning the lower-level details by reading the code and checking how the game behaves. That is a more honest description of my understanding than claiming full authorship simply because the system is part of my project.
