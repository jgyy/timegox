"""Signature props for the characters: the things their stories put in their hands.

Each function adds one prop to a Builder, weighted to the bone that carries it (a hand, the hips,
the chest), positioned for the character's rest pose.  A prop held in a hand is built where the
hand is when the arm is posed by ``person.POSES`` (``"hold_l"``: left forearm raised in front of
the body; ``"hold_both"``: both hands together in front of the chest), so the pose and the prop
agree in every clip.

Props: fly-whisk, gourd, lantern, oar, fishing rod and creel, a cormorant on the shoulder,
teapot, soup bowl, ledger and brush, scroll, smith's hammer and apron, folding fan, bamboo flute,
herdsman's whip, weaving shuttle, mulberry basket, hand drum, spectacles, abacus, peach branch,
dragon pearl, five-colour stone, hoe, cowherd's straw cape, magpie-feather cloak, star crown and
floating spirit swords.
"""

import math

from garment import WRI
from kit import CLOTH, CRYSTAL, FOLIAGE, HAIR, MAT_GLOW, MAT_PLAIN, METAL, SKIN, STONE, WOOD, V, darken, lighten, mix
from sculpt import bezier, strand

# where the hands are in the two holding poses (rest-pose space; the prop rides the hand bone)
HAND_R = WRI * V(-1, 1, 1) + V(-0.004, -0.075, 0.02)
HAND_L = WRI + V(0.004, -0.075, 0.02)


def held_l():
    """The left hand at rest, where a prop held in it is built (the hold pose moves the bone)."""
    return V(HAND_L)


# ---------------------------------------------------------------- belt and back
def gourd(b, col="d8a048", side=1, cord="b03020"):
    """A calabash hanging at the hip from a red cord: two bulbs, a waist tied with cord, a stopper."""
    c = V(0.2 * side, 0.86, 0.06)
    bone = {"hips": 0.4, "robe_l" if side > 0 else "robe_r": 0.6}
    b.lathe(c, [(0.0001, -0.08), (0.055, -0.06), (0.062, -0.03), (0.045, 0.0), (0.025, 0.02), (0.038, 0.045), (0.035, 0.07), (0.012, 0.09)], col, cls=WOOD, bone=bone, seg=16, col_top=lighten(col, 0.15))
    b.tube([c + V(0, 0.01, 0) + V(math.sin(a) * 0.027, 0, math.cos(a) * 0.027) for a in [i / 12 * 2 * math.pi for i in range(13)]], [0.005] * 13, cord, cls=CLOTH, bone=bone, seg=4, cap0=False, cap1=False)
    b.tube([c + V(0, 0.09, 0), c + V(0, 0.11, 0)], [0.012, 0.01], "6a4020", cls=WOOD, bone=bone, seg=8)
    strand(b, [c + V(0, 0.02, 0), V(0.18 * side, 0.97, 0.1)], 0.004, 0.004, cord, cls=CLOTH, bone=bone, seg=4, per=2)
    for k in range(4):
        strand(b, [c + V(0.005 * k, 0.01, 0.025), c + V(0.01 * k, -0.06, 0.03)], 0.003, 0.002, cord, cls=CLOTH, bone=bone, seg=3, per=2)


def apron(b, col="6a4a30", strap="3a2818"):
    """A leather smith's apron hanging from the neck to the knees, scorched at the hem."""
    rows = []
    cols = []
    for j in range(7):
        t = j / 6
        y = 1.42 - t * 0.98
        half = 0.13 + 0.07 * t
        z = 0.16 + 0.04 * t
        rows.append([V(-half, y, z - 0.02), V(0, y, z + 0.01), V(half, y, z - 0.02)])
        cols.append(mix(col, darken(col, 0.45), max(0.0, (t - 0.75) * 4.0)))
    bones = [{"chest": 1.0}, {"chest": 0.6, "spine": 0.4}, {"spine": 1.0}, {"hips": 1.0}, {"hips": 0.5, "robe_f": 0.5}, {"robe_f": 1.0}, {"robe_f": 1.0}]
    b.sheet(rows, col, bones=bones, cols=cols, thickness=0.01)
    for s in (1, -1):
        b.tube([V(0.12 * s, 1.42, 0.14), V(0.08 * s, 1.52, 0.06), V(0.0, 1.55, -0.05)], [0.01, 0.01, 0.01], strap, cls=CLOTH, bone="chest", seg=5)
        b.tube([V(0.15 * s, 1.08, 0.14), V(0.2 * s, 1.06, 0.0), V(0.12 * s, 1.05, -0.13)], [0.008] * 3, strap, cls=CLOTH, bone="hips", seg=5)


