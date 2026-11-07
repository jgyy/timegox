"""Demon lord: a towering horned warlord with burning eyes, spiked armour, a long cape and a broad
blade (Demon Lord Xu Mo, the Blood Moon generals, Heavenly General Tian Wei, Shadow of Pangu ...).
Recolourable cloth, 1.35x scale.
Run: blender --background --python art/monsters/demon.py  ->  assets/monsters/demon.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402
from kit import CLOTH, CRYSTAL, MAT_GLOW, STONE, V  # noqa: E402

kit.reset()


def demon_extra(b, rig, o, tor):
    """Spiked pauldrons over the armour, a burning rune on the chest and wing-like shoulder
    flames (the 'extra' hook of art/lib/person.py)."""
    for s in (1, -1):
        sd = "L" if s > 0 else "R"
        for k in range(3):
            base = V(0.2 * s, 1.5 - k * 0.04, -0.02 + k * 0.05)
            b.cone(base + V(0.03 * s, 0.06, 0), 0.025, 0.14 - 0.03 * k, "2a1a20", cls=STONE, bone={"chest": 0.4, "upper_arm." + sd: 0.6}, seg=6, rot=(0, 0, -0.6 * s))
        for k in range(5):
            root = V(0.18 * s, 1.48, -0.1 - k * 0.02)
            b.leaf(root, root + V(0.15 * s + 0.05 * k * s, 0.3 - 0.04 * k, -0.15), 0.05, "ff6030", side=(0, 0, 1), cls=CLOTH, bone="chest", col_tip="ffd060", mat=MAT_GLOW)
    c = tor.point(1.3, 0.0, 0.03)
    ring = [c + V(math.cos(a) * 0.06, math.sin(a) * 0.06, 0.004) for a in [i / 16 * 2 * math.pi for i in range(17)]]
    b.tube(ring, [0.006] * 17, "ff4020", cls=CRYSTAL, bone="chest", seg=4, mat=MAT_GLOW)
    for k in range(3):
        a = k / 3 * 2 * math.pi
        b.tube([c + V(0, 0, 0.004), c + V(math.cos(a) * 0.05, math.sin(a) * 0.05, 0.004)], [0.005, 0.005], "ff4020", cls=CRYSTAL, bone="chest", seg=4, mat=MAT_GLOW)


person.export_person("monsters/demon.glb", {
    # demonic features: clawed hands, fangs, a barbed tail and the extras above
    "claws": True, "claw_len": 0.07, "fangs": True, "tail": "4a3a48", "extra": demon_extra, "age": 0.0, "brow": 1.4, "jaw": 1.05,
    "robe": "9a9a9a", "trim": "e8e8e8", "inner": "6a6a6a", "sash": "4a4a4a", "pants": "4a4a4a", "boots": "3a3a3a",
    "sleeve": "8a8a8a", "hair": "200010", "hair_style": "wild", "eyes": "ff3020", "glow_eyes": True, "slit_eyes": True,
    "horns": True, "sword": True, "armor": True, "metal": "4a3a48", "cape": "b0b0b0", "stern": True, "tint_cloth": True,
    "blade": "e0a0a0", "scale": 1.35,
})
