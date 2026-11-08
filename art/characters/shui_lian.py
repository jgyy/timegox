"""Pearl-Weaver Shui Lian of Tearwater (Part XI): a Jiaoren of the sea under the earth, who weaves
dragon-silk that water cannot wet and weeps tears that harden into pearls.  Teal fins where her
ears would be, patches of teal scales on her cheekbones and the backs of her hands, sea-green and
pearl-white robes, pearls strung in her hair, and her weaving shuttle.
Run: blender --background --python art/characters/shui_lian.py  ->  assets/characters/shui_lian.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402
from face import HC  # noqa: E402
from kit import V  # noqa: E402

kit.reset()
PEARL = "f4f0f6"


def pearls(b, rig, o, tor):
    """Two strings of pearls looped round the back of the head under the knot of hair, and a short
    drop of pearls from the hairpin."""
    for k, (y0, rx, rz) in enumerate(((0.022, 0.128, 0.146), (-0.012, 0.132, 0.15))):
        for i in range(13):
            u = i / 12
            a = math.pi * (0.6 + 0.8 * u)
            p = V(math.sin(a) * rx, HC.y + y0 - 0.022 * math.sin(math.pi * u), HC.z + math.cos(a) * rz)
            b.ball(p, 0.0078 - 0.0014 * k, PEARL, cls=kit.CRYSTAL, bone="head", seg=8, rings=5)
    bun = V(0, HC.y + 0.06, -0.12)
    for i in range(4):
        b.ball(bun + V(0.0, -0.034 - i * 0.017, -0.03), 0.006 + 0.002 * (i == 3), PEARL, cls=kit.CRYSTAL, bone="head", seg=8, rings=5)


person.export_person("characters/shui_lian.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "eye_size": 1.34, "jaw": 0.86, "lip": "d88a90", "hair_len": 0.7, "build": 0.94,
    # race (art/lib/race.py): the Jiaoren's fins and scales
    "ears": "fin", "ear_col": "3aa89e", "ear_inner": "dcfaf4", "scales": "3a9e9a",
    # signature props (art/lib/accessory.py) and the pearls in her hair
    "props": [("shuttle", {"col": "e8dcc4"})], "extra": pearls,
    "robe": "4e9c88", "trim": "f2f0ea", "inner": "fafaf6", "sash": "d8d0ec", "hair": "16303c", "hair_style": "long",
    "eyes": "2a9a9a", "pin": PEARL, "jade": "eaf0f4", "embroidery": "f0f0f4", "collar2": "8ac8b8", "sheen": (0.2, 0.42, 0.45),
})
