"""Elder Qing Xuan: white robe with gold trim, long beard and a gem-topped staff.
Run: blender --background --python art/characters/elder_qing.py  ->  assets/characters/elder_qing.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/elder_qing.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": False, "age": 0.85, "beard_len": 1.35, "brow": 1.2, "cheek": 0.8,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("fly_whisk", {"side": 1})],
    "robe": "e8e8ff", "trim": "c8a850", "inner": "fffaf0", "hair": "e8e8f0", "hair_style": "bald",
    "eyes": "5a6a8a", "sash": "8a7040", "beard": True, "staff": True, "boots": "4a4048", "pants": "8a8aa0",
    "stern": True,
})
