"""Articulated xianxia cultivator built with the kit: rig, hanfu robe, anime face, hair styles,
weapons and seven baked animation clips.  The character scripts in ``art/characters`` only pick
colours and options.

Rig (Godot space, the model faces +Z, +X is the character's left):

    root - hips - spine - chest - neck - head - (eyes, hair_tail)
                              \\- upper_arm.L/R - forearm.L/R - hand.L/R
                              \\- cape - cape2
         hips - thigh.L/R - shin.L/R - foot.L/R
         hips - robe_f, robe_b, robe_l, robe_r   (skirt panels that swing with the legs)

Clips: idle (4 s loop), walk (2.1 s loop, three strides), sit (4 s loop, lotus meditation),
attack, cast, hurt (0.55 s) and victory (1.2 s).  The numbers mirror ``Models.anim_person`` in
``scripts/models.gd`` so the procedural and the Blender characters move the same way.
"""

import math

from kit import (CLOTH, CRYSTAL, HAIR, MAT_GLOW, MAT_PLAIN, METAL, SKIN, STONE, WOOD, Builder, Rig, V, darken, env, finish_rigged, lighten, mix, rgb)

SKIN_COL = "f4cfaa"
HIP_Y = 0.92
SHO = V(0.19, 1.44, 0.0)
ELB = V(0.24, 1.17, -0.01)
WRI = V(0.27, 0.93, 0.03)
KNEE = V(0.105, 0.5, 0.02)
ANK = V(0.105, 0.1, -0.01)


def make_rig():
    r = Rig("rig")
    r.bone("root", (0, 0, 0), (0, 0.25, 0))
    r.bone("hips", (0, HIP_Y, 0), (0, 1.05, 0), "root")
    r.bone("spine", (0, 1.05, 0), (0, 1.28, 0), "hips")
    r.bone("chest", (0, 1.28, 0), (0, 1.47, 0), "spine")
    r.bone("neck", (0, 1.47, 0.0), (0, 1.56, 0.01), "chest")
    r.bone("head", (0, 1.56, 0.01), (0, 1.88, 0.0), "neck")
    r.bone("eyes", (0, 1.675, 0.15), (0, 1.73, 0.15), "head")
    r.bone("hair_tail", (0, 1.8, -0.12), (0, 1.4, -0.2), "head")
    for s, sd in ((1, "L"), (-1, "R")):
        sh = V(SHO.x * s, SHO.y, SHO.z)
        el = V(ELB.x * s, ELB.y, ELB.z)
        wr = V(WRI.x * s, WRI.y, WRI.z)
        r.bone("upper_arm." + sd, sh, el, "chest")
        r.bone("forearm." + sd, el, wr, "upper_arm." + sd)
        r.bone("hand." + sd, wr, wr + V(0.01 * s, -0.1, 0.01), "forearm." + sd)
        kn = V(KNEE.x * s, KNEE.y, KNEE.z)
        an = V(ANK.x * s, ANK.y, ANK.z)
        r.bone("thigh." + sd, V(0.1 * s, HIP_Y, 0), kn, "hips")
        r.bone("shin." + sd, kn, an, "thigh." + sd)
        r.bone("foot." + sd, an, V(ANK.x * s, 0.03, 0.15), "shin." + sd)
    r.bone("robe_f", (0, 0.98, 0.13), (0, 0.3, 0.2), "hips")
    r.bone("robe_b", (0, 0.98, -0.13), (0, 0.3, -0.22), "hips")
    r.bone("robe_l", (0.17, 0.98, 0), (0.27, 0.3, 0), "hips")
    r.bone("robe_r", (-0.17, 0.98, 0), (-0.27, 0.3, 0), "hips")
    r.bone("cape", (0, 1.45, -0.14), (0, 1.0, -0.24), "chest")
    r.bone("cape2", (0, 1.0, -0.24), (0, 0.45, -0.34), "cape")
    return r


def clamp01(x):
    return max(0.0, min(1.0, x))


def torso_w(p):
    y = p.y
    wh = clamp01((1.12 - y) / 0.16)
    wc = clamp01((y - 1.2) / 0.16)
    ws = max(0.0, 1.0 - wh - wc)
    w = {"hips": wh, "spine": ws, "chest": wc}
    ax = abs(p.x)
    k = clamp01((ax - 0.15) / 0.07) * clamp01((y - 1.33) / 0.08)
    if k > 0:
        side = "L" if p.x > 0 else "R"
        for nm in list(w):
            w[nm] *= 1.0 - k * 0.7
        w["upper_arm." + side] = k * 0.7
    if y > 1.5:
        w = {"chest": 0.5, "neck": 0.5}
    return w


def skirt_w(p):
    t = clamp01((1.0 - p.y) / 0.7)
    a = math.atan2(p.x, p.z)
    cf = max(0.0, math.cos(a)) ** 2
    cb = max(0.0, -math.cos(a)) ** 2
    cl = max(0.0, math.sin(a)) ** 2
    cr = max(0.0, -math.sin(a)) ** 2
    k = t ** 0.8
    return {"hips": max(0.02, 1.0 - k), "robe_f": k * cf, "robe_b": k * cb, "robe_l": k * cl, "robe_r": k * cr}


