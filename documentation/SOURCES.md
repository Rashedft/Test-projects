# Data and asset provenance

No ROM, save-state, Nintendo model, texture, sprite, sound or music was extracted or included. Geometry is authored procedurally in this project as temporary original art.

## PokeAPI reference

Repository: https://github.com/PokeAPI/pokeapi

Pinned commit: `2bf639e5572812a67d2b94903fdcb9d095f5aeb2`.

`data/reference/manifest.json` records exact HTTPS source URLs, byte lengths and SHA-256 hashes. `tools/import_reference.py` downloads that pinned CSV snapshot, retains the relevant base-species records and extracts version group **15 (X/Y)** exclusively for learnsets. It imports no sprites or flavor text. `POKEAPI-LICENSE.txt` contains the project's required copyright/license notice. Data licensing does not grant rights to proprietary game art or trademarks.

`tools/build_catalog.py` rolls modern stats/types/abilities back using the nearest applicable historical-generation rows and rolls move fields back using changes after version group 15. It deliberately keeps catalog use separate from runtime effect coverage. Ability effects, evolution requirements, historical capture/friendship/XP yields, alternate non-Mega forms and TM/HM numbered mappings need further audits.

## Independent historical category correction

PokeAPI move_changelog has no damage-class column. Water Shuriken is explicitly normalized to Physical for Gen VI, matching:

https://github.com/smogon/pokemon-showdown/blob/1242c1e2d9763ba5b85d33f13aecb89bae19ae3d/data/mods/gen6/moves.ts

The referenced Gen VI override sets `watershuriken.category` to `Physical`. No simulator source code is copied into the game.

## Runtime subset

Ten base species and eighteen moves are in gameplay. Learnsets are exact X/Y entries through level 10 for the selected species, with no invented later moves. All 25 nature modifiers are sourced from the same pinned nature table. Gen VI stat changes (e.g. Pikachu defense and Raichu speed), Fairy effectiveness and pre-Gen-VII Tackle power are retained. Curated subset checks run independently of the game rules implementation.

## Engine

Godot 4.6.3 official binary and Windows export templates:
https://github.com/godotengine/godot/releases/tag/4.6.3-stable

The template installer uses official HTTPS release assets, validates ZIP size/CRC and does not disable TLS verification. Only Windows x86-64 members are fetched via byte ranges. Godot's license is included in GODOT-LICENSE.txt. No third-party asset packs are bundled.
