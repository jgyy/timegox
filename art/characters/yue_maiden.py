"""The Maiden of Yue (Part XXI, the Hundred Arms release): the girl of the southern forest who taught the army of Yue the sword and met the old white
ape on the road: sixteen, slight, sunburnt, barefoot in leg wraps, a short green robe kilted up for wading, hair in one braid, a bamboo switch (the game puts it in her hand).
Run: blender --background --python art/characters/yue_maiden.py  ->  assets/characters/yue_maiden.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/yue_maiden.glb", {"fem": True, "age": 0.0, "build": 0.9, "bust": 0.3, "eye_size": 1.24, "jaw": 0.88, "smile": False, "skin": "e0b088", "lip": "c87a70",
    "robe": "5a8a5a", "trim": "e8e0b0", "inner": "f0ecd8", "sash": "8a5a30", "pants": "4a6a48", "boots": "8a6a48", "hair": "1a1410", "hair_style": "long", "hair_len": 0.7,
    "eyes": "4a3a1a", "ribbon": "c8d060", "robe_len": "short", "wraps": "c8c0a0", "sleeve_w": 0.75, "staff": True, "staff_gem": "7ac060"})
