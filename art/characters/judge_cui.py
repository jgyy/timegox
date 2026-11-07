"""Judge Cui Jue, scribe of the Wheel of the Six Paths (Part VI): black court robes with crimson trim, a winged scholar's cap and a long beard.
Run: blender --background --python art/characters/judge_cui.py  ->  assets/characters/judge_cui.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/judge_cui.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "age": 0.45, "build": 1.06, "brow": 1.3,
    "robe": "1e2030", "trim": "b02a2a", "inner": "e8e0d0", "sash": "6a1a1a", "hair": "1a1a20", "hair_style": "bun",
    "hat": "scholar", "eyes": "8a6a3a", "beard": True, "beard_col": "2a2a30", "crown": False, "stern": True, "collar2": "b02a2a",
    "embroidery": "e8c060", "boots": "141418",
})
