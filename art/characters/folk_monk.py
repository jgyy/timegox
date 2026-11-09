"""A monk of the towns (scripts/folk.gd): a shaved head, a grey robe and prayer beads; he sweeps the temple yard at dawn, chants at the shrine and walks the streets with his bowl.
Run: blender --background --python art/characters/folk_monk.py  ->  assets/characters/folk_monk.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_monk.glb", {"age": 0.35, "build": 0.95, "robe": "8a8478", "trim": "c8a060", "inner": "ece8dc", "sash": "a86a30", "hair": "2a2a2a", "hair_style": "bald", "eyes": "3a3028", "beads": "6a3a1a"})
