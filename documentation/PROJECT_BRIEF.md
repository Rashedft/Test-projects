# PROJECT: Pokémon Three Regions 3D — Complete Game Development

## 1. Your Role

You are my **lead game developer, software engineer, technical architect, and project manager**.

Your responsibility is to develop a complete, playable, 3D Pokémon-inspired RPG for Windows PC using Godot 4.

I am the project owner and game director, not an experienced game developer. I want you to handle the technical development, including:

- Writing and maintaining game code.
- Designing the software architecture.
- Organizing all files and folders.
- Creating and configuring Godot scenes.
- Building gameplay systems.
- Implementing the Pokémon database.
- Creating maps, characters, NPCs, and story events.
- Integrating appropriately licensed 3D models and animations.
- Building user interfaces.
- Implementing battle mechanics and trainer AI.
- Managing saves and game progression.
- Testing and debugging.
- Packaging playable Windows builds.
- Maintaining documentation and tracking development progress.

**Do not repeatedly ask me to implement individual features or test every small change.**

I want you to work independently through as much development as your environment permits, integrating related features together before requesting my involvement.

When you require information, permissions, assets, or testing that you genuinely cannot obtain yourself, explain exactly what you need.

Use reasonable design decisions where details are missing. Avoid unnecessary questions.

The ultimate deliverable is **one complete, integrated, playable Windows game**, not a collection of unrelated technical demonstrations.

---

# 2. Existing Project

I already have an early working Godot 4 prototype.

It currently includes basic versions of:

- A simple 3D Pallet Town environment.
- Character movement.
- Professor Oak interaction.
- Mom interaction.
- Pokémon starter gifts.
- Party management.
- Following Pokémon.
- Pikachu evolution using a Thunder Stone.
- Basic battle demonstrations.
- Saving and loading.

Build 03.1 was confirmed to launch successfully on my PC.

Build 04 contains further battle-development changes but has not yet been fully verified.

**Start by inspecting the existing Godot project files I provide.**

Do not rebuild functioning systems unnecessarily.

Identify which systems are working, incomplete, broken, or missing.

Refactor and expand the existing project into a maintainable, modular game.

If an existing feature is poorly implemented, improve it without breaking other functionality.

Preserve a backup of the last known working build.

---

# 3. Game Overview

## Game title

Working title: Pokémon Three Regions 3D.

## Platform

- Primary platform: Windows PC.
- Game engine: Godot 4.
- Rendering: 3D, using the Forward+ renderer where appropriate.
- Target resolution: 1920 × 1080.
- Target performance: 60 FPS.
- Support keyboard controls, with gamepad support desirable.
- Save and load games locally.

## Target hardware

My computer has approximately:

- Intel Core i7, possibly 8th generation.
- 32 GB DDR4 RAM at 3200 MHz.
- EVGA NVIDIA RTX 3080 Ti.
- Windows operating system.

Optimize the game for this hardware without unnecessarily sacrificing graphics quality.

## Core concept

Create one connected Pokémon RPG containing three fully explorable regions:

1. Kanto
2. Johto
3. Hoenn

The player begins in Kanto, progresses into Johto, and finally travels to Hoenn.

Each region contains:

- Eight gym leaders.
- Eight gym badges.
- Its own Elite Four.
- Its own Champion.
- Regional storyline.
- Rival encounters.
- Towns and cities.
- Routes.
- Wild Pokémon.
- Optional quests.
- Legendary Pokémon encounters.
- Pokémon Centers and Poké Marts.
- Story events and progression requirements.

The player retains their original team throughout all three regions.

There must be **24 gym badges in total, 12 Elite Four members, and three Champions**.

---

# 4. Graphics and Camera

The game must use fully 3D graphics inspired by **Pokémon X & Y on Nintendo 3DS**.

Do not use Pokémon Emerald's 2D graphical style as the final presentation.

The visual direction should include:

- Stylized 3D environments.
- Detailed towns and cities.
- 3D buildings and interiors.
- Trees, grass, rivers, caves, and mountains.
- Animated human characters.
- Animated 3D Pokémon.
- Smooth character movement.
- Third-person exploration camera.
- Dynamic battle camera.
- Appropriate lighting and shadows.
- Clear dialogue windows and menus.
- Polished Pokémon-style battle presentation.

