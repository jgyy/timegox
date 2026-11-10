# Ascension of the Azure Cloud: notes for AI contributors

## Art rule
**All art is generated from scripts.** Every model, texture, animation and effect must be reproducible by running code in this repository. Do not add hand-made, downloaded or AI-image-generated asset files. Screenshots in `docs/screenshots` are outputs, not inputs.

- **Godot code** (`scripts/`, GDScript and shaders): anything built from game data or changing at runtime, such as terrain, weather, spell effects, shaders and UI.
- **Blender Python** (`art/`, `bpy` for the latest Blender release): hero assets such as characters, monsters, rigs, animations and baked textures. Each script exports a `.glb` into `assets/` via `blender --background --python <script>`. Exported files are rebuilt from their scripts and never edited by hand.
- `art/lib/kit.py` is the shared toolkit (Godot-space coordinates, tint UV, toon/plain/glow material slots, baked AO, rigs, clips); `art/lib/person.py` and `art/lib/creature.py` build characters and monsters. `python art/build_all.py` (with `pip install bpy`) rebuilds everything; run `godot --headless --path . --import` afterwards.
- **Exports are packed.** `kit.export` runs `art/lib/pack.py` on every `.glb` it writes (byte weights, 16-bit tint UVs and bone rotations, no tracks for bones that rest, shared time tracks, compact JSON: about a third smaller, and Godot imports the same meshes and clips). Never commit a raw export; `python art/pack_all.py` packs anything exported with `ART_PACK=0`. Do not quantise normals or positions: Godot's importer refuses `KHR_mesh_quantization`.
- After any art change, render and look at screenshots: `godot --path . --fixed-fps 30 -- --tour=<dir> --areas=<id> --no-extras --gallery` (use `xvfb-run` on a server).
- **Screenshots are WebP, never PNG.** Every capture the tour, the gallery or the bot writes is saved with `Image.save_webp(path, true, 0.9)` (lossy, quality 0.9: visually the same as the PNG, 4 to 10 times smaller). Name new captures `.webp` and link them from the README with `.webp`. Do not commit PNG screenshots; if one turns up, convert it with `magick in.png -quality 90 -define webp:method=6 out.webp` and delete the PNG.

## Trials (many roads)
- The bosses that carry the main story forward are guarded by **trials** in `scripts/trials.gd`: each has three or four ways through (might, craft, wealth, respect, Dao, friendship, relic), and only a met way can be taken. A new chapter's lords should get trials too, with recipes whose essences can be hunted on the way and quest items found before them (`tests/run_tests.gd` checks this).
- Give every new trial a planned way in the bot's `TRIAL_PLAN` (`scripts/bot.gd`) that it can actually work towards, and keep respect thresholds above the renown the bosses and trials alone give.

## Crossroads, works and the hours of the wild
- **Choices are crossroads** (`scripts/echoes.gd`): a question asked once after a step, whose answers tip one of three scales (mercy and rigour, new works and old ways, the wide world and the home fire), give something, **echo** in later conversations (`echo`: a dialogue key later in the story -> lines for each answer) and are told at the end (`end`). A new chapter should have at least one crossroads of its own, give earlier ones an echo in its conversations, and give the bot an answer in `CROSS_PLAN` (`scripts/bot.gd`); `tests/run_tests.gd` checks every echo lands in a real, later conversation and fits the dialogue box. Conversations are fetched through `Echoes.told`, never straight from `Data.DIALOGUE`.
- **Technology is works** (`scripts/works.gd`, `scripts/machines.gd`): eighteen things to build in three schools (the Hand, the Wheel, the Art), paid for in know-how (learned by looking: bestiary, lords, things tried, obstacles, deeds, caves) and spirit stones. Each changes one number through `Works.mod` / `Works.add` and stands in the land as a machine built from code. A journey's know-how must never buy all eighteen (the test checks it), so that which to build stays a choice. Trials can be passed "By the works" (`["works", school or "" or "best", n]`).
- **Monsters keep hours** (`scripts/habits.gd`): every new enemy gets a habit from its shape and element (or an entry in `Habits.OWN`), and what a pack is doing at the hour it is met (asleep, hunting, resting, gathered) is drawn in the land and changes the battle. Bosses keep no hours.

## Hearths (the six cultures) and who the hero is
- The peoples of the land are the **Six Hearths** in `scripts/cultures.gd` (towns, keepers, greetings, tables, fires, customs, standing, the six beginnings and the five endings). A new town of the land belongs to a hearth (`towns`, `areas`); a new chapter's errands for a hearth carry `"hearth": "<id>"` on their steps, done in that hearth's own way, and an errand among its townsfolk names its `"town"`.
- The hero can be a man or a woman. **Write story text about "Lin Feng" and "he" as always**; `scripts/voice.gd` tells it of her on the way to the screen (narration by rule, speech only by what the hero is called). Where the rule gets a new line wrong, add the whole line to `Voice.FIX`; `tests/run_tests.gd` reads every conversation through it. Words about nobody but the hero (an outfit, a ride) go through `Voice.her`.
- New people need a Blender script in `art/characters/`; women are marked `"fem": True` there and, if they are named without a woman's title, listed in `Voice.WOMEN`.

## Performance
- `godot --path . -- --bench=build/bench.json` (with `xvfb-run` on a server) times the opening of the world and counts what a frame draws; `--census` lists the triangles in the scene by kind (`--census-view`: only what the camera sees). Compare draw calls and primitives between two builds on the same machine; the frame rate of a software renderer says little.
- Keep the importer's LODs when a mesh is rebuilt (`Assets.lods_of`), give anything heavy that is scattered out to 100 m a far mesh (`Terrain3D.far_mesh`), and do not hand the renderer people or things further off than they can be made out (`World.ENT_SHOW`). `Data.step_index` is a lookup: `Game.reached` is asked thousands of times a frame.

## Checks before pushing
- `godot --headless --path . --script tests/run_tests.gd`
- `godot --headless --path . --script tests/manual_input_test.gd`
- `godot --headless --fixed-fps 30 --path . -- --bot --seed=1234 --min-time=57600` (CI requires the full game to complete in at least 16 hours of game time)
