"""Zhou Chu of Yixing (Part XXVIII): the strong, fatherless young man whom his town counted with the tiger of the south
hill and the jiao under the long bridge as the third of its three scourges, who killed the other two and came home to
hear the town rejoicing that he was dead; very big in the shoulder, a rust-red jacket open at the neck with the sleeves
torn off, hair tied anyhow, no beard, a grin.
Run: blender --background --python art/characters/zhou_chu.py  ->  assets/characters/zhou_chu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/zhou_chu.glb", {"fem": False, "age": 0.26, "build": 1.3, "jaw": 1.15, "brow": 1.15, "smile": True, "skin": "c89a6e",
    "robe": "7a3a2a", "trim": "3a1e16", "inner": "c89a6e", "sash": "3a2a1a", "pants": "4a4038", "boots": "2a2018", "sleeve_w": 0.55, "robe_len": "short",
    "hair": "1a1614", "hair_style": "topknot", "eyes": "2e2014", "scale": 1.08})
