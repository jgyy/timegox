"""Steward Feng Xuan of Guiyun (Part XXV): the retainer of Lord Mengchang who was so poor that he sang to his sword ("Long sword, let
us go home! There is no fish to eat"), was sent to Xue to collect the debts, burned every tally in the square, and came back saying he had bought the one
thing the house was short of: a lean man of forty-odd in a patched grey robe with a hemp sash, a short beard, and a long plain sword he has never drawn.
Run: blender --background --python art/characters/feng_xuan.py  ->  assets/characters/feng_xuan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/feng_xuan.glb", {"fem": False, "age": 0.5, "build": 0.9, "jaw": 0.95, "brow": 1.05, "smile": True, "skin": "caa888",
    "robe": "6e6c5c", "trim": "4a4638", "inner": "d8d2bc", "sash": "b0a070", "pants": "4a463c", "boots": "2e2a24", "hair": "2a2622", "hair_style": "topknot", "eyes": "3a3028",
    "beard": True, "beard_len": 0.16, "beard_col": "3a3632", "sleeve_w": 1.0,
    "sword": True, "blade": "b8bcc4", "hilt": "6a5a40"})
