"""Budai, the Cloth-Sack Monk (Part XXVII): the fat, laughing monk of Fenghua who wandered with everything he had been
given in a hemp sack over his shoulder, and who, asked what the teaching was, put the sack down, and asked what came after,
picked it up and walked away; a very stout bald man with a wide smile, his grey robe open over his chest and belly,
straw sandals, the sack slung from his left hand down his back.
Run: blender --background --python art/characters/budai.py  ->  assets/characters/budai.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/budai.glb", {"fem": False, "age": 0.5, "build": 1.3, "waist": 1.9, "jaw": 1.18, "cheek": 1.35, "brow": 0.9, "smile": True, "skin": "e0bc94",
    "robe": "8a8478", "trim": "5a5448", "inner": "e0bc94", "sash": "5a4a30", "pants": "6a665c", "boots": "3a3020", "shoes": "sandals", "sleeve_w": 1.05,
    "hair": "d8d4cc", "hair_style": "bald", "eyes": "3a2a1a",
    "props": ["cloth_sack"], "pose": "hold_l"})