def build(o):
    """o: robe, trim, hair, hair_style, eyes, inner, sash, boots, sword, staff, beard, cape,
    ribbon, crown, armor, metal, scale."""
    rig = make_rig()
    b = Builder("body")
    robe = o.get("robe", "3a8ae8")
    trim = o.get("trim", lighten(robe, 0.5))
    inner = o.get("inner", "f4f0e8")
    dark = darken(robe, 0.45)
    hair = o.get("hair", "1a1a2a")
    sash = o.get("sash", darken(robe, 0.55))
    boots = o.get("boots", "2a2430")
    pants = o.get("pants", darken(robe, 0.6))
    metal = o.get("metal", "b8bcc8")
    skin = o.get("skin", SKIN_COL)

    # ---------------- legs: trousers and boots
    for s, sd in ((1, "L"), (-1, "R")):
        hip = V(0.1 * s, HIP_Y - 0.02, 0)
        kn = V(KNEE.x * s, KNEE.y, KNEE.z)
        an = V(ANK.x * s, ANK.y, ANK.z)
        b.tube([hip, hip.lerp(kn, 0.5), kn, kn.lerp(an, 0.35)], [0.085, 0.075, 0.062, 0.058], pants, bones=["thigh." + sd, "thigh." + sd, {"thigh." + sd: 0.5, "shin." + sd: 0.5}, "shin." + sd], seg=12)
        # boot shaft, cuff and foot
        b.tube([kn.lerp(an, 0.3), kn.lerp(an, 0.7), an + V(0, -0.02, 0)], [0.064, 0.058, 0.058], boots, bones=["shin." + sd, "shin." + sd, {"shin." + sd: 0.5, "foot." + sd: 0.5}], seg=12, cls=CLOTH)
        b.tube([kn.lerp(an, 0.3) + V(0, 0.015, 0), kn.lerp(an, 0.3) - V(0, 0.015, 0)], [0.07, 0.07], trim, bone="shin." + sd, seg=12)
        b.ellipsoid(V(ANK.x * s, 0.05, 0.05), (0.06, 0.05, 0.12), boots, bone="foot." + sd, seg=14, rings=8, col2=darken(boots, 0.4))
        b.ellipsoid(V(ANK.x * s, 0.018, 0.04), (0.062, 0.018, 0.13), darken(boots, 0.5), bone="foot." + sd, seg=12, rings=6)
        # cloud-shoe toe: a small upturned tip in the trim colour
        b.tube([V(ANK.x * s, 0.04, 0.15), V(ANK.x * s, 0.06, 0.185), V(ANK.x * s, 0.09, 0.19)], [0.028, 0.018, 0.004], trim, bone="foot." + sd, seg=8)

    # ---------------- torso: inner robe and outer robe
    b.lathe(V(0, 0, 0), [(0.15, 0.9), (0.165, 1.02), (0.19, 1.18), (0.215, 1.32), (0.22, 1.4), (0.19, 1.47), (0.11, 1.52), (0.06, 1.545)], robe, seg=28, squash=(1.0, 0.74), col_top=lighten(robe, 0.08), bone_fn=torso_w, folds=(9, 0.035, 1.1))
    # crossed collar, left over right ("y" shape): the inner white collar shows at the neck and
    # the trimmed outer lapel sweeps from the neck down to the right hip; a band circles the nape
    b.auto = torso_w
    nape = [V(0.055, 1.52, 0.08)]
    for i in range(1, 8):
        a = i / 8 * math.pi
        nape.append(V(0.075 * math.cos(a) * 0.8 + 0.0, 1.535, -0.06 * math.sin(a) + 0.02 * math.cos(a)))
    b.tube(nape + [V(-0.055, 1.52, 0.08)], [0.02] * 9, trim, seg=8, flat=0.5, up=(0, 1, 0))
    b.tube([V(-0.055, 1.52, 0.08), V(-0.02, 1.47, 0.14), V(0.03, 1.4, 0.172)], [0.02, 0.02, 0.012], inner, seg=8, flat=0.45, up=(0, 0, 1))
    lap = [V(0.055, 1.52, 0.08), V(0.035, 1.47, 0.145), V(-0.02, 1.38, 0.178), V(-0.09, 1.24, 0.172), V(-0.14, 1.09, 0.15), V(-0.15, 1.03, 0.14)]
    mid_band = o.get("collar2", mix(sash, robe, 0.3))
    b.tube([q + V(0.012, 0.004, -0.004) for q in lap[:4]], [0.03] * 4, mid_band, seg=8, flat=0.4, up=(0, 0, 1))
    # the trimmed lapel carries embroidered dots along its length
    lap_fine = []
    for i in range(len(lap) - 1):
        for k in range(3):
            lap_fine.append(lap[i].lerp(lap[i + 1], k / 3))
    lap_fine.append(lap[-1])
    gold = o.get("embroidery", "f0c860")
    b.tube(lap_fine, [0.024] * len(lap_fine), trim, seg=8, flat=0.42, up=(0, 0, 1), cols=[mix(trim, gold, 0.7) if i % 3 == 1 else rgb(trim) for i in range(len(lap_fine))])
    b.auto = torso_w
    b.ellipsoid(V(0, 1.46, 0.105), (0.07, 0.045, 0.03), inner, seg=12, rings=6)
    # shoulders
    for s, sd in ((1, "L"), (-1, "R")):
        b.ellipsoid(V(0.17 * s, 1.43, 0.0), (0.085, 0.07, 0.085), mix(robe, trim, 0.15), bone={"chest": 0.5, "upper_arm." + sd: 0.5}, seg=14, rings=8)
    b.auto = None
    # sash / belt with a knot and hanging tails
    b.lathe(V(0, 0, 0), [(0.172, 0.94), (0.178, 0.97), (0.178, 1.03), (0.172, 1.06)], sash, seg=20, squash=(1.0, 0.76), bone="hips", cap_bottom=False, cap_top=False)
    b.ellipsoid(V(0.04, 1.0, 0.14), (0.05, 0.04, 0.03), lighten(sash, 0.15), bone="hips", seg=12, rings=6)
    # a gold belt plaque with a jade inlay, and a woven pattern band across the sash
    b.superquad(V(-0.06, 1.0, 0.142), (0.032, 0.026, 0.008), o.get("embroidery", "f0c860"), e=0.35, cls=METAL, bone="hips")
    b.ellipsoid(V(-0.06, 1.0, 0.151), (0.012, 0.012, 0.004), o.get("jade", "6af0b0"), cls=CRYSTAL, bone="hips", seg=8, rings=5)
    band = b.lathe(V(0, 0, 0), [(0.18, 0.985), (0.181, 1.015)], sash, seg=40, squash=(1.0, 0.76), bone="hips", cap_bottom=False, cap_top=False)
    b.recolor(band, lambda p: lighten(sash, 0.35) if math.sin(math.atan2(p.x, p.z) * 20.0) > 0.4 else None)
    for k, x in enumerate((0.02, 0.07)):
        b.ribbon([V(x, 0.99, 0.15), V(x + 0.01, 0.82, 0.17), V(x + 0.02, 0.62, 0.18)], [0.022, 0.02, 0.016], (1, 0, 0), sash, bones=[{"hips": 1}, {"hips": 0.5, "robe_f": 0.5}, {"robe_f": 1}], col_end=lighten(sash, 0.2))
    # jade pendant on a cord
    b.tube([V(-0.08, 0.97, 0.13), V(-0.085, 0.86, 0.15)], [0.004, 0.004], "c8a050", bone={"hips": 0.5, "robe_f": 0.5}, seg=5)
    b.ellipsoid(V(-0.085, 0.84, 0.155), (0.025, 0.03, 0.01), o.get("jade", "6af0b0"), cls=CRYSTAL, bone="robe_f", seg=10, rings=6)
    # skirt: long outer robe split at the front
    prof = [(0.18, 1.0), (0.2, 0.86), (0.23, 0.68), (0.26, 0.5), (0.29, 0.34), (0.31, 0.22)]
    folds = (o.get("folds", 14), 0.045, 0.4)
    b.lathe(V(0, 0, 0), prof, robe, seg=42, squash=(1.0, 0.82), cols=[robe, robe, robe, darken(robe, 0.05), darken(robe, 0.1), darken(robe, 0.15)], bone_fn=skirt_w, open_angle=0.55, folds=folds)
    # hem trim band, following the folds, embroidered with a repeating cloud scallop
    hem = b.lathe(V(0, 0, 0), [(0.312, 0.235), (0.318, 0.2)], trim, seg=42, squash=(1.0, 0.82), bone_fn=skirt_w, open_angle=0.55, folds=(folds[0], 0.045 * 0.95, folds[2]))
    def scallop(p):
        a = math.atan2(p.x, p.z)
        k = math.sin(a * 18.0) * 0.5 + 0.5
        return mix(trim, gold, 0.75) if (k > 0.72 and p.y > 0.212) or (p.y < 0.207 and k < 0.2) else None
    b.recolor(hem, scallop)
    # inner skirt (lighter layer seen through the slit)
    b.lathe(V(0, 0, 0), [(0.165, 0.97), (0.2, 0.7), (0.24, 0.4), (0.25, 0.27)], inner, seg=18, squash=(1.0, 0.8), bone_fn=skirt_w, cap_bottom=False, cap_top=False)
    # trim down both front edges of the slit
    for s in (1, -1):
        a = 0.275 * s
        pts = []
        for (r, y) in prof:
            pts.append(V(math.sin(a) * (r + 0.004), y, math.cos(a) * (r + 0.004) * 0.82))
        b.tube(pts, [0.016] * len(pts), trim, bone=None, bones=[skirt_w(p) for p in pts], seg=6, flat=0.5)

    # ---------------- arms: sleeves, bell cuffs and hands
    sleeve = o.get("sleeve", robe)
    for s, sd in ((1, "L"), (-1, "R")):
        sh = V(SHO.x * s, SHO.y, SHO.z)
        el = V(ELB.x * s, ELB.y, ELB.z)
        wr = V(WRI.x * s, WRI.y, WRI.z)
        ua = "upper_arm." + sd
        fa = "forearm." + sd
        b.tube([sh + V(-0.02 * s, 0.02, 0), sh.lerp(el, 0.5), el], [0.07, 0.066, 0.062], sleeve, bones=[{"chest": 0.3, ua: 0.7}, ua, {ua: 0.5, fa: 0.5}], seg=12)
        # wide hanfu sleeve, flaring towards the wrist and hanging lower at the back
        pts = [el, el.lerp(wr, 0.35), el.lerp(wr, 0.7), wr + V(0, -0.03, -0.02)]
        b.tube(pts, [(0.07, 0.07), (0.09, 0.11), (0.115, 0.15), (0.13, 0.17)], sleeve, bones=[{ua: 0.4, fa: 0.6}, fa, fa, fa], seg=14, cap1=False)
        for k, t in enumerate((0.3, 0.55)):
            q = el.lerp(wr, t)
            b.tube([q + V(0, 0.008, 0), q - V(0, 0.008, 0)], [(0.085 + 0.035 * t, 0.1 + 0.06 * t)] * 2, darken(sleeve, 0.12), bone=fa, seg=14, cap0=False, cap1=False)
        b.tube([wr + V(0, -0.02, -0.02), wr + V(0, -0.045, -0.02)], [(0.132, 0.172), (0.132, 0.172)], trim, bone=fa, seg=14, cap0=False, cap1=False)
        # inner cuff and hand
        b.tube([el.lerp(wr, 0.6), wr + V(0, -0.02, 0)], [0.04, 0.038], inner, bone=fa, seg=10)
        hc = wr + V(0.005 * s, -0.065, 0.01)
        b.ellipsoid(hc, (0.026, 0.042, 0.04), skin, cls=SKIN, bone="hand." + sd, seg=12, rings=8)
        # four fingers, gently curled, and a thumb on the front edge of the palm
        for k, (fz, fl) in enumerate(((0.024, 0.044), (0.008, 0.05), (-0.008, 0.048), (-0.023, 0.04))):
            f0 = hc + V(0.002 * s, -0.035, fz)
            f1 = f0 + V(-0.004 * s, -fl * 0.55, 0.004)
            f2 = f1 + V(-0.008 * s, -fl * 0.45, 0.012)
            b.tube([f0, f1, f2], [0.0095, 0.0085, 0.006], skin, cls=SKIN, bone="hand." + sd, seg=7)
        b.tube([hc + V(-0.012 * s, -0.005, 0.032), hc + V(-0.02 * s, -0.03, 0.05), hc + V(-0.022 * s, -0.05, 0.056)], [0.011, 0.009, 0.007], skin, cls=SKIN, bone="hand." + sd, seg=7)

    # ---------------- head
    if o.get("beast_head") is not None:
        b.tube([V(0, 1.47, 0.0), V(0, 1.58, 0.01)], [0.06, 0.055], o.get("head_col", "6a4a3a"), cls=CLOTH, bones=[{"neck": 0.6, "chest": 0.4}, {"neck": 0.5, "head": 0.5}], seg=12)
        beast_head(b, o)
    else:
        b.tube([V(0, 1.47, 0.0), V(0, 1.58, 0.01)], [0.048, 0.044], skin, cls=SKIN, bones=[{"neck": 0.6, "chest": 0.4}, {"neck": 0.5, "head": 0.5}], seg=12)
        b.ellipsoid(V(0, 1.7, 0.0), (0.175, 0.195, 0.185), skin, cls=SKIN, bone="head", seg=22, rings=14)
        # soft anime jaw and chin
        b.ellipsoid(V(0, 1.625, 0.045), (0.135, 0.105, 0.13), skin, cls=SKIN, bone="head", seg=18, rings=10)
        b.ellipsoid(V(0, 1.585, 0.1), (0.05, 0.035, 0.05), skin, cls=SKIN, bone="head", seg=12, rings=6)
        # ears
        for s in (1, -1):
            b.ellipsoid(V(0.172 * s, 1.68, -0.01), (0.022, 0.04, 0.03), skin, cls=SKIN, bone="head", seg=10, rings=6, rot=(0, 0.3 * s, 0))
        # cheeks blush, nose, mouth
        for s in (1, -1):
            b.ellipsoid(V(0.088 * s, 1.63, 0.152), (0.02, 0.008, 0.008), "f8b0a8", cls=SKIN, bone="head", seg=10, rings=5, rot=(0, 0.45 * s, 0), mat=MAT_PLAIN)
        b.ellipsoid(V(0, 1.645, 0.183), (0.012, 0.018, 0.012), mix(skin, "d89070", 0.3), cls=SKIN, bone="head", seg=8, rings=5, mat=MAT_PLAIN)
        mouth = []
        for i in range(5):
            t = i / 4 - 0.5
            mouth.append(V(t * 0.05, 1.598 + t * t * 0.03, 0.172 - abs(t) * 0.02))
        b.tube(mouth, [0.0045] * 5, "a04050", cls=SKIN, bone="head", seg=6, mat=MAT_PLAIN)
        # eyes on their own bone (it scales to blink)
        eyes = o.get("eyes", "3a6ad8")
        for s in (1, -1):
            b.eye(V(0.068 * s, 1.678, 0.155), 0.042, eyes, side=s, bone="eyes", rot_y=0.32, h=1.35, glow=o.get("glow_eyes", False), slit=o.get("slit_eyes", False))
            # eyelash line and brow
            lash = [V(0.068 * s + 0.045 * s * (i / 4 - 0.5) * 2, 1.722 - 0.012 * (i / 4 - 0.5) ** 2 * 4 + 0.004 * s * (i / 4 - 0.5), 0.172 - 0.01 * abs(i / 4 - 0.5)) for i in range(5)]
            b.tube(lash, [0.006, 0.008, 0.008, 0.007, 0.004], "1a1420", cls=HAIR, bone="eyes", seg=6, mat=MAT_PLAIN)
            brow = [V(0.068 * s + 0.04 * s * (i / 3 - 0.5) * 2, 1.765 + 0.008 * (1 - abs(i / 3 - 0.5) * 2) - (0.01 * s * (i / 3 - 0.5) if o.get("stern", False) else 0), 0.168) for i in range(4)]
            b.tube(brow, [0.006, 0.008, 0.007, 0.004], darken(hair, 0.2), cls=HAIR, bone="head", seg=6, mat=MAT_PLAIN)
        hair_style(b, o.get("hair_style", "topknot"), hair, o)
    if o.get("beard", False):
        bc = o.get("beard_col", "e8e8f0")
        for i in range(7):
            a = (i / 6 - 0.5) * 1.6
            root = V(math.sin(a) * 0.1, 1.6 - abs(a) * 0.02, 0.1 + math.cos(a) * 0.04)
            b.tube([root, root + V(math.sin(a) * 0.03, -0.12, 0.04), root + V(math.sin(a) * 0.02, -0.28 + abs(a) * 0.08, 0.05)], [0.022, 0.018, 0.004], bc, cls=HAIR, bones=["head", {"head": 0.7, "neck": 0.3}, {"head": 0.5, "neck": 0.5}], seg=7)
        for s in (1, -1):
            b.tube([V(0.03 * s, 1.618, 0.17), V(0.09 * s, 1.6, 0.15), V(0.13 * s, 1.52, 0.12)], [0.012, 0.01, 0.003], bc, cls=HAIR, bone="head", seg=6)
    if o.get("crown", False):
        gold = "f0c850"
        b.lathe(V(0, 1.86, -0.03), [(0.07, 0.0), (0.075, 0.04), (0.06, 0.06)], gold, cls=METAL, bone="head", seg=14)
        for i in range(5):
            a = (i / 4 - 0.5) * 2.0
            b.cone(V(math.sin(a) * 0.07, 1.93, -0.03 + math.cos(a) * 0.05), 0.016, 0.07, gold, cls=METAL, bone="head", seg=6)
        b.ball(V(0, 1.9, 0.04), 0.018, "ff5060", cls=CRYSTAL, bone="head", seg=10, rings=6)

    # ---------------- cape
    if o.get("cape") is not None:
        cc = o["cape"]
        rows = []
        bones = []
        n = 7
        for j in range(n):
            t = j / (n - 1)
            y = 1.46 - t * 1.02
            half = 0.2 + t * 0.12
            z = -0.15 - t * 0.17
            row = []
            for i in range(7):
                u = i / 6 - 0.5
                row.append(V(u * 2 * half, y + abs(u) * 0.03, z - (1 - (u * 2) ** 2) * 0.03))
            rows.append(row)
            if t < 0.15:
                bones.append({"chest": 1.0})
            elif t < 0.5:
                k = (t - 0.15) / 0.35
                bones.append({"chest": 1 - k, "cape": k})
            else:
                k = (t - 0.5) / 0.5
                bones.append({"cape": 1 - k, "cape2": k})
        b.sheet(rows, cc, bones=bones, cols=[mix(cc, darken(cc, 0.3), j / (n - 1)) for j in range(n)], thickness=0.012)
        for s in (1, -1):
            b.ellipsoid(V(0.17 * s, 1.47, -0.08), (0.035, 0.035, 0.02), "f0c850", cls=METAL, bone="chest", seg=10, rings=6)

    # ---------------- armour
    if o.get("armor", False):
        for s, sd in ((1, "L"), (-1, "R")):
            b.superquad(V(0.2 * s, 1.44, 0), (0.1, 0.06, 0.1), metal, e=0.4, cls=METAL, bone={"chest": 0.4, "upper_arm." + sd: 0.6}, rot=(0, 0, -0.35 * s))
        b.superquad(V(0, 1.27, 0.13), (0.16, 0.13, 0.05), metal, e=0.4, cls=METAL, bone={"spine": 0.5, "chest": 0.5})

    # ---------------- weapons
    if o.get("sword", False):
        sword(b, "hand.R", WRI * V(-1, 1, 1) + V(0, -0.08, 0.02), o.get("blade", "dce8ff"), o.get("hilt", "3a3048"))
        # scabbard at the left hip
        b.tube([V(0.2, 0.98, -0.05), V(0.27, 0.62, -0.2)], [0.022, 0.018], o.get("scabbard", "2a2a40"), cls=WOOD, bones=[{"hips": 1}, {"hips": 0.5, "robe_l": 0.5}], seg=8, flat=0.5)
    if o.get("staff", False):
        hc = WRI * V(-1, 1, 1) + V(0, -0.07, 0.02)
        b.tube([hc + V(0, -0.8, 0), hc + V(0, 0.6, 0)], [0.018, 0.016], "7a5a3a", cls=WOOD, bone="hand.R", seg=8)
        top = hc + V(0, 0.66, 0)
        for i in range(8):
            a = 2 * math.pi * i / 8
            b.tube([top, top + V(math.cos(a) * 0.06, 0.06 + math.sin(a) * 0.06, 0)], [0.01, 0.006], "c8a050", cls=METAL, bone="hand.R", seg=5)
        b.ball(top + V(0, 0.06, 0), 0.035, o.get("staff_gem", "8af0ff"), cls=CRYSTAL, bone="hand.R", seg=12, rings=8, mat=MAT_GLOW)
    if o.get("ribbon") is not None:
        rc = o["ribbon"]
        for s in (1, -1):
            b.ribbon([V(0.08 * s, 1.84, -0.12), V(0.14 * s, 1.72, -0.2), V(0.16 * s, 1.55, -0.24)], [0.03, 0.025, 0.01], (1, 0, 0), rc, bones=["head", {"head": 0.5, "hair_tail": 0.5}, "hair_tail"], col_end=lighten(rc, 0.3))
            b.ellipsoid(V(0.07 * s, 1.85, -0.11), (0.04, 0.03, 0.02), rc, bone="head", seg=10, rings=6, rot=(0, 0, 0.5 * s))
    hat = o.get("hat")
    if hat == "straw":
        # wide conical straw hat (douli) with a chin cord
        b.lathe(V(0, 1.86, -0.02), [(0.42, 0.0), (0.38, 0.03), (0.2, 0.12), (0.04, 0.2), (0.001, 0.22)], o.get("hat_col", "d8c080"), cls=WOOD, bone="head", seg=20, cap_bottom=True)
        for side in (1, -1):
            b.tube([V(0.16 * side, 1.84, 0.0), V(0.12 * side, 1.66, 0.08), V(0.0, 1.56, 0.13)], [0.005] * 3, "6a4a2a", cls=CLOTH, bone="head", seg=4)
    elif hat == "scholar":
        # black gauze scholar's cap with stiff side wings
        b.lathe(V(0, 1.84, -0.03), [(0.17, 0.0), (0.18, 0.08), (0.14, 0.16), (0.001, 0.18)], "1a1a22", cls=CLOTH, bone="head", seg=16)
        for side in (1, -1):
            b.superquad(V(0.26 * side, 1.92, -0.06), (0.1, 0.02, 0.006), "1a1a22", e=0.3, cls=CLOTH, bone="head")
    elif hat == "hood":
        b.ellipsoid(V(0, 1.74, -0.04), (0.22, 0.23, 0.23), o.get("hat_col", "6a5a8a"), cls=CLOTH, bone="head", seg=18, rings=10, squash_top=1.1)
        b.tube([V(0, 1.9, -0.18), V(0, 1.7, -0.3), V(0, 1.45, -0.28)], [0.12, 0.1, 0.05], o.get("hat_col", "6a5a8a"), cls=CLOTH, bones=["head", {"head": 0.5, "hair_tail": 0.5}, "hair_tail"], seg=10)
    elif hat == "fur":
        b.lathe(V(0, 1.8, -0.02), [(0.21, 0.0), (0.23, 0.05), (0.22, 0.14), (0.15, 0.2), (0.001, 0.22)], o.get("hat_col", "c8b8a0"), cls=HAIR, bone="head", seg=18)
    elif hat == "qing":
        # Qing-dynasty official's hat: a turned-up brim, a domed crown, a red silk fringe and a bead
        b.lathe(V(0, 1.82, -0.02), [(0.25, 0.0), (0.24, 0.035), (0.17, 0.05), (0.16, 0.12), (0.1, 0.17), (0.001, 0.18)], o.get("hat_col", "2a2a30"), cls=CLOTH, bone="head", seg=20)
        b.lathe(V(0, 1.86, -0.02), [(0.15, 0.0), (0.12, 0.1), (0.001, 0.14)], "c02a20", cls=HAIR, bone="head", seg=18, folds=(16, 0.12, 0.0))
        b.ball(V(0, 2.01, -0.02), 0.03, "e8c050", cls=METAL, bone="head", seg=10, rings=6)
        b.tube([V(0, 1.99, -0.05), V(0, 1.95, -0.2), V(0, 1.8, -0.3)], [0.02, 0.03, 0.006], "3a8a7a", cls=HAIR, bone="head", seg=6, flat=0.4)
    if o.get("talisman", False):
        # a yellow paper talisman pasted to the forehead, brushed with red script
        tal = b.ribbon([V(0, 1.84, 0.17), V(0, 1.72, 0.2), V(0.01, 1.56, 0.19)], [0.045, 0.045, 0.042], (1, 0, 0), "f0d860", bone="head", col_end="e8c850")
        b.recolor(tal, lambda p: "c02018" if abs(p.x) < 0.012 and int(p.y * 60) % 3 != 0 else None)
    if o.get("halberd", False):
        hc2 = WRI * V(-1, 1, 1) + V(0, -0.07, 0.02)
        b.tube([hc2 + V(0, -0.9, 0), hc2 + V(0, 0.95, 0)], [0.022, 0.02], "4a3020", cls=WOOD, bone="hand.R", seg=8)
        top2 = hc2 + V(0, 0.95, 0)
        b.cone(top2 + V(0, 0.18, 0), 0.04, 0.36, "c8ccd8", cls=METAL, bone="hand.R", seg=6)
        b.tube([top2 + V(0, 0.02, 0), top2 + V(0.06, 0.06, 0.18), top2 + V(0.0, -0.08, 0.3)], [(0.03, 0.006), (0.06, 0.008), (0.01, 0.004)], "c8ccd8", cls=METAL, bone="hand.R", seg=6, up=(1, 0, 0))
        b.ribbon([top2 + V(0, -0.04, 0), top2 + V(0.02, -0.18, -0.05), top2 + V(0.03, -0.34, -0.06)], [0.03, 0.035, 0.01], (1, 0, 0), "c02a20", bone="hand.R", col_end="ff6040")
    if o.get("horns", False):
        hcol = o.get("horn_col", "2a1a20")
        for side in (1, -1):
            pts = [V(0.1 * side, 1.84, 0.02), V(0.16 * side, 1.95, -0.02), V(0.22 * side, 2.04, -0.1), V(0.2 * side, 2.12, -0.2)]
            b.tube(pts, [0.04, 0.032, 0.02, 0.004], hcol, cls=STONE, bone="head", seg=8)
    if o.get("tint_cloth", False):
        # a recolourable enemy: every cloth surface takes the colour the game asks for
        for v in b.bm.verts:
            if v[b.cl][3] > 0.94:
                v[b.tl] = 1.0
    hk = o.get("head_scale", 0.9)
    if hk != 1.0:
        pivot = V(0, 1.58, 0.0)
        b.scale_where(lambda w: w.get("head", 0.0) + w.get("eyes", 0.0) + w.get("hair_tail", 0.0) >= 0.5, pivot, hk)
        for nm in ("eyes", "hair_tail"):
            h0, t0, par = rig.bones[nm]
            rig.bones[nm] = (pivot + (V(h0) - pivot) * hk, pivot + (V(t0) - pivot) * hk, par)
        h0, t0, par = rig.bones["head"]
        rig.bones["head"] = (h0, pivot + (V(t0) - pivot) * hk, par)
    sc = o.get("scale", 1.0)
    if sc != 1.0:
        for v in b.bm.verts:
            v.co *= sc
        for nm in list(rig.bones):
            h, t, p = rig.bones[nm]
            rig.bones[nm] = (h * sc, t * sc, p)
    return b, rig


