"""Lin Feng as the player may make him (character creation, scripts/create.gd): The wandering swordsman: hair in one long braid down the back, an easy smile.
The same rig, robe and clips as art/characters/lin_feng.py; the game recolours the robe, hair and
eyes at run time (scripts/assets.gd Assets.hero_instance).
Run: blender --background --python art/characters/lin_feng_wanderer.py  ->  assets/characters/lin_feng_wanderer.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/lin_feng_wanderer.glb", {
    "fem": False, "age": 0.0, "build": 1.03,
    "robe": "3a8ae8", "trim": "e8f0ff", "inner": "f4f6ff", "hair": "1a1a2a",
    "eyes": "3a7ae8", "sash": "1c3a78", "cape": "2a5aa8", "sword": True, "boots": "232838", "pants": "1e2c50",
    "hair_style": "braid", "hair_len": 0.5, "smile": True, "jaw": 0.94, "cheek": 1.02,
}, clips=person.HERO_CLIPS)