def straw_cape(b, col="b8a060"):
    """A cowherd's rain cape of straw (suoyi): layered fringes of straw over the shoulders."""
    for row in range(3):
        n = 26
        for i in range(n):
            a = math.pi * 0.25 + (i / (n - 1)) * math.pi * 1.5
            top = V(math.sin(a) * (0.17 + 0.05 * row), 1.48 - row * 0.12, math.cos(a) * (0.14 + 0.04 * row) - 0.01)
            out = V(math.sin(a), 0, math.cos(a))
            tip = top + out * 0.06 + V(0, -0.22, 0)
            c = mix(col, darken(col, 0.25), (i % 3) / 3)
            bone = {"chest": 1.0} if row < 2 else {"chest": 0.6, "spine": 0.4}
            strand(b, [top, top.lerp(tip, 0.5) + out * 0.02, tip], 0.014, 0.003, c, col_tip=lighten(c, 0.15), cls=HAIR, bone=bone, flat=0.4, seg=4, per=2, mat=MAT_PLAIN)


def feather_cloak(b, col="1a1a24", white="f0f0f8", sheen="3a5ab0"):
    """A magpie-feather cloak: black feathers with a blue sheen, a white band at the shoulders."""
    for row in range(5):
        n = 14 + row * 2
        for i in range(n):
            a = math.pi * 0.35 + (i / (n - 1)) * math.pi * 1.3
            y = 1.46 - row * 0.2
            rr = 0.2 + 0.04 * row
            root = V(math.sin(a) * rr, y, math.cos(a) * rr * 0.8 - 0.06 - 0.02 * row)
            out = V(math.sin(a), 0, math.cos(a))
            tip = root + out * 0.04 + V(0, -0.26, -0.02)
            c = white if row == 0 else (sheen if (i + row) % 4 == 0 else col)
            bones = {"chest": 1.0} if row < 2 else ({"cape": 1.0} if row < 4 else {"cape2": 1.0})
            b.leaf(root, tip, 0.05, c, side=V(math.cos(a), 0, -math.sin(a)), cls=HAIR, bone=bones, col_tip=lighten(c, 0.1), curl=0.08)


def spirit_swords(b, n=5, col="a0d8ff"):
    """Spectral swords floating in a fan behind the shoulders."""
    for k in range(n):
        a = (k / (n - 1) - 0.5) * 2.2
        base = V(math.sin(a) * 0.35, 1.25 + math.cos(a) * 0.25, -0.25)
        tip = base + V(math.sin(a) * 0.4, math.cos(a) * 0.45, -0.05)
        d = (tip - base).normalized()
        b.tube([base, base.lerp(tip, 0.9), tip], [(0.02, 0.005), (0.018, 0.005), (0.002, 0.001)], col, cls=CRYSTAL, bone="chest", seg=6, mat=MAT_GLOW, up=(0, 0, 1))
        b.tube([base - d * 0.02 + V(0.05, 0, 0), base - d * 0.02 - V(0.05, 0, 0)], [0.008, 0.008], lighten(col, 0.3), cls=CRYSTAL, bone="chest", seg=5, mat=MAT_GLOW)
        b.tube([base - d * 0.03, base - d * 0.12], [0.009, 0.009], lighten(col, 0.2), cls=CRYSTAL, bone="chest", seg=5, mat=MAT_GLOW)


# ---------------------------------------------------------------- held in the right hand
def fly_whisk(b, handle="8a5a30", hair="f4f4f0", side=-1):
    """The Taoist fly-whisk (fuchen): a short lacquered handle and a long fall of white horsehair.
    side=-1 in the right hand, +1 in the left."""
    h = HAND_R if side < 0 else HAND_L
    hb = "hand.R" if side < 0 else "hand.L"
    b.tube([h + V(0, 0.08, 0.02), h + V(0, -0.1, 0.03)], [0.012, 0.011], handle, cls=WOOD, bone=hb, seg=8)
    b.ball(h + V(0, 0.09, 0.02), 0.016, "d8b050", cls=METAL, bone=hb, seg=8, rings=5)
    top = h + V(0, -0.1, 0.03)
    for k in range(14):
        a = k / 14 * 2 * math.pi
        out = V(math.cos(a) * 0.012, 0, math.sin(a) * 0.012)
        strand(b, [top + out, top + out * 2 + V(0.02, -0.15, 0.04), top + out * 3 + V(0.05, -0.32, 0.03)], 0.008, 0.002, hair, cls=HAIR, bone=hb, seg=4, per=3, mat=MAT_PLAIN)