def beast_head(b, o):
    """Animal heads for the runners of the underworld: 'ox' (Ox-Head) and 'horse' (Horse-Face)."""
    kind = o["beast_head"]
    hc = o.get("head_col", "6a4a3a")
    muz = o.get("muzzle_col", lighten(hc, 0.25))
    eye = o.get("eyes", "ff4020")
    if kind == "ox":
        b.ellipsoid(V(0, 1.74, 0.0), (0.18, 0.16, 0.18), hc, cls=CLOTH, bone="head", seg=20, rings=12)
        b.ellipsoid(V(0, 1.63, 0.16), (0.13, 0.1, 0.13), muz, cls=SKIN, bone="head", seg=18, rings=10)
        for s in (1, -1):
            b.ellipsoid(V(0.045 * s, 1.63, 0.285), (0.022, 0.016, 0.01), "1a1010", cls=SKIN, bone="head", seg=8, rings=5)
            # sweeping horns, pale at the tips
            b.tube([V(0.13 * s, 1.84, 0.0), V(0.27 * s, 1.88, -0.02), V(0.36 * s, 1.96, 0.04), V(0.36 * s, 2.08, 0.12)], [0.05, 0.04, 0.026, 0.004], "e8dcc0", cls=STONE, bone="head", seg=10, cols=["8a7a60", "c8b898", "e8dcc0", "f8f0e0"])
            b.ellipsoid(V(0.19 * s, 1.74, -0.02), (0.07, 0.03, 0.045), hc, cls=CLOTH, bone="head", seg=10, rings=6, rot=(0, 0, 0.4 * s))
            b.tube([V(0.07 * s, 1.81, 0.15), V(0.12 * s, 1.8, 0.13)], [0.022, 0.016], darken(hc, 0.3), bone="head", seg=6)
        ring = []
        for i in range(13):
            a = 2 * math.pi * i / 12
            ring.append(V(math.sin(a) * 0.04, 1.585 + math.cos(a) * 0.035, 0.28))
        b.tube(ring, [0.007] * 13, "e8c050", cls=METAL, bone="head", seg=6)
        for s in (1, -1):
            b.eye(V(0.09 * s, 1.76, 0.155), 0.03, eye, side=s, bone="eyes", rot_y=0.4, h=0.9, glow=True, slit=False)
    else:
        b.ellipsoid(V(0, 1.76, -0.01), (0.13, 0.15, 0.16), hc, cls=CLOTH, bone="head", seg=20, rings=12)
        b.tube([V(0, 1.76, 0.06), V(0, 1.68, 0.22), V(0, 1.58, 0.38)], [(0.1, 0.12), (0.085, 0.1), (0.075, 0.07)], hc, bone="head", seg=14)
        b.ellipsoid(V(0, 1.565, 0.4), (0.075, 0.065, 0.07), muz, cls=SKIN, bone="head", seg=14, rings=8)
        b.tube([V(0, 1.82, 0.04), V(0, 1.72, 0.24), V(0, 1.62, 0.36)], [0.025, 0.03, 0.02], lighten(hc, 0.5), bone="head", seg=6)
        for s in (1, -1):
            b.ellipsoid(V(0.035 * s, 1.585, 0.46), (0.016, 0.022, 0.01), "1a1010", cls=SKIN, bone="head", seg=8, rings=5)
            b.cone(V(0.07 * s, 1.93, -0.03), 0.026, 0.11, hc, cls=CLOTH, bone="head", seg=8, rot=(-0.3, 0, -0.2 * s))
            b.eye(V(0.12 * s, 1.78, 0.09), 0.032, eye, side=s, bone="eyes", rot_y=1.0, h=0.95, glow=True, slit=False)
        mane = o.get("hair", "1a1010")
        for i in range(10):
            y = 1.93 - i * 0.045
            z = -0.05 - i * 0.012
            b.leaf(V(0, y, z), V(0.0, y - 0.04, z - 0.2), 0.06, mane, side=(1, 0, 0), cls=HAIR, bone="head" if i < 6 else "neck", col_tip=lighten(mane, 0.2))


