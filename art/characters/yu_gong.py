"""Yu Gong, the Foolish Old Man of the North Mountain (Part XX, the Hollow Hills release): nearly ninety, who set out
to carry two mountains away in baskets: broad and bent, in a peasant's short hemp jacket the colour of the
earth he digs, leg wraps and a white beard to his belt.
Run: blender --background --python art/characters/yu_gong.py  ->  assets/characters/yu_gong.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/yu_gong.glb", {"fem": False, "age": 1.0, "build": 1.16, "jaw": 1.06, "brow": 1.1, "cheek": 1.1, "smile": True, "skin": "b07848",
    "robe": "8a7450", "trim": "5a4a30", "inner": "d8ccac", "sash": "4a3a24", "pants": "6a5a3c", "boots": "4a3a26", "hair": "e8e4dc", "hair_style": "bun", "eyes": "2e2418",
    "beard": True, "beard_len": 1.0, "beard_col": "ece8e0", "robe_len": "short", "wraps": "a89870",
    "props": [("basket", {"col": "9a7a48", "fill": "6a5a48"})], "pose": "hold_l"})
