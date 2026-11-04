"""Nomad Matriarch Ba Yin of the Desert of Fallen Stars: sand-coloured robes under a straw hat.
Run: blender --background --python art/characters/nomad.py  ->  assets/characters/nomad.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/nomad.glb", {
    "robe": "e8c890",
    "trim": "b05a30",
    "hair": "4a3020",
    "hair_style": "long",
    "hat": "straw",
    "eyes": "6a4a2a",
    "sash": "b05a30",
    "staff": True,
    "staff_gem": "ffd890",})
