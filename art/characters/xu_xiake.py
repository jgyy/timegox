"""Xu Xiake the Traveller (Part XX, the Hollow Hills release): the man who walked the whole land for thirty years
and went down every cave he passed with a pine torch: lean, weathered, in a short travelling robe of faded indigo,
leg wraps, a straw hat and a staff worn smooth.
Run: blender --background --python art/characters/xu_xiake.py  ->  assets/characters/xu_xiake.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/xu_xiake.glb", {"fem": False, "age": 0.5, "build": 0.94, "jaw": 0.94, "smile": True, "skin": "c89868",
    "robe": "4a5a7a", "trim": "c8c0a0", "inner": "e8e0c8", "sash": "7a5a30", "pants": "3a4458", "boots": "5a4630", "hair": "4a4640", "hair_style": "topknot", "eyes": "3a2a1a",
    "beard": True, "beard_len": 0.3, "beard_col": "5a5650", "hat": "straw", "hat_col": "d0b870", "robe_len": "short", "wraps": "b8a878",
    "staff": True, "staff_gem": "7a5a30"})