The camera should resemble Pokémon X & Y's exploration perspective rather than a first-person game.

Use modular scene construction so towns, routes, caves, buildings, and other environments can be developed independently and connected into one world.

Temporary placeholder models are acceptable during development, but the final product must not look like a basic block-based technical prototype.

Use original or appropriately licensed assets where possible. Do not assume proprietary Nintendo models, music, textures, or other copyrighted assets are freely available for redistribution.

---

# 5. Pokémon Availability

The game must include the Pokémon species introduced in Generations 1–4.

This means the original 493 Pokémon, from Bulbasaur through Arceus.

All included Pokémon should have:

- Species identification.
- Types.
- Base statistics.
- Abilities.
- Nature.
- Individual Values (IVs).
- Effort Values (EVs).
- Experience and leveling.
- Evolution requirements.
- Learnable moves.
- Move animations.
- Catch rates.
- Wild encounter availability.
- Pokédex entries.
- 3D representation.
- Appropriate battle behavior.

The data architecture should support adding more Pokémon later without rewriting the underlying systems.

---

# 6. Pokémon X & Y Mechanics — Extremely Important

Although the Pokémon roster is limited to Generations 1–4, **the battle rules and move-learning systems must follow Pokémon X & Y, Generation 6**.

This requirement is essential.

Do not use the original Generation 1, 2, 3, or 4 level-up learnsets simply because a Pokémon originally appeared in that generation.

For example:

Pikachu must use its Pokémon X & Y level-up learnset, not its Pokémon Yellow learnset.

The same applies to Bulbasaur, Charmander, Squirtle, and every other included Pokémon.

Implement:

- Generation 6 species-specific level-up learnsets.
- Generation 6 move power and accuracy.
- Generation 6 move typing.
- Generation 6 Physical/Special classifications.
- Generation 6 type-effectiveness chart.
- Fairy type.
- Generation 6 abilities and their relevant effects.
- Generation 6 status-condition mechanics.
- Generation 6 experience and battle calculations.
- Generation 6 TM/HM compatibility.
- Generation 6 evolution requirements.
- Moves introduced in later generations when available in Pokémon X & Y.
- Move PP, priority, secondary effects, and accuracy calculations.

Build the Pokémon and move databases using reliable, verifiable Generation 6 reference data.

Do not invent learnsets, base stats, move properties, or evolution methods.

Implement learnsets as structured data separate from the battle code.

### Mega Evolution

**Mega Evolution must be completely excluded.**

No Mega Stones, Mega forms, Mega Evolution buttons, or Mega Evolution mechanics.

Normal evolution remains available.

---

# 7. Opening Story — Kanto

The player begins in Pallet Town, following the general structure of Pokémon Yellow.

## Professor Oak

Professor Oak gives the player:

**Pikachu — Level 5**

Pikachu becomes the first Pokémon in the player's party.

## Player's Mom

After receiving Pikachu, the player returns home.

Mom surprises the player by giving them:

- Bulbasaur — Level 5
- Charmander — Level 5
- Squirtle — Level 5

The player therefore begins their adventure with four Pokémon.

All four Pokémon should be available immediately, before leaving Pallet Town.

Do not require the player to obtain Bulbasaur, Charmander, or Squirtle later in the Kanto storyline.

The Pokémon gift events must occur only once and persist correctly after saving and loading.

---

# 8. Party and Following Pokémon

The game must support a standard six-Pokémon active party.

**The Pokémon in party slot 1 must automatically follow the player in the overworld.**

This is not restricted to Pikachu.

Examples:

- Pikachu in slot 1 → Pikachu follows the player.
- Charizard in slot 1 → Charizard follows the player.
- Blastoise in slot 1 → Blastoise follows the player.
- Gengar in slot 1 → Gengar follows the player.

Changing the party order should immediately update the following Pokémon.

The lead Pokémon should:

- Walk behind the player.
- Follow the player's movement naturally.
- Avoid excessive clipping into objects.
- Teleport or reposition safely if stuck.
- Display walking or idle animations.
- Be the first Pokémon sent into battle.
- Reflect its current evolutionary form.

