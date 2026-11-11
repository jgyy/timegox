"""Ji Chang the Archer (Part XXI, the Hundred Arms release): who lay under a loom to learn not to blink, looked at a louse until it was a cartwheel, and in
the end forgot what a bow was: lean, weathered, far-sighted, in a fur-trimmed steppe coat and a fur hat, an archer's bracer on the left arm, no bow.
Run: blender --background --python art/characters/ji_chang.py  ->  assets/characters/ji_chang.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/ji_chang.glb", {"fem": False, "age": 0.55, "build": 0.92, "jaw": 0.96, "smile": True, "skin": "c89a70", "eye_size": 1.06,
    "robe": "6a5a3a", "trim": "d8d0c0", "inner": "e8e0d0", "sash": "8a3a2a", "pants": "4a4030", "boots": "3a2c20", "hair": "5a5650", "hair_style": "topknot", "eyes": "5a6a7a",
    "beard": True, "beard_len": 0.2, "beard_col": "6a6660", "hat": "fur", "hat_col": "8a7a60", "bracers": "5a3a24", "robe_len": "short", "wraps": "8a7a5a"})
