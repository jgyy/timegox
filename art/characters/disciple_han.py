"""Senior Brother Han, the sect's sparring master (towns): a tall young disciple in a short training robe, bracers and a wooden practice sword.
Run: blender --background --python art/characters/disciple_han.py  ->  assets/characters/disciple_han.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/disciple_han.glb", {
    "age": 0.15, "build": 1.1, "jaw": 1.05, "stern": True,
    "robe": "3a6aa0", "trim": "e8f0ff", "inner": "f2f4fa", "sash": "1e2c50", "hair": "1a1a24", "hair_style": "topknot",
    "eyes": "2a3a5a", "robe_len": "short", "bracers": "3a3a44", "sword": True, "blade": "c8a070", "hilt": "5a3a24", "wraps": "e8e0d0",
})
