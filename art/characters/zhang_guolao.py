"""Zhang Guolao, Who Rides Backwards (Part XII): the oldest of the immortals, older than the Court, white-bearded, with a bamboo fish-drum; his paper donkey folded away in his sleeve.
Run: blender --background --python art/characters/zhang_guolao.py  ->  assets/characters/zhang_guolao.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/zhang_guolao.glb", {
    "age": 0.95, "build": 0.9, "brow": 1.35, "beard": True, "beard_col": "f0eee8", "beard_len": 1.2,
    "props": [("drum", {"skin": "e8dcc0", "rim": "6a8a4a"})], "pose": "hold_l", "hat": "straw", "hat_col": "b8a060",
    "robe": "8a8a7a", "trim": "e8e4d8", "inner": "f2f0e8", "sash": "5a4a3a", "hair": "f0eee8", "hair_style": "bun", "eyes": "3a3a30"
})
