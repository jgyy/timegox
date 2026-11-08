"""Tea Seller Pan of the Dawn Market (Part IX): a lean, cheerful old man in a cloth cap with a big kettle of hot tea in the heat.
Run: blender --background --python art/characters/tea_seller_pan.py  ->  assets/characters/tea_seller_pan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/tea_seller_pan.glb", {
    "age": 0.7, "build": 0.9, "beard": True, "beard_len": 0.4, "beard_col": "b8b0a8", "smile": True,
    "robe": "5a7a5a", "trim": "e8e0c8", "inner": "f0ece0", "sash": "6a4a2a", "hair": "a8a4a0", "hair_style": "topknot",
    "eyes": "3a3020", "hat": "scholar", "hat_col": "3a4a3a", "props": ["teapot"], "pose": "hold_both", "robe_len": "short", "wraps": "c8bca0",
})
