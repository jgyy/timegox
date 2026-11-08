"""Boatwright Gao of Longmen: a burly boat-builder in a leather apron with a mallet, who builds hulls the old way, without a single nail.
Run: blender --background --python art/characters/boatwright_gao.py  ->  assets/characters/boatwright_gao.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/boatwright_gao.glb", {
    "age": 0.45, "build": 1.3, "jaw": 1.15, "brow": 1.15, "beard": True, "beard_len": 0.3, "beard_col": "2a2018",
    "robe": "7a5a3a", "trim": "d8c8a0", "inner": "e8dcc4", "sash": "3a2a1a", "hair": "1a1410", "hair_style": "short",
    "eyes": "3a2414", "props": [("apron", {"col": "6a4a2a", "strap": "3a2818"}), "hammer"], "robe_len": "short", "wraps": "b0a080", "shoes": "sandals",
})
