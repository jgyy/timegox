"""Horse-Face, Ox-Head's brother and fellow runner of the Ten Courts (Part VI): a long equine head
with a black mane and lateral eyes over the same court livery; carries a halberd.  Cloth is tinted
per enemy.  1.4x scale.
Run: blender --background --python art/monsters/horseface.py  ->  assets/monsters/horseface.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import person  # noqa: E402
from creature import person_die  # noqa: E402
import anatomy as A  # noqa: E402
from kit import METAL, V  # noqa: E402

kit.reset()
creature.realtime()
def shackles(b, rig, o, tor):
    """Iron shackles on the wrists with broken chains - the runners drag the dead in chains."""
    for s in (1, -1):
        sd = "L" if s > 0 else "R"
        wr = V(0.27 * s, 0.95, 0.03)
        b.lathe(wr, [(0.05, -0.025), (0.055, 0.0), (0.05, 0.025)], "3a3a44", cls=METAL, bone="forearm." + sd, seg=14, cap_bottom=False, cap_top=False)
        A.chain(b, wr + V(0.0, -0.06, -0.02), V(0.0, -0.07, -0.02), 5, "forearm." + sd, col="4a4a54", r=0.022)


person.export_person("monsters/horseface.glb", {
    # iron shackles and chains, leather bracers, clawed hands
    "extra": shackles, "bracers": "3a2a20", "claws": True, "claw_col": "2a2020",
    "robe": "a0a0a0", "trim": "e0e0e0", "inner": "707070", "sash": "4a4a4a", "pants": "505050", "boots": "2a2a2a",
    "sleeve": "909090", "beast_head": "horse", "head_col": "6a4030", "muzzle_col": "a08070", "hair": "141010", "eyes": "ffb020",
    "armor": True, "metal": "3a3440", "halberd": True, "tint_cloth": True, "scale": 1.4, "head_scale": 1.0,
    "embroidery": "c8a040", "folds": 10,
}, clips=dict(person.CLIPS, die=(1.2, person_die(person.clip_idle))))
