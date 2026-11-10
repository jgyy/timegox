"""The Gardener of Hanyin (Part XIX, the Hundred Works release): the old man of the Zhuangzi who waters his cabbages with a
pitcher and will not use a well-sweep: small, sun-browned, in faded green homespun and a straw hat, with a basket of greens.
Run: blender --background --python art/characters/gardener_hanyin.py  ->  assets/characters/gardener_hanyin.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/gardener_hanyin.glb", {"fem": False, "age": 0.9, "build": 0.92, "cheek": 1.15, "smile": True, "skin": "b88458",
    "robe": "6a8a5a", "trim": "c8c090", "inner": "e8e0c0", "sash": "8a6a3a", "pants": "5a5a3a", "boots": "7a6a40", "hair": "e0dcd0", "hair_style": "bun", "eyes": "3a2a1a",
    "beard": True, "beard_len": 0.6, "beard_col": "e8e4d8", "hat": "straw", "hat_col": "d8c078", "robe_len": "short", "wraps": "b8a878",
    "props": [("basket", {"col": "b89a60", "fill": "6ab04a"})], "pose": "hold_l"})
