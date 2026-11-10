"""Lei Gong, Duke of Thunder (Part XVII), in person: the thunder god of the old prints, come down to Thunder Valley to drum the first thunder of spring.  Blue-skinned and heavy-browed, a crest of gold feathers, great grey wings folded at his back, a storm-grey robe with lightning-gold trim and bracers, a wild white mane, glowing gold eyes, and his mallet.
Run: blender --background --python art/characters/lei_gong.py  ->  assets/characters/lei_gong.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/lei_gong.glb", {
    "fem": False, "age": 0.45, "build": 1.3, "jaw": 1.12, "brow": 1.3, "stern": True, "smile": False,
    "skin": "7a98c8", "eyes": "ffe060", "glow_eyes": True,
    "robe": "4a5068", "trim": "f0c840", "inner": "e8ecf4", "sash": "2a2e40", "pants": "2a3040", "boots": "1a1c24",
    "hair": "eceaf4", "hair_style": "wild", "beard": True, "beard_col": "eceaf4", "beard_len": 0.5,
    "wings": "6a7088", "wing_tip": "e8e4f0", "crest": "f0c840", "crest_tip": "fff0a0", "crest_len": 0.2,
    "bracers": "c8a040", "embroidery": "f0d040",
    "props": ["hammer"],
})
