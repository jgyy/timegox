# Ascension of the Azure Cloud: notes for AI contributors

## Art rule
**All art is generated from scripts.** Every model, texture, animation and effect must be reproducible by running code in this repository. Do not add hand-made, downloaded or AI-image-generated asset files. Screenshots in `docs/screenshots` are outputs, not inputs.

- **Godot code** (`scripts/`, GDScript and shaders): anything built from game data or changing at runtime, such as terrain, weather, spell effects, shaders and UI.
- **Blender Python** (`art/`, `bpy` for the latest Blender release): hero assets such as characters, monsters, rigs, animations and baked textures. Each script exports a `.glb` into `assets/` via `blender --background --python <script>`. Exported files are rebuilt from their scripts and never edited by hand.
- `art/lib/kit.py` is the shared toolkit (Godot-space coordinates, tint UV, toon/plain/glow material slots, baked AO, rigs, clips); `art/lib/person.py` and `art/lib/creature.py` build characters and monsters. `python art/build_all.py` (with `pip install bpy`) rebuilds everything; run `godot --headless --path . --import` afterwards.
- After any art change, render and look at screenshots: `godot --path . --fixed-fps 30 -- --tour=<dir> --areas=<id> --no-extras --gallery` (use `xvfb-run` on a server).

## Checks before pushing
- `godot --headless --path . --script tests/run_tests.gd`
- `godot --headless --path . --script tests/manual_input_test.gd`
- `godot --headless --fixed-fps 30 --path . -- --bot --seed=1234 --min-time=18000` (CI requires the full game to complete in at least 5 hours of game time)