def oar(b, col="7a5a38"):
    """A ferryman's long sculling oar, held upright."""
    h = HAND_R
    b.tube([h + V(0, -0.85, 0.02), h + V(0, 0.75, 0.02)], [0.02, 0.018], col, cls=WOOD, bone="hand.R", seg=8)
    blade = h + V(0, -0.85, 0.02)
    b.superquad(blade + V(0, -0.22, 0), (0.07, 0.24, 0.012), darken(col, 0.15), e=0.3, cls=WOOD, bone="hand.R", seg=10, rings=6)
    b.tube([h + V(0, 0.7, 0.02), h + V(0.12, 0.72, 0.02)], [0.015, 0.015], col, cls=WOOD, bone="hand.R", seg=6)


def fishing_rod(b, col="a08a50"):
    """A bamboo rod over the shoulder with a line and a float, a creel on the hip."""
    h = HAND_R
    pts = [h + V(0, -0.05, -0.05), h + V(0, 0.5, -0.3), h + V(0, 1.0, -0.45), h + V(0.05, 1.4, -0.4)]
    strand(b, pts, 0.014, 0.004, col, cls=WOOD, bone="hand.R", seg=6, per=4)
    for k in range(4):
        q = pts[0].lerp(pts[2], 0.2 + k * 0.25)
        b.tube([q + V(0, 0.006, 0), q - V(0, 0.006, 0)], [0.016 - k * 0.002] * 2, darken(col, 0.25), cls=WOOD, bone="hand.R", seg=6, cap0=False, cap1=False)
    line = bezier(pts[-1], pts[-1] + V(0.05, -0.2, 0.2), pts[-1] + V(0.1, -0.8, 0.3), pts[-1] + V(0.12, -1.0, 0.3), 8)
    b.tube(line, [0.002] * len(line), "e8e8e8", cls=HAIR, bone="hand.R", seg=3, mat=MAT_PLAIN)
    b.ball(line[-1], 0.018, "e04030", cls=WOOD, bone="hand.R", seg=8, rings=5)
    c = V(0.21, 0.9, -0.06)
    b.lathe(c, [(0.07, -0.08), (0.09, -0.02), (0.085, 0.05), (0.06, 0.08)], "b89a60", cls=WOOD, bone={"hips": 0.5, "robe_l": 0.5}, seg=14, folds=(14, 0.05, 0.0), cap_top=False)


def hammer(b, head="5a5a64", handle="6a4a2a"):
    """A smith's cross-peen hammer, held head-down at the side."""
    h = HAND_R
    b.tube([h + V(0, 0.08, 0.02), h + V(0, -0.3, 0.03)], [0.016, 0.015], handle, cls=WOOD, bone="hand.R", seg=8)
    hd = h + V(0, -0.32, 0.03)
    b.superquad(hd, (0.03, 0.035, 0.07), head, e=0.3, cls=METAL, bone="hand.R", seg=10, rings=6)
    b.superquad(hd + V(0, 0, -0.08), (0.03, 0.012, 0.02), head, e=0.4, cls=METAL, bone="hand.R", seg=8, rings=5)


def hoe(b, col="7a5a38", blade="6a6a70"):
    """A farmer's hoe on the shoulder."""
    h = HAND_R
    b.tube([h + V(0, -0.1, 0.0), h + V(0, 0.9, -0.3)], [0.016, 0.016], col, cls=WOOD, bone="hand.R", seg=8)
    top = h + V(0, 0.9, -0.3)
    b.superquad(top + V(0, -0.06, 0.08), (0.08, 0.05, 0.008), blade, e=0.3, cls=METAL, bone="hand.R", seg=10, rings=5, rot=(0.4, 0, 0))


