"""Lock-Keeper Qian of Longmen: a thin, careful old man in a hooded coat with a lantern, who lets the river down its locks one step at a time.
Run: blender --background --python art/characters/lockkeeper_qian.py  ->  assets/characters/lockkeeper_qian.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/lockkeeper_qian.glb", {
    "age": 0.8, "build": 0.85, "eye_size": 1.0, "beard": True, "beard_len": 0.6, "beard_col": "d8d4cc",
    "robe": "5a6a7a", "trim": "d8d0c0", "inner": "e8e4d8", "sash": "2a3a4a", "hair": "c8c4c0", "hair_style": "topknot",
    "eyes": "3a3a3a", "hat": "hood", "hat_col": "3a4a5a", "props": [("lantern", {"glow": "fff0c8"})], "pose": "hold_l", "scale": 0.96,
})
