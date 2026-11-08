"""Well-Keeper Zhaya of Shazhou Oasis: a veiled desert woman with a water gourd, who sells a cup of sweet well water for a story and a story for a cup.
Run: blender --background --python art/characters/well_keeper_zhaya.py  ->  assets/characters/well_keeper_zhaya.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/well_keeper_zhaya.glb", {
    "fem": True, "age": 0.5, "build": 0.95, "eye_size": 1.15,
    "robe": "c8a070", "trim": "6a3a8a", "inner": "f0e8d8", "sash": "6a3a8a", "hair": "1a1014", "hair_style": "long",
    "eyes": "3a2a1a", "hat": "hood", "hat_col": "e8dcc0", "props": [("gourd", {"col": "c89040"})], "pose": "hold_l", "beads": "3a8aa0",
})
