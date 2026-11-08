"""Bell-Caster Wei of Tushan: a soot-streaked bell-founder in a hood and leather apron, with the hammer he tunes his bells by.
Run: blender --background --python art/characters/caster_wei.py  ->  assets/characters/caster_wei.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/caster_wei.glb", {
    "age": 0.45, "build": 1.1, "jaw": 1.1, "eye_size": 1.0,
    "robe": "6a5a4a", "trim": "c8a868", "inner": "e0d8c4", "sash": "8a3a2a", "hair": "1a1410", "hair_style": "short",
    "eyes": "3a2414", "hat": "hood", "hat_col": "4a3a2a", "props": [("apron", {"col": "4a3020", "strap": "2a1a10"}), "hammer"], "robe_len": "short",
})
