"""Ou Yezi the Swordsmith (Part XXI, the Hundred Arms release): the smith of Yue who cast the five great swords, come back to a furnace that
is pouring by itself: old and broad, forearms like bridge-cables, a scorched leather apron over a short brown robe, a headcloth, a grey beard singed short.
Run: blender --background --python art/characters/ou_yezi.py  ->  assets/characters/ou_yezi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/ou_yezi.glb", {"fem": False, "age": 0.75, "build": 1.2, "jaw": 1.1, "brow": 1.15, "stern": True, "smile": False, "skin": "b87a50",
    "robe": "5a3a24", "trim": "2a2420", "inner": "c8b89a", "sash": "3a2a20", "pants": "3a2c22", "boots": "2a2018", "hair": "8a8680", "hair_style": "bun", "eyes": "3a2a1a",
    "beard": True, "beard_len": 0.25, "beard_col": "8a8680", "robe_len": "short", "wraps": "6a5a44", "bracers": "3a2c20", "sleeve_w": 0.7})
