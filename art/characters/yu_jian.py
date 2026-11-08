"""Fletcher Yu Jian of Featherfall (Part XI): the Yumin who fletches arrows for the hunters of the
high branches, with the feathers his own wings drop in the moult.  Brown hawk wings barred with
dark umber, a short brown crest, a workman's short robe of moss green and a scorched leather
apron.
Run: blender --background --python art/characters/yu_jian.py  ->  assets/characters/yu_jian.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/yu_jian.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": False, "age": 0.3, "brow": 1.1, "build": 1.06, "jaw": 1.02,
    # race (art/lib/race.py): a hawk's barred wings and a short crest
    "wings": "9a6a3c", "wing_tip": "d6b484", "wing_bar": "3a2414",
    "crest": "7a5232", "crest_tip": "c8a070", "crest_len": 0.15, "crest_n": 3, "crest_up": 0.35,
    # signature props (art/lib/accessory.py)
    "props": [("apron", {"col": "7a5434", "strap": "3a2818"})], "robe_len": "short",
    "robe": "5a6a42", "trim": "c8b890", "inner": "efe6d4", "sash": "8a4a2a", "pants": "4a3a2a", "boots": "3a2a1e",
    "collar2": "a87a48", "hair": "2a1e16", "hair_style": "short", "eyes": "8a5a2a",
})