def sword(b, bone, grip, blade, hilt):
    """A jian held in the hand: grip, guard, long double-edged blade pointing forward."""
    g = V(grip)
    d = V(0, -0.25, 1.0).normalized()
    up = V(1, 0, 0)
    b.tube([g - d * 0.09, g + d * 0.06], [0.016, 0.016], hilt, cls=WOOD, bone=bone, seg=8)
    b.ball(g - d * 0.1, 0.022, "d8b050", cls=METAL, bone=bone, seg=10, rings=6)
    b.ellipsoid(g + d * 0.08, (0.07, 0.02, 0.025), "d8b050", cls=METAL, bone=bone, rot=(math.atan2(-d.y, d.z), 0, 0), seg=12, rings=6)
    pts = [g + d * (0.09 + 0.78 * t) for t in (0.0, 0.3, 0.7, 0.95)]
    b.tube(pts, [(0.024, 0.006), (0.023, 0.006), (0.02, 0.005), (0.006, 0.002)], blade, cls=METAL, bone=bone, seg=8, up=up)
    # a faint glowing edge
    b.tube([g + d * 0.12, g + d * 0.85], [(0.003, 0.0035), (0.002, 0.002)], lighten(blade, 0.5), cls=CRYSTAL, bone=bone, seg=5, mat=MAT_GLOW, up=up)
    # tassel
    b.ribbon([g - d * 0.1, g - d * 0.12 + V(0, -0.1, 0), g - d * 0.14 + V(0, -0.2, 0)], [0.012, 0.014, 0.004], (1, 0, 0), "e04050", bone=bone, col_end="ff8090")


