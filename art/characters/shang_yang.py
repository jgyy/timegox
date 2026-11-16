"""Shang Yang, Lord of Shang (Part XXX): the minister of Qin who wrote that no inn may lodge a traveller without papers,
on pain of sharing his guilt; and who, fleeing by night with no papers, was turned from an inn door by his own law and
said: so this is what it comes to. A tall, cold-eyed man in a travel-stained minister's robe of dark blue with a grey
border, a long thin moustache and chin-beard, the tablets of the law under his arm.
Run: blender --background --python art/characters/shang_yang.py  ->  assets/characters/shang_yang.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/shang_yang.glb", {"fem": False, "age": 0.55, "build": 1.0, "jaw": 0.95, "brow": 1.3, "stern": True, "smile": False, "skin": "c4a078",
    "robe": "2e4c86", "trim": "8a8e96", "inner": "dcd8d0", "sash": "8a8e96", "pants": "22335a", "boots": "1a1a1e",
    "hair": "1a181c", "hair_style": "topknot", "eyes": "22201c", "beard": True, "beard_len": 0.3, "beard_col": "1a181c"})
