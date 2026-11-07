"""Zhi, the Last Weaver-Girl of the Loom of Borders (Part VII): a pale celestial weaver in silver and rose, ribbons like loose thread.
Run: blender --background --python art/characters/apprentice_zhi.py  ->  assets/characters/apprentice_zhi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/apprentice_zhi.glb", {
    "robe": "e0d0f0", "trim": "f0a0c8", "inner": "fff8ff", "sash": "a06090", "hair": "f0e8f8", "hair_style": "long",
    "pin": "f0c8e8", "eyes": "a060c0", "ribbon": "ffd0f0", "crown": True, "embroidery": "ffe0f8", "glow_eyes": False,
})
