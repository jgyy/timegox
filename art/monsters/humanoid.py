"""Humanoid enemy: a recolourable martial cultivator (Mountain Bandit, Blood Acolyte, Bone Knight,
Iron Fang, Founder Qing Lian, The Ancestor Who Took ...).  Built from the character library with
every cloth surface tinted by the enemy's colour; armour, skin and steel keep their own.
Run: blender --background --python art/monsters/humanoid.py  ->  assets/monsters/humanoid.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import person  # noqa: E402
from creature import person_die  # noqa: E402

kit.reset()
creature.realtime()
person.export_person("monsters/humanoid.glb", {
    "robe": "d8d8d8", "trim": "f8f8f8", "inner": "eeeeee", "sash": "707070", "pants": "7a7a7a", "boots": "505050",
    "sleeve": "c8c8c8", "hair": "2a2030", "hair_style": "bun", "eyes": "5a4a3a", "sword": True, "armor": True,
    "metal": "8a8ea0", "stern": True, "tint_cloth": True, "blade": "c8d0e0",
    # a seasoned fighter: leather bracers, a weathered face, broad build
    "bracers": "4a3a2a", "age": 0.35, "build": 1.08, "brow": 1.2, "jaw": 1.06,
}, clips=dict(person.CLIPS, die=(1.2, person_die(person.clip_idle))))