Implement a proper party menu where the player can:

- View Pokémon.
- View levels, types, and HP.
- Inspect statistics.
- Inspect moves.
- Rearrange the party.
- Use eligible items.
- Select Pokémon for battle.
- Send Pokémon to PC storage where allowed.

### Pikachu Evolution

Pikachu must be able to evolve into Raichu using a Thunder Stone.

Do not permanently prevent Pikachu from evolving as Pokémon Yellow originally did.

If Pikachu evolves while occupying party slot 1, Raichu should replace Pikachu as the following Pokémon.

---

# 9. Kanto Region

Kanto is the first region and should follow the broad storyline and progression of Pokémon Yellow.

Include the major locations, characters, events, routes, caves, and cities associated with that adventure.

Implement the eight Kanto gyms:

1. Brock — Pewter City
2. Misty — Cerulean City
3. Lt. Surge — Vermilion City
4. Erika — Celadon City
5. Koga — Fuchsia City
6. Sabrina — Saffron City
7. Blaine — Cinnabar Island
8. Giovanni — Viridian City

Include:

- Team Rocket.
- Jessie and James where appropriate.
- Silph Co.
- Pokémon Tower.
- Safari Zone.
- Victory Road.
- Indigo Plateau.
- Kanto Elite Four.
- Champion Blue/Gary.

The Kanto storyline should be complete before the main progression to Johto.

### Kanto Rival

Blue/Gary is the principal Kanto rival.

He begins his Pokémon journey alongside the player and becomes progressively stronger through scripted encounters.

Do not arbitrarily scale his Pokémon to match the player.

Create a believable progression for his team and abilities.

### Additional Rival

Include a newly created rival who appears throughout the adventure.

Design an original personality, motivation, Pokémon team, character arc, and recurring encounters.

This rival should meaningfully contribute to the story without replacing Blue or Silver.

---

# 10. Traveling from Kanto to Johto

After collecting all eight Kanto badges and defeating the Kanto Pokémon League, the player unlocks travel to Johto.

The S.S. Anne becomes the regional transportation system.

The player boards the ship in Vermilion City.

The ship travels to Olivine City in Johto.

Create:

- A port interaction.
- Ticket or boarding requirements.
- Ship interior.
- NPCs.
- Optional trainer battles.
- Travel dialogue.
- Arrival event.

After arrival in Johto, direct the player toward New Bark Town and Professor Elm so the regional storyline can proceed naturally.

The player must retain:

- Every owned Pokémon.
- Existing levels.
- Experience.
- Evolutions.
- Moves.
- Items.
- Pokédex progress.
- Money.
- PC storage.

Do not reset the player's progress between regions.

---

# 11. Johto Region

Johto is based on Pokémon Gold and Silver, with suitable elements from Crystal and HeartGold/SoulSilver.

Include its eight gyms:

1. Falkner
2. Bugsy
3. Whitney
4. Morty
5. Chuck
6. Jasmine
7. Pryce
8. Clair

Include:

- Professor Elm.
- New Bark Town.
- Cherrygrove City.
- Violet City.
- Azalea Town.
- Goldenrod City.
- Ecruteak City.
- Olivine City.
- Cianwood City.
- Mahogany Town.
- Blackthorn City.
- Team Rocket's return.
- Important legendary Pokémon quests.
- Johto Elite Four.
- Separate Johto Champion.

Unlike the original games, Johto must have its own distinct Pokémon League challenge rather than requiring the player to repeat Kanto's League unchanged.

## Silver — Critical Rival Requirement

Silver must begin his adventure from scratch.

He steals a level 5 starter Pokémon from Professor Elm.

He should not suddenly receive level 60 or level 80 Pokémon simply because the player arrived from Kanto with a strong team.

His progression must be:

- Story-driven.
- Gradual.
- Believable.
- Based on repeated training and encounters.
- Independent of the player's current levels.

Silver can train quickly and eventually become a formidable opponent, but he must earn that strength through the progression of the Johto story.

Early Silver battles can be easy for the experienced player.

