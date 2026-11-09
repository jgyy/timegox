"""One of the Yumin, the Feathered Folk of Featherfall (scripts/folk.gd): wings folded at the back and a crest of feathers; they glide between the aeries, tend the egg-nursery and sing at the Aerie Tower.
Run: blender --background --python art/characters/folk_yumin.py  ->  assets/characters/folk_yumin.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_yumin.glb", {"age": 0.25, "build": 0.95, "wings": "c8a070", "wing_tip": "f4ecd8", "crest": "e8d8b8", "crest_tip": "b88a50", "crest_len": 0.16, "robe": "e8e0cc", "trim": "a8783a", "inner": "fbf8f0", "sash": "6a8ab0", "hair": "2a2018", "hair_style": "short", "eyes": "8a5a20", "robe_len": "short"})
