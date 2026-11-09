"""Tala of the Horse-Folk (a fated encounter, scripts/fate.gd): a girl of the horse-folk who winter below
Thunder Valley; a long braid tied with red cord, a fur hat, a blue-grey riding coat with a fur-coloured trim
and a red sash, and a riding whip.
Run: blender --background --python art/characters/tala.py  ->  assets/characters/tala.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/tala.glb", {
    "fem": True, "age": 0.0, "build": 0.92, "jaw": 0.9, "eye_size": 1.2, "smile": True,
    "hair_style": "braid", "hair_len": 0.6, "hair": "16100c", "pin": "c02020", "hat": "fur", "hat_col": "8a6a4a",
    "robe": "4a6a8a", "trim": "d8c098", "inner": "f0e8d8", "sash": "b83030", "pants": "3a3428", "boots": "4a3020",
    "eyes": "3a2414", "robe_len": "short", "props": ["whip"],
})
