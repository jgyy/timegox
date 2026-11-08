"""Old Shen, keeper of the sect's bell tower (towns): a bald old man in ochre with prayer beads, who rings the hours.
Run: blender --background --python art/characters/bell_shen.py  ->  assets/characters/bell_shen.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/bell_shen.glb", {
    "age": 0.95, "build": 0.9, "eye_size": 1.0,
    "robe": "b8803a", "trim": "f0d890", "inner": "f0e8d0", "sash": "6a3a1a", "hair": "e8e8ec", "hair_style": "bald",
    "eyes": "4a3a2a", "beard": True, "beard_col": "e8e8ec", "beard_len": 0.7, "beads": "5a2a1a", "staff": True, "staff_gem": "f0d070",
})
