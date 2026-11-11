"""Lin Feng, the sweeper with the Nine Heavens root: azure robe, white trim, cape, topknot and a jian.
Run: blender --background --python art/characters/lin_feng.py  ->  assets/characters/lin_feng.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
# the party: the twenty-one clips every person has, and what they do with the things of the world
person.export_person("characters/lin_feng.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": False, "age": 0.0, "build": 1.03, "jaw": 0.96,
    "robe": "3a8ae8", "trim": "e8f0ff", "inner": "f4f6ff", "hair": "1a1a2a", "hair_style": "topknot",
    "eyes": "3a7ae8", "sash": "1c3a78", "cape": "2a5aa8", "sword": True, "arms": True, "boots": "232838", "pants": "1e2c50",
    "stern": True, "ahoge": True,
}, clips=person.HERO_CLIPS)