def broom(b, col="a08a50", twigs="c8a868"):
    """A bamboo broom held upright: a long handle and a fan of bound twigs (Lin Feng swept the sect's
    steps with one for three years; now someone else does)."""
    h = HAND_R
    b.tube([h + V(0, 0.5, 0.0), h + V(0, -0.58, 0.07)], [0.014, 0.015], col, cls=WOOD, bone="hand.R", seg=8)
    base = h + V(0, -0.58, 0.07)
    b.tube([base + V(0, 0.03, 0), base - V(0, 0.04, 0)], [0.024, 0.024], darken(col, 0.3), cls=WOOD, bone="hand.R", seg=8)
    for k in range(13):
        a = (k / 12 - 0.5) * 1.3
        tip = base + V(math.sin(a) * 0.17, -0.22 + abs(a) * 0.04, math.cos(a) * 0.04 + 0.03)
        b.tube([base, base.lerp(tip, 0.5) + V(0, 0, 0.01), tip], [0.008, 0.006, 0.002], twigs if k % 2 else darken(twigs, 0.15), cls=WOOD, bone="hand.R", seg=4)


def whip(b, col="5a3a20"):
    """A herdsman's short whip: a bamboo stock and a plaited lash looping down."""
    h = HAND_R
    b.tube([h + V(0, 0.06, 0.02), h + V(0, -0.22, 0.06)], [0.012, 0.01], "a08a50", cls=WOOD, bone="hand.R", seg=6)
    lash = bezier(h + V(0, -0.22, 0.06), h + V(0.1, -0.4, 0.15), h + V(0.05, -0.6, 0.0), h + V(-0.05, -0.5, -0.05), 10)
    b.tube(lash, [0.006 - 0.0004 * i for i in range(len(lash))], col, cls=CLOTH, bone="hand.R", seg=4)


def folding_fan(b, col="f0e8d8", ribs="5a3a20", painted="3a6a8a"):
    """A folding fan, half open, with ribs and a painted mountain."""
    h = HAND_R + V(0, -0.02, 0.04)
    n = 9
    for i in range(n):
        a = -0.9 + 1.8 * i / (n - 1)
        d = V(math.sin(a) * 0.0, math.cos(a), math.sin(a)).normalized()
        b.tube([h, h + d * 0.2], [0.003, 0.003], ribs, cls=WOOD, bone="hand.R", seg=3)
    rows = []
    for j in range(2):
        rr = 0.08 + 0.12 * j
        rows.append([h + V(0, math.cos(-0.9 + 1.8 * i / 8), math.sin(-0.9 + 1.8 * i / 8)) * rr + V(0.004, 0, 0) for i in range(9)])
    b.sheet(rows, col, cls=CLOTH, bone="hand.R", cols=[col, mix(col, painted, 0.35)], thickness=0.004)


def scroll(b, paper="f0e4c0", rod="7a4a28"):
    """A rolled scroll held across the body in the right hand."""
    h = HAND_R + V(0.02, 0.0, 0.05)
    b.tube([h + V(-0.12, 0, 0), h + V(0.12, 0, 0)], [0.028, 0.028], paper, cls=CLOTH, bone="hand.R", seg=12)
    for s in (1, -1):
        b.tube([h + V(0.12 * s, 0, 0), h + V(0.15 * s, 0, 0)], [0.012, 0.012], rod, cls=WOOD, bone="hand.R", seg=8)
        b.ball(h + V(0.155 * s, 0, 0), 0.014, "d8b050", cls=METAL, bone="hand.R", seg=8, rings=5)
    b.tube([h + V(-0.02, -0.028, 0), h + V(-0.03, -0.12, 0.01)], [0.004, 0.003], "c02020", cls=CLOTH, bone="hand.R", seg=4)


def brush(b, col="3a2a1a"):
    """A calligraphy brush in the right hand, tip wet with ink."""
    h = HAND_R
    b.tube([h + V(0, 0.07, 0.03), h + V(0, -0.12, 0.05)], [0.007, 0.007], col, cls=WOOD, bone="hand.R", seg=6)
    b.cone(h + V(0, -0.14, 0.05), 0.012, 0.045, "1a1418", cls=HAIR, bone="hand.R", seg=8, rot=(math.pi, 0, 0))


