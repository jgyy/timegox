"""Ling Fei, Who Cannot Fly (towns): a young Yumin of Featherfall whose wings are only for show; pale blue wings, a short crest and walking boots.
Run: blender --background --python art/characters/ling_fei.py  ->  assets/characters/ling_fei.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/ling_fei.glb", {
    "fem": True, "age": 0.0, "eye_size": 1.3, "jaw": 0.86, "build": 0.9, "smile": True,
    "wings": "9ac0e8", "wing_tip": "f8faff", "crest": "f4f6fa", "crest_tip": "a8c8f0", "crest_len": 0.12,
    "robe_len": "short", "boots": "4a5a7a", "monotone": True,
    "robe": "eef2f8", "trim": "7ab0e0", "inner": "ffffff", "sash": "4a7ab0", "hair": "1a2232", "hair_style": "short", "eyes": "3a7ad0", "pants": "5a7aa8"
})
