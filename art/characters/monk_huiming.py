"""Monk Huiming of the Sun Shrine (Part IX): a calm young monk in grey with prayer beads and an alms bowl, very good at the noon sutra by now.
Run: blender --background --python art/characters/monk_huiming.py  ->  assets/characters/monk_huiming.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/monk_huiming.glb", {
    "age": 0.25, "build": 0.95, "eye_size": 1.05,
    "robe": "8a8478", "trim": "c8a060", "inner": "ece8dc", "sash": "a86a30", "hair": "2a2a2a", "hair_style": "bald",
    "eyes": "3a3028", "beads": "6a3a1a", "props": [("bowl", {"col": "5a4a3a", "soup": "e8e0c8"})], "pose": "hold_both",
})