def shuttle(b, col="c8a060"):
    """A weaver's boat shuttle with a bobbin of thread."""
    h = HAND_R + V(0, -0.02, 0.04)
    b.lathe(h, [(0.0001, -0.11), (0.022, -0.06), (0.026, 0.0), (0.022, 0.06), (0.0001, 0.11)], col, cls=WOOD, bone="hand.R", seg=10, rot=(math.pi / 2, 0, 0), squash=(1.0, 0.6))
    b.tube([h + V(0, 0.0, -0.04), h + V(0, 0.0, 0.04)], [0.014, 0.014], "e04060", cls=CLOTH, bone="hand.R", seg=10)


def drum(b, skin="f0e0c0", rim="8a4a2a"):
    """A shaman's frame drum with a beater, ribbons hanging from the rim."""
    h = HAND_R + V(0, 0.02, 0.06)
    b.lathe(h, [(0.13, -0.02), (0.135, 0.0), (0.13, 0.02)], rim, cls=WOOD, bone="hand.R", seg=24, rot=(math.pi / 2, 0, 0), cap_bottom=False, cap_top=False)
    b.disc(h, 0.13, skin, cls=SKIN, bone="hand.R", seg=24, rot=(math.pi / 2, 0, 0), col_rim=darken(skin, 0.15), thick=0.01)
    for k in range(5):
        a = math.pi * (1.2 + 0.15 * k)
        q = h + V(math.cos(a) * 0.13, math.sin(a) * 0.13, 0)
        b.ribbon([q, q + V(0.0, -0.12, 0.0), q + V(0.01, -0.22, 0.0)], [0.012, 0.012, 0.004], (1, 0, 0), ("c02020", "2060c0", "e0c020", "20a040", "f0f0f0")[k], bone="hand.R")


# ---------------------------------------------------------------- held in the left hand (hold_l pose)
def lantern(b, col="f0a040", frame="5a3a20", glow="ffd070"):
    """A paper lantern hanging from a short pole in the left hand, glowing inside."""
    h = held_l()
    b.tube([h + V(0, 0.0, 0.0), h + V(0, 0.0, 0.25)], [0.008, 0.008], frame, cls=WOOD, bone="hand.L", seg=6)
    top = h + V(0, -0.02, 0.25)
    b.tube([top, top + V(0, -0.08, 0)], [0.002, 0.002], frame, cls=CLOTH, bone="hand.L", seg=3)
    c = top + V(0, -0.18, 0)
    b.lathe(c, [(0.02, -0.1), (0.07, -0.08), (0.085, 0.0), (0.07, 0.08), (0.02, 0.1)], col, cls=CLOTH, bone="hand.L", seg=16, folds=(10, 0.05, 0.0))
    b.ball(c, 0.05, glow, cls=CRYSTAL, bone="hand.L", seg=10, rings=6, mat=MAT_GLOW)
    for y in (-0.1, 0.1):
        b.lathe(c + V(0, y, 0), [(0.03, -0.01), (0.03, 0.01)], frame, cls=WOOD, bone="hand.L", seg=12)
    b.tube([c + V(0, -0.11, 0), c + V(0, -0.2, 0)], [0.006, 0.002], "c02020", cls=CLOTH, bone="hand.L", seg=4)


def bowl(b, col="f0f0e8", soup="c09060"):
    """A bowl held in both hands at the chest (hold_both pose): Meng Po's soup of forgetting."""
    c = V(0.0, 1.16, 0.3)
    bone = "chest"
    b.lathe(c, [(0.0001, -0.04), (0.04, -0.045), (0.07, -0.02), (0.085, 0.03), (0.083, 0.035)], col, cls=STONE, bone=bone, seg=20, cap_top=False)
    b.disc(c + V(0, 0.02, 0), 0.078, soup, cls=CRYSTAL, bone=bone, seg=20, thick=0.004)
    b.tube([c + V(0.087 * math.sin(a), 0.032, 0.087 * math.cos(a)) for a in [i / 20 * 2 * math.pi for i in range(21)]], [0.004] * 21, "3a6ab0", cls=STONE, bone=bone, seg=4, cap0=False, cap1=False)
    for k in range(3):
        b.tube([c + V(0.02 * k - 0.02, 0.05, 0), c + V(0.03 * k - 0.03, 0.15, 0.01), c + V(0.02 * k - 0.02, 0.25, -0.01)], [0.012, 0.01, 0.002], "f8f8ff", cls=CRYSTAL, bone=bone, seg=5, mat=MAT_GLOW)


