"""Little Bei of Tearwater (Part XI): a Jiaoren child who has wept exactly one pearl in her life,
over a crab, and carries it everywhere.  Small sea-green fins, a few scales, two little buns, a
short robe of sea green and shell pink, and her one pearl glowing in her hand.
Run: blender --background --python art/characters/little_bei.py  ->  assets/characters/little_bei.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/little_bei.glb", {
    # a child (like little_dou and child_hua): small, with a big head and big eyes
    "fem": True, "age": 0.0, "build": 0.8, "eye_size": 1.45, "scale": 0.7, "head_scale": 1.2, "jaw": 0.85,
    # race (art/lib/race.py): small fins and a few scales
    "ears": "fin", "ear_col": "4ab4aa", "ear_inner": "e2fcf6", "ear_size": 0.8, "scales": "4aa8a0",
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("pearl", {"col": "f4f0fa"})], "pose": "hold_l", "robe_len": "short",
    "robe": "6ab8a0", "trim": "fff4f0", "inner": "fffaf8", "sash": "e8a0a8", "ribbon": "e8a0a8",
    "hair": "1a3a44", "hair_style": "twin_buns", "pin": "f4f0fa", "eyes": "2aa0a0",
})
