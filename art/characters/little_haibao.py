"""Little Haibao (Part XII): a nine-year-old of Landfall named after a boy who landed with Xu Fu, in a short orange jacket, carrying a basket with a crab in it.
Run: blender --background --python art/characters/little_haibao.py  ->  assets/characters/little_haibao.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/little_haibao.glb", {
    "age": 0.0, "build": 0.8, "eye_size": 1.45, "scale": 0.7, "head_scale": 1.2, "jaw": 0.85, "smile": True,
    "props": [("basket", {"col": "b89a60", "fill": "d8603a"})], "pose": "hold_l", "robe_len": "short",
    "robe": "e0a050", "trim": "fff0d0", "inner": "fff8ee", "sash": "3a6a9a", "hair": "1a1410", "hair_style": "short", "eyes": "2a1a10", "pants": "4a6a8a"
})