def teapot(b, col="8a4a3a"):
    """A Yixing clay teapot held in both hands."""
    c = V(0.0, 1.14, 0.3)
    b.lathe(c, [(0.0001, -0.05), (0.06, -0.045), (0.075, 0.0), (0.06, 0.04), (0.035, 0.05), (0.0001, 0.055)], col, cls=STONE, bone="chest", seg=18)
    b.ball(c + V(0, 0.07, 0), 0.014, darken(col, 0.2), cls=STONE, bone="chest", seg=8, rings=5)
    b.tube([c + V(0.06, 0.0, 0.0), c + V(0.1, 0.03, 0.0), c + V(0.12, 0.06, 0.0)], [0.014, 0.01, 0.008], col, cls=STONE, bone="chest", seg=8)
    b.tube([c + V(-0.06, 0.03, 0.0), c + V(-0.11, 0.03, 0.0), c + V(-0.11, -0.02, 0.0), c + V(-0.065, -0.02, 0.0)], [0.009] * 4, col, cls=STONE, bone="chest", seg=6)
    for k in range(3):
        b.tube([c + V(0.12, 0.07 + 0.04 * k, 0), c + V(0.12 + 0.02 * math.sin(k), 0.11 + 0.04 * k, 0)], [0.008, 0.004], "f8f8ff", cls=CRYSTAL, bone="chest", seg=4, mat=MAT_GLOW)


def ledger(b, cover="2a2a3a", paper="f0e4c0"):
    """A thick stitched ledger held against the chest in the left arm."""
    c = held_l() + V(-0.06, 0.16, 0.02)
    b.superquad(c, (0.1, 0.14, 0.03), cover, e=0.2, cls=CLOTH, bone="hand.L", seg=10, rings=6, rot=(0, 0.3, 0.15))
    b.superquad(c + V(0.004, 0, 0.0), (0.095, 0.135, 0.026), paper, e=0.2, cls=CLOTH, bone="hand.L", seg=10, rings=6, rot=(0, 0.3, 0.15))
    for k in range(4):
        b.ball(c + V(-0.09, -0.1 + k * 0.066, 0.0), 0.006, "c8a040", cls=METAL, bone="hand.L", seg=5, rings=3)


def basket(b, col="b89a60", fill="5a9a3a"):
    """A woven basket on the left arm, heaped with leaves (or buns, or mushrooms)."""
    c = held_l() + V(0.04, -0.06, 0.02)
    v = b.lathe(c, [(0.08, -0.06), (0.11, 0.0), (0.12, 0.06)], col, cls=WOOD, bone="hand.L", seg=20, folds=(20, 0.04, 0.0), cap_top=False)
    b.recolor(v, lambda p: darken(col, 0.2) if math.sin(p.y * 160.0) > 0.4 else None, cls=WOOD)
    b.tube(bezier(c + V(-0.11, 0.06, 0), c + V(-0.11, 0.24, 0), c + V(0.11, 0.24, 0), c + V(0.11, 0.06, 0), 8), [0.008] * 9, col, cls=WOOD, bone="hand.L", seg=5)
    for k in range(9):
        a = k * 2.4
        root = c + V(math.cos(a) * 0.05, 0.06, math.sin(a) * 0.05)
        b.leaf(root, root + V(math.cos(a) * 0.06, 0.05, math.sin(a) * 0.06), 0.04, fill, cls=FOLIAGE, bone="hand.L", col_tip=lighten(fill, 0.2))


def peach_branch(b, wood="5a3a28", bloom="ffb0c8", fruit="ffa070"):
    """A flowering peach branch with two ripe peaches, held in the left hand."""
    h = held_l()
    pts = [h, h + V(0.02, 0.15, 0.04), h + V(-0.03, 0.32, 0.06), h + V(0.0, 0.45, 0.04)]
    strand(b, pts, 0.012, 0.003, wood, cls=WOOD, bone="hand.L", seg=6, per=3)
    for k in range(9):
        q = pts[1].lerp(pts[3], k / 8) + V(0.03 * math.sin(k * 2.0), 0, 0.03 * math.cos(k * 2.0))
        for p5 in range(5):
            a = p5 / 5 * 2 * math.pi
            b.leaf(q, q + V(math.cos(a) * 0.02, 0.008, math.sin(a) * 0.02), 0.012, bloom, cls=FOLIAGE, bone="hand.L", n=3)
        b.ball(q, 0.005, "ffe060", cls=CRYSTAL, bone="hand.L", seg=5, rings=3)
    for k in range(2):
        q = pts[1] + V(0.05 - 0.1 * k, 0.02, 0.03)
        b.ball(q, 0.035, fruit, cls=SKIN, bone="hand.L", seg=12, rings=8, col2=lighten(fruit, 0.3))
        b.leaf(q + V(0, 0.03, 0), q + V(0.03, 0.06, 0.02), 0.015, "4a8a3a", cls=FOLIAGE, bone="hand.L")