def hair_style(b, style, hc, o):
    """Hair cap, bangs, side locks and the style's crown piece (strands are tapered tubes)."""
    dk = darken(hc, 0.25)
    if style == "bald":
        b.ellipsoid(V(0, 1.72, -0.01), (0.182, 0.18, 0.19), mix("f4cfaa", "e8d0c0", 0.3), cls=SKIN, bone="head", seg=20, rings=12)
        # white hair ring at the back of the head
        for i in range(9):
            a = math.pi * 0.35 + (i / 8) * math.pi * 1.3
            root = V(math.sin(a) * 0.18, 1.67, math.cos(a) * 0.18)
            b.tube([root, root + V(math.sin(a) * 0.03, -0.08, math.cos(a) * 0.02)], [0.03, 0.01], o.get("beard_col", "e8e8f0"), cls=HAIR, bone="head", seg=6)
        return
    b.ellipsoid(V(0, 1.735, -0.03), (0.19, 0.19, 0.2), hc, cls=HAIR, bone="head", seg=22, rings=14, squash_top=1.05)
    lt = lighten(hc, 0.12)
    # layered locks sweep from the crown over the cap, so the hair has volume and a ragged,
    # strand-by-strand silhouette instead of reading as a smooth helmet
    crown = V(0, 1.935, -0.04)
    n_locks = 18
    for i in range(n_locks):
        a = math.pi * 0.28 + (i / (n_locks - 1)) * math.pi * 1.44
        ca, sa = math.cos(a), math.sin(a)
        rim = V(sa * 0.205, 1.7 - 0.05 * (1 + math.cos(a)) * 0.5, ca * 0.21 - 0.03)
        mid = crown.lerp(rim, 0.55) + V(sa * 0.06, 0.03, ca * 0.05)
        tip = rim + V(sa * 0.03, -0.08 - 0.06 * (i % 3) / 2, ca * 0.025)
        b.tube([crown + V(sa * 0.03, 0, ca * 0.03), mid, rim, tip], [0.05, 0.055, 0.04, 0.004], (dk, hc, lt)[i % 3], cls=HAIR, bone="head", seg=7, flat=0.45, up=(0, 1, 0))
    # bangs: tapered locks over the forehead, clumped in twos and threes
    for i in range(11):
        u = i / 10 - 0.5
        clump = (-0.012, 0.0, 0.012)[i % 3]
        root = V(u * 0.24, 1.865, 0.05)
        tip = V(u * 0.36 + clump, 1.69 + abs(u) * 0.12 + (0.025 if i % 2 else 0.0), 0.195 - abs(u) * 0.07)
        mid = root.lerp(tip, 0.5) + V(0, 0.012, 0.055)
        b.tube([root, mid, tip], [0.034, 0.028, 0.003], (hc, dk, lt)[i % 3] if i % 4 else dk, cls=HAIR, bone="head", seg=7, flat=0.5, up=(0, 0, 1))
    if o.get("ahoge", False):
        b.tube([V(0, 1.93, 0.0), V(0.03, 2.02, 0.03), V(0.07, 2.03, 0.08), V(0.08, 1.99, 0.1)], [0.012, 0.01, 0.007, 0.002], hc, cls=HAIR, bone="head", seg=6, flat=0.5)
    # side locks
    for s in (1, -1):
        b.tube([V(0.155 * s, 1.78, 0.07), V(0.18 * s, 1.64, 0.1), V(0.17 * s, 1.5, 0.08)], [0.03, 0.03, 0.004], hc, cls=HAIR, bones=["head", "head", {"head": 0.7, "neck": 0.3}], seg=7, flat=0.5, up=(0, 0, 1))
        b.tube([V(0.17 * s, 1.76, 0.03), V(0.2 * s, 1.62, 0.04), V(0.19 * s, 1.46, 0.02)], [0.028, 0.026, 0.003], dk, cls=HAIR, bones=["head", "head", {"head": 0.6, "neck": 0.4}], seg=7, flat=0.5, up=(0, 0, 1))
    if style == "topknot":
        b.ball(V(0, 1.93, -0.05), 0.075, hc, cls=HAIR, bone="head", seg=14, rings=10)
        b.lathe(V(0, 1.89, -0.05), [(0.075, 0.0), (0.078, 0.025), (0.07, 0.04)], "f0c850", cls=METAL, bone="head", seg=14)
        b.tube([V(-0.13, 1.94, -0.05), V(0.13, 1.94, -0.05)], [0.006, 0.006], "d8b050", cls=METAL, bone="head", seg=6)
        # high ponytail swinging from the knot
        for k in range(5):
            off = V((k - 2) * 0.018, 0, (k % 2) * 0.01)
            pts = [V(0, 1.92, -0.1) + off, V(0, 1.82, -0.2) + off * 1.5, V(0, 1.62, -0.24) + off * 2, V(0, 1.42, -0.22) + off * 2.4]
            b.tube(pts, [0.03, 0.03, 0.022, 0.003], hc if k % 2 else dk, cls=HAIR, bones=["head", {"head": 0.5, "hair_tail": 0.5}, "hair_tail", "hair_tail"], seg=7)
    elif style == "long":
        b.ellipsoid(V(0, 1.66, -0.1), (0.19, 0.22, 0.13), hc, cls=HAIR, bone={"head": 0.7, "hair_tail": 0.3}, seg=18, rings=10)
        for k in range(11):
            u = k / 10 - 0.5
            root = V(u * 0.3, 1.8, -0.12)
            pts = [root, root + V(u * 0.1, -0.22, -0.06), root + V(u * 0.12, -0.45, -0.07), root + V(u * 0.1, -0.68, -0.05)]
            b.tube(pts, [0.04, 0.04, 0.03, 0.004], hc if k % 3 else dk, cls=HAIR, bones=["head", {"head": 0.5, "hair_tail": 0.5}, "hair_tail", "hair_tail"], seg=7, flat=0.6, up=(0, 0, 1))
        # side bun with a jade pin
        b.ball(V(0.12, 1.86, -0.08), 0.06, hc, cls=HAIR, bone="head", seg=12, rings=8)
        b.tube([V(0.06, 1.9, -0.05), V(0.22, 1.86, -0.12)], [0.006, 0.005], o.get("pin", "6af0b0"), cls=CRYSTAL, bone="head", seg=6)
    elif style == "bun":
        b.ball(V(0, 1.8, -0.2), 0.085, hc, cls=HAIR, bone="head", seg=14, rings=10)
        b.tube([V(-0.1, 1.84, -0.2), V(0.12, 1.79, -0.22)], [0.006, 0.006], o.get("pin", "6af0b0"), cls=CRYSTAL, bone="head", seg=6)
    elif style == "wild":
        for i in range(11):
            a = -1.4 + i * 0.28
            root = V(math.sin(a) * 0.1, 1.8, math.cos(a) * 0.05 - 0.08)
            b.tube([root, root + V(math.sin(a) * 0.22, 0.1 + math.cos(a) * 0.06, -0.12)], [0.05, 0.004], hc, cls=HAIR, bone="head", seg=7)


