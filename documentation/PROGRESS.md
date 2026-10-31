# Progress — 2026-10-27 — build 0.1

**Overall: approximately 1% of the requested complete game.** This is a conservative scope estimate, not an objective measurement of code quantity. Current area: foundation and initial core gameplay. No complete region or campaign is playable.

| Area | Total workload weight | Current evidence |
|---|---:|---|
| Foundation | 5% | Opening map, movement, NPC interaction, party/follower and saves verified; reusable map/scene composition remains partial |
| Core gameplay | 20% | Small single-battle/capture/item/leveling subset verified; full Gen VI rules remain incomplete |
| Kanto | 25% | Oak/Mom opening and a small Route 1 field; no gyms/story campaign |
| Johto | 20% | Specification only |
| Hoenn | 20% | Specification only; design decision: Juan gym eight, Wallace Champion |
| Integration/polish | 10% | Early integration checks, original procedural placeholder art and Windows export; production assets/performance/campaign QA pending |

## Verified versus data/code-only

Verified: 65 automated engine checks, 148 playable-data checks against the pinned reference, catalog consistency/regression assertions, headless startup, software OpenGL rendering/screenshots and Windows export structure/bundled-resource smoke test.

Data/code-only: offline catalog of 493 default species / 617 move records is not full runtime support. Some evolution data is retained as raw references pending a Gen VI audit. The complete type chart exists, but only representative interactions have independent test vectors. Three save slots exist, but cross-version migrations are not yet needed or implemented. The normal-evolution code is unit-tested for Charmander→Charmeleon; full evolutionary trees are absent.

Unverified: native Windows executable launch, GPU rendering on the target PC, 60 FPS, long-session save resilience, all combinations of battle effects, all resolutions and gamepads.

## Exact next implementation tasks

1. Extract UI into reusable scenes and player/follower controllers; create a map registry/portal/spawn system. Keep this opening playable during refactoring.
2. Add a move-learning replacement queue and complete the curated species' full X/Y learnsets. Audit evolution data and XP/EV battle yields. Cover each rule with independent tests before enabling it.
3. Finish battle command/event separation and effects: faint/switch edge cases, accuracy/evasion, full status/weather/ability/held-item rules, correct escape odds, critical captures, participation/XP and doubles. Guaranteed wild escape and development XP rewards must be removed before claiming Gen VI compliance.
4. Activate catalog species incrementally after effect coverage/data/form validation. Import exact X/Y TM/HM number mappings and test compatibility.
5. Build Viridian City, Route 2, Viridian Forest and Pewter/Brock as connected maps, with healing, shops, trainer progression, encounters and one gym loop. Do not create region-unlock flags without the actual content.
6. Implement fixed rival schedules and bounded multi-member boss scaling; then author all Kanto progression, League and travel. Complete Johto and Hoenn afterward with the same state/save service.
7. Replace placeholders with original/licensed asset packs; maintain asset credits. Add audio/animations, options, accessibility and gamepad support.
8. Test native Windows launch/rendering and target hardware performance; then add a repeatable campaign playthrough and save migration fixtures.

## Continuation instructions

Read README, ARCHITECTURE, TESTING, SOURCES and the original PROJECT_BRIEF. Use the existing isolated checkout. Run `bash tools/check.sh` before changing tested behavior. Do not inflate catalog coverage into playable completion. Preserve the build-0.1 source/binary archives as the first verified baseline; no Build 03.1 or 04 Godot source was supplied. Never extract ROM assets or silently substitute modern learnsets. Re-export and repackage after changes, and report Windows-native testing separately from export success.

## Cloud configuration

Reusable `start_skill` instructions were saved to the environment draft. No credentials, network changes or package dependencies were added. The draft is not published; review/save the environment settings and publish to retain the prepared environment snapshot. Publication/fresh-task restoration has not been verified.

## 2026-10-30 — project name

Renamed the game to **Poke Journey** in the project settings, HUD, root scene, export preset and player instructions. The original build-0.1 artifacts are preserved. The application uses the previous custom user-data directory so existing saves remain accessible. This is a branding/package update; the completion estimate is unchanged. Earlier `/workspace/...` chat links were local file references, not confirmed working download attachments. Download access remains to be confirmed in the user’s interface.

## 2026-10-31 — graphics preview 0.2

Overall remains approximately **1%** of the complete requested scope. This session improves presentation of existing content; no additional campaign or gym is complete.

Implemented: original character/species mesh library, jointed human walk animation and creature idle/blink/tail/wing motion; closer camera and wheel zoom; modular detailed homes/lab/field station; roof/path/grass/flower instancing; water/wind/outline shaders; gardens, fences, pond and hills; coherent light UI, two battle HP bars and Fight/Pokémon/Bag/Run grid; decorated battle stage retained across actions; a model viewer integrated in the adventure menu; scene-independent resolved-hit/status events feeding elemental VFX; safe relocation for legacy save positions blocked by new scenery.

Validation: the original 65 checks plus 32 visual-integration checks, 148 playable-data checks and catalog regressions pass. Actual rendered screenshots are captured at 1920×1080 using software OpenGL. Native Windows 0.2 launch, RTX 3080 Ti performance and final graphical fidelity remain unverified. No ripped/proprietary model or texture assets are used. The art is still in development and is not an exact X/Y asset recreation.

Next: evaluate this concrete visual preview against the target reference, refine character proportions/materials and animation, and extract map/UI components before connecting Viridian/Forest/Pewter. Keep the existing opening, gifts, party, saves and battle loop working. Full battle rules and the three regional campaigns remain on the backlog above.
