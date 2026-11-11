"""The Mountain Spirit of the Nine Songs (Part XXII): clothed in fig leaves and girdled with hanging moss, who came late
through the dark bamboo and has stood on her summit in the rain ever since, waiting for somebody who has not come.
Run: blender --background --python art/characters/shan_gui.py  ->  assets/characters/shan_gui.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/shan_gui.glb", {"fem": True, "age": 0.0, "lip": "c05a5a", "eye_size": 1.3, "hair_len": 0.8, "scale": 1.04, "skin": "e8dcc8",
    "robe": "4a7a4a", "trim": "c8e0a0", "inner": "e8f0d8", "hair": "16241a", "hair_style": "long",
    "eyes": "6aa04a", "sash": "a03a2a", "ribbon": "8ab86a", "boots": "3a5a3a", "pants": "3a6040",
    "jade": "c8e0a0", "pin": "a03a2a", "sleeve_w": 1.5, "cape": "2a4a30"})
