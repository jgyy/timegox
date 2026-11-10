"""A woman of Shazhou Oasis for the towns' crowds (the New Fire release, the Sweet-Well Hearth): a long striped coat
over wide trousers, a bright headscarf knotted at the nape, silver at her collar.
Run: blender --background --python art/characters/folk_oasis_f.py  ->  assets/characters/folk_oasis_f.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_oasis_f.glb", {"fem": True, "age": 0.25, "build": 0.98, "eye_size": 1.2, "skin": "d8a884", "lip": "b0565a", "robe": "c86a3a", "trim": "f0d890", "inner": "f4ead0", "sash": "2a7a8a",
    "pants": "8a3a4a", "boots": "6a4a30", "hair": "1a120c", "hair_style": "long", "hair_len": 0.45, "eyes": "3a2414", "hat": "headcloth", "hat_col": "c8363a", "hat_trim": "f0c850",
    "brocade": "waves", "brocade_col": "f0d890", "beads": "d8d8e0"})
