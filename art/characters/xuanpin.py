"""Xuanpin, the Valley Spirit (Part XX, the Hollow Hills release): 'the valley spirit never dies; it is called the
dark female': what is in a hollow when nothing is: a tall, still woman the colour of deep water in a cave, her
robe darkening to black at the hem, her hair unbound to the knee, her eyes very pale.
Run: blender --background --python art/characters/xuanpin.py  ->  assets/characters/xuanpin.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/xuanpin.glb", {"fem": True, "age": 0.2, "build": 0.98, "bust": 0.5, "eye_size": 1.3, "jaw": 0.84, "skin": "e8ecf4", "lip": "8a7ab0",
    "robe": "1e2a44", "trim": "6ad0c8", "inner": "c8d8e8", "sash": "3a4a7a", "pants": "141c30", "boots": "0e1422", "hair": "0a0c14", "hair_style": "long", "hair_len": 1.0,
    "eyes": "b8e8f0", "sleeve_w": 1.6, "brocade": "cloud", "brocade_col": "3a5a8a", "cape": "0e1626", "flare": 1.25, "pin": "6ad0c8"})
