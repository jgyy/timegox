"""Wu Pu, Who Kept His Teeth (Part XXVI): Hua Tuo's pupil, who did the five frolics every morning and at ninety had
sharp eyes, sharp ears and every tooth in his head; a broad, brown, upright old man in a short jacket of green hemp and
rolled trousers, a grey topknot and a short beard, barefoot in straw sandals.
Run: blender --background --python art/characters/wu_pu.py  ->  assets/characters/wu_pu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/wu_pu.glb", {"fem": False, "age": 0.62, "build": 1.04, "jaw": 1.02, "brow": 0.9, "smile": True, "skin": "c49a74",
    "robe": "5a7a4a", "trim": "e8e0c8", "inner": "efe8d4", "sash": "c8a050", "pants": "3a4a30", "boots": "2a2a20", "shoes": "sandals", "robe_len": "short",
    "hair": "c4c0b8", "hair_style": "topknot", "eyes": "3a2a1a", "beard": True, "beard_len": 0.22, "beard_col": "cfcac2", "sleeve_w": 0.75})
