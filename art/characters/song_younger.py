"""Song the Younger (Part XXXVI): the son of the man of Song who pulled up his grain to help it grow (Mencius): the boy
who ran out to the field and found it lying down. A farmer of forty, broad in the shoulder and brown, in a short
coat the colour of dry millet with the sleeves bound, a straw hat on his back and a hoe never far from his hand.
Run: blender --background --python art/characters/song_younger.py  ->  assets/characters/song_younger.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/song_younger.glb", {"age": 0.42, "build": 1.1, "jaw": 1.06, "brow": 1.05, "smile": False, "skin": "b88a60",
    "robe": "8a8a4a", "trim": "5a5a30", "inner": "d0c8a8", "sash": "4a4028", "pants": "6a6440", "shoes": "sandals",
    "hair": "1c1814", "hair_style": "topknot", "eyes": "2a2018", "hat": "straw", "robe_len": "short", "wraps": "a8a078"})
