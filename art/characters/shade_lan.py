"""Little Lan of Youdu (Part XI): a shade child who lost her way on the road down the Yellow Springs
and has been looking for her grandmother among the lanterns of the Dark Capital ever since.  Pale
grey-blue skin, glowing pale eyes, two little buns tied with faded ribbons, a short robe of faded
grey-blue, and a lantern too big for her.
Run: blender --background --python art/characters/shade_lan.py  ->  assets/characters/shade_lan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/shade_lan.glb", {
    # a child (like little_dou and child_hua), a shade's pale skin and glowing eyes
    "fem": True, "age": 0.0, "build": 0.8, "eye_size": 1.45, "scale": 0.68, "head_scale": 1.2, "jaw": 0.85,
    "skin": "cad6de", "glow_eyes": True, "lip": "b8a2aa",
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("lantern", {"col": "e8eef2", "frame": "3a3a44", "glow": "d8f4ff"})], "pose": "hold_l", "robe_len": "short",
    # everything faded to the greys and blues of the Dark Capital: keep the colours chosen here
    "monotone": True,
    "robe": "9aaabb", "trim": "e8eef4", "inner": "f4f6f8", "sash": "c8a0b0", "pants": "5c687a", "boots": "3a4250",
    "collar2": "b8a4b4", "ribbon": "c8a0b0", "hair": "24242c", "hair_style": "twin_buns", "pin": "d8dce4", "eyes": "d8f4ff",
})
