"""Ling Yu of the Yumin (Part XI): a young messenger of the Feathered Folk who flew down the trunk
of the world tree with word for the hero.  Folded wings of sky blue fading to white at the tips, a
white crest sweeping back from the crown, a short practical robe for flying in, cloud-white and
sky blue with a little gold, and a gourd of dew at the hip.
Run: blender --background --python art/characters/ling_yu.py  ->  assets/characters/ling_yu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/ling_yu.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": False, "age": 0.0, "jaw": 0.9, "eye_size": 1.26, "build": 0.92,
    # race (art/lib/race.py): the Yumin's folded wings and feathered crest
    "wings": "7ab4e8", "wing_tip": "f4f8ff", "crest": "f4f6fa", "crest_tip": "c8dcf4", "crest_len": 0.2,
    # signature props (art/lib/accessory.py)
    "props": [("gourd", {"col": "e0b058"})], "robe_len": "short",
    # a white robe: keep the blues chosen here (harmonise would re-dye a pale robe's sash)
    "monotone": True,
    "robe": "eef2f8", "trim": "6aa4dc", "inner": "ffffff", "sash": "3a6ab0", "pants": "4a6a9e", "boots": "34405a",
    "collar2": "8ab8e8", "hair": "1a2232", "hair_style": "short", "eyes": "3a7ad0", "embroidery": "e8c860",
})
