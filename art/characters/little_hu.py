"""Little Hu, Iron Fang's son (a fated encounter, scripts/fate.gd): a boy of ten in patched brown, hair
nobody combs, standing over his father with a kitchen knife.
Run: blender --background --python art/characters/little_hu.py  ->  assets/characters/little_hu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/little_hu.glb", {
    "fem": False, "age": 0.0, "build": 0.8, "scale": 0.7, "head_scale": 1.2, "eye_size": 1.4, "jaw": 0.84,
    "hair_style": "wild", "hair": "1a1410", "robe": "6a4a30", "trim": "a88a60", "inner": "d8c8a8", "sash": "3a2818",
    "pants": "4a3a2a", "boots": "2a2018", "eyes": "2a1a10", "robe_len": "short", "stern": True,
})
