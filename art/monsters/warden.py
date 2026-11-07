"""Warden (new in Part VIII): the Heavenly Warden of the River and the Court's last gate-keepers.
A towering general in silver lamellar armour and a plumed helmet, a spear in each hand, a cape,
leather bracers and a stern bearded face.  Cloth is tinted per enemy; steel and skin keep theirs.
Run: blender --background --python art/monsters/warden.py  ->  assets/monsters/warden.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import garment as G  # noqa: E402
import person  # noqa: E402
from creature import person_die  # noqa: E402

kit.reset()
creature.realtime()


def gear(b, rig, o, tor):
    G.helmet(b, 1.9, metal="c8ccd8", plume="c02a20")
    G.twin_spears(b)


person.export_person("monsters/warden.glb", {
    "fem": False, "age": 0.4, "build": 1.2, "brow": 1.4, "jaw": 1.1, "stern": True, "beard": True, "beard_col": "2a2a30", "beard_len": 0.6,
    "armor": True, "metal": "c0c4d0", "marks": "scar", "bracers": "4a3020", "extra": gear, "cape": "b8b8b8", "smile": False,
    "robe": "c8c8c8", "trim": "f0f0f0", "inner": "e8e8e8", "sash": "707070", "pants": "6a6a6a", "boots": "3a3a3a", "sleeve": "b8b8b8",
    "hair": "1a1a20", "hair_style": "short", "eyes": "4a5a7a", "embroidery": "e0c060", "tint_cloth": True, "scale": 1.4,
}, clips=dict(person.CLIPS, die=(1.2, person_die(person.clip_idle))))
