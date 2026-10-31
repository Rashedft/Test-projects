# Technical architecture

## Current implementation

- `main.tscn` composes the running opening through `scripts/world.gd`.
- `scripts/town_builder.gd` constructs world geometry and reusable original character/creature placeholders. It owns presentation generation, not persistent gameplay state.
- `scripts/world.gd` handles exploration, NPC interactions, UI navigation and battle presentation. Menus scroll within bounded panels. Extract these menu builders into reusable UI scenes before the next map expansion.
- `scripts/game.gd` is the persistent state service: species vs individual records, stats, 25 natures, party/storage/items, gifts/quest flags, leveling/evolution, purchases, and save/load validation.
- `scripts/battle.gd` is a presentation-independent session with injected state and seedable RNG, move resolution, stages, type chart, switching, capture and terminal outcomes.
- `data/species.json`, `moves.json`, `natures.json` are the curated playable subset. Runtime never falls back to an invented move or unknown species.
- `data/reference/` retains a pinned source snapshot and provenance. `data/catalog/` normalizes all 493 base/default species and 617 XY-era moves. Both are excluded from the executable until effects/data audits are completed.

## Individual Pokémon contract

UID, species ID, nickname, level/XP, nature, IV/EV arrays, ability, friendship, HP/status and move-slot PP are persisted individually. Species data is shared and separate. Swapping or evolving emits state change and refreshes the follower. Storage holds the original individual, preserving identity and all fields.

## Save contract

Schema version 1; three named slots; temp file + flush + rename; prior save copied to `.bak`. Load validates the entire candidate before replacing live state. Current validation accepts only implemented maps/species/statuses and rejects unknown future versions. Add explicit sequential migrations when changing the schema. New regions must extend this validation and world loading together; never reset team or inventory during travel. Backups are not automatically recovered yet.

## Planned expansion

1. Extract menu/player/follower/NPC components and Pallet into reusable scenes; add map registry, portals, spawn points and navigation.
2. Move battle commands/events into typed records. Presentation consumes event streams; all rules stay independent of scene nodes. Add effect handlers with explicit coverage flags; unsupported effects must never silently behave as ordinary attacks.
3. Activate catalog entries only after historical data and effect coverage tests. Separate learnsets by X/Y version group and method; import TM/HM item mappings. Model non-Mega forms explicitly.
4. Add a move-learning choice queue; accurate XP/EV rewards/participation; abilities, held items, weather/status, full capture/escape odds and doubles.
5. Store regions, trainer teams, encounters, quest transitions, dialogue, travel and boss scaling in structured resources. Rival levels are fixed by story milestone; boss scaling evaluates multiple party members, uses bounded regional baselines and never alters player progression.
6. Build contiguous Kanto progression first; then independent Johto and Hoenn campaigns sharing the same persistent state. Canon decision: Juan is gym eight, Wallace is Hoenn Champion. Johto has a separate League challenge.
7. Replace procedural assets through a license-tracked pipeline, then Forward+ lighting, dynamic battle camera, sound/accessibility/gamepad and performance testing.

No existing working source build was supplied; no legacy build was overwritten. The first tested source/binary archives are the baseline for future releases. Each task already has an isolated checkout; use the existing checkout without creating a worktree unless explicitly requested.

## Presentation layer added in 0.2

`presentation/character_art.gd` owns original reusable mesh shapes and cached materials. `animated_actor.gd` animates limb pivots, blinks, wings and tails. `battle_effects.gd` consumes plain resolved-hit/status events from BattleSession, using temporary self-cleaning effect nodes. These files do not change battle calculations. Battle actor meshes persist across turns and are replaced only when the active identity/species changes. The arena is never recreated per attack.

`town_builder.gd` builds a repeatable layout, with local scenery RNG independent of the gameplay RNG. Roof tiles, grass, pavers and flowers use MultiMesh batches; material/low-detail primitive reuse bounds the resource cost. The model viewer shares exactly the same art factory as exploration and battle, and never grants species or modifies saves. Ground collision queries relocate loaded positions when new geometry would trap the player.

Water, grass and outline shaders are original source in `shaders/`. The preview remains on Compatibility with 4× MSAA because that is the renderer available for actual software rendering here. Forward+ and the hardware FPS target still require a separate validation pass.

Static building/tree primitives are baked into material-grouped meshes after construction; their collision bodies are reparented with world transforms preserved. Roof/grass/path MultiMeshes remain separate batches. The archive helper excludes the repository's downloads directory so successive source archives do not recursively include previous binary ZIPs.
