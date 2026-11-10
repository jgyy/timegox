"""A woman of the horse-folk for the towns' crowds (the New Fire release, the Felt Hearth): a long belted robe, two braids, a felt hat.
Run: blender --background --python art/characters/folk_herder_f.py  ->  assets/characters/folk_herder_f.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_herder_f.glb", {"fem": True, "age": 0.2, "build": 1.0, "eye_size": 1.16, "skin": "d0a07c", "robe": "a03a4a", "trim": "e8c050", "inner": "f0e4cc", "sash": "3a8a8a",
    "pants": "3a2420", "boots": "5a3a24", "hair": "1a1410", "hair_style": "braid", "hair_len": 0.6, "eyes": "2a1a10", "hat": "felt", "hat_col": "8a2a3a", "hat_trim": "e8dcc0", "beads": "3aa0a0"})
