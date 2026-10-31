# Validation and known issues — build 0.1

Run `bash tools/check.sh` from this checkout. It preserves command failures, checks Godot logs for script/runtime errors, and returns nonzero on failure. Cloud data/config/cache directories are under `/workspace/.runtime/godot`, avoiding read-only home-directory errors.

## Completed

- Godot 4.6.3 import and startup, including a 120-frame headless smoke test.
- 65 automated checks: gifts/order/idempotency, initial X/Y moves, stat/nature/damage vectors, party order, Thunder Stone/level evolution, potions/healing, storage overflow/deposit/withdraw, save round trip/backup/corruption handling, malformed save types/IVs/identities/inventory, type interactions, PP/Struggle, trainer restrictions, capture, shop/research reward, follower changes, menu bounds, battle transitions, actual keyboard movement, menu pause, lab wall collision and world NPC interactions.
- 148 historical data assertions for the curated subset: base stats, types, X/Y learnsets through level 10, move power/accuracy/PP/priority/type/category.
- Offline catalog: 493 base/default species and 617 moves; all learnset references resolve. Regression checks include Fairy Clefairy, Gen VI Levitate Gengar, pre-Gen-VII Dugtrio Attack, Tackle power, Leech Life power, Knock Off power and Water Shuriken's physical category.
- Software OpenGL rendering using an isolated dummy X server. Exploration, party and battle screenshots inspected at a 1280×720 window with a 1920×1080 logical viewport. The initial battle overlay hid the models; it was corrected to a side panel.
- Windows x86-64 embedded-PCK export; PE/PCK structure verification and packed-resource startup with the Linux Godot engine.

## Known limitations

- Windows-native launch is untested; no Wine or Windows machine is available. Export success is not a native launch test. Software-rendering screenshots do not establish target hardware FPS.
- Procedural art, minimal movement bob/lunge animations, no production models or audio. Compatibility renderer remains the development default.
- Runtime has 10 species / 18 moves and learns moves only through level 10. No move replacement choice yet. The catalog remains separate and is not a claim that all 493 species are playable.
- Single battles only. Battle implementation is a subset, not certified complete Gen VI mechanics. Wild escape is guaranteed; XP rewards use a development constant (`enemy level × 18`), not species yields/participation. Full damage rounding/effect combinations still need reference-oracle coverage. Capture lacks critical captures; all special Ball types, most abilities/statuses/weather/items and doubles remain absent.
- New games start directly in the opening map. No title screen, production options, gym/campaign/travel content or map interiors.
- Follower avoidance uses a short ray and a stuck reposition, not full navigation. Large/different species silhouettes and complex geometry need further testing.
- Save schema v1 validates current content only. No historical schema migration fixtures, automatic backup recovery, crash injection or Windows-specific filesystem failure testing yet. Loading invalid data preserves the live game.
- UI has scrolling/ellipsis/tooltips, but localization, touch/ultrawide/minimum-resolution/gamepad QA is pending.

## Error log

1. Initial Godot invocation attempted to write under the read-only home folder. Resolved using writable XDG directories. This was an environment configuration issue.
2. An early test compared raw JSON strings before/after numeric JSON decoding. Changed to compare parsed state, preserving the underlying data check.
3. Reference checks exposed Pikachu's incorrect Growl/Tail Whip levels and Withdraw's incorrect type in the first draft. Corrected against pinned source data before the release export.
4. Rendering exposed the battle overlay occlusion. Resolved with side layout and larger original placeholder models.
5. Synthetic keyboard tests reused one event in a frame, producing a runner warning. Changed to distinct duplicated input events.
6. The dummy OpenGL driver does not support VSync configuration. Its warning does not indicate a game failure; target-machine rendering remains unverified.

No unresolved parse/startup errors remain in the final automated check run. See CHECK_RESULTS.txt for that run's output. Full-game progression tests are unrun because those campaigns do not yet exist.
