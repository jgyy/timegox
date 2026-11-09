"""Fang Hu, Iron Fang's son grown up (a fated encounter, scripts/fate.gd): about seventeen, in a leather
jerkin over brown, his father's iron gauntlet on his right hand, his wild hair tied back.
Run: blender --background --python art/characters/hu_grown.py  ->  assets/characters/hu_grown.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/hu_grown.glb", {
    "fem": False, "age": 0.0, "build": 1.06, "jaw": 1.02, "brow": 1.08, "stern": True,
    "hair_style": "wild", "hair": "1a1410", "robe": "6a4a32", "trim": "a8885a", "inner": "d8c8a8", "sash": "2a1a12",
    "pants": "3a2c20", "boots": "2a2018", "eyes": "3a2414", "armor": True, "metal": "4a4a52", "bracers": "3a3a42", "robe_len": "short",
})