This is intentional.

His character development and increasing strength should make later battles meaningful.

---

# 12. Johto Starter Side Quests

Do not automatically give the player Johto's starter Pokémon upon arrival.

Instead, create optional quests that reward:

- Chikorita
- Cyndaquil
- Totodile

The player should be able to obtain all three eventually.

Professor Elm can provide research-related missions that unlock them.

Each starter should be received at level 5.

These quests should feel like part of Johto's world rather than simple item collection.

All three quests should be tracked and preserved in the save file.

---

# 13. Traveling from Johto to Hoenn

After defeating Johto's eight gym leaders, Elite Four, and Champion, unlock the next voyage.

Professor Elm introduces a Pokémon research expedition taking place in Hoenn.

The player boards the S.S. Anne at Olivine City.

The ship arrives in Slateport City, Hoenn.

Include story dialogue explaining the expedition.

After unlocking regional travel, the player should eventually be able to move freely between the three regions using the ship transportation system.

All Pokémon, levels, items, experience, and other progress must remain intact.

---

# 14. Hoenn Region

Hoenn is the third and final main region.

It should follow the broad storyline of Pokémon Ruby, Sapphire, and Emerald, with an integrated narrative involving Team Aqua and Team Magma.

Include:

- Professor Birch.
- Littleroot Town.
- Oldale Town.
- Petalburg City.
- Rustboro City.
- Dewford Town.
- Slateport City.
- Mauville City.
- Fallarbor Town.
- Lavaridge Town.
- Fortree City.
- Lilycove City.
- Mossdeep City.
- Sootopolis City.
- Ever Grande City.
- Groudon.
- Kyogre.
- Rayquaza.
- Team Aqua.
- Team Magma.
- Hoenn Elite Four.
- Hoenn Champion.

The eight Hoenn gyms are:

1. Roxanne
2. Brawly
3. Wattson
4. Flannery
5. Norman
6. Winona
7. Tate & Liza
8. Juan or Wallace, depending on the chosen Emerald-inspired storyline.

Use one consistent Emerald-inspired canon for gym and Champion roles. Prefer Wallace as the eighth gym leader only if Steven remains Champion; otherwise use Juan as the eighth gym leader with Wallace as Champion.

## Hoenn Rivals

Brendan and/or May begin their adventures with level 5 Pokémon.

Their teams must progress naturally over time.

They must not artificially scale to the player's powerful team after the player has completed Kanto and Johto.

The player should feel like an experienced trainer entering a region with new trainers.

The major challenges in Hoenn should come primarily from the gym leaders, Elite Four, Champion, and significant story opponents.

---

# 15. Hoenn Starter Side Quests

Treecko, Torchic, and Mudkip must be obtainable through separate optional quests.

Do not automatically give the player these Pokémon upon reaching Hoenn.

Professor Birch can provide field research tasks involving unusual habitats or regional Pokémon behavior.

Completing each task awards the relevant level 5 starter.

All three starters should eventually be obtainable.

---

# 16. Difficulty and Level Scaling

The game must remain challenging across all three regions without erasing the player's progression.

Use two different progression systems.

## A. Rivals

Rivals follow a fixed, story-driven level progression.

Their levels are not dynamically matched to the player.

This applies especially to:

- Blue/Gary.
- Silver.
- Brendan.
- May.
- The new original rival.

## B. Gyms, Elite Four, and Champions

Important boss encounters adapt to the player's team strength and regional progression.

Their teams should:

- Remain challenging.
- Use competitive but reasonable movesets.
- Have improved battle AI.
- Use appropriate held items.
- Have intelligently selected Pokémon.
- Avoid unfair or arbitrary difficulty spikes.
- Account for the player's existing team.

The scaling system should consider multiple Pokémon and party composition rather than only the highest-level Pokémon.

Gym leaders should also become progressively stronger within their region.

Do not force the player to restart with low-level Pokémon in Johto or Hoenn.

The player's original team remains fully usable.

---

# 17. Battle System

Develop a complete turn-based Pokémon battle system using Generation 6 mechanics.

Include:

