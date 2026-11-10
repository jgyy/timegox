# Ascension of the Azure Cloud: notes for AI contributors

## Art rule
**All art is generated from scripts.** Every model, texture, animation and effect must be reproducible by running code in this repository. Do not add hand-made, downloaded or AI-image-generated asset files. Screenshots in `docs/screenshots` are outputs, not inputs.

- **Godot code** (`scripts/`, GDScript and shaders): anything built from game data or changing at runtime, such as terrain, weather, spell effects, shaders and UI.
- **Blender Python** (`art/`, `bpy` for the latest Blender release): hero assets such as characters, monsters, rigs, animations and baked textures. Each script exports a `.glb` into `assets/` via `blender --background --python <script>`. Exported files are rebuilt from their scripts and never edited by hand.
- `art/lib/kit.py` is the shared toolkit (Godot-space coordinates, tint UV, toon/plain/glow material slots, baked AO, rigs, clips); `art/lib/person.py` and `art/lib/creature.py` build characters and monsters. `python art/build_all.py` (with `pip install bpy`) rebuilds everything; run `godot --headless --path . --import` afterwards.
- After any art change, render and look at screenshots: `godot --path . --fixed-fps 30 -- --tour=<dir> --areas=<id> --no-extras --gallery` (use `xvfb-run` on a server).

## Trials (many roads)
- The bosses that carry the main story forward are guarded by **trials** in `scripts/trials.gd`: each has three or four ways through (might, craft, wealth, respect, Dao, friendship, relic), and only a met way can be taken. A new chapter's lords should get trials too, with recipes whose essences can be hunted on the way and quest items found before them (`tests/run_tests.gd` checks this).
- Give every new trial a planned way in the bot's `TRIAL_PLAN` (`scripts/bot.gd`) that it can actually work towards, and keep respect thresholds above the renown the bosses and trials alone give.

## Hearths (the six cultures) and who the hero is
- The peoples of the land are the **Six Hearths** in `scripts/cultures.gd` (towns, keepers, greetings, tables, fires, customs, standing, the six beginnings and the five endings). A new town of the land belongs to a hearth (`towns`, `areas`); a new chapter's errands for a hearth carry `"hearth": "<id>"` on their steps, done in that hearth's own way, and an errand among its townsfolk names its `"town"`.
- The hero can be a man or a woman. **Write story text about "Lin Feng" and "he" as always**; `scripts/voice.gd` tells it of her on the way to the screen (narration by rule, speech only by what the hero is called). Where the rule gets a new line wrong, add the whole line to `Voice.FIX`; `tests/run_tests.gd` reads every conversation through it. Words about nobody but the hero (an outfit, a ride) go through `Voice.her`.
- New people need a Blender script in `art/characters/`; women are marked `"fem": True` there and, if they are named without a woman's title, listed in `Voice.WOMEN`.

## Checks before pushing
- `godot --headless --path . --script tests/run_tests.gd`
- `godot --headless --path . --script tests/manual_input_test.gd`
- `godot --headless --fixed-fps 30 --path . -- --bot --seed=1234 --min-time=57600` (CI requires the full game to complete in at least 16 hours of game time)
