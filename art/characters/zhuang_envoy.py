"""The Swordsman in Scholar's Dress (Part XXI, the Hundred Arms release): the thin man the prince of Zhao sent for to stop his father's swordsmen, who came
as he was and is turned away from the gate every day: a patched scholar's robe the colour of dust, a tall scholar's cap, straw sandals, hands in his sleeves, amused.
Run: blender --background --python art/characters/zhuang_envoy.py  ->  assets/characters/zhuang_envoy.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/zhuang_envoy.glb", {"fem": False, "age": 0.45, "build": 0.88, "jaw": 0.9, "smile": True, "skin": "e0c0a0",
    "robe": "9a9484", "trim": "5a5a54", "inner": "e8e4d8", "sash": "5a5444", "pants": "6a6658", "boots": "b8a070", "hair": "2a2620", "hair_style": "topknot", "eyes": "3a3020",
    "beard": True, "beard_len": 0.35, "beard_col": "2a2620", "hat": "scholar", "hat_col": "3a3a40", "sleeve_w": 1.4, "pose": "sleeves"})
