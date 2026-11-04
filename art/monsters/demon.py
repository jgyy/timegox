"""Demon lord: a towering horned warlord with burning eyes, spiked armour, a long cape and a broad
blade (Demon Lord Xu Mo, the Blood Moon generals, Heavenly General Tian Wei, Shadow of Pangu ...).
Recolourable cloth, 1.35x scale.
Run: blender --background --python art/monsters/demon.py  ->  assets/monsters/demon.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("monsters/demon.glb", {
    "robe": "9a9a9a", "trim": "e8e8e8", "inner": "6a6a6a", "sash": "4a4a4a", "pants": "4a4a4a", "boots": "3a3a3a",
    "sleeve": "8a8a8a", "hair": "200010", "hair_style": "wild", "eyes": "ff3020", "glow_eyes": True, "slit_eyes": True,
    "horns": True, "sword": True, "armor": True, "metal": "4a3a48", "cape": "b0b0b0", "stern": True, "tint_cloth": True,
    "blade": "e0a0a0", "scale": 1.35,
})
