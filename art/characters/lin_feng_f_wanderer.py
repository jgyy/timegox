"""Lin Feng as a young woman, the Wanderer look (the New Fire release: the hero can be either):
one long braid down the back.  The same rig, robe, sword and clips as art/characters/lin_feng.py on a woman's
frame and face (art/lib/garment.py Torso.TABLE_F, art/lib/face.py); the game recolours the robe, hair
and eyes at run time (scripts/assets.gd Assets.hero_instance).
Run: blender --background --python art/characters/lin_feng_f_wanderer.py  ->  assets/characters/lin_feng_f_wanderer.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/lin_feng_f_wanderer.glb", {
    "fem": True, "age": 0.0, "build": 0.98, "lip": "d8848a",
    "robe": "3a8ae8", "trim": "e8f0ff", "inner": "f4f6ff", "hair": "1a1a2a",
    "eyes": "3a7ae8", "sash": "1c3a78", "cape": "2a5aa8", "sword": True, "boots": "232838", "pants": "1e2c50",
    "hair_style": "braid", "smile": True, "jaw": 0.88, "cheek": 1.02, "eye_size": 1.26, "hair_len": 0.62,
}, clips=person.HERO_CLIPS)
