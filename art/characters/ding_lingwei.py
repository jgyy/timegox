"""Ding Lingwei, the Crane (Part XXIX): the man of Liaodong who studied the Way on Lingxu Mountain and came home a thousand
years later as a crane, to perch on the pillar at the city gate and find the walls as they were and the people gone; as a
man again, tall and spare, in a white robe with black borders like a crane's wing, a red cap like its crown, long white
hair and no beard.
Run: blender --background --python art/characters/ding_lingwei.py  ->  assets/characters/ding_lingwei.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/ding_lingwei.glb", {"fem": False, "age": 0.75, "build": 0.9, "jaw": 0.92, "brow": 1.0, "smile": False, "skin": "e8d8c8",
    "robe": "f0f0f2", "trim": "1a1a1e", "inner": "f8f8f8", "sash": "1a1a1e", "pants": "e0e0e4", "boots": "1a1a1e",
    "hair": "f0f0f0", "hair_style": "long", "eyes": "2a2018", "robe_len": "long"})
