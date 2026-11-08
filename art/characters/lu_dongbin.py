"""Lu Dongbin, the Sword Immortal (Part XII): a scholar who dreamed a whole life over a pot of millet and woke an immortal; white robe, a long sword on his back, a fly-whisk, a black scholar's cap and a thin beard, slightly drunk.
Run: blender --background --python art/characters/lu_dongbin.py  ->  assets/characters/lu_dongbin.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/lu_dongbin.glb", {
    "age": 0.35, "build": 1.0, "jaw": 0.96, "beard": True, "beard_col": "1a1a20", "beard_len": 0.75, "smile": True,
    "props": [("fly_whisk", {"handle": "8a5a30", "hair": "f4f4f0"})], "sword": True, "blade": "d8e0e8", "hilt": "2a2a3a",
    "hat": "scholar", "hat_col": "1a1a24",
    "robe": "eef0f4", "trim": "3a6a8a", "inner": "ffffff", "sash": "3a6a8a", "hair": "141418", "hair_style": "topknot", "eyes": "2a2a2a", "monotone": True
})