def pearl(b, col="d0f8ff"):
    """A dragon pearl floating over the left palm, ringed with a mist of light."""
    c = held_l() + V(0, 0.12, 0.05)
    b.ball(c, 0.04, col, cls=CRYSTAL, bone="hand.L", seg=14, rings=10, mat=MAT_GLOW)
    ring = [c + V(math.cos(a) * 0.07, math.sin(a * 2) * 0.01, math.sin(a) * 0.07) for a in [i / 16 * 2 * math.pi for i in range(17)]]
    b.tube(ring, [0.004] * 17, lighten(col, 0.3), cls=CRYSTAL, bone="hand.L", seg=4, mat=MAT_GLOW, cap0=False, cap1=False)


def five_colour_stone(b):
    """One of Nuwa's five-coloured mending stones, glowing in the left hand."""
    c = held_l() + V(0, 0.08, 0.04)
    cols = ("e04040", "f0c040", "40c060", "4080e0", "f0f0f0")
    for k, col in enumerate(cols):
        a = k / 5 * 2 * math.pi
        b.crystal(c + V(math.cos(a) * 0.02, 0, math.sin(a) * 0.02), 0.022, 0.08, col, bone="hand.L", rot=(0.3 * math.sin(a), 0, 0.3 * math.cos(a)))
    b.ball(c + V(0, 0.02, 0), 0.03, "ffffff", cls=CRYSTAL, bone="hand.L", seg=10, rings=6, mat=MAT_GLOW)


def flute(b, col="a8b060"):
    """A bamboo flute raised in both hands (the cowherd's), with nodes and finger holes."""
    a = V(0.05, 1.64, 0.13)
    c = V(-0.33, 1.56, 0.24)
    b.tube([a, c], [0.011, 0.011], col, cls=WOOD, bone="head", seg=8)
    for k in range(3):
        q = a.lerp(c, 0.2 + 0.3 * k)
        b.tube([q + (c - a).normalized() * 0.004, q - (c - a).normalized() * 0.004], [0.013, 0.013], darken(col, 0.25), cls=WOOD, bone="head", seg=8, cap0=False, cap1=False)
    for k in range(6):
        q = a.lerp(c, 0.45 + 0.08 * k) + V(0, 0.011, 0)
        b.ball(q, 0.003, "2a2018", cls=WOOD, bone="head", seg=4, rings=3, mat=MAT_PLAIN)
    b.ribbon([c, c + V(0.02, -0.08, 0.0), c + V(0.03, -0.16, 0.0)], [0.01, 0.01, 0.003], (1, 0, 0), "c02020", bone="head")


def abacus(b, frame="5a3a20", beads="2a1a14"):
    """An abacus held in the left hand."""
    c = held_l() + V(-0.02, 0.1, 0.06)
    w, h = 0.14, 0.09
    for y in (-h, h):
        b.tube([c + V(-w, y, 0), c + V(w, y, 0)], [0.008, 0.008], frame, cls=WOOD, bone="hand.L", seg=6)
    for x in (-w, w):
        b.tube([c + V(x, -h, 0), c + V(x, h, 0)], [0.008, 0.008], frame, cls=WOOD, bone="hand.L", seg=6)
    b.tube([c + V(-w, 0.03, 0), c + V(w, 0.03, 0)], [0.005, 0.005], frame, cls=WOOD, bone="hand.L", seg=5)
    for i in range(7):
        x = -w + (i + 1) * (2 * w / 8)
        b.tube([c + V(x, -h, 0), c + V(x, h, 0)], [0.002, 0.002], "c8a040", cls=METAL, bone="hand.L", seg=3)
        for k in range(5):
            y = (0.06 if k == 0 else -0.07 + 0.022 * k) + (0.0 if i % 2 else 0.01)
            b.ellipsoid(c + V(x, y, 0), (0.011, 0.007, 0.011), beads, cls=WOOD, bone="hand.L", seg=8, rings=4)


