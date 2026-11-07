"""Carpenter Gu (towns): a burly craftsman with a hammer and a leather apron, rebuilding the village's roofs.
Run: blender --background --python art/characters/carpenter_gu.py  ->  assets/characters/carpenter_gu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/carpenter_gu.glb", {
    "age": 0.5, "build": 1.25, "brow": 1.15, "beard": True, "beard_len": 0.45, "beard_col": "3a2a20",
    "robe": "8a6a4a", "trim": "d8c8a8", "inner": "e8dcc4", "sash": "4a3020", "hair": "2a2018", "hair_style": "wild",
    "eyes": "3a2414", "props": [("apron", {"col": "6a4a2a", "strap": "3a2818"}), "hammer"], "robe_len": "short", "wraps": "a89a7a",
})
