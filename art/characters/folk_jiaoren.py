"""One of the Jiaoren, the Pearl-Weepers of Tearwater (scripts/folk.gd): fin ears and a dusting of scales; they weave the silk water cannot wet and dive for pearls in the black water.
Run: blender --background --python art/characters/folk_jiaoren.py  ->  assets/characters/folk_jiaoren.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_jiaoren.glb", {"fem": True, "age": 0.25, "eye_size": 1.25, "jaw": 0.9, "ears": "fin", "ear_col": "4aa8a0", "ear_inner": "dcfaf4", "scales": "4a9e9a", "robe": "3a8a7a", "trim": "f0f0e8", "inner": "f8faf6", "sash": "c8c0e0", "hair": "1a3640", "hair_style": "long", "eyes": "2a9a9a"})
