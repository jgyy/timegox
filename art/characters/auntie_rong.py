"""Auntie Rong of the Smelting Pits (towns): keeper of Tushan's never-cold fires, broad-shouldered and soot-streaked, in a leather apron with a forge hammer.
Run: blender --background --python art/characters/auntie_rong.py  ->  assets/characters/auntie_rong.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/auntie_rong.glb", {
    "fem": True, "age": 0.55, "build": 1.14, "jaw": 1.0, "eye_size": 1.05,
    "props": [("apron", {"col": "5a3a24", "strap": "3a2818"}), ("hammer", {"head": "5a5a64", "handle": "6a4a2a"})], "robe_len": "short",
    "robe": "a84a2a", "trim": "e8c080", "inner": "f0e0c8", "sash": "3a2a1a", "hair": "2a2220", "hair_style": "bun", "eyes": "2a1a10", "pants": "4a3a2a", "bracers": "4a3a2a"
})
