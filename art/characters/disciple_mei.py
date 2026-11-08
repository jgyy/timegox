"""Junior Sister Mei (towns): a cheerful young disciple with twin buns who keeps the sect's pond and sneaks the koi extra rice.
Run: blender --background --python art/characters/disciple_mei.py  ->  assets/characters/disciple_mei.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/disciple_mei.glb", {
    "fem": True, "age": 0.05, "eye_size": 1.36, "build": 0.92,
    "robe": "6aa0c8", "trim": "f8f4ff", "inner": "fdfcff", "sash": "e88aa8", "hair": "2a1a20", "hair_style": "twin_buns",
    "eyes": "5a3a6a", "ribbon": "f0a0c0", "props": [("bowl", {"soup": "f0ece0"})], "pose": "hold_both",
})