- Single battles.
- Double battles where required.
- Wild Pokémon battles.
- Trainer battles.
- Gym battles.
- Elite Four battles.
- Champion battles.
- Legendary encounters.
- Moves and move selection.
- PP.
- Turn order.
- Move priority.
- Speed calculations.
- Accuracy and evasion.
- Critical hits.
- STAB.
- Type effectiveness.
- Weather.
- Status conditions.
- Stat stages.
- Abilities.
- Held items.
- Switching Pokémon.
- Fainting.
- Experience distribution.
- Evolution.
- Battle rewards.
- Trainer AI.

Implement the familiar battle menu:

**Fight | Pokémon | Bag | Run**

Running should be restricted appropriately in trainer battles.

Create proper battle messages, HP bars, move effects, and animations.

Use an architecture separating battle calculations from graphical presentation to make the rules testable.

---

# 18. Catching, Evolution, and Storage

Implement:

- Wild encounters.
- Poké Ball capture calculations.
- Different Poké Ball types.
- Pokémon nicknames.
- Pokémon Centers.
- Healing.
- PC Pokémon storage.
- Six-Pokémon active party.
- Pokémon switching.
- Evolution animations.
- Level-based evolution.
- Evolution stones.
- Friendship evolution.
- Trade-based evolution alternatives suitable for a single-player game.
- Other relevant Generation 6 evolution methods.

When the active party is full, newly captured Pokémon should transfer to PC storage.

Ensure species data and individual Pokémon data are stored separately.

---

# 19. Inventory and Menus

Develop polished menus consistent with the overall 3D visual style.

Include:

- Main menu.
- Pokémon party.
- Bag.
- Pokédex.
- Trainer Card.
- Region map.
- Quest journal.
- Options.
- Save and load.
- Pokémon PC storage.
- Move summaries.
- Pokémon statistics.

Use responsive layouts that do not clip or extend beyond the screen.

The existing prototype previously had an issue with an incomplete party menu, so UI scaling and screen boundaries must receive specific attention.

---

# 20. Saving and Loading

Create a robust save system.

Save data must preserve:

- Player position.
- Current region.
- Story progression.
- Gym badges.
- Elite Four completions.
- Champion victories.
- Pokémon party.
- Pokémon boxes.
- Pokémon experience and levels.
- Evolution stages.
- Moves and PP.
- Items.
- Money.
- Quests.
- Rival progression.
- Regional travel unlocks.
- Legendary encounters.
- NPC event flags.

Implement versioned save data so future game updates do not unnecessarily corrupt older saves.

Include multiple save slots if feasible.

---

# 21. Game World and Map Architecture

Use a modular world system.

Suggested project organization:

```text
PokemonThreeRegions/
├── project.godot
├── scenes/
│   ├── player/
│   ├── npc/
│   ├── pokemon/
│   ├── battles/
│   ├── menus/
│   └── world/
├── regions/
│   ├── kanto/
│   │   ├── towns/
│   │   ├── routes/
│   │   ├── gyms/
│   │   ├── caves/
│   │   └── league/
│   ├── johto/
│   │   ├── towns/
│   │   ├── routes/
│   │   ├── gyms/
│   │   ├── caves/
│   │   └── league/
│   └── hoenn/
│       ├── towns/
│       ├── routes/
│       ├── gyms/
│       ├── caves/
│       └── league/
├── scripts/
│   ├── core/
│   ├── player/
│   ├── pokemon/
│   ├── battles/
│   ├── trainers/
│   ├── inventory/
│   ├── quests/
│   ├── progression/
│   └── save/
├── data/
│   ├── species/
│   ├── moves/
│   ├── abilities/
│   ├── evolutions/
│   ├── learnsets/
│   ├── trainers/
│   ├── encounters/
│   └── items/
├── assets/
│   ├── models/
│   ├── animations/
│   ├── textures/
│   ├── audio/
│   └── ui/
├── tests/
├── tools/
├── documentation/
└── builds/
```

You may improve this structure if a better architecture is appropriate.

Avoid placing all gameplay code into one enormous script.

Build reusable components.

---

# 22. Testing and Quality Assurance

Do not depend entirely on me to discover basic programming errors.

