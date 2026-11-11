"""The Hegemon-King of Western Chu (Part XXIII; a lord of the story, fought in his own model): Xiang Yu, whose strength plucked up the hills, who never
lost a charge and would not cross the Wu River alone: very tall, in black armour over dark red, a king's crown, a black cape, a heavy blade.
Run: blender --background --python art/characters/xiang_yu.py  ->  assets/characters/xiang_yu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/xiang_yu.glb", {"fem": False, "age": 0.2, "build": 1.3, "jaw": 1.15, "brow": 1.25, "stern": True, "smile": False, "skin": "d8c0a4", "scale": 1.22,
    "robe": "5a1a1a", "trim": "c8a050", "inner": "2a2a2e", "sash": "c8a050", "pants": "1e1e22", "boots": "101012", "hair": "141416", "hair_style": "topknot", "eyes": "3a2a1a",
    "crown": True, "cape": "121214", "sleeve_w": 1.0, "armor": True,
    "sword": True, "blade": "d8dce4", "hilt": "c8a050"})