# ---------------------------------------------------------------- on the head and face
def spectacles(b, col="3a3020", y=None):
    """Round reading spectacles on the nose."""
    from face import EYE_X, EYE_Y, HC, RZF
    yy = HC.y + EYE_Y if y is None else y
    for s in (1, -1):
        c = V(EYE_X * s, yy, HC.z + RZF + 0.015)
        ring = [c + V(math.cos(a) * 0.024, math.sin(a) * 0.022, 0) for a in [i / 16 * 2 * math.pi for i in range(17)]]
        b.tube(ring, [0.0022] * 17, col, cls=METAL, bone="head", seg=4, cap0=False, cap1=False)
        b.tube([c + V(0.024 * s, 0, 0), V(0.095 * s, yy + 0.005, HC.z + 0.02)], [0.0018, 0.0018], col, cls=METAL, bone="head", seg=3)
    b.tube([V(0.012, yy + 0.004, HC.z + RZF + 0.016), V(-0.012, yy + 0.004, HC.z + RZF + 0.016)], [0.002, 0.002], col, cls=METAL, bone="head", seg=3)


def star_crown(b, top, col="f0e0a0", star="fff8d0"):
    """A celestial crown of seven stars on fine gold stems (the Weaver Star)."""
    base = V(0, top - 0.03, -0.03)
    b.lathe(base, [(0.07, 0.0), (0.075, 0.015), (0.07, 0.03)], col, cls=METAL, bone="head", seg=20, cap_bottom=False, cap_top=False)
    for k in range(7):
        a = (k / 6 - 0.5) * 2.6
        stem_top = base + V(math.sin(a) * 0.1, 0.1 - 0.02 * abs(a), math.cos(a) * 0.06)
        strand(b, [base + V(math.sin(a) * 0.07, 0.02, math.cos(a) * 0.05), base + V(math.sin(a) * 0.09, 0.06, math.cos(a) * 0.06), stem_top], 0.004, 0.002, col, cls=METAL, bone="head", seg=4, per=3)
        for p5 in range(5):
            ang = p5 / 5 * 2 * math.pi
            b.leaf(stem_top, stem_top + V(math.cos(ang) * 0.02, math.sin(ang) * 0.02, 0.0), 0.006, star, cls=CRYSTAL, bone="head", n=3, mat=MAT_GLOW)


def cormorant(b, col="1a1a20", beak="e0c040"):
    """A fishing cormorant perched on the left shoulder."""
    c = V(0.2, 1.56, -0.02)
    bone = {"chest": 0.4, "upper_arm.L": 0.6}
    b.ellipsoid(c, (0.06, 0.06, 0.11), col, cls=HAIR, bone=bone, seg=14, rings=8, col2=lighten(col, 0.1))
    neck = [c + V(0, 0.03, 0.08), c + V(0, 0.1, 0.12), c + V(0, 0.15, 0.1)]
    b.tube(neck, [0.03, 0.025, 0.022], col, cls=HAIR, bone=bone, seg=8)
    hd = neck[-1] + V(0, 0.02, 0.02)
    b.ball(hd, 0.03, col, cls=HAIR, bone=bone, seg=10, rings=6)
    strand(b, [hd + V(0, -0.005, 0.02), hd + V(0, -0.01, 0.07), hd + V(0, -0.025, 0.09)], 0.008, 0.002, beak, cls=METAL, bone=bone, seg=5, per=3)
    for s in (1, -1):
        b.ball(hd + V(0.02 * s, 0.008, 0.012), 0.006, "20c060", cls=CRYSTAL, bone=bone, seg=6, rings=4, mat=MAT_GLOW)
    b.tube([hd + V(0, 0, -0.02), hd + V(0, -0.01, -0.06)], [0.008, 0.008], "e04030", cls=CLOTH, bone=bone, seg=5)
    for k in range(5):
        b.leaf(c + V(0, 0.01, -0.08), c + V((k - 2) * 0.02, -0.02, -0.2), 0.015, col, cls=HAIR, bone=bone, n=3)

