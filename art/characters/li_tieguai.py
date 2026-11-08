"""Iron-Crutch Li (Part XII): the immortal who came back from a wandering of the soul to find his body burned and moved into a beggar's; ragged, wild-haired, bearded, an iron crutch and a gourd of medicine.
Run: blender --background --python art/characters/li_tieguai.py  ->  assets/characters/li_tieguai.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/li_tieguai.glb", {
    "age": 0.7, "build": 0.98, "brow": 1.3, "jaw": 1.05, "beard": True, "beard_col": "3a3028", "beard_len": 1.0,
    "props": [("gourd", {"col": "c89040", "cord": "8a2a1a"})], "staff": True, "staff_gem": "5a5a64", "robe_len": "short",
    "robe": "6a5a4a", "trim": "4a3a2a", "inner": "a89878", "sash": "3a2a1a", "hair": "2a2420", "hair_style": "wild", "eyes": "3a2a1a", "pants": "5a4a3a"
})
