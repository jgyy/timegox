"""Lin Feng as the player may make him (character creation, scripts/create.gd): The wild child of the mountain: hair no comb has ever won against, a grin and a cowlick.
The same rig, robe and clips as art/characters/lin_feng.py; the game recolours the robe, hair and
eyes at run time (scripts/assets.gd Assets.hero_instance).
Run: blender --background --python art/characters/lin_feng_wild.py  ->  assets/characters/lin_feng_wild.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/lin_feng_wild.glb", {
    "fem": False, "age": 0.0, "build": 1.03,
    "robe": "3a8ae8", "trim": "e8f0ff", "inner": "f4f6ff", "hair": "1a1a2a",
    "eyes": "3a7ae8", "sash": "1c3a78", "cape": "2a5aa8", "sword": True, "boots": "232838", "pants": "1e2c50",
    "hair_style": "wild", "smile": True, "ahoge": True, "jaw": 0.98, "brow": 1.1,
}, clips=person.HERO_CLIPS)
