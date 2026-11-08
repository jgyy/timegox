"""Rain-Clerk Ao Xun (towns): a young dragon-kin clerk of the Rain Ministry, third grade, with small antlers, teal scales and an inky brush.
Run: blender --background --python art/characters/ao_xun.py  ->  assets/characters/ao_xun.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/ao_xun.glb", {
    "age": 0.1, "build": 0.94, "jaw": 0.92, "eye_size": 1.2, "slit_eyes": True,
    "horns": "antler", "horn_col": "e0e8d8", "antler_size": 0.55, "scales": "5aa898",
    "props": [("brush", {"col": "2a3a34"})], "hat": "scholar", "hat_col": "1a3a3a",
    "robe": "3a7a7a", "trim": "e8e0c0", "inner": "f2f4ee", "sash": "1a3a3a", "hair": "1a2a2a", "hair_style": "topknot", "eyes": "e0c040"
})
