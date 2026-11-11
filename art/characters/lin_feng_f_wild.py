"""Lin Feng as a young woman, the Wild Child look (the New Fire release: the hero can be either):
hair no comb has ever beaten.  The same rig, robe, sword and clips as art/characters/lin_feng.py on a woman's
frame and face (art/lib/garment.py Torso.TABLE_F, art/lib/face.py); the game recolours the robe, hair
and eyes at run time (scripts/assets.gd Assets.hero_instance).
Run: blender --background --python art/characters/lin_feng_f_wild.py  ->  assets/characters/lin_feng_f_wild.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/lin_feng_f_wild.glb", {
    "fem": True, "age": 0.0, "build": 0.98, "lip": "d8848a",
    "robe": "3a8ae8", "trim": "e8f0ff", "inner": "f4f6ff", "hair": "1a1a2a",
    "eyes": "3a7ae8", "sash": "1c3a78", "cape": "2a5aa8", "sword": True, "arms": True, "boots": "232838", "pants": "1e2c50",
    "hair_style": "wild", "smile": True, "ahoge": True, "jaw": 0.92, "brow": 0.6, "eye_size": 1.28,
}, clips=person.HERO_CLIPS)
