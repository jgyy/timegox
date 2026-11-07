"""Tome: the Jade Ledger and the Court's living record-books.  A great jade-bound book floating
open, the top leaves of each page block curling up and riffling apart, a row of paper teeth
along each fore-edge so the boards bite when they slam shut, its pages fanning and flapping on
their own bones, an eye set into the clasp of its cover,
bookmarks of red silk trailing beneath, brass corner guards, chains hanging from its spine and
glowing script hovering over the open pages.  Tinted by the game per enemy; pages, script and the
eye keep their colours.
The boards are carved with a raised border and a gilt cloud-scroll, the spine is banded with
raised cords, the page edges are ruled and gilt, leather straps hold the clasp, the chains are
interlocking links, and every loose page carries lines of script.
Run: blender --background --python art/monsters/tome.py  ->  assets/monsters/tome.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from creature import chain_rig, wave_chain, zero_pose  # noqa: E402
from mathutils import Matrix  # noqa: E402
from kit import CLOTH, MAT_GLOW, MAT_PLAIN, METAL, STONE, V, Builder, Rig, env  # noqa: E402
from creature import add, smooth  # noqa: E402

kit.reset()
creature.realtime()
Y = 1.6
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("spine", (0, Y - 0.1, -0.05), (0, Y + 0.1, -0.05), "root")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("cover." + sd, (0.0, Y, -0.05), (0.55 * s, Y + 0.12, 0.05), "spine")
for k in range(5):
    a = (k - 2) * 0.25
    r.bone("page%d" % k, (0, Y + 0.02, -0.05), (math.sin(a) * 0.5, Y + 0.15 + math.cos(a) * 0.05, 0.0), "spine")
marks = chain_rig(r, "mark", [V(0, Y - 0.05, 0.0), V(0.02, Y - 0.35, 0.05), V(0.0, Y - 0.65, 0.08)], "spine")
b = Builder("tome")


def slab(sd, s):
    """One cover board: a thick superquad with brass corner guards and a jade inlay."""
    c = V(0.28 * s, Y + 0.06, 0.0)
    b.superquad(c, (0.28, 0.035, 0.38), (0.75, 0.75, 0.75), e=0.25, cls=STONE, bone="cover." + sd, tint=1.0, rot=(0, 0, -0.22 * s), seg=16, rings=8)
    for zz in (-1, 1):
        b.superquad(c + V(0.24 * s, 0.0, 0.33 * zz), (0.05, 0.045, 0.06), "d8b050", e=0.3, cls=METAL, bone="cover." + sd, rot=(0, 0, -0.22 * s))
    b.superquad(c + V(0, -0.035, 0), (0.14, 0.012, 0.2), (1.0, 1.0, 1.0), e=0.3, cls=STONE, bone="cover." + sd, tint=1.0, rot=(0, 0, -0.22 * s))


for s, sd in ((1, "L"), (-1, "R")):
    slab(sd, s)
    # the block of pages resting on the cover, and the top leaves of it curving up from the
    # spine and riffling apart towards the fore-edge
    b.superquad(V(0.25 * s, Y + 0.1, 0.0), (0.24, 0.04, 0.35), "f4ecd8", e=0.3, cls=CLOTH, bone="cover." + sd, rot=(0, 0, -0.22 * s), seg=12, rings=6)
    rotc = Matrix.Rotation(-0.22 * s, 3, "Z")
    for k in range(5):
        lift = 0.03 + 0.012 * k
        rows = []
        for j in range(6):
            u = j / 5
            x = (0.02 + 0.45 * u) * s
            y = lift * math.sin(math.pi * 0.5 * u) + 0.012 * k * u * u
            rows.append([V(0.03 * s, Y + 0.075, 0) + rotc @ V(x, y, zz * (0.335 - 0.004 * k)) for zz in (-1.0, 0.0, 1.0)])
        b.sheet(rows, "faf2e0", cls=CLOTH, bone="cover." + sd, cols=["f6eedc"] * 5 + ["d8c8a0"], thickness=0.003)
    # paper teeth along the fore-edge: when the boards slam shut they bite
    for k in range(9):
        zz = -0.3 + k * 0.075
        q = V(0.03 * s, Y + 0.075, 0) + rotc @ V(0.46 * s, 0.07, zz)
        b.cone(q, 0.022, 0.07 + 0.02 * (k % 2), "f8f0dc", cls=CLOTH, bone="cover." + sd, seg=5, rot=(0, 0, 0.3 * s))
b.tube([V(0, Y - 0.04, -0.4), V(0, Y - 0.06, 0.4)], [0.06, 0.06], (0.6, 0.6, 0.6), cls=STONE, bone="spine", tint=1.0, seg=10)
# loose pages fanning in the middle
for k in range(5):
    a = (k - 2) * 0.25
    root = V(0, Y + 0.12, -0.05)
    tip = V(math.sin(a) * 0.45, Y + 0.18 + math.cos(a) * 0.05, -0.05)
    rows = [[root + V(0, 0, -0.32), root + V(0, 0, 0.32)], [root.lerp(tip, 0.5) + V(0, 0.06, -0.32), root.lerp(tip, 0.5) + V(0, 0.06, 0.32)], [tip + V(0, 0, -0.32), tip + V(0, 0, 0.32)]]
    b.sheet(rows, "fbf4e0", cls=CLOTH, bone="page%d" % k, cols=["fbf4e0", "f4ead0", "ece0c0"])
# the eye in the clasp
b.ellipsoid(V(0, Y - 0.02, 0.42), (0.1, 0.1, 0.05), "d8b050", cls=METAL, bone="spine", seg=14, rings=8)
b.eye(V(0, Y - 0.02, 0.46), 0.07, "40ffb0", side=1, bone="spine", rot_y=0.0, h=1.0, glow=True, slit=True, accent=True)
# glowing script hovering above the pages
for k in range(14):
    a = (k / 13 - 0.5) * 1.6
    c = V(math.sin(a) * 0.38, Y + 0.38 + 0.08 * math.cos(k * 1.7), math.cos(a) * 0.08 - 0.05)
    b.superquad(c, (0.03, 0.05, 0.005) if k % 2 else (0.05, 0.02, 0.005), "80ffd0", e=0.3, cls=CLOTH, bone="spine", mat=MAT_GLOW)
# red silk bookmarks and hanging chains
pts = [r.head(n) for n in marks] + [r.tail(marks[-1])]
for dx in (-0.06, 0.06):
    b.ribbon([p + V(dx, 0, 0) for p in pts], [0.03, 0.03, 0.02, 0.01], (1, 0, 0), "c02a2a", bones=[marks[0], marks[0], marks[1], marks[1]], col_end="ff6050")
for s in (1, -1):
    for k in range(6):
        c = V(0.12 * s, Y - 0.12 - k * 0.08, -0.38)
        b.lathe(c, [(0.025, -0.022), (0.035, 0.0), (0.025, 0.022)], "6a6a78", cls=METAL, bone="spine", seg=8, rot=(0, 0, (k % 2) * 1.57), cap_bottom=False, cap_top=False)
b.cur_pal = 1.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# the cover is carved: a raised border and a cloud-scroll medallion on each board, the spine
# banded with raised cords, the page block's edges ruled in fine lines and gilt
for s, sd in ((1, "L"), (-1, "R")):
    rot = Matrix.Rotation(-0.22 * s, 3, "Z")
    c = V(0.28 * s, Y + 0.06, 0.0)
    border = []
    for i in range(21):
        t = i / 20 * 4
        side = int(t) % 4
        u = t - int(t)
        corners = [V(-0.24, 0, -0.34), V(0.24, 0, -0.34), V(0.24, 0, 0.34), V(-0.24, 0, 0.34), V(-0.24, 0, -0.34)]
        q = corners[side].lerp(corners[side + 1], u)
        border.append(c + rot @ (q + V(0, -0.036, 0)))
    b.tube(border, [0.01] * 21, (0.9, 0.9, 0.9), cls=STONE, bone="cover." + sd, tint=1.0, seg=5, cap0=False, cap1=False)
    scroll = []
    for i in range(30):
        a = i / 29 * 4 * math.pi
        rr = 0.02 + 0.08 * i / 29
        scroll.append(c + rot @ V(math.cos(a) * rr, -0.04, math.sin(a) * rr * 1.2))
    b.tube(scroll, [0.008] * 30, "d8b050", cls=METAL, bone="cover." + sd, seg=5)
    for k in range(8):
        y = Y + 0.065 + k * 0.009
        b.tube([V(0.48 * s, y - 0.02 + 0.0, -0.33), V(0.48 * s, y - 0.02, 0.33)], [0.002, 0.002], "c8a060" if k % 3 == 0 else "b8a888", cls=CLOTH, bone="cover." + sd, seg=3, mat=MAT_PLAIN)
for k in range(4):
    z = -0.3 + k * 0.2
    b.tube([V(0, Y - 0.05, z - 0.012), V(0, Y - 0.05, z + 0.012)], [0.07, 0.07], "d8b050", cls=METAL, bone="spine", seg=12, cap0=False, cap1=False)
# leather clasp straps holding the eye, and proper interlocking chains from the spine
for s in (1, -1):
    b.ribbon([V(0.08 * s, Y - 0.02, 0.4), V(0.22 * s, Y + 0.02, 0.38), V(0.4 * s, Y + 0.06, 0.34)], [0.03, 0.03, 0.028], (0, 1, 0), "6a3a20", bone="spine", col_end="5a3018")
    A.chain(b, V(0.12 * s, Y - 0.12, -0.38), V(0.0, -0.075, -0.01), 7, "spine", col="6a6a78", r=0.026)
# runes on every loose page
for k in range(5):
    a = (k - 2) * 0.25
    root = V(0, Y + 0.12, -0.05)
    tip = V(math.sin(a) * 0.45, Y + 0.18 + math.cos(a) * 0.05, -0.05)
    for j in range(3):
        q = root.lerp(tip, 0.35 + 0.2 * j) + V(0, 0.05, -0.15 + 0.15 * j)
        b.tube([q + V(0, 0, -0.04), q + V(0, 0.0, 0.04)], [0.005, 0.005], "2a2018", cls=CLOTH, bone="page%d" % k, seg=3, mat=MAT_PLAIN)


T_IDLE = 2.8


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    p["spine"] = ((math.sin(t * w) * 0.1, math.sin(t * w + 0.8) * 0.25, 0), (0, math.sin(t * w) * 0.1, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["cover." + sd] = ((0, 0, (0.05 + 0.08 * math.sin(t * w * 2)) * s), (0, 0, 0))
    for k in range(5):
        p["page%d" % k] = ((0, 0, math.sin(t * w * 3 + k) * 0.25), (0, 0, 0))
    wave_chain(p, marks, t, w * 2, 0.15, axis=0)
    return p


def attack(t):
    k = t / 0.55
    e = env(k)
    slam = math.sin(min(1.0, k * 1.6) * math.pi)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0.1 * slam, 0.5 * slam))
    for sd, s in (("L", 1), ("R", -1)):
        p["cover." + sd] = ((0, 0, (0.4 * e - 1.2 * slam) * s), (0, 0, 0))
    for kk in range(5):
        p["page%d" % kk] = ((0, 0, math.sin(t * 30 + kk) * 0.6 * e), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["spine"] = ((-0.4 * e, 0, 0.3 * e), (0, 0, -0.15 * e))
    for kk in range(5):
        p["page%d" % kk] = ((0, 0, math.sin(t * 26 + kk) * 0.8 * e), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    p["spine"] = ((-0.3 * e, t * 4.0, 0), (0, 0.3 * e, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["cover." + sd] = ((0, 0, 0.6 * e * s), (0, 0, 0))
    for kk in range(5):
        p["page%d" % kk] = ((0, 0, (kk - 2) * 0.5 * e), (0, 0, 0))
    return p


T_WALK = 1.0


def walk(t):
    """Flies on its covers like wings, pages riffling, leaning into the flight."""
    w = 2 * math.pi / T_WALK
    p = idle(t * T_IDLE / T_WALK)
    add(p, "spine", (0.25, 0, 0), (0, 0.06 * math.sin(t * w * 2), 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "cover." + sd, (0, 0, s_ * (0.15 + 0.35 * math.sin(t * w * 2))))
    return p


def die(t):
    """Snaps shut and drops to the ground, landing flat."""
    k = min(1.0, t / 1.2)
    shut = smooth(0.0, 0.25, k)
    f = smooth(0.2, 0.75, k) ** 1.5
    p = idle(0.0)
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "cover." + sd, (0, 0, s_ * 1.25 * shut))
    for kk in range(5):
        add(p, "page%d" % kk, (0, 0, (kk - 2) * 0.1 * shut))
    add(p, "spine", (0.0, 0.6 * f, 1.4 * f), (0, -2.4 * f + 0.05 * math.sin(math.pi * smooth(0.72, 0.9, k)), 0))
    return p

kit.scale_asset(b, r, 1.6)
print("[art] tome: %d triangles" % b.tri_count())
# a book has a binding, not a coat: its leather keeps its own tooling (no coat split)
kit.finish_rigged(b, r, "monsters/tome.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, coat=False, samples=12, dist=0.25, strength=0.45)
