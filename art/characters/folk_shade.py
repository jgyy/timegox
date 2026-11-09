"""A shade of Youdu, the Dark Capital (scripts/folk.gd): pale skin, eyes that glow and the dark robe of a soul keeping house until it is ready to be born again; Youdu's lanterns never go out and neither do its shades.
Run: blender --background --python art/characters/folk_shade.py  ->  assets/characters/folk_shade.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_shade.glb", {"age": 0.4, "skin": "c8d4dc", "glow_eyes": True, "robe": "2a2a36", "trim": "b8c0cc", "inner": "e4e8ee", "sash": "6a7488", "hair": "1a1a22", "hair_style": "topknot", "eyes": "c8f0ff", "hat": "scholar", "hat_col": "121216"})