# ---------------------------------------------------------------- animation
def _blink(t, at):
    for a in at:
        if a <= t < a + 0.12:
            return 0.12
    return 1.0


def _secondary(p, t, walking, sit, legs_x, lag):
    """Robe panels, cape and hair follow the legs and the stride."""
    fwd = max(-legs_x[0], -legs_x[1]) if not sit else 1.2
    back = max(legs_x[0], legs_x[1])
    p["robe_f"] = ((-max(0.0, fwd) * 0.8 - (0.15 if walking else 0.0), 0, 0), (0, 0, 0))
    p["robe_b"] = ((max(0.0, back) * 0.6 + (0.3 if walking else 0.03), 0, 0), (0, 0, 0))
    p["robe_l"] = ((-abs(legs_x[0]) * 0.35 - (0.6 if sit else 0.0), 0, -0.05 if not sit else -0.5), (0, 0, 0))
    p["robe_r"] = ((-abs(legs_x[1]) * 0.35 - (0.6 if sit else 0.0), 0, 0.05 if not sit else 0.5), (0, 0, 0))
    p["cape"] = ((0.12 + (0.45 + 0.12 * lag if walking else 0.04 * math.sin(t * 2 * math.pi / 4)), 0, 0), (0, 0, 0))
    p["cape2"] = ((0.1 + (0.25 * abs(lag) if walking else 0.03 * math.sin(t * 2 * math.pi / 2)), 0, 0), (0, 0, 0))
    p["hair_tail"] = ((0.15 + (0.35 if walking else 0.05) * abs(lag), 0, lag * (0.25 if walking else 0.06)), (0, 0, 0))


