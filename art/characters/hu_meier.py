"""Hu Mei'er of the Moon-Fox Pavilion (Part XI): a young celestial fox, barely three tails old, who
guards the sky gate chiefly by playing tricks on whoever comes to it.  Red-orange fox ears, three
red tails tipped with white held high behind her, red hair tied with ribbons, an orange and cream
robe with a teal sash, and a grin.
Run: blender --background --python art/characters/hu_meier.py  ->  assets/characters/hu_meier.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/hu_meier.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "age": 0.05, "eye_size": 1.4, "jaw": 0.84, "lip": "e07a7a", "hair_len": 0.5, "smile": True, "ahoge": True,
    "build": 0.92,
    # race (art/lib/race.py): a young fox's ears and three tails
    "ears": "fox", "ear_col": "d8622c", "ear_inner": "fbe6d6", "ear_tip": "3a2018",
    "tails": 3, "tail_col": "d4582a", "tail_tip": "fbf6ee",
    "ribbon": "e8443a",
    "robe": "e87428", "trim": "fff0dc", "inner": "fff8ee", "sash": "3a8a84",
    "hair": "c8501e", "hair_style": "long", "eyes": "e0a030", "pin": "e8443a",
})
