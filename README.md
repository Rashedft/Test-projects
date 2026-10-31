# Poke Journey — development build 0.1

A new unified Godot 4 source project. **This is an early playable opening, not the complete three-region game.** No previous Godot prototype source was available. No uploaded ROMs or emulator files were extracted or bundled.

## Downloads

[Download Windows build](https://github.com/Rashedft/Test-projects/raw/refs/heads/main/downloads/PokeJourney-0.1-Windows.zip) · [Download Godot source](https://github.com/Rashedft/Test-projects/raw/refs/heads/main/downloads/PokeJourney-0.1-Source.zip)

See [download instructions](downloads/README.md) if your browser opens a GitHub file page.

## Play on Windows

Extract the Windows ZIP and run `PokeJourney.exe`. It has an embedded resource pack; no Godot installation is needed to run it. The build was exported on Linux and its bundled resources smoke-tested with the Linux engine. Native Windows launch and performance remain unverified.

- WASD / arrows: move; E: interact with a nearby character.
- P: party; Esc: menu/back; mouse: select menu actions.
- Visit Oak outside the northeastern lab, then Mom outside the western house.
- Visit the Nurse southeast of the crossroads to heal and manage PC storage.
- A supplies merchant stands southwest of the crossroads.
- Meet Mira north of town for fixed-level practice battles and a capture research quest.
- Walk through the northern grass for wild encounters. Use Fight / Pokémon / Bag / Run.
- Choose a partner in the party menu to change the lead, nickname, use a Potion or use the one development Thunder Stone.
- Save manually using the menu. Three slots are available; closing the application does not auto-save.

Save location on Windows: `%APPDATA%/Godot/app_userdata/Three Regions — Development Build 0.1/`. The legacy save-directory name is intentionally retained so renaming the game preserves existing saves. Previous slot contents are preserved as `.bak`; backup recovery is currently manual.

## Source development

Open `project.godot` in **Godot 4.6.3**, then press F6 on `main.tscn` or F5 to run the project. The default renderer is Compatibility for cloud/software-renderer testing. A Forward+ quality/performance pass on the target RTX hardware is still required.

Linux cloud checks: `bash tools/check.sh`. Python 3 and Godot 4.6.3 are available in the prepared environment. All runtime data is local; the game needs no credentials or internet.

Windows export: `python3 tools/install_templates.py` if the official templates are absent; then run `godot --headless --path . --export-release "Windows Desktop" builds/PokeJourney.exe`. The cloud XDG variables used by `tools/check.sh` must also be set for export. See [architecture](documentation/ARCHITECTURE.md), [progress](documentation/PROGRESS.md), [testing](documentation/TESTING.md), and [data sources](documentation/SOURCES.md).

## Scope of this build

Implemented: a procedural 3D Pallet Town/Route 1 field, collision/movement/camera, repeat-safe starter gifts, six-member party, lead follower, nicknames, HP/stats/move summaries, PC deposit/withdraw, healing, Potions, shop purchases, Thunder Stone and basic level evolution, encounters/capture, a fixed-level trainer, an optional research quest, initial single-battle mechanics and versioned saves.

The runtime contains **10 species and 18 moves**. A separate offline catalog contains **493 base species and 617 XY-era move records**, with historical stat/type/ability overrides and exact X/Y learnsets. Catalog coverage does not mean those species, moves or abilities are fully playable.

Not complete: full Generation 6 battle behavior, doubles, all learnsets in gameplay, TMs/HMs, all evolutions/forms, held items, comprehensive abilities/status/weather, full Pokédex text, all regional maps/stories/gyms/leagues/travel, licensed production models/animations/music, polished menus, gamepad controls and final optimization. Current runtime learnsets cover level 1–10 only; do not use this build for long-term campaign progress.