def clip_idle(t):
    w = 2 * math.pi / 4.0
    br = math.sin(t * w * 2)
    p = {}
    p["hips"] = ((0, math.sin(t * w) * 0.05, 0), (0, br * 0.008, 0))
    p["spine"] = ((br * 0.01, 0, 0), (0, 0, 0))
    p["chest"] = ((-br * 0.015, 0, 0), (0, 0, 0))
    p["head"] = ((math.sin(t * w * 1) * 0.04, math.sin(t * w) * 0.16, math.sin(t * w * 2) * 0.03), (0, 0, 0))
    p["upper_arm.L"] = ((math.sin(t * w * 2) * 0.04, 0, -0.08 - br * 0.02), (0, 0, 0))
    p["upper_arm.R"] = ((-math.sin(t * w * 2) * 0.04, 0, 0.08 + br * 0.02), (0, 0, 0))
    p["forearm.L"] = ((-0.2, 0, 0), (0, 0, 0))
    p["forearm.R"] = ((-0.25, 0, 0), (0, 0, 0))
    p["shin.L"] = ((0.04, 0, 0), (0, 0, 0))
    p["shin.R"] = ((0.04, 0, 0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, _blink(t, (1.3, 3.4)), 1))
    _secondary(p, t, False, False, (0.0, 0.0), math.sin(t * w * 2))
    return p


