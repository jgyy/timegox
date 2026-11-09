"""A grandmother of the towns (scripts/folk.gd): white hair in a bun, a stick to lean on and a sharp eye; she sits at her door shelling beans and knows everybody's business.
Run: blender --background --python art/characters/folk_grandma.py  ->  assets/characters/folk_grandma.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_grandma.glb", {"fem": True, "age": 0.95, "build": 0.88, "robe": "5a4a5a", "trim": "e8dcc8", "inner": "f0e8dc", "sash": "7a3a3a", "hair": "dcd8d2", "hair_style": "bun", "pin": "6a8a5a", "eyes": "3a3020", "staff": True, "staff_gem": "7a5a3a", "scale": 0.93})
