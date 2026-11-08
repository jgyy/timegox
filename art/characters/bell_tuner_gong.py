"""Bell-Tuner Gong (towns): a Tushan caster who files the wrong notes out of bells, grey-haired, in a leather apron, a little tuning hammer in hand.
Run: blender --background --python art/characters/bell_tuner_gong.py  ->  assets/characters/bell_tuner_gong.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/bell_tuner_gong.glb", {
    "age": 0.7, "build": 0.98, "brow": 1.2, "beard": True, "beard_col": "8a8680", "beard_len": 0.5,
    "props": [("apron", {"col": "6a4a30", "strap": "3a2818"}), ("hammer", {"head": "b07a40", "handle": "5a3a20"})], "robe_len": "short",
    "robe": "8a6a3a", "trim": "d8c080", "inner": "eee4d0", "sash": "3a2a1a", "hair": "8a8680", "hair_style": "topknot", "eyes": "2a2018", "pants": "5a4a3a", "bracers": "4a3a2a"
})
