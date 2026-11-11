"""Wang Zhi the Woodcutter (Part XX, the Hollow Hills release): who stopped in a cave on Rotten-Axe Mountain to watch
two boys play weiqi, and has not yet noticed what became of the handle of his axe: a young man in a short brown
jacket with a red headband and bracers, and the look of somebody who has only been gone an afternoon.
Run: blender --background --python art/characters/wang_zhi.py  ->  assets/characters/wang_zhi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/wang_zhi.glb", {"fem": False, "age": 0.05, "build": 1.1, "jaw": 1.02, "smile": True, "skin": "d8a070",
    "robe": "7a5a3a", "trim": "c8b080", "inner": "e8dcc0", "sash": "a83a2a", "pants": "4a4030", "boots": "3a2c1c", "hair": "1a1612", "hair_style": "bun", "eyes": "3a2a14",
    "ribbon": "a83a2a", "robe_len": "short", "wraps": "c8b48a", "bracers": "5a4028"})
