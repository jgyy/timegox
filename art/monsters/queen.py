"""Queen (new in Part VIII): Xiwangmu, the Queen Mother of the West, as the Classic of Mountains and
Seas describes her - a woman with a tiger's teeth and a leopard's tail, her hair grey and loose
under the sheng headdress - enthroned beside the Jasper Pool with a staff of peach wood.
Built from the character library (fem, aged, tall) with the sheng crown, tiger fangs, clawed
hands, a spotted leopard's tail, a cape of cloud brocade and a peach-wood staff.  Cloth is
tinted per enemy; skin, jade, gold and fur keep their colours.
Run: blender --background --python art/monsters/queen.py  ->  assets/monsters/queen.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import garment as G  # noqa: E402
import person  # noqa: E402
from creature import person_die  # noqa: E402
from kit import SKIN, V  # noqa: E402
from sculpt import catmull  # noqa: E402

kit.reset()
creature.realtime()


def leopard(b, rig, o, tor):
    """The sheng crown and a leopard's tail curling out from under the robe, spotted with
    rosettes and dark-tipped."""
    G.sheng_crown(b, 1.9)
    pts = catmull([V(0, 0.95, -0.15), V(0.05, 0.7, -0.35), V(0.25, 0.45, -0.48), V(0.45, 0.3, -0.42), V(0.55, 0.32, -0.25)], 4)
    bones = [{"hips": 1.0 - min(1.0, k / 4)} | ({"robe_b": min(1.0, k / 4)} if k else {}) for k in range(len(pts))]
    radii = [0.05 - 0.025 * k / (len(pts) - 1) for k in range(len(pts))]
    cols = []
    for k in range(len(pts)):
        cols.append("2a2018" if (k % 3 == 0 or k > len(pts) - 3) else "d8a050")
    b.tube(pts, radii, "d8a050", cls=SKIN, bones=bones, seg=10, cols=cols)
    for k in range(1, len(pts) - 2, 2):
        for a in (0.0, 2.1, 4.2):
            q = pts[k] + V(math.cos(a + k) * radii[k] * 0.95, math.sin(a + k) * radii[k] * 0.95, 0.0)
            b.ball(q, radii[k] * 0.28, "3a2818", cls=SKIN, bone=bones[k], seg=6, rings=4)


person.export_person("monsters/queen.glb", {
    # face and build: an ageless, terrible queen
    "brocade": "waves", "brocade_col": "f0f0f0", "fem": True, "age": 0.55, "build": 1.05, "brow": 1.2, "eye_size": 1.1, "lip": "a04050", "slit_eyes": True, "glow_eyes": True,
    "fangs": True, "claws": True, "claw_col": "e8d8b0", "claw_len": 0.06, "extra": leopard, "props": [("peach_branch", {"wood": "5a3020"})], "pose": "hold_l",
    "robe": "d8d8d8", "trim": "f0e0a0", "inner": "f4f0e8", "sash": "a0a0a0", "pants": "8a8a8a", "boots": "3a3a3a", "sleeve": "c8c8c8",
    "hair": "a8a4b0", "hair_style": "long", "hair_len": 0.7, "eyes": "f0b020", "cape": "c0c0c0", "staff": True, "staff_gem": "ff90b0",
    "embroidery": "f0d070", "collar2": "b0b0b0", "tint_cloth": True, "scale": 1.3, "flare": 1.2,
}, clips=dict(person.CLIPS, die=(1.2, person_die(person.clip_idle))))
