"""A woman of the Dawn Market for the towns' crowds (the New Fire release, the Lantern Hearth): a short persimmon
jacket over a pleated skirt the yellow of lamplight, hair in two buns tied with red, a paper lantern in her hand.
Run: blender --background --python art/characters/folk_lantern_f.py  ->  assets/characters/folk_lantern_f.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_lantern_f.glb", {"fem": True, "age": 0.15, "build": 0.96, "eye_size": 1.24, "smile": True, "robe": "e0703a", "trim": "ffe0a0", "inner": "fff4dc", "sash": "c02a2a",
    "pants": "8a3a2a", "boots": "5a2a20", "hair": "20141a", "hair_style": "twin_buns", "eyes": "5a3018", "ribbon": "e03a3a", "brocade": "plum", "brocade_col": "ffe0a0",
    "pose": "hold_l", "props": ["lantern"]})
