"""Zhong Ziqi the woodcutter (Part XXII): who heard high mountains and running water in a stranger's qin:
brown homespun to the knee, wrapped shins, forearms like his axe handle.
Run: blender --background --python art/characters/zhong_ziqi.py  ->  assets/characters/zhong_ziqi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/zhong_ziqi.glb", {"fem": False, "age": 0.3, "build": 1.12, "jaw": 1.06, "brow": 1.05, "stern": False, "smile": True, "skin": "c89468",
    "robe": "6a5a3a", "trim": "3a3024", "inner": "c8b89a", "sash": "4a3a28", "pants": "4a3c2a", "boots": "3a2c1c", "hair": "241c18", "hair_style": "bun", "eyes": "3a2a1a",
    "robe_len": "short", "wraps": "8a7a5a", "bracers": "3a2c20", "sleeve_w": 0.65})
