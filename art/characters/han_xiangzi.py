"""Han Xiangzi of the Jade Flute (Part XII): the youngest-looking of the immortals, whose flute makes flowers open; a green robe, a jade flute at his lips.
Run: blender --background --python art/characters/han_xiangzi.py  ->  assets/characters/han_xiangzi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/han_xiangzi.glb", {
    "age": 0.05, "build": 0.94, "jaw": 0.9, "eye_size": 1.2,
    "props": [("flute", {"col": "8ad0a0"})], "pose": "flute",
    "robe": "5a9a6a", "trim": "f0f0d8", "inner": "f4f8f0", "sash": "2a5a3a", "hair": "141418", "hair_style": "twin_buns", "eyes": "2a3a2a"
})
