"""Tu Lan, last of the Tushan cauldron-casters: a strong, grey-streaked founder in a scorched leather apron and bracers, with the casting hammer of her clan.
Run: blender --background --python art/characters/tu_lan.py  ->  assets/characters/tu_lan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/tu_lan.glb", {
    "fem": True, "age": 0.6, "build": 1.15, "brow": 1.2, "jaw": 1.05, "eye_size": 1.0, "stern": True,
    "robe": "8a3a2a", "trim": "e0c890", "inner": "e8dcc4", "sash": "3a2a1a", "hair": "4a4040", "hair_style": "bun", "pin": "c8803a",
    "eyes": "3a2a1a", "props": [("apron", {"col": "5a3a24", "strap": "2a1a10"}), "hammer"], "bracers": "4a2a1a", "robe_len": "short", "pants": "4a2a1a",
})
