"""Houtu, Sovereign Earth (Part XI): the goddess of the earth under heaven, mother of the soil and
queen of the dead below it, to whom the Nine Springs and every root of the world tree answer.
Robes of earth brown and ochre gold woven with clouds, a mantle the colour of loam, a golden
crown, a jade pendant, a calm and motherly face, and a jade bi - the round of heaven - held
before her in both hands.
Run: blender --background --python art/characters/houtu.py  ->  assets/characters/houtu.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402
from kit import V  # noqa: E402

kit.reset()
JADE = "6ab48e"


def jade_bi(b, rig, o, tor):
    """A jade bi disc held upright before the chest in both hands (the hold_both pose brings the
    hands here, as for accessory.bowl): a ring with a rolled rim, raised grain on its face, a red
    cord at the top and a tassel below."""
    c = V(0.0, 1.17, 0.3)
    bone = "chest"
    prof = [(0.03, -0.007), (0.084, -0.007), (0.091, -0.003), (0.091, 0.003), (0.084, 0.007), (0.03, 0.007), (0.026, 0.0), (0.03, -0.007)]
    b.lathe(c, prof, JADE, cls=kit.CRYSTAL, bone=bone, seg=28, rot=(math.pi / 2, 0, 0), cap_bottom=False, cap_top=False, col_top=kit.lighten(JADE, 0.2))
    for ring, (rr, cnt) in enumerate(((0.045, 10), (0.068, 16))):
        for k in range(cnt):
            a = (k + 0.5 * ring) / cnt * 2.0 * math.pi
            for s in (1, -1):
                b.ball(c + V(math.cos(a) * rr, math.sin(a) * rr, 0.0075 * s), 0.0045, kit.lighten(JADE, 0.25), cls=kit.CRYSTAL, bone=bone, seg=6, rings=4)
    top = c + V(0.0, 0.09, 0.0)
    b.tube([top, top + V(0.0, 0.03, 0.0)], [0.003, 0.003], "b82a24", cls=kit.CLOTH, bone=bone, seg=4)
    bot = c + V(0.0, -0.09, 0.0)
    b.ball(bot + V(0, -0.012, 0), 0.008, "d8a840", cls=kit.METAL, bone=bone, seg=8, rings=5)
    for k in range(6):
        x = (k / 5 - 0.5) * 0.024
        b.tube([bot + V(x * 0.3, -0.018, 0), bot + V(x, -0.1, 0.004)], [0.0024, 0.001], "c8302a", cls=kit.CLOTH, bone=bone, seg=4)


person.export_person("characters/houtu.glb", {
    # face and build (see art/lib/face.py, garment.py): a calm, motherly face
    "fem": True, "age": 0.28, "eye_size": 1.16, "jaw": 0.92, "cheek": 1.05, "lip": "c8786e", "smile": True,
    "hair_len": 0.8, "flare": 1.15,
    # woven brocade over the robe (garment.MOTIFS)
    "brocade": "cloud", "brocade_col": "c89a50",
    # crown, jade and the bi held in both hands (person.POSES)
    "crown": True, "jade": JADE, "pose": "hold_both", "extra": jade_bi, "cape": "5a3a22",
    # earth and ochre gold: keep the colours chosen here
    "monotone": True,
    "robe": "7a4a26", "trim": "dcae48", "inner": "f6ead2", "sash": "d4a040", "pants": "4a2e18", "boots": "3a2414",
    "collar2": "b8863a", "hair": "1a120e", "hair_style": "long", "pin": "dcae48", "eyes": "6a4a2a", "embroidery": "e8c060",
})
