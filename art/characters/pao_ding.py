"""Cook Ding of the Cauldron Hall (Part XXVI): the cook of the Zhuangzi, whose knife was nineteen years old and as if it
had just come from the stone because he went where the gaps were; a broad, heavy, cheerful man in a white cook's jacket,
a leather apron and a headcloth, sleeves narrow for work, his cleaver in his right hand.
Run: blender --background --python art/characters/pao_ding.py  ->  assets/characters/pao_ding.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/pao_ding.glb", {"fem": False, "age": 0.42, "build": 1.24, "jaw": 1.1, "cheek": 1.3, "smile": True, "skin": "d0a882",
    "robe": "ece6d8", "trim": "9a8a74", "inner": "f4f0e6", "sash": "6a4a30", "pants": "4a3a2a", "boots": "2a2420", "robe_len": "short",
    "hair": "2a2420", "hair_style": "topknot", "hat": "headcloth", "hat_col": "e8e2d4", "hat_trim": "9a8a74", "eyes": "3a2a1a",
    "props": [("apron", {"col": "7a5232", "strap": "3a2818"}), "cleaver"], "sleeve_w": 0.72})
