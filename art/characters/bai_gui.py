"""Minister Bai Gui (Part XXXVII): the minister who told Mencius that he managed the waters better than Yu, and was told
that Yu made the four seas his drain and he made his neighbour's country his (Mencius 6B). A well-fed man of sixty in
a minister's slate-blue robe with a pale trim, a tall hat's worth of dignity in the neck, a neat grey beard, and ink
on the first two fingers of the right hand.
Run: blender --background --python art/characters/bai_gui.py  ->  assets/characters/bai_gui.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/bai_gui.glb", {"age": 0.7, "build": 1.12, "jaw": 1.05, "brow": 1.0, "smile": False, "skin": "d0b090", "robe": "5a6a7a", "trim": "c8d0d0", "inner": "e0dcd0", "sash": "2e3a44", "pants": "4a5560", "shoes": "boots", "hair": "8a8884", "hair_style": "topknot", "eyes": "30281c", "beard": True, "beard_len": 0.45, "beard_col": "a8a6a0", "brow_col": "7a7874", "robe_len": "long"})
