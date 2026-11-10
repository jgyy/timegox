"""The Player, the dancer Yan Shi made for King Mu (Part XIX, the Hundred Works release): a slight figure with a face of white
lacquer, painted eyes and long black hair, in a court dancer's pale robe with vermilion trim and water sleeves.
Run: blender --background --python art/characters/the_player.py  ->  assets/characters/the_player.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/the_player.glb", {"fem": True, "age": 0.1, "build": 0.9, "bust": 0.55, "eye_size": 1.25, "jaw": 0.86, "skin": "f6f2ea", "lip": "c8302a",
    "robe": "f0e8dc", "trim": "c8302a", "inner": "fff8f0", "sash": "c8302a", "pants": "e8dcd0", "boots": "c8302a", "hair": "0e0e12", "hair_style": "long", "hair_len": 0.8,
    "eyes": "1a1a22", "ribbon": "c8302a", "sleeve_w": 1.5, "brocade": "cloud", "brocade_col": "e0b8b0", "pin": "e8c060"})
