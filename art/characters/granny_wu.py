"""Old Dame Wu (Part XXXIII): the old woman of the stream below Xiang'er Mountain whom the boy Li Bai found grinding
an iron pestle on a stone, to make a needle of it. Past eighty, small and square, in a mended blue jacket with
the sleeves tied back, a headcloth, and the pestle across her in one hand: black where she holds it and bright
along the end that has been on the stone.
Run: blender --background --python art/characters/granny_wu.py  ->  assets/characters/granny_wu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/granny_wu.glb", {"fem": True, "age": 0.95, "build": 0.96, "eye_size": 1.08, "smile": True, "skin": "d8b898",
    "robe": "4a5a72", "trim": "8a8e96", "inner": "e6e2d6", "sash": "2e3644", "pants": "3a4250", "boots": "3a3028",
    "hair": "d0ccc8", "hair_style": "bun", "eyes": "3a2e24", "hat": "headcloth", "hat_col": "6a7484", "robe_len": "short",
    "props": [("iron_pestle", {})], "pose": "hold_l"})
