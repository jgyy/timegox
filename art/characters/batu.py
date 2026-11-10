"""Batu the horse-herd of the Felt Hearth (the New Fire release): a broad young herder in a blue robe with the right
sleeve off the shoulder in the heat, an orange sash, a felt hat and a horse-whip.
Run: blender --background --python art/characters/batu.py  ->  assets/characters/batu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/batu.glb", {"fem": False, "age": 0.15, "build": 1.14, "jaw": 1.1, "eye_size": 1.1, "skin": "c8946c", "smile": True,
    "robe": "2a5a9a", "trim": "e8c050", "inner": "f0e4cc", "sash": "e08a2a", "pants": "3a2c24", "boots": "4a3020", "hair": "1a1410", "hair_style": "braid", "hair_len": 0.4,
    "eyes": "2a1a10", "hat": "felt", "hat_col": "2a4a7a", "hat_trim": "c8b8a0", "props": ["whip"]})
