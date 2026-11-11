"""Gao Jianli of the Leaded Lute (Part XXIII; a lord of the story, fought in his own model): Jing Ke's friend, who played at the River Yi, was blinded by
the First Emperor and swung a lute full of lead at his head: a gaunt man in ash-grey and black, a black cloth over his eyes, hair loose.
Run: blender --background --python art/characters/gao_jianli.py  ->  assets/characters/gao_jianli.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/gao_jianli.glb", {"fem": False, "age": 0.5, "build": 0.88, "jaw": 0.94, "brow": 1.2, "stern": True, "smile": False, "skin": "cfc0b0", "scale": 1.06,
    "robe": "4a4a5a", "trim": "1a1a22", "inner": "8a8a94", "sash": "1a1a22", "pants": "2a2a34", "boots": "16161c", "hair": "2a2a30", "hair_style": "long", "eyes": "5a5a60",
    "beard": True, "beard_len": 0.25, "beard_col": "3a3a40", "sleeve_w": 1.4, "blindfold": "141418", "cape": "24242c"})