WALK_T = 2.1


def clip_walk(t):
    ph = t * 2 * math.pi * 3 / WALK_T
    sw = math.sin(ph)
    p = {}
    legs = (sw * 0.62, -sw * 0.62)
    p["thigh.L"] = ((legs[0], 0, 0), (0, 0, 0))
    p["thigh.R"] = ((legs[1], 0, 0), (0, 0, 0))
    p["shin.L"] = ((0.15 + max(0.0, -math.cos(ph)) * 0.95, 0, 0), (0, 0, 0))
    p["shin.R"] = ((0.15 + max(0.0, math.cos(ph)) * 0.95, 0, 0), (0, 0, 0))
    p["foot.L"] = ((-0.2 * max(0.0, sw), 0, 0), (0, 0, 0))
    p["foot.R"] = ((-0.2 * max(0.0, -sw), 0, 0), (0, 0, 0))
    p["upper_arm.L"] = ((-sw * 0.5, 0, -0.12), (0, 0, 0))
    p["upper_arm.R"] = ((sw * 0.4, 0, 0.12), (0, 0, 0))
    p["forearm.L"] = ((-0.35 - max(0.0, sw) * 0.3, 0, 0), (0, 0, 0))
    p["forearm.R"] = ((-0.35 - max(0.0, -sw) * 0.3, 0, 0), (0, 0, 0))
    p["hips"] = ((0.07, sw * 0.12, 0), (0, abs(math.sin(ph)) * 0.045, 0))
    p["chest"] = ((0, -sw * 0.08, 0), (0, 0, 0))
    p["head"] = ((-0.05, -sw * 0.06, 0), (0, 0, 0))
    lag = math.sin(ph - 0.8)
    _secondary(p, t, True, False, legs, lag)
    return p


def clip_sit(t):
    w = 2 * math.pi / 4.0
    br = math.sin(t * w)
    p = {}
    for i, sd in enumerate(("L", "R")):
        s = 1 if sd == "L" else -1
        p["thigh." + sd] = ((-1.45, 0, 0.55 * s), (0, 0, 0))
        p["shin." + sd] = ((2.5, 0, 0), (0, 0, 0))
        p["foot." + sd] = ((0.3, 0, 0), (0, 0, 0))
        p["upper_arm." + sd] = ((-0.55, 0, 0.25 * s), (0, 0, 0))
        p["forearm." + sd] = ((-0.9, 0, -0.35 * s), (0, 0, 0))
        p["hand." + sd] = ((0.2, 0, 0), (0, 0, 0))
    p["hips"] = ((0, 0, 0), (0, br * 0.006, 0))
    p["chest"] = ((-br * 0.02, 0, 0), (0, 0, 0))
    p["head"] = ((0.12 + br * 0.02, 0, 0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 0.15, 1))
    _secondary(p, t, False, True, (-1.45, -1.45), br)
    return p


ACT_T = 0.55


def _base_for_act():
    p = clip_idle(0.0)
    return p


def clip_attack(t):
    k = t / ACT_T
    e = env(k)
    cut = max(0.0, min(1.0, (k - 0.3) / 0.35))
    p = _base_for_act()
    # wind up behind the head, then a fast diagonal cut with the sword arm (right)
    p["upper_arm.R"] = ((-2.6 + 3.0 * cut, 0, -(0.5 - 0.8 * cut)), (0, 0, 0))
    p["forearm.R"] = ((-0.9 + 0.8 * cut, 0, 0), (0, 0, 0))
    p["upper_arm.L"] = ((-0.6 * e, 0, -0.5 * e), (0, 0, 0))
    p["hips"] = ((0.1 * e, (0.5 - 1.1 * cut) * e * 0.5, 0), (0, 0, 0.08 * e))
    p["chest"] = ((0.15 * e, (0.5 - 1.1 * cut) * e * 0.6, 0), (0, 0, 0))
    p["thigh.L"] = ((-0.5 * e, 0, 0), (0, 0, 0))
    p["shin.L"] = ((0.4 * e, 0, 0), (0, 0, 0))
    p["thigh.R"] = ((0.35 * e, 0, 0), (0, 0, 0))
    _secondary(p, t, False, False, (-0.5 * e, 0.35 * e), e)
    return p


def clip_cast(t):
    e = env(t / ACT_T)
    p = _base_for_act()
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-1.5 * e, 0, -(0.15 + 0.5 * e) * s), (0, 0, 0))
        p["forearm." + sd] = ((-0.6 * e, 0, 0), (0, 0, 0))
        p["hand." + sd] = ((-0.4 * e, 0, 0), (0, 0, 0))
    p["head"] = ((-0.25 * e, 0, 0), (0, 0, 0))
    p["chest"] = ((-0.12 * e, 0, 0), (0, 0, 0))
    p["hips"] = ((0, 0, 0), (0, 0.04 * e, 0))
    p["cape"] = ((0.4 * e, 0, 0), (0, 0, 0))
    return p


def clip_hurt(t):
    e = env(t / ACT_T)
    p = _base_for_act()
    p["chest"] = ((-0.35 * e, 0, 0.05 * e), (0, 0, 0))
    p["spine"] = ((-0.1 * e, 0, 0), (0, 0, 0))
    p["head"] = ((-0.3 * e, 0.2 * e, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["upper_arm." + sd] = ((0.5 * e, 0, 0), (0, 0, 0))
    p["hips"] = ((0, 0, 0), (0, 0, -0.08 * e))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 - 0.8 * e, 1))
    return p


def clip_victory(t):
    k = min(1.0, t / 0.35)
    e = math.sin(k * math.pi / 2)
    p = _base_for_act()
    p["upper_arm.R"] = ((-2.8 * e, 0, -0.2), (0, 0, 0))
    p["forearm.R"] = ((-0.2, 0, 0), (0, 0, 0))
    p["upper_arm.L"] = ((0.1, 0, -0.3 * e), (0, 0, 0))
    p["forearm.L"] = ((-1.2 * e, 0, 0), (0, 0, 0))
    p["head"] = ((-0.15 * e, 0, 0), (0, 0, 0))
    p["chest"] = ((-0.06 * e, 0, 0), (0, 0, 0))
    return p


CLIPS = {
    "idle": (4.0, clip_idle),
    "walk": (WALK_T, clip_walk),
    "sit": (4.0, clip_sit),
    "attack": (ACT_T, clip_attack),
    "cast": (ACT_T, clip_cast),
    "hurt": (ACT_T, clip_hurt),
    "victory": (1.2, clip_victory),
}


def export_person(rel, opts, clips=None):
    b, rig = build(opts)
    print("[art] %s: %d triangles" % (rel, b.tri_count()))
    return finish_rigged(b, rig, rel, clips or CLIPS, samples=16, dist=0.25, strength=0.5, floor_y=0.0, floor_k=0.2)
