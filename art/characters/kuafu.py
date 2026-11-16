"""Kuafu (Part XXXI): the giant who did not measure his strength and ran after the sun, drank the River and the Wei dry,
and died of thirst on the way to the Great Marsh; whose thrown-down staff became the Deng forest, a wood of peaches
several thousand li across. Young, enormous, burnt dark by what he was chasing: a runner's short jacket and leg wraps,
two yellow cords in his hair where the old pictures hang a yellow snake at each ear, and the staff in his hand.
Run: blender --background --python art/characters/kuafu.py  ->  assets/characters/kuafu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/kuafu.glb", {"age": 0.2, "build": 1.38, "head_scale": 0.88, "hand_k": 1.18, "jaw": 1.12, "brow": 1.2, "smile": True, "skin": "a8704a",
    "robe": "b8862e", "trim": "e8c860", "inner": "c89858", "sash": "7a3a22", "pants": "6a4a2a", "robe_len": "short", "wraps": "c8a868", "shoes": "sandals",
    "hair": "1c1410", "hair_style": "wild", "eyes": "e8a020", "ribbon": "e8c020", "bracers": "8a5a2a", "staff": True, "staff_gem": "f0a8b0"})
