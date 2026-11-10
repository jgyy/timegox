"""A man of the horse-folk for the towns' crowds (the New Fire release, the Felt Hearth): belted robe, felt hat, riding boots.
Run: blender --background --python art/characters/folk_herder.py  ->  assets/characters/folk_herder.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_herder.glb", {"fem": False, "age": 0.3, "build": 1.1, "jaw": 1.08, "skin": "c8946c", "robe": "7a5a3a", "trim": "d8b060", "inner": "f0e4cc", "sash": "c05a2a",
    "pants": "3a2c24", "boots": "4a3020", "hair": "1a1410", "hair_style": "short", "eyes": "2a1a10", "hat": "felt", "hat_col": "6a4a2a", "hat_trim": "d8c8a8"})
