"""Yang Bao, aged nine (Part XXVIII): the boy of Huayin who found a siskin struck down by an owl and beset by ants, kept it
in a box and fed it yellow flowers for a hundred days, and was brought four rings of white jade by a youth in yellow; a
small serious boy in a yellow-brown jacket with the sleeves pushed up, short hair, bare shins and sandals.
Run: blender --background --python art/characters/yang_bao.py  ->  assets/characters/yang_bao.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/yang_bao.glb", {"age": 0.0, "build": 0.8, "eye_size": 1.42, "scale": 0.72, "head_scale": 1.18, "jaw": 0.85, "smile": False,
    "robe": "c8a848", "trim": "6a4a2a", "inner": "f4f0e4", "sash": "6a4a2a", "hair": "1a1612", "hair_style": "short", "eyes": "3a2414",
    "robe_len": "short", "pants": "d8c8a0", "shoes": "sandals"})