Where tools are available, perform:

- Godot startup tests.
- Script parsing checks.
- Automated battle tests.
- Pokémon stat validation.
- Move database validation.
- Evolution validation.
- Save/load tests.
- Party management tests.
- Regional progression tests.
- Encounter table tests.
- Story flag tests.
- UI layout checks.
- Windows export checks.

Maintain an error log.

If a test cannot be run in your environment, clearly identify it as unverified.

Do not report a feature as fully working merely because its source code exists.

---

# 23. Development Strategy

I prefer **integrated development rather than testing one small feature at a time**.

Organize the work in this order internally:

### Foundation
Establish a stable Godot project, player movement, camera, NPCs, interactions, party, saves, and world management.

### Core Gameplay
Implement species data, moves, Generation 6 rules, battle systems, catching, leveling, evolutions, inventory and trainer AI.

### Kanto
Build the complete first region and all its main events.

### Johto
Build the second region, Silver's progression, regional quests, and the Johto League.

### Hoenn
Build the third region, Hoenn storyline, regional quests and League.

### Presentation
Integrate polished 3D models, environments, animations, sound, effects and interfaces throughout development.

### Final Integration
Connect all regions, complete progression, balance difficulty, test the entire adventure and generate a Windows build.

These are internal development stages, not requests for me to test after every stage.

Maintain one unified project throughout development.

---

# 24. Progress Tracking

Track the entire project's completion as 100%.

Use the following initial estimates:

| Development area | Estimated share |
|---|---:|
| Foundation and project structure | 5% |
| Core gameplay systems | 20% |
| Kanto | 25% |
| Johto | 20% |
| Hoenn | 20% |
| Final integration and polish | 10% |
| **Total** | **100%** |

These percentages are approximate workload weights, not claims that a feature is complete.

Track verified completion separately from code written but not yet tested.

When reporting progress, briefly explain:

- Overall percentage completed.
- Current development area.
- What is working.
- What remains.
- Any blockers requiring my involvement.

Do not inflate completion estimates.

---

# 25. Deliverables

The final deliverables should include:

1. A complete Godot 4 source project.
2. All game scripts and structured data files.
3. Organized regional maps and game scenes.
4. Integrated models, animations, and other permitted assets.
5. A playable Windows executable.
6. Functional save and load.
7. Documentation explaining controls and installation.
8. Known issues and testing results.

Do not claim the game is finished until it is actually playable and major progression paths have been tested.

---

# 26. Communication and Autonomy

I want you to take initiative.

Do not continually ask me to approve minor decisions.

You are authorized to make reasonable technical and gameplay implementation decisions consistent with these requirements.

Whenever possible:

- Write the actual code instead of merely describing how to write it.
- Create the files instead of telling me to create them.
- Organize the project yourself.
- Fix programming errors you can reproduce.
- Implement dependent systems together.
- Reuse stable functionality rather than rewriting it.
- Test before presenting builds.
- Keep the project runnable.

If you need my assistance, explain the requirement using simple, numbered instructions because I am unfamiliar with the Godot editor.

Do not ask me to manually create dozens of folders, scenes or scripts if you can generate them yourself.

Avoid repeatedly asking whether I want to proceed.

**Assume I want you to continue developing toward the complete game whenever your tools and current execution environment permit it.**

Do not imply you can work asynchronously when the execution environment cannot support it.

---

# 27. Your First Task

Begin by auditing the existing project files I provide.

Then:

1. Inspect the source code and scenes.
2. Identify working and incomplete functionality.
3. Create a technical architecture for the complete game.
4. Organize or refactor the project appropriately.
5. Begin implementing the missing core systems.
6. Integrate the systems into the existing Godot project.
7. Run available tests and resolve failures.
8. Continue implementing the game within your current working session instead of stopping after a small demonstration.
9. Produce updated project files and accurate progress documentation.

Prioritize completing substantial, functional portions of the game.

If the entire game cannot be finished in one execution, preserve the current working state and document the exact next tasks so development can resume without losing progress.

**The objective is a complete, polished, single-player, three-region 3D Pokémon adventure, developed as one cohesive game rather than disconnected prototypes.**
