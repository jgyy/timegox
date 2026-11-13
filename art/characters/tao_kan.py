"""Tao Kan, Governor of Guangzhou (Part XXVII): who carried a hundred bricks out of his study every morning and in again
every evening, so that ease should not unfit him for the work he meant to do, and who kept the sawdust and the butt ends of
the bamboo; a broad, weathered man of sixty in a plain dark-green official's robe with the sleeves tied back, a grey
topknot and a short grey beard, a brick in his hand.
Run: blender --background --python art/characters/tao_kan.py  ->  assets/characters/tao_kan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/tao_kan.glb", {"fem": False, "age": 0.62, "build": 1.1, "jaw": 1.08, "brow": 1.15, "stern": True, "smile": False, "skin": "c8a47e",
    "robe": "3e5a48", "trim": "1e2e26", "inner": "e8e0cc", "sash": "2a2a22", "pants": "2a3a30", "boots": "1e1e1a", "sleeve_w": 0.7,
    "hair": "9a968e", "hair_style": "topknot", "eyes": "2e2418", "beard": True, "beard_len": 0.3, "beard_col": "a8a49c",
    "props": ["brick"], "pose": "hold_l"})
