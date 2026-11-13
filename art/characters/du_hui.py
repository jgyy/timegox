"""Du Hui, the strong man of Qin (Part XXVIII): the champion who stood alone before the army of Jin at Fushi and could
not be thrown, until his heel found a knot of grass; a huge, thick-necked soldier in black lacquered armour with red
cords, a shaven chin and a heavy moustache, a long-hafted hammer over his shoulder.
Run: blender --background --python art/characters/du_hui.py  ->  assets/characters/du_hui.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/du_hui.glb", {"fem": False, "age": 0.42, "build": 1.34, "waist": 1.3, "jaw": 1.2, "brow": 1.35, "stern": True, "smile": False, "skin": "b8926a",
    "robe": "2a2a30", "trim": "b83a2a", "inner": "5a2a22", "sash": "b83a2a", "pants": "1e1e24", "boots": "141416", "armor": True, "metal": "2e2e36",
    "hair": "141214", "hair_style": "topknot", "eyes": "241a14", "beard": True, "beard_len": 0.12, "beard_col": "141214", "scale": 1.12,
    "props": ["hammer"], "pose": "hold_r"})
