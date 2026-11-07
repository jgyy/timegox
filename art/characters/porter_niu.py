"""Porter Niu of the Dawn Market (Part IX): a broad-shouldered porter in a straw hat and rolled trousers, with nothing to carry but his own shadow.
Run: blender --background --python art/characters/porter_niu.py  ->  assets/characters/porter_niu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/porter_niu.glb", {
    "age": 0.35, "build": 1.3, "jaw": 1.1, "brow": 1.1,
    "robe": "9a7a4a", "trim": "e0d4b8", "inner": "e8dcc4", "sash": "4a3a2a", "hair": "1a1410", "hair_style": "short",
    "eyes": "3a2414", "hat": "straw", "hat_col": "c8a858", "props": [("gourd", {"col": "d8a048"})], "robe_len": "short", "wraps": "b0a080", "shoes": "sandals",
})
