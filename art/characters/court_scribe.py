"""Scribe Wen Yu, the runaway scribe of the Jade Court: jade-green clerk robes and a scholar's cap, ink-stained sleeves.
Run: blender --background --python art/characters/court_scribe.py  ->  assets/characters/court_scribe.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/court_scribe.glb", {
    "robe": "3a8a6a", "trim": "e8e0c0", "inner": "f0ece0", "sash": "1a4a3a", "hair": "1a1a24", "hair_style": "long", "eyes": "3a7a5a",
    "hat": "scholar", "sleeve": "2a6a50", "embroidery": "e8d890",
})
